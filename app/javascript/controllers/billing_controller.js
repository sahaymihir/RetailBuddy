// app/javascript/controllers/billing_controller.js
import { Controller } from "@hotwired/stimulus"
import { v4 as uuidv4 } from "uuid"

export default class extends Controller {
  // Define ALL elements the controller needs to interact with
  static targets = [
    "billItemsBody",      // The <tbody> of the current bill table
    "summarySubtotal",    // The <span> for the subtotal
    "summaryGrandTotal",  // The <span> for the grand total
    "noItemsRow",         // The "No items added yet" row
    "finalizeError",      // Element to display errors (e.g., <div data-billing-target="finalizeError"></div>)
    "paymentBtn",         // Payment buttons (add data-billing-target="paymentBtn")
    "qrModal",            // QR code modal container (add data-billing-target="qrModal")
    "qrCodeImage",        // img tag inside the modal (add data-billing-target="qrCodeImage")
    "qrInstructions"      // p tag for instructions below QR code (add data-billing-target="qrInstructions")
  ]

  // Store selected payment method
  selectedPaymentMethod = null;
  // Store placeholder QR code URL (replace with your actual data)
  placeholderQrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=YOUR_STATIC_UPI_ID_OR_PAYMENT_LINK"; // Base URL

  connect() {
    console.log("Billing controller connected!");
    this.updateTotals(); // Initial calculation
  }

  // --- Action to handle payment method selection ---
  // Connect in HTML: data-action="click->billing#selectPaymentMethod" on payment buttons
  selectPaymentMethod(event) {
    event.preventDefault();
    const clickedButton = event.currentTarget;
    this.selectedPaymentMethod = clickedButton.dataset.method; // Get method from data-method attribute

    // Update button styles
    this.paymentBtnTargets.forEach(btn => {
      btn.classList.remove('active'); // Remove active class from all
    });
    clickedButton.classList.add('active'); // Add active class to clicked button

    console.log("Payment method selected:", this.selectedPaymentMethod);
    // Clear any previous finalization errors when selecting payment
    if (this.hasFinalizeErrorTarget) {
        this.finalizeErrorTarget.textContent = '';
    }
  }

  // --- Action to handle display logic (alert/QR) after payment method selection ---
  // Connect in HTML: Add this as a second action: data-action="click->billing#selectPaymentMethod click->billing#handlePaymentDisplay"
  handlePaymentDisplay(event) {
     const method = event.currentTarget.dataset.method;
     console.log("Handling display for:", method);

     switch(method) {
         case 'Cash':
             alert("Please collect cash payment at the counter.");
             this.closeQrModal(); // Ensure QR modal is closed
             break;
         case 'UPI':
             this.showUpiQrCode(); // Show the QR code modal
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
          this.displayError("Could not display QR Code - configuration error."); // Show user error
          return;
      }

      const grandTotal = parseFloat(this.summaryGrandTotalTarget.textContent.replace(/[^0-9.-]+/g,"")) || 0;

      // Update QR code image source (using static URL from placeholderQrUrl)
      // In a real app, you might generate this dynamically or fetch it
      this.qrCodeImageTarget.src = this.placeholderQrUrl;
      this.qrCodeImageTarget.alt = `Scan UPI QR Code to Pay ${this.formatCurrency(grandTotal)}`;

      // Update instructions if target exists
       if (this.hasQrInstructionsTarget) {
           this.qrInstructionsTarget.textContent = `Amount to Pay: ${this.formatCurrency(grandTotal)}`;
       }

      // Show the modal
      this.qrModalTarget.classList.remove('hidden');
  }

  // --- Action to close the UPI QR Code Modal ---
  // Connect in HTML: data-action="click->billing#closeQrModal" on the modal's close button
  closeQrModal() {
      if (this.hasQrModalTarget) {
          this.qrModalTarget.classList.add('hidden');
      }
  }

