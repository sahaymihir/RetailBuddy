// app/javascript/controllers/billing_controller.js

import { Controller } from "@hotwired/stimulus";
// import { v4 as uuidv4 } from "uuid"; // Keep if needed for other features

export default class extends Controller {
  static targets = [
    "billItemsBody",
    "summarySubtotal",
    "summaryTotalTax",
    "summaryGrandTotal",
    "noItemsRow",
    "finalizeError",
    "paymentBtn",
    "qrModal",         // Modal container element
    "qrCodeImage",     // <img> tag for QR code
    "qrInstructions",  // Element to display amount in modal
    // "customerSelect" // Uncomment if needed
  ];

  selectedPaymentMethod = null;
  // Example UPI details (replace with your actual details)
  // Extracted from user-provided image: upi://pay?pa=mihir.sahay0123-2@okaxis&pn=Mihir%20Sahay...
  upiId = "mihir.sahay0123-2@okaxis"; 
  payeeName = "Mihir Sahay"; // URL Encoded name from image was "Mihir%20Sahay"

  connect() {
    console.log("Billing controller connected!");
    this.updateTotals(); // Initial calculation on page load
  }

  /**
   * Handles selection of a payment method button.
   * Sets the selected method, updates button styles, and triggers display logic.
   */
  selectPaymentMethod(event) {
    event.preventDefault();
    const clickedButton = event.currentTarget;
    this.selectedPaymentMethod = clickedButton.dataset.method;

    // Update button active states
    this.paymentBtnTargets.forEach((btn) => btn.classList.remove("active"));
    clickedButton.classList.add("active");

    console.log("Payment method selected:", this.selectedPaymentMethod);
    
    // Clear any previous finalization errors
    if (this.hasFinalizeErrorTarget) {
      this.finalizeErrorTarget.textContent = "";
      this.finalizeErrorTarget.classList.add("hidden");
    }

    // Handle display changes based on the selected method (e.g., show QR modal)
    this.handlePaymentDisplay(); 
  }

  /**
   * Shows/hides elements or triggers actions based on the selected payment method.
   */
  handlePaymentDisplay() {
    const method = this.selectedPaymentMethod; // Use the stored method
    console.log("Handling display for:", method);

    switch (method) {
      case "Cash":
        // Show the correct alert for cash payment
        alert("Please pay cash at the counter"); 
        this.closeQrModal(); // Ensure QR modal is closed if switching from UPI
        break;
      case "UPI":
        // Show the UPI QR code modal
        this.showUpiQrCode();
        break;
      default:
        console.warn("Unknown payment method selected for display:", method);
        this.closeQrModal(); // Close modal for unknown methods
    }
  }

  /**
   * Generates and displays the UPI QR code modal.
   */
  showUpiQrCode() {
    // Check if all necessary targets for the modal are present
    if (!this.hasQrModalTarget || !this.hasQrCodeImageTarget || !this.hasSummaryGrandTotalTarget) {
      console.error("QR Modal targets missing! Cannot display QR Code.");
      this.displayError("Could not display QR Code - configuration error.");
      return;
    }

    // Ensure totals are current before generating QR code data
    this.updateTotals(); 
    const grandTotal = parseFloat(this.summaryGrandTotalTarget.textContent.replace(/[^0-9.]/g, "")) || 0;

    // Do not show QR code if the amount is zero or less
    if (grandTotal <= 0) {
      this.displayError("Cannot generate QR code for zero amount.");
      this.closeQrModal();
      return;
    }

    // --- Generate Dynamic UPI QR Code Data ---
    // Construct the UPI payment string dynamically
    // pa = Payee Address (Your UPI ID)
    // pn = Payee Name
    // am = Amount (ensure 2 decimal places)
    // cu = Currency (INR)
    // tn = Transaction Note (optional, good practice to include unique ID like invoice number or timestamp)
    const transactionNote = `RB${Date.now()}`; // Example: RetailBuddy + Timestamp
    const upiDataString = `upi://pay?pa=${encodeURIComponent(this.upiId)}&pn=${encodeURIComponent(this.payeeName)}&am=${grandTotal.toFixed(2)}&cu=INR&tn=${encodeURIComponent(transactionNote)}`;
    
    // Use a QR code generation API (like qrserver.com) with the dynamic data
    const qrApiUrl = `https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=${encodeURIComponent(upiDataString)}`;
    
    // Update the image source and alt text
    this.qrCodeImageTarget.src = qrApiUrl; 
    this.qrCodeImageTarget.alt = `Scan UPI QR Code to Pay ${this.formatCurrency(grandTotal)} to ${this.payeeName}`;

    // Update the instructions text in the modal
    if (this.hasQrInstructionsTarget) {
      this.qrInstructionsTarget.textContent = `Scan to Pay: ${this.formatCurrency(grandTotal)}`;
    }

    // Make the modal visible
    this.qrModalTarget.classList.remove("hidden"); 
  }

  /**
   * Hides the UPI QR code modal.
   */
  closeQrModal() {
    if (this.hasQrModalTarget) {
      this.qrModalTarget.classList.add("hidden");
    }
  }

