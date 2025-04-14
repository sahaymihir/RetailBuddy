// app/javascript/controllers/billing_controller.js
import { Controller } from "@hotwired/stimulus"
import { v4 as uuidv4 } from "uuid"

export default class extends Controller {
  static targets = [
    "billItemsBody",      // The <tbody> of the current bill table
    "summarySubtotal",    // The <span> for the subtotal (before tax)
    "summaryTotalTax",    // The <span> for the total calculated tax << NEW TARGET
    "summaryGrandTotal",  // The <span> for the grand total (subtotal + tax)
    "noItemsRow",         // The "No items added yet" row
    "finalizeError",      // Element to display errors
    "paymentBtn",         // Payment buttons
    "qrModal",            // QR code modal container
    "qrCodeImage",        // img tag inside the modal
    "qrInstructions"      // p tag for instructions below QR code
    // Add other targets if needed (e.g., customer select)
  ]

  selectedPaymentMethod = null;
  placeholderQrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=YOUR_STATIC_UPI_ID_OR_PAYMENT_LINK"; // Base URL

  connect() {
    console.log("Billing controller connected!");
    this.updateTotals(); // Initial calculation
  }

  // --- Action to handle payment method selection ---
  selectPaymentMethod(event) {
    event.preventDefault();
    const clickedButton = event.currentTarget;
    this.selectedPaymentMethod = clickedButton.dataset.method;

    this.paymentBtnTargets.forEach(btn => btn.classList.remove('active'));
    clickedButton.classList.add('active');

    console.log("Payment method selected:", this.selectedPaymentMethod);
    if (this.hasFinalizeErrorTarget) this.finalizeErrorTarget.textContent = '';
  }

  // --- Action to handle display logic (alert/QR) after payment method selection ---
  handlePaymentDisplay(event) {
     const method = event.currentTarget.dataset.method;
     console.log("Handling display for:", method);

     switch(method) {
         case 'Cash':
             alert("Please collect cash payment at the counter.");
             this.closeQrModal();
             break;
         case 'UPI':
             this.showUpiQrCode();
             break;
         default:
             console.warn("Unknown payment method display:", method);
             this.closeQrModal();
     }
  }

  // --- Method to show the UPI QR Code Modal ---
  showUpiQrCode() {
      if (!this.hasQrModalTarget || !this.hasQrCodeImageTarget || !this.hasSummaryGrandTotalTarget) {
          console.error("QR Modal targets not found!");
          this.displayError("Could not display QR Code - configuration error.");
          return;
      }

      // Ensure totals are up-to-date before getting grand total
      this.updateTotals();
      const grandTotal = parseFloat(this.summaryGrandTotalTarget.textContent.replace(/[^0-9.-]+/g,"")) || 0;

      // You might want to generate amount-specific QR if your UPI provider supports it
      // For now, using static QR and showing amount in text
      this.qrCodeImageTarget.src = this.placeholderQrUrl;
      this.qrCodeImageTarget.alt = `Scan UPI QR Code to Pay ${this.formatCurrency(grandTotal)}`;

      if (this.hasQrInstructionsTarget) {
           this.qrInstructionsTarget.textContent = `Amount to Pay: ${this.formatCurrency(grandTotal)}`;
       }

      this.qrModalTarget.classList.remove('hidden');
  }

  // --- Action to close the UPI QR Code Modal ---
  closeQrModal() {
      if (this.hasQrModalTarget) {
          this.qrModalTarget.classList.add('hidden');
      }
  }

  // --- Action to Finalize the Bill ---
  async finalizeBill(event) {
    event.preventDefault();
    console.log("Finalize Bill clicked");
    if (this.hasFinalizeErrorTarget) { this.finalizeErrorTarget.textContent = ''; }

    // 1. Get Items and perform basic validation
    const items = [];
    const productRows = this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]");
    if (productRows.length === 0) { this.displayError("Cannot finalize an empty bill."); return; }

