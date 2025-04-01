import "@hotwired/turbo-rails"

// Function to initialize all dashboard functionality
function initializeDashboard() {
  // Dark mode toggle
  const themeToggle = document.getElementById("themeToggle");
  if (themeToggle) {
    themeToggle.addEventListener("click", function() {
      document.body.classList.toggle("light-mode");
      const icon = this.querySelector("i");
      icon.className = document.body.classList.contains("light-mode") 
        ? "fas fa-moon" 
        : "fas fa-sun";
    });
  }

  // User dropdown functionality
  const userButton = document.getElementById("userButton");
  const userDropdown = document.getElementById("userDropdown");

  if (userButton && userDropdown) {
    userButton.addEventListener("click", function(e) {
      e.preventDefault();
      e.stopPropagation();
      userDropdown.classList.toggle("show");
      
      // Toggle chevron icon
      const chevron = this.querySelector(".fa-chevron-down, .fa-chevron-up");
      if (chevron) {
        chevron.className = userDropdown.classList.contains("show")
          ? "fas fa-chevron-up"
          : "fas fa-chevron-down";
      }
    });

    // Close dropdown when clicking outside
    document.addEventListener("click", function() {
      if (userDropdown.classList.contains("show")) {
        userDropdown.classList.remove("show");
        const chevron = userButton.querySelector(".fa-chevron-up");
        if (chevron) chevron.className = "fas fa-chevron-down";
      }
    });

    // Prevent dropdown from closing when clicking inside it
    userDropdown.addEventListener("click", function(e) {
      e.stopPropagation();
    });
  }
}

// Initialize on both regular load and Turbo visits
document.addEventListener("DOMContentLoaded", initializeDashboard);
document.addEventListener("turbo:load", initializeDashboard);