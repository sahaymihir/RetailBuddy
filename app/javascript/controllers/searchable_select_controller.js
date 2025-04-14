// app/javascript/controllers/searchable_select_controller.js
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="searchable-select"
export default class extends Controller {
  connect() {
    if (this.element.tomselect) {
      // console.warn("TomSelect already initialized on this element."); // Optional logging
      return;
    }

    if (this.element.tagName !== "SELECT") {
      console.error("SearchableSelect controller must be attached to a SELECT element.");
      return;
    }

    try {
      this.select = new window.TomSelect(this.element, {
        create: false,
        sortField: {
          field: "text",
          direction: "asc"
        }
        // Add other Tom Select options here if needed
      });

      // --- Force Styles After Initialization ---
      this.applyStyles();
      // Optional: Observe theme changes if you have a theme toggle
      // document.addEventListener('theme:change', this.applyStyles.bind(this));

    } catch (error) {
      console.error("Error initializing TomSelect:", error);
    }
  }

  // --- NEW Method to Apply Styles ---
  applyStyles() {
    if (!this.select || !this.select.control) return; // Ensure TomSelect is initialized

    const controlElement = this.select.control; // The main input div
    const isLightMode = document.body.classList.contains('light-mode');

    // Get colors from CSS variables (safer than hardcoding)
    const rootStyle = getComputedStyle(document.documentElement);
    const darkBg = rootStyle.getPropertyValue('--input-bg').trim() || '#2d2d2d';
    const lightBg = rootStyle.getPropertyValue('--card-bg').trim() || '#ffffff';
    const darkText = rootStyle.getPropertyValue('--text-color').trim() || '#f8f9fa'; // Assuming --text-color is light in dark mode
    const lightText = '#333333'; // Assuming default dark text for light mode
    const darkBorder = darkBg; // Match background
    const lightBorder = '#ccc';

    if (isLightMode) {
      controlElement.style.backgroundColor = lightBg;
      controlElement.style.borderColor = lightBorder;
      controlElement.style.color = lightText;
       // Style inner input if accessible (may vary by TomSelect version)
       if (this.select.control_input) {
            this.select.control_input.style.color = lightText;
       }
    } else {
      // Dark Mode
      controlElement.style.backgroundColor = darkBg;
      controlElement.style.borderColor = darkBorder;
      controlElement.style.color = darkText;
       // Style inner input if accessible
       if (this.select.control_input) {
           this.select.control_input.style.color = darkText;
       }
    }
     // Ensure placeholder color is also set correctly (might need ::placeholder CSS still)
  }


  disconnect() {
    // Optional: Remove theme change listener if added
    // document.removeEventListener('theme:change', this.applyStyles.bind(this));

    if (this.select) {
      this.select.destroy();
      this.select = null; // Clear reference
    }
  }
}