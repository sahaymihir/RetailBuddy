import "@hotwired/turbo-rails";

function initializeDashboard() {

  // --- USER DROPDOWN LOGIC (No changes needed) ---
  const userButton = document.getElementById("userButton"); // Now targets the welcome text button
  const userDropdown = document.getElementById("userDropdown");

  if (userButton && userDropdown) {
    userButton.addEventListener("click", function(e) {
      e.preventDefault();
      e.stopPropagation();
      userDropdown.classList.toggle("show");

      const chevron = this.querySelector(".fa-chevron-down, .fa-chevron-up");
      if (chevron) {
        chevron.className = userDropdown.classList.contains("show")
          ? "fas fa-chevron-up"
          : "fas fa-chevron-down";
      }
    });

    document.addEventListener("click", function(e) {
      if (!userButton.contains(e.target) && !userDropdown.contains(e.target)) {
        if (userDropdown.classList.contains("show")) {
          userDropdown.classList.remove("show");
          const chevron = userButton.querySelector(".fa-chevron-up");
          if (chevron) chevron.className = "fas fa-chevron-down";
        }
      }
    });

    userDropdown.addEventListener("click", function(e) {
      e.stopPropagation();
    });
  }
  // --- END USER DROPDOWN LOGIC ---

}

document.addEventListener("turbo:load", initializeDashboard);
document.addEventListener("DOMContentLoaded", initializeDashboard);