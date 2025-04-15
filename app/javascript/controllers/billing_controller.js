import { Controller } from "@hotwired/stimulus";
import { v4 as uuidv4 } from "uuid";

export default class extends Controller {
  static targets = [
    "billItemsBody",
    "summarySubtotal",
    "summaryTotalTax", // Target for displaying total tax
    "summaryGrandTotal",
    "noItemsRow",
    "finalizeError",
    "paymentBtn",
    "qrModal",
    "qrCodeImage",
    "qrInstructions",
    // "customerSelect" // Uncomment if needed elsewhere
  ];

  selectedPaymentMethod = null;
  // Placeholder for your actual UPI QR code generation logic or static URL
  placeholderQrUrl =
    "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=YOUR_STATIC_UPI_ID_OR_PAYMENT_LINK";

  connect() {
    console.log("Billing controller connected!");
    this.updateTotals(); // Initial calculation on page load
  }

  selectPaymentMethod(event) {
    event.preventDefault();
    const clickedButton = event.currentTarget;
    this.selectedPaymentMethod = clickedButton.dataset.method;
    this.paymentBtnTargets.forEach((btn) => btn.classList.remove("active"));
    clickedButton.classList.add("active");
    console.log("Payment method selected:", this.selectedPaymentMethod);
    if (this.hasFinalizeErrorTarget) this.finalizeErrorTarget.textContent = "";
    this.handlePaymentDisplay(event); // Handle QR code display etc.
  }

  handlePaymentDisplay(event) {
    const method =
      event.currentTarget.dataset.method || this.selectedPaymentMethod;
    console.log("Handling display for:", method);

    switch (method) {
      case "Cash":
        // Potentially display a message or simply do nothing specific
        alert("Please collect cash payment at the counter.");
        this.closeQrModal();
        break;
      case "UPI":
        this.showUpiQrCode();
        break;
      default:
        console.warn("Unknown payment method selected for display:", method);
        this.closeQrModal();
    }
  }

  showUpiQrCode() {
    if (
      !this.hasQrModalTarget ||
      !this.hasQrCodeImageTarget ||
      !this.hasSummaryGrandTotalTarget
    ) {
      console.error("QR Modal targets missing! Cannot display QR Code.");
      this.displayError("Could not display QR Code - configuration error.");
      return;
    }

    // Ensure totals are up-to-date before generating QR
    this.updateTotals();
    const grandTotal =
      parseFloat(
        this.summaryGrandTotalTarget.textContent.replace(/[^0-9.]/g, "") // Extract number from formatted currency
      ) || 0;

    if (grandTotal <= 0) {
      this.displayError("Cannot generate QR code for zero amount.");
      this.closeQrModal();
      return;
    }

    // Replace placeholderQrUrl logic with your actual QR code generation if dynamic
    this.qrCodeImageTarget.src = this.placeholderQrUrl; // Example: Use static URL or call a generator
    this.qrCodeImageTarget.alt = `Scan UPI QR Code to Pay ${this.formatCurrency(
      grandTotal
    )}`;

    if (this.hasQrInstructionsTarget) {
      this.qrInstructionsTarget.textContent = `Scan to Pay: ${this.formatCurrency(
        grandTotal
      )}`;
    }

    this.qrModalTarget.classList.remove("hidden");
  }

  closeQrModal() {
    if (this.hasQrModalTarget) {
      this.qrModalTarget.classList.add("hidden");
    }
  }

  async finalizeBill(event) {
    event.preventDefault();
    console.log("Attempting to finalize bill...");
    if (this.hasFinalizeErrorTarget) {
      this.finalizeErrorTarget.textContent = ""; // Clear previous errors
    }

    const items = [];
    const productRows = this.billItemsBodyTarget.querySelectorAll(
      "tr[data-product-id]"
    );

    if (productRows.length === 0) {
      this.displayError("Cannot finalize an empty bill.");
      return;
    }

    let invalidItemFound = false;
    productRows.forEach((row) => {
      if (invalidItemFound) return; // Stop processing if an error was found

      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10);
      const productId = row.dataset.productId;
      // Use the price stored on the row dataset
      const unitPrice = parseFloat(row.dataset.price);

      // Validate essential data for each line item
      if (!productId || isNaN(quantity) || quantity <= 0 || isNaN(unitPrice)) {
        this.displayError(
          `Invalid quantity or price for item: ${
            row.cells[0]?.textContent || "Unknown"
          }. Please correct.`
        );
        invalidItemFound = true;
        quantityInput?.classList.add("error"); // Highlight the input with error
        return;
      } else {
        quantityInput?.classList.remove("error"); // Remove error highlight if valid
      }

      items.push({
        product_id: productId,
        quantity: quantity,
        unit_price: unitPrice, // Send the unit price used for calculation
      });
    });

