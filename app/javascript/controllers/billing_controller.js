import { Controller } from "@hotwired/stimulus";
import { v4 as uuidv4 } from "uuid";

export default class extends Controller {
  static targets = [
    "billItemsBody",
    "summarySubtotal",
    "summaryTotalTax",
    "summaryGrandTotal",
    "noItemsRow",
    "finalizeError",
    "paymentBtn",
    "qrModal",
    "qrCodeImage",
    "qrInstructions",
    // "customerSelect"  // Keep this if you need to access it in other methods
  ];

  selectedPaymentMethod = null;
  placeholderQrUrl =
    "https://api.qrserver.com/v1/create-qr-code/?size=250x250&data=YOUR_STATIC_UPI_ID_OR_PAYMENT_LINK";

  connect() {
    console.log("Billing controller connected!");
    this.updateTotals();
  }

  selectPaymentMethod(event) {
    event.preventDefault();
    const clickedButton = event.currentTarget;
    this.selectedPaymentMethod = clickedButton.dataset.method;
    this.paymentBtnTargets.forEach((btn) => btn.classList.remove("active"));
    clickedButton.classList.add("active");
    console.log("Payment method selected:", this.selectedPaymentMethod);
    if (this.hasFinalizeErrorTarget) this.finalizeErrorTarget.textContent = "";
    this.handlePaymentDisplay(event);
  }