  /**
   * Handles the click action for the modal's close button.
   * Closes the modal and shows a confirmation prompt.
   */
  closeUpiModalAndPrompt(event) {
    if (event) {
      event.preventDefault(); // Prevent default button behavior if triggered by event
    }
    this.closeQrModal(); // Hide the modal
    // Show the specific prompt after closing
    alert("Please Check UPI transaction is received or not"); 
  }

  /**
   * Gathers bill data and sends it to the backend to create an invoice.
   */
  async finalizeBill(event) {
    event.preventDefault();
    console.log("Attempting to finalize bill...");
    if (this.hasFinalizeErrorTarget) {
      this.finalizeErrorTarget.textContent = ""; 
      this.finalizeErrorTarget.classList.add("hidden");
    }

    const items = [];
    const productRows = this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]");

    // Check if there are items in the bill
    if (productRows.length === 0) {
      this.displayError("Cannot finalize an empty bill.");
      return;
    }

    // Validate each item row
    let invalidItemFound = false;
    productRows.forEach((row) => {
      if (invalidItemFound) return; 

      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10);
      const productId = row.dataset.productId;
      const unitPrice = parseFloat(row.dataset.price);

      if (!productId || isNaN(quantity) || quantity <= 0 || isNaN(unitPrice)) {
        this.displayError(`Invalid quantity or price for item: ${row.cells[0]?.textContent || "Unknown"}. Please correct.`);
        invalidItemFound = true;
        quantityInput?.classList.add("error"); 
        return;
      } else {
        quantityInput?.classList.remove("error"); 
      }

      items.push({
        product_id: productId,
        quantity: quantity,
        unit_price: unitPrice, 
      });
    });

    if (invalidItemFound) {
      return; // Stop if validation failed
    }

    // Get selected customer ID
    const customerSelect = document.getElementById("customer-select"); // Use the correct ID for your customer dropdown
    const customerId = customerSelect ? customerSelect.value : null;

    // Ensure a payment method is selected
    if (!this.selectedPaymentMethod) {
      this.displayError("Please select a payment method.");
      return;
    }

    // Prepare the data payload for the server
    const payload = {
      invoice: {
        customer_id: customerId,
        payment_method: this.selectedPaymentMethod,
        payment_status: "Completed", // Consider making this dynamic based on payment verification
        invoice_lines_attributes: items, 
      },
    };
    console.log("Payload to be sent:", JSON.stringify(payload));

    // Get CSRF token for Rails security
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
    if (!csrfToken) {
        this.displayError("Security token missing. Please refresh the page.");
        return;
    }

    // --- Send data to backend via fetch API ---
    try {
      const response = await fetch("/invoices", { // Ensure this matches your Rails route for invoice creation
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json", 
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify(payload),
      });

      const responseData = await response.json(); 

      if (response.ok && responseData.success && responseData.invoice_id) {
        // Success: Redirect to the newly created invoice's show page
        console.log("Invoice created successfully:", responseData);
        window.location.href = `/invoices/${responseData.invoice_id}`; 
      } else {
        // Handle backend errors (e.g., validation failures)
        console.error("Invoice creation failed on backend:", responseData);
        this.displayError(
          responseData.message || responseData.error || "An unknown error occurred processing the bill."
        );
      }
    } catch (error) {
      // Handle network or fetch-related errors
      console.error("Network or fetch error:", error);
      this.displayError("Could not connect to the server. Please check your network and try again.");
    }
  }

  /**
   * Displays an error message in the designated error target or via alert.
   */
  displayError(message) {
    if (this.hasFinalizeErrorTarget) {
      this.finalizeErrorTarget.textContent = message;
      this.finalizeErrorTarget.classList.remove("hidden"); 
    } else {
      // Fallback if the error target element doesn't exist
      alert(`Error: ${message}`);
    }
  }

  /**
   * Adds an item to the bill or increments quantity if it already exists.
   * Triggered by clicking the '+' button on a product list item.
   */
  addItem(event) {
    event.preventDefault();
    const productElement = event.currentTarget.closest("[data-product-id]");
    if (!productElement) {
      console.error("Could not find product data element from event target:", event.currentTarget);
      return;
    }

    // Extract product data from data attributes
    const productId = productElement.dataset.productId;
    const productName = productElement.dataset.productName;
    const productPrice = parseFloat(productElement.dataset.productPrice);
    const productTaxRate = parseFloat(productElement.dataset.productTaxPercentage || 0);

    // Validate extracted data
    if (!productId || !productName || isNaN(productPrice) || isNaN(productTaxRate)) {
      console.error("Invalid or missing product data attributes found:", productElement.dataset);
      this.displayError("Could not add item: essential product data is missing.");
      return;
    }

    // Check if the item is already in the bill
    const existingRow = this.billItemsBodyTarget.querySelector(`tr[data-product-id="${productId}"]`);

    if (existingRow) {
      // Increment quantity if item exists
      const quantityInput = existingRow.querySelector(".quantity-input");
      if (quantityInput) {
        quantityInput.value = parseInt(quantityInput.value, 10) + 1;
        this.updateTotals(); // Recalculate after quantity change
      }
    } else {
      // Add a new row if item is not in the bill
      this.addBillRow(productId, productName, productPrice, productTaxRate);
    }
  }

  /**
   * Creates and appends a new row to the bill items table body.
   */
  addBillRow(id, name, price, taxRate) {
    const billBody = this.billItemsBodyTarget;

    // Hide the "No items" message row if it's visible
    if (this.hasNoItemsRowTarget) {
       this.noItemsRowTarget.classList.add("hidden");
    }

    const row = document.createElement("tr");
    // Store essential data on the row itself for later calculations
    row.dataset.productId = id;
    row.dataset.price = price; 
    row.dataset.taxRate = taxRate; 

    const initialQuantity = 1;
    const lineSubtotal = price * initialQuantity; 

    // Define the HTML structure for the new table row
    // Ensure class names match your CSS/framework (e.g., Tailwind, Bootstrap)
    row.innerHTML = `
      <td class="py-2 px-3 border-b border-gray-700 text-gray-300">${name}</td>
      <td class="py-2 px-3 border-b border-gray-700">
        <input
          type="number"
          value="${initialQuantity}"
          min="1"
          class="quantity-input form-input w-16 text-right border rounded bg-gray-700 text-white border-gray-600 focus:ring-blue-500 focus:border-blue-500"
          data-action="change->billing#updateTotals keyup->billing#updateTotals">
      </td>
      <td class="py-2 px-3 border-b border-gray-700 text-right text-gray-300">${this.formatCurrency(price)}</td>
      <td class="line-total py-2 px-3 border-b border-gray-700 text-right text-gray-300">${this.formatCurrency(lineSubtotal)}</td>
      <td class="py-2 px-3 border-b border-gray-700 text-center">
        <button class="remove-item-btn text-red-500 hover:text-red-400 px-1" data-action="click->billing#removeItem" aria-label="Remove ${name}">
           <i class="fas fa-times-circle"></i>
        </button>
      </td>
    `;

    billBody.appendChild(row); 
    this.updateTotals(); // Recalculate after adding item
  }

  /**
   * Removes an item row from the bill table.
   * Triggered by clicking the remove button on a bill item row.
   */
  removeItem(event) {
    event.preventDefault();
    const rowToRemove = event.currentTarget.closest("tr");
    if (rowToRemove) {
      rowToRemove.remove(); 
      this.updateTotals(); // Recalculate totals
    }

    // Show the "No items" message if the table becomes empty
    if (this.hasNoItemsRowTarget && this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]").length === 0) {
      this.noItemsRowTarget.classList.remove("hidden");
    }
  }

  /**
   * Recalculates and updates the subtotal, total tax, and grand total display.
   */
  updateTotals() {
    let overallSubtotal = 0;
    let overallTotalTax = 0; 

    const productRows = this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]");

    productRows.forEach((row) => {
      const price = parseFloat(row.dataset.price) || 0; 
      const taxRate = parseFloat(row.dataset.taxRate) || 0; 
      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10) || 0; 
      const lineTotalCell = row.querySelector(".line-total"); 

      if (quantity > 0) { 
        const lineSubtotal = price * quantity; 
        const lineTax = lineSubtotal * (taxRate / 100.0); 
        overallSubtotal += lineSubtotal; 
        overallTotalTax += lineTax; 
        // Update the individual line total display (optional)
        if (lineTotalCell) { 
          lineTotalCell.textContent = this.formatCurrency(lineSubtotal); 
        }
      } else if (lineTotalCell) {
        // Display 0 if quantity is invalid
        lineTotalCell.textContent = this.formatCurrency(0);
      }
    });

    const grandTotal = overallSubtotal + overallTotalTax; 

    // Update the summary display elements
    if (this.hasSummarySubtotalTarget) { 
      this.summarySubtotalTarget.textContent = this.formatCurrency(overallSubtotal); 
    }
    if (this.hasSummaryTotalTaxTarget) { 
      this.summaryTotalTaxTarget.textContent = this.formatCurrency(overallTotalTax); 
    }
    if (this.hasSummaryGrandTotalTarget) { 
      this.summaryGrandTotalTarget.textContent = this.formatCurrency(grandTotal); 
    }

    // Toggle the visibility of the "No items" row
    if (this.hasNoItemsRowTarget) {
        this.noItemsRowTarget.classList.toggle("hidden", productRows.length > 0);
    }
  }

  /**
   * Helper function to format numbers as Indian Rupees (INR).
   */
  formatCurrency(value) {
    try {
      return new Intl.NumberFormat("en-IN", {
        style: "currency",
        currency: "INR",
      }).format(value);
    } catch (e) {
      console.warn("Intl.NumberFormat failed, using fallback currency format:", e);
      return `₹${Number(value || 0).toFixed(2)}`;
    }
  }

  /**
   * Cleanup logic when the controller disconnects from the element.
   */
  disconnect() {
    console.log("Billing controller disconnected");
    // Add any cleanup logic here if needed (e.g., removing event listeners)
  }
} // End of class