    let invalidItemFound = false;
    productRows.forEach(row => {
      if (invalidItemFound) return;

      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10);
      const productId = row.dataset.productId;
      // Price is used for client-side calculation display, but backend should use its own price source
      // const price = parseFloat(row.dataset.price);

      if (!productId || isNaN(quantity) || quantity <= 0) {
         this.displayError(`Invalid quantity for an item. Please check the bill.`);
         invalidItemFound = true;
         return;
      }
      // Send only product_id and quantity. Backend calculates subtotal/tax based on these.
      items.push({ product_id: productId, quantity: quantity });
    });

    if (invalidItemFound || items.length === 0) { return; }

    // 2. Get Customer
    const customerSelect = document.getElementById('customer-select'); // Make sure this ID exists
    const customerId = customerSelect ? customerSelect.value : null;
    // Add validation if customer is required:
    // if (!customerId) { this.displayError("Please select a customer."); return; }


    // 3. Get Payment Method
    if (!this.selectedPaymentMethod) { this.displayError("Please select a payment method."); return; }

    // 4. Construct Payload for Rails backend
    // Send only essential info. Backend calculates totals.
    const payload = {
      invoice: {
        customer_id: customerId,
        payment_method: this.selectedPaymentMethod,
        // Nested attributes format for invoice_lines
        invoice_lines_attributes: items.map((item, index) => ({
          product_id: item.product_id,
          quantity: item.quantity
          // Backend will fetch unit_price and calculate tax based on product_id
        }))
      }
    };
    console.log("Payload being sent:", JSON.stringify(payload)); // Debugging


    // 5. Get CSRF Token
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
    if (!csrfToken) { this.displayError("Security token missing. Please refresh the page."); return; }

    // 6. Perform Fetch POST Request to /invoices
    try {
      const response = await fetch('/invoices', { // Ensure this matches your Rails route
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(payload)
      });

      const responseData = await response.json();

      if (response.ok && responseData.success && responseData.invoice_id) {
        console.log("Invoice creation successful:", responseData);
        // Redirect to the invoice show page (printable or view)
        window.location.href = `/invoices/${responseData.invoice_id}`;
      } else {
        console.error("Invoice creation failed:", responseData);
        this.displayError(responseData.message || "An unknown error occurred processing the bill.");
      }
    } catch (error) {
      console.error("Fetch error:", error);
      this.displayError("Could not connect to the server. Please check your network and try again.");
    }
  } // End finalizeBill

  // --- Helper to display errors ---
  displayError(message) {
     if (this.hasFinalizeErrorTarget) {
       this.finalizeErrorTarget.textContent = message;
     } else {
       alert(message);
     }
  }

  // --- Add Item to Bill ---
  // Triggered by an action, expects the triggering element to have product data attributes
  addItem(event) {
    event.preventDefault();
    // Assuming the product info is on the element that was clicked or a parent
    const productElement = event.currentTarget.closest('[data-product-id]');
    if (!productElement) { console.error("Could not find product data element from event:", event.currentTarget); return; }

    const productId = productElement.dataset.productId;
    const productName = productElement.dataset.productName; // Ensure this attribute exists
    const productPrice = parseFloat(productElement.dataset.productPrice); // Ensure this attribute exists
    // --- Get the tax rate from the product data ---
    const productTaxRate = parseFloat(productElement.dataset.productTaxPercentage || 0.0); // Ensure this attribute exists

    if (!productId || !productName || isNaN(productPrice) || isNaN(productTaxRate)) {
      console.error("Invalid product data attributes found:", productElement.dataset);
      this.displayError("Could not add item: missing required product data.");
      return;
    }

    const existingRow = this.billItemsBodyTarget.querySelector(`tr[data-product-id="${productId}"]`);
    if (existingRow) {
       const quantityInput = existingRow.querySelector(".quantity-input");
       if (quantityInput) {
          quantityInput.value = parseInt(quantityInput.value, 10) + 1;
          this.updateTotals(); // Trigger recalculation
       }
    } else {
       this.addBillRow(productId, productName, productPrice, productTaxRate); // Pass tax rate
       this.updateTotals(); // Calculate after adding new row
    }
  }

  // --- Create and Add Row HTML ---
  addBillRow(id, name, price, taxRate) { // Accept taxRate
    const billBody = this.billItemsBodyTarget;
    if (this.hasNoItemsRowTarget && !this.noItemsRowTarget.classList.contains('hidden')) {
        this.noItemsRowTarget.classList.add('hidden');
    }
    const row = document.createElement("tr");
    row.id = `bill-item-${uuidv4()}`;
    row.dataset.productId = id;
    row.dataset.price = price;
    row.dataset.taxRate = taxRate; // Store tax rate on the row

    const lineSubtotal = price * 1; // Initial quantity is 1

    row.innerHTML = `
      <td class="py-2 px-3 border-b">${name}</td>
      <td class="py-2 px-3 border-b">
        <input
          type="number"
          value="1"
          min="1"
          class="quantity-input form-input w-16 text-right border rounded" <%# Basic styling %>
          data-action="change->billing#updateTotals keyup->billing#updateTotals">
      </td>
      <td class="py-2 px-3 border-b text-right">${this.formatCurrency(price)}</td>
      <%# Display Line Subtotal (Before Tax) %>
      <td class="line-total py-2 px-3 border-b text-right">${this.formatCurrency(lineSubtotal)}</td>
      <td class="py-2 px-3 border-b text-center">
        <button class="remove-item-btn text-red-500 hover:text-red-700 px-1" data-action="click->billing#removeItem" aria-label="Remove ${name}">
           <i class="fas fa-times-circle"></i> <%# Font Awesome example %>
        </button>
      </td>
    `;
    billBody.appendChild(row);
  }

  // --- Remove Item from Bill ---
  removeItem(event) {
    event.preventDefault();
    const rowToRemove = event.currentTarget.closest('tr');
    if (rowToRemove) {
        rowToRemove.remove();
        this.updateTotals();
    }
    if (this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]").length === 0 && this.hasNoItemsRowTarget) {
       this.noItemsRowTarget.classList.remove('hidden');
    }
  }

  // --- Update Subtotal, Tax, and Grand Total ---
  updateTotals() {
    let overallSubtotal = 0;
    let totalTax = 0;

    const productRows = this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]");
    productRows.forEach(row => {
        const price = parseFloat(row.dataset.price) || 0;
        const taxRate = parseFloat(row.dataset.taxRate) || 0; // Get tax rate from row
        const quantityInput = row.querySelector(".quantity-input");
        const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10) || 0;
        const lineTotalCell = row.querySelector(".line-total");

        if (quantity >= 0) { // Allow 0 quantity during input maybe? Or validate >= 1? Let's allow 0 for calc.
            const lineSubtotal = price * quantity;
            const lineTax = lineSubtotal * (taxRate / 100.0);

            overallSubtotal += lineSubtotal;
            totalTax += lineTax;

            // Update the line total cell to show the line's subtotal (before tax)
            if(lineTotalCell) { lineTotalCell.textContent = this.formatCurrency(lineSubtotal); }

        } else {
             // Handle invalid negative input if necessary (though min="1" should prevent usually)
             if(lineTotalCell) { lineTotalCell.textContent = this.formatCurrency(0); }
        }
    });

    const grandTotal = overallSubtotal + totalTax;

    // Update summary display using targets
    if (this.hasSummarySubtotalTarget) {
      this.summarySubtotalTarget.textContent = this.formatCurrency(overallSubtotal);
    }
    if (this.hasSummaryTotalTaxTarget) { // Update the new tax target
      this.summaryTotalTaxTarget.textContent = this.formatCurrency(totalTax);
    }
    if (this.hasSummaryGrandTotalTarget) {
      this.summaryGrandTotalTarget.textContent = this.formatCurrency(grandTotal);
    }
  }

  // --- Currency Formatting ---
  formatCurrency(value) {
      try {
          return new Intl.NumberFormat('en-IN', { style: 'currency', currency: 'INR' }).format(value);
      } catch (e) {
          console.error("Error formatting currency:", e);
          return `₹${Number(value || 0).toFixed(2)}`; // Fallback
      }
  }

  // --- Disconnect ---
  disconnect() {
    console.log("Billing controller disconnected");
  }
}