    if (invalidItemFound) {
      return; // Don't proceed if there were invalid items
    }

    // Get selected customer ID (ensure the element ID is correct)
    const customerSelect = document.getElementById("customer-select"); // Adjust ID if needed
    const customerId = customerSelect ? customerSelect.value : null;

    if (!this.selectedPaymentMethod) {
      this.displayError("Please select a payment method.");
      return;
    }

    // Prepare the payload for the backend
    const payload = {
      invoice: {
        customer_id: customerId,
        payment_method: this.selectedPaymentMethod,
        payment_status: "Completed", // Assuming payment is completed on finalization
        invoice_lines_attributes: items, // Nested attributes for invoice lines
      },
    };
    console.log("Payload to be sent:", JSON.stringify(payload));

    // Get CSRF token for Rails security
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
    if (!csrfToken) {
        this.displayError("Security token missing. Please refresh the page.");
        return;
    }

    // --- Send data to backend ---
    try {
      const response = await fetch("/invoices", { // Ensure this matches your Rails route
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json", // Expect JSON response
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify(payload),
      });

      const responseData = await response.json(); // Parse JSON response

      if (response.ok && responseData.success && responseData.invoice_id) {
        // Success: Redirect to the created invoice page
        console.log("Invoice created successfully:", responseData);
        window.location.href = `/invoices/${responseData.invoice_id}`; // Redirect
      } else {
        // Handle backend errors (validation errors, etc.)
        console.error("Invoice creation failed on backend:", responseData);
        this.displayError(
          responseData.message || // Display specific message from backend if available
            responseData.error ||
            "An unknown error occurred processing the bill."
        );
      }
    } catch (error) {
      // Handle network errors
      console.error("Network or fetch error:", error);
      this.displayError(
        "Could not connect to the server. Please check your network and try again."
      );
    }
  }

  displayError(message) {
    if (this.hasFinalizeErrorTarget) {
      this.finalizeErrorTarget.textContent = message;
      this.finalizeErrorTarget.classList.remove("hidden"); // Make error visible
    } else {
      // Fallback if the target doesn't exist
      alert(`Error: ${message}`);
    }
  }

  // Called when clicking the '+' button on a product in the search list
  addItem(event) {
    event.preventDefault();
    const productElement = event.currentTarget.closest("[data-product-id]");
    if (!productElement) {
      console.error("Could not find product data element from event target:", event.currentTarget);
      return;
    }

    const productId = productElement.dataset.productId;
    const productName = productElement.dataset.productName;
    const productPrice = parseFloat(productElement.dataset.productPrice);
    // Read the tax percentage from the product list item's dataset
    const productTaxRate = parseFloat(productElement.dataset.productTaxPercentage || 0);

    // Basic validation of product data
    if (!productId || !productName || isNaN(productPrice) || isNaN(productTaxRate)) {
      console.error("Invalid or missing product data attributes found:", productElement.dataset);
      this.displayError("Could not add item: essential product data is missing.");
      return;
    }

    // Check if the item already exists in the bill
    const existingRow = this.billItemsBodyTarget.querySelector(
      `tr[data-product-id="${productId}"]`
    );

    if (existingRow) {
      // If exists, just increment quantity
      const quantityInput = existingRow.querySelector(".quantity-input");
      if (quantityInput) {
        quantityInput.value = parseInt(quantityInput.value, 10) + 1;
        this.updateTotals(); // Recalculate totals after quantity change
      }
    } else {
      // If new, add a new row to the bill table
      this.addBillRow(productId, productName, productPrice, productTaxRate);
    }
  }

  // Adds a new row to the bill items table
  addBillRow(id, name, price, taxRate) {
    const billBody = this.billItemsBodyTarget;

    // Hide the "No items" message if it's currently visible
    if (this.hasNoItemsRowTarget && !this.noItemsRowTarget.classList.contains("hidden")) {
      this.noItemsRowTarget.classList.add("hidden");
    }

    const row = document.createElement("tr");
    // Store essential data on the row itself using data attributes
    row.dataset.productId = id;
    row.dataset.price = price; // Store unit price
    row.dataset.taxRate = taxRate; // Store tax rate for this item

    const initialQuantity = 1;
    const lineSubtotal = price * initialQuantity; // Calculate initial subtotal

    // Define the HTML structure for the new row
    // Ensure class names match your CSS for styling
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

    billBody.appendChild(row); // Add the new row to the table body
    this.updateTotals(); // Recalculate totals after adding item
  }

  // Removes an item row from the bill
  removeItem(event) {
    event.preventDefault();
    const rowToRemove = event.currentTarget.closest("tr");
    if (rowToRemove) {
      rowToRemove.remove(); // Remove the row from the DOM
      this.updateTotals(); // Recalculate totals
    }

    // Show the "No items" message if the table is now empty
    if (this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]").length === 0 && this.hasNoItemsRowTarget) {
      this.noItemsRowTarget.classList.remove("hidden");
    }
  }

  // Calculates subtotal, total tax, and grand total based on items in the bill
  updateTotals() {
    let overallSubtotal = 0;
    let overallTotalTax = 0; // Initialize tax accumulator

    console.log("--- Calculating Totals ---");

    const productRows = this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]");

    productRows.forEach((row) => {
      const productId = row.dataset.productId; // Get product ID (for logging/debug)
      const price = parseFloat(row.dataset.price) || 0; // Get unit price from row
      const taxRate = parseFloat(row.dataset.taxRate) || 0; // Get tax rate from row
      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10) || 0; // Get quantity
      const lineTotalCell = row.querySelector(".line-total"); // Get cell to update line total display

      console.log(`Row - ID: ${productId}, Price: ${price}, Qty: ${quantity}, Tax Rate: ${taxRate}%`);

      if (quantity > 0) { // Ensure quantity is valid
        const lineSubtotal = price * quantity; // Calculate subtotal for this line
        const lineTax = lineSubtotal * (taxRate / 100.0); // Calculate tax for this line

        overallSubtotal += lineSubtotal; // Add to overall subtotal
        overallTotalTax += lineTax; // Add to overall tax

        console.log(`  -> Line Subtotal: ${this.formatCurrency(lineSubtotal)}, Line Tax: ${this.formatCurrency(lineTax)}`);

        // Update the displayed line total in the table row
        if (lineTotalCell) {
          lineTotalCell.textContent = this.formatCurrency(lineSubtotal);
        }
      } else if (lineTotalCell) {
        // If quantity is invalid (e.g., 0 or NaN), display 0 for the line total
        lineTotalCell.textContent = this.formatCurrency(0);
         console.log(`  -> Invalid Quantity (${quantity})`);
      }
    });

    const grandTotal = overallSubtotal + overallTotalTax; // Calculate grand total

    console.log(`Final - Subtotal: ${this.formatCurrency(overallSubtotal)}, Tax: ${this.formatCurrency(overallTotalTax)}, Grand Total: ${this.formatCurrency(grandTotal)}`);
    console.log("--- Finished Calculating Totals ---");

    // Update the summary section display
    if (this.hasSummarySubtotalTarget) {
      this.summarySubtotalTarget.textContent = this.formatCurrency(overallSubtotal);
    }
    if (this.hasSummaryTotalTaxTarget) {
      // Update the dedicated tax display element
      this.summaryTotalTaxTarget.textContent = this.formatCurrency(overallTotalTax);
    }
    if (this.hasSummaryGrandTotalTarget) {
      this.summaryGrandTotalTarget.textContent = this.formatCurrency(grandTotal);
    }

    // Show/Hide the "No items" message row
    if (this.hasNoItemsRowTarget) {
        if (productRows.length === 0) {
            this.noItemsRowTarget.classList.remove("hidden");
        } else {
            this.noItemsRowTarget.classList.add("hidden");
        }
    }
  }

  // Helper to format numbers as Indian Rupees (INR)
  formatCurrency(value) {
    try {
      // Use Intl API for robust currency formatting
      return new Intl.NumberFormat("en-IN", {
        style: "currency",
        currency: "INR",
      }).format(value);
    } catch (e) {
      // Fallback for environments where Intl might not be fully supported
      console.warn("Intl.NumberFormat failed, using fallback currency format:", e);
      return `₹${Number(value || 0).toFixed(2)}`;
    }
  }

  disconnect() {
    console.log("Billing controller disconnected");
    // Add any cleanup logic here if needed
  }
} // End of class