  // --- Action to Finalize the Bill ---
  // Connect in HTML: data-action="click->billing#finalizeBill" on the finalize button
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
      if (invalidItemFound) return; // Stop if error already found

      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10);
      const price = parseFloat(row.dataset.price);
      const productId = row.dataset.productId;
      const lineTotalCell = row.querySelector(".line-total");
      const lineTotal = parseFloat(lineTotalCell ? lineTotalCell.textContent.replace(/[^0-9.-]+/g,"") : 0);

      if (!productId || isNaN(price) || isNaN(quantity) || quantity <= 0) {
         this.displayError(`Invalid quantity or data for an item. Please check the bill.`);
         invalidItemFound = true; // Set flag to stop processing
         return;
      }
      items.push({ product_id: productId, quantity: quantity, price: price, total: lineTotal });
    });

    if (invalidItemFound || items.length === 0) { return; } // Exit if errors or no valid items

    // 2. Get Customer
    const customerSelect = document.getElementById('customer-select');
    const customerId = customerSelect ? customerSelect.value : null;

    // 3. Get Payment Method
    if (!this.selectedPaymentMethod) { this.displayError("Please select a payment method."); return; }

    // 4. Get Totals
    const subtotal = parseFloat(this.summarySubtotalTarget.textContent.replace(/[^0-9.-]+/g,""));
    const grandTotal = parseFloat(this.summaryGrandTotalTarget.textContent.replace(/[^0-9.-]+/g,""));

    // 5. Construct Payload for Rails backend
    const payload = {
      invoice: {
        customer_id: customerId,
        subtotal: subtotal,
        grand_total: grandTotal,
        payment_method: this.selectedPaymentMethod,
        items: items
        // Add discount, tax here if implemented
      }
    };

    // 6. Get CSRF Token
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
    if (!csrfToken) { this.displayError("Security token missing. Please refresh the page."); return; }

    // 7. Perform Fetch POST Request to /invoices
    try {
      const response = await fetch('/invoices', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify(payload)
      });

      const responseData = await response.json(); // Expect JSON response

      if (response.ok && responseData.success) {
        // SUCCESS: Redirect to the printable invoice page
        console.log("Invoice creation successful:", responseData);
        window.location.href = `/invoices/${responseData.invoice_id}`;
      } else {
        // FAILURE: Display error message from backend
        console.error("Invoice creation failed:", responseData);
        this.displayError(responseData.message || "An unknown error occurred processing the bill.");
      }
    } catch (error) {
      // Network or other fetch-related error
      console.error("Fetch error:", error);
      this.displayError("Could not connect to the server. Please check your network and try again.");
    }
  } // End finalizeBill

  // --- Helper to display errors ---
  displayError(message) {
     if (this.hasFinalizeErrorTarget) {
       this.finalizeErrorTarget.textContent = message;
     } else {
       alert(message); // Fallback if target doesn't exist
     }
  }

  // --- Add Item to Bill ---
  // Connect in HTML: data-action="click->billing#addItem" on the add button/item
  addItem(event) {
    event.preventDefault();
    const productElement = event.currentTarget.closest('[data-product-id]');
    if (!productElement) { console.error("Could not find product element from event:", event.currentTarget); return; }

    const productId = productElement.dataset.productId;
    const productName = productElement.dataset.productName;
    const productPrice = parseFloat(productElement.dataset.productPrice);

    if (!productId || !productName || isNaN(productPrice)) { console.error("Invalid product data attributes:", productElement.dataset); return; }

    // Check if item already exists and increment quantity (optional)
    const existingRow = this.billItemsBodyTarget.querySelector(`tr[data-product-id="${productId}"]`);
    if (existingRow) {
       const quantityInput = existingRow.querySelector(".quantity-input");
       if (quantityInput) {
          quantityInput.value = parseInt(quantityInput.value, 10) + 1;
          // Trigger updateTotals explicitly after changing value programmatically
          this.updateTotals();
       }
       return; // Don't add a new row if incrementing
    }

    // Add new row if item doesn't exist
    this.addBillRow(productId, productName, productPrice);
    this.updateTotals();
  }

  // --- Create and Add Row HTML ---
  addBillRow(id, name, price) {
    const billBody = this.billItemsBodyTarget;
    if (this.hasNoItemsRowTarget && !this.noItemsRowTarget.classList.contains('hidden')) {
        this.noItemsRowTarget.classList.add('hidden');
    }
    const row = document.createElement("tr");
    row.id = `bill-item-${uuidv4()}`; // Unique ID for the row
    row.dataset.productId = id;
    row.dataset.price = price;
    row.innerHTML = `
      <td>${name}</td>
      <td>
        <input
          type="number"
          value="1"
          min="1"
          class="quantity-input"
          data-action="change->billing#updateTotals keyup->billing#updateTotals"> <%# Update on change or keyup %>
      </td>
      <td>${this.formatCurrency(price)}</td>
      <td class="line-total">${this.formatCurrency(price)}</td>
      <td>
        <button class="remove-item-btn text-red-500 hover:text-red-700 px-1" data-action="click->billing#removeItem" aria-label="Remove ${name}"> <%# Simple styling %>
           <i class="fas fa-times-circle"></i>
        </button>
      </td>
    `;
    billBody.appendChild(row);
  }

  // --- Remove Item from Bill ---
  // Connect in HTML: data-action="click->billing#removeItem" on remove button
  removeItem(event) {
    event.preventDefault();
    const rowToRemove = event.currentTarget.closest('tr');
    if (rowToRemove) {
        rowToRemove.remove();
        this.updateTotals(); // Recalculate
    }
    // Show "No items" row if bill becomes empty
    if (this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]").length === 0 && this.hasNoItemsRowTarget) {
       this.noItemsRowTarget.classList.remove('hidden');
    }
  }

  // --- Update Subtotal and Grand Total ---
  updateTotals() {
    let subtotal = 0;
    const productRows = this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]");
    productRows.forEach(row => {
        const price = parseFloat(row.dataset.price);
        const quantityInput = row.querySelector(".quantity-input");
        const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10) || 0;
        const lineTotalCell = row.querySelector(".line-total");

        if (!isNaN(price) && !isNaN(quantity) && quantity >= 0) {
            const lineTotal = price * quantity;
            subtotal += lineTotal;
            if(lineTotalCell) { lineTotalCell.textContent = this.formatCurrency(lineTotal); }
        } else {
             // Handle invalid intermediate input state
             if(lineTotalCell) { lineTotalCell.textContent = this.formatCurrency(0); }
        }
    });

    // Update summary display
    if (this.hasSummarySubtotalTarget) { this.summarySubtotalTarget.textContent = this.formatCurrency(subtotal); }
    // Assuming grand total is same as subtotal for now
    if (this.hasSummaryGrandTotalTarget) { this.summaryGrandTotalTarget.textContent = this.formatCurrency(subtotal); }

    // Clear finalize error if total changes (optional)
    // if (this.hasFinalizeErrorTarget) { this.finalizeErrorTarget.textContent = ''; }
  }

  // --- Currency Formatting ---
  formatCurrency(value) {
      // Using Intl for better formatting (adjust locale 'en-IN' and currency 'INR' as needed)
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
    // Add any cleanup logic if needed
  }
}