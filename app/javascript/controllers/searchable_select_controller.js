// app/javascript/controllers/searchable_select_controller.js
import { Controller } from "@hotwired/stimulus";

// Import TomSelect library if it's not globally available via the asset pipeline or CDN
// Ensure TomSelect is properly pinned in your config/importmap.rb
// Example: pin "tom-select", to: "https://cdn.jsdelivr.net/npm/tom-select@2.4.3/dist/js/tom-select.complete.js"
// import TomSelect from "tom-select"; // Uncomment if you need to import it directly

// Connects to data-controller="searchable-select"
export default class extends Controller {
  static values = {
    // Define any configuration options you might want to pass from HTML
    // Example: create: Boolean // default would be false
  }

  connect() {
    // Check if TomSelect is available (either globally via window or imported)
    const TomSelectConstructor = window.TomSelect; // || TomSelect; // Use imported if needed
    if (typeof TomSelectConstructor === 'undefined') {
        console.error("TomSelect library not found. Make sure it's pinned in importmap.rb and loaded, or imported here.");
        return;
    }

    // Prevent re-initialization
    if (this.element.tomselect) {
      console.warn("TomSelect already initialized on this element.");
      return;
    }

    // Ensure the controller is attached to a SELECT element
    if (this.element.tagName !== "SELECT") {
      console.error("SearchableSelect controller must be attached to a SELECT element.");
      return;
    }

    // Default Tom Select options
    const defaultOptions = {
        create: this.hasCreateValue ? this.createValue : false, // Allow overriding create via data-searchable-select-create-value="true"
        sortField: {
            field: "text",
            direction: "asc"
        },
        // Add a placeholder if the select element has one
        placeholder: this.element.getAttribute('placeholder'),
        // Add more default Tom Select options here if needed
        // render: { // Example: Custom rendering if needed later
        //   option: function(data, escape) {
        //     return `<div>${escape(data.text)}</div>`;
        //   },
        //   item: function(item, escape) {
        //      return `<div>${escape(item.text)}</div>`;
        //    }
        // }
    };

    try {
        // Initialize Tom Select
        this.select = new TomSelectConstructor(this.element, defaultOptions);
        console.log("TomSelect initialized successfully.");

        // NO JS styling applied here - rely on billing.css

    } catch (error) {
        console.error("Error initializing TomSelect:", error, this.element);
    }
  }

  disconnect() {
    // Destroy Tom Select instance when the controller disconnects
    if (this.select) {
      this.select.destroy();
      this.select = null; // Clear the reference
      console.log("TomSelect instance destroyed.");
    }
  }
}