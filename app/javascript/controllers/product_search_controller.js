// app/javascript/controllers/product_search_controller.js

import { Controller } from "@hotwired/stimulus";
import { debounce } from "lodash-es"; // Use lodash debounce

export default class extends Controller {
  static targets = ["searchInput", "productListContainer"];
  static values = { searchUrl: String };

  connect() {
    console.log("ProductSearch controller connected");
    // Bind the debounced function to ensure 'this' context is correct
    this.debouncedPerformSearch = debounce(this.performSearch.bind(this), 300);
  }

  // Action triggered by input event
  search(event) {
    this.debouncedPerformSearch(); // Call the debounced version
  }

  async performSearch() {
    const query = this.searchInputTarget.value.trim();

    // Ensure searchUrlValue exists and is not empty
    if (!this.hasSearchUrlValue || !this.searchUrlValue) {
      console.error("Search URL value is missing or empty.");
      this.productListContainerTarget.innerHTML = `<li class="list-group-item text-danger">Configuration error: Search URL not set.</li>`;
      return; // Stop if URL is not set
    }

    const url = `${this.searchUrlValue}?q=${encodeURIComponent(query)}`;
    console.log(`Searching for: ${query} at ${url}`);

    try {
      const response = await fetch(url, {
        headers: {
          Accept: "application/json", // Expect JSON
        },
      });

      if (!response.ok) {
        // Try to get more info from the response if possible
        let errorBody = "";
        try {
          errorBody = await response.text(); // Get response body as text
        } catch (e) {
          /* Ignore if reading body fails */
        }
        console.error(
          `Search request failed: ${response.status} ${response.statusText}`,
          errorBody
        );
        throw new Error(
          `Search request failed: ${response.statusText}. Server responded with: ${errorBody.substring(0, 100)}`
        );
      }

      // Check content type before parsing JSON
      const contentType = response.headers.get("content-type");
      if (contentType && contentType.includes("application/json")) {
        const data = await response.json(); // Parse JSON data
        this.updateProductList(data); // Update the list
        console.log("Product list updated.");
      } else {
        const responseText = await response.text();
        console.error("Received non-JSON response:", responseText);
        throw new Error(`Expected JSON response but received ${contentType}`);
      }
    } catch (error) {
      console.error("Error fetching or updating product list:", error);
      this.productListContainerTarget.innerHTML = `<li class="list-group-item text-danger">Error loading products. ${error.message}</li>`;
    }
  }

  // Corrected function to update the product list HTML
  updateProductList(data) {
    if (data.products && data.products.length > 0) {
      const html = data.products
        .map(
          (product) => `
          <li class="product-item list-group-item py-2"
              data-product-id="${product.id}"
              data-product-name="${product.product_name || ''}"
              data-product-price="${product.price || 0}"
              data-product-tax-percentage="${product.tax_rate || 0.0}" <%# Corrected attribute %>
              data-product-stock="${product.stock_quantity || 0}"
              >
            <div class="d-flex justify-content-between align-items-start">
              <div class="product-info me-2">
                <div class="d-flex align-items-center product-name-button-wrapper mb-1">
                  <span class="product-name product-name-small me-2">${product.product_name || 'Unnamed Product'}</span>
                  <button class="btn btn-outline-primary btn-sm product-add-btn"
                          data-action="click->billing#addItem" <%# Connects to billing controller %>
                          aria-label="Add ${product.product_name || 'Unnamed Product'} to bill">
                     <i class="fas fa-plus"></i>
                  </button>
                </div>
                <small class="product-meta text-muted d-block">
                  ${product.price ? this.formatCurrency(product.price) : 'Price N/A'}
                </small>
              </div>
              <span class="badge ${product.stock_quantity > 0 ? 'bg-success-soft' : 'bg-danger-soft'} text-dark product-stock-badge">
                Stock: ${product.stock_quantity ?? 'N/A'}
              </span>
            </div>
          </li>
        `
        )
        .join('');
      this.productListContainerTarget.innerHTML = html;
    } else {
      this.productListContainerTarget.innerHTML = `<li class="list-group-item text-warning">No products found matching your query.</li>`;
    }
  }

  // Helper function for currency formatting
  formatCurrency(value) {
    try {
      // Adjust locale and currency code as needed ('en-IN', 'INR')
      return new Intl.NumberFormat("en-IN", {
        style: "currency",
        currency: "INR",
      }).format(value);
    } catch (e) {
      console.warn("Intl.NumberFormat failed, using fallback currency format:", e);
      // Basic fallback formatting
      return `₹${Number(value || 0).toFixed(2)}`;
    }
  }

  disconnect() {
    // Cancel any pending debounced search if the controller disconnects
    if (this.debouncedPerformSearch && this.debouncedPerformSearch.cancel) {
      this.debouncedPerformSearch.cancel();
      console.log("ProductSearch debounced search cancelled on disconnect.");
    }
  }
}