  handlePaymentDisplay(event) {
    const method =
      event.currentTarget.dataset.method || this.selectedPaymentMethod;
    console.log("Handling display for:", method);

    switch (method) {
      case "Cash":
        alert("Please collect cash payment at the counter.");
        this.closeQrModal();
        break;
      case "UPI":
        this.showUpiQrCode();
        break;
      default:
        console.warn(
          "Unknown payment method selected for display:",
          method
        );
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

    this.updateTotals();
    const grandTotal =
      parseFloat(
        this.summaryGrandTotalTarget.textContent.replace(/[^0-9.]/g, "")
      ) || 0;

    if (grandTotal <= 0) {
      this.displayError("Cannot generate QR code for zero amount.");
      this.closeQrModal();
      return;
    }

    this.qrCodeImageTarget.src = this.placeholderQrUrl;
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
      this.finalizeErrorTarget.textContent = "";
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
      if (invalidItemFound) return;

      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10);
      const productId = row.dataset.productId;
      const unitPrice = parseFloat(row.dataset.price);

      if (!productId || isNaN(quantity) || quantity <= 0 || isNaN(unitPrice)) {
        this.displayError(
          `Invalid quantity or price for item: ${
            row.cells[0]?.textContent || "Unknown"
          }. Please correct.`
        );
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
      return;
    }

    const customerSelect = document.getElementById("customer-select");
    const customerId = customerSelect ? customerSelect.value : null;

    if (!this.selectedPaymentMethod) {
      this.displayError("Please select a payment method.");
      return;
    }

    const payload = {
      invoice: {
        customer_id: customerId,
        payment_method: this.selectedPaymentMethod,
        payment_status: "Completed",
        invoice_lines_attributes: items,
      },
    };
    console.log("Payload to be sent:", JSON.stringify(payload));

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute(
      "content"
    );
    if (!csrfToken) {
      this.displayError("Security token missing. Please refresh the page.");
      return;
    }

    try {
      const response = await fetch("/invoices", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify(payload),
      });

      const responseData = await response.json();

      if (responseData.success && responseData.invoice_id) {
        console.log("Invoice created successfully:", responseData);
        window.location.href = `/invoices/${responseData.invoice_id}`;
      } else {
        console.error("Invoice creation failed on backend:", responseData);
        this.displayError(
          responseData.message ||
            responseData.error ||
            "An unknown error occurred processing the bill."
        );
      }
    } catch (error) {
      console.error("Network or fetch error:", error);
      this.displayError(
        "Could not connect to the server. Please check your network and try again."
      );
    }
  }

  displayError(message) {
    if (this.hasFinalizeErrorTarget) {
      this.finalizeErrorTarget.textContent = message;
      this.finalizeErrorTarget.classList.remove("hidden");
    } else {
      alert(`Error: ${message}`);
    }
  }

  addItem(event) {
    event.preventDefault();
    const productElement = event.currentTarget.closest("[data-product-id]");
    if (!productElement) {
      console.error(
        "Could not find product data element from event target:",
        event.currentTarget
      );
      return;
    }

    const productId = productElement.dataset.productId;
    const productName = productElement.dataset.productName;
    const productPrice = parseFloat(productElement.dataset.productPrice);
    const productTaxRate = parseFloat(
      productElement.dataset.productTaxPercentage || 0
    );

    if (!productId || !productName || isNaN(productPrice) || isNaN(productTaxRate)) {
      console.error(
        "Invalid or missing product data attributes found:",
        productElement.dataset
      );
      this.displayError("Could not add item: essential product data is missing.");
      return;
    }

    const existingRow = this.billItemsBodyTarget.querySelector(
      `tr[data-product-id="${productId}"]`
    );

    if (existingRow) {
      const quantityInput = existingRow.querySelector(".quantity-input");
      if (quantityInput) {
        quantityInput.value = parseInt(quantityInput.value, 10) + 1;
        this.updateTotals();
      }
    } else {
      this.addBillRow(productId, productName, productPrice, productTaxRate);
    }
  }

  addBillRow(id, name, price, taxRate) {
    const billBody = this.billItemsBodyTarget;

    if (
      this.hasNoItemsRowTarget &&
      !this.noItemsRowTarget.classList.contains("hidden")
    ) {
      this.noItemsRowTarget.classList.add("hidden");
    }

    const row = document.createElement("tr");
    row.dataset.productId = id;
    row.dataset.price = price;
    row.dataset.taxRate = taxRate;

    const lineSubtotal = price * 1;

    row.innerHTML = `
      <td class="py-2 px-3 border-b border-gray-700 text-gray-300">${name}</td>
      <td class="py-2 px-3 border-b border-gray-700">
        <input
          type="number"
          value="1"
          min="1"
          class="quantity-input form-input w-16 text-right border rounded bg-gray-700 text-white border-gray-600 focus:ring-blue-500 focus:border-blue-500"
          data-action="change->billing#updateTotals keyup->billing#updateTotals">
      </td>
      <td class="py-2 px-3 border-b border-gray-700 text-right text-gray-300">${this.formatCurrency(
        price
      )}</td>
      <td class="line-total py-2 px-3 border-b border-gray-700 text-right text-gray-300">${this.formatCurrency(
        lineSubtotal
      )}</td>
      <td class="py-2 px-3 border-b border-gray-700 text-center">
        <button class="remove-item-btn text-red-500 hover:text-red-400 px-1" data-action="click->billing#removeItem" aria-label="Remove ${name}">
           <i class="fas fa-times-circle"></i>
        </button>
      </td>
    `;

    billBody.appendChild(row);
    this.updateTotals();
  }

  removeItem(event) {
    event.preventDefault();
    const rowToRemove = event.currentTarget.closest("tr");
    if (rowToRemove) {
      rowToRemove.remove();
      this.updateTotals();
    }

    if (
      this.billItemsBodyTarget.querySelectorAll("tr[data-product-id]").length ===
        0 &&
      this.hasNoItemsRowTarget
    ) {
      this.noItemsRowTarget.classList.remove("hidden");
    }
  }

  updateTotals() {
    let overallSubtotal = 0;
    let overallTotalTax = 0;

    const productRows = this.billItemsBodyTarget.querySelectorAll(
      "tr[data-product-id]"
    );

    productRows.forEach((row) => {
      const price = parseFloat(row.dataset.price) || 0;
      const taxRate = parseFloat(row.dataset.taxRate) || 0;
      const quantityInput = row.querySelector(".quantity-input");
      const quantity = parseInt(quantityInput ? quantityInput.value : 0, 10) || 0;
      const lineTotalCell = row.querySelector(".line-total");

      if (quantity >= 0) {
        const lineSubtotal = price * quantity;
        const lineTax = lineSubtotal * (taxRate / 100);
        overallSubtotal += lineSubtotal;
        overallTotalTax += lineTax;

        if (lineTotalCell) {
          lineTotalCell.textContent = this.formatCurrency(lineSubtotal);
        }
      } else if (lineTotalCell) {
        lineTotalCell.textContent = this.formatCurrency(0);
      }
    });

    const grandTotal = overallSubtotal + overallTotalTax;

    if (this.hasSummarySubtotalTarget) {
      this.summarySubtotalTarget.textContent =
        this.formatCurrency(overallSubtotal);
    }
    if (this.hasSummaryTotalTaxTarget) {
      this.summaryTotalTaxTarget.textContent =
        this.formatCurrency(overallTotalTax);
    }
    if (this.hasSummaryGrandTotalTarget) {
      this.summaryGrandTotalTarget.textContent =
        this.formatCurrency(grandTotal);
    }
  }

  formatCurrency(value) {
    try {
      return new Intl.NumberFormat("en-IN", {
        style: "currency",
        currency: "INR",
      }).format(value);
    } catch (e) {
      console.warn(
        "Intl.NumberFormat failed, using fallback currency format:",
        e
      );
      return `₹${Number(value || 0).toFixed(2)}`;
    }
  }

  disconnect() {
    console.log("Billing controller disconnected");
  }
}