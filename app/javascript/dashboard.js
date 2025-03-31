import "@hotwired/turbo-rails"

document.addEventListener("DOMContentLoaded", function () {
  // Dark mode toggle functionality
  const themeToggle = document.getElementById("themeToggle");
  const body = document.body;

  if (themeToggle) {
    themeToggle.addEventListener("click", function () {
      // Toggle the light-mode class on the body
      body.classList.toggle("light-mode");

      // Update the icon based on the current mode
      const icon = themeToggle.querySelector("i");
      if (body.classList.contains("light-mode")) {
        icon.className = "fas fa-moon"; // Change to moon icon for light mode
      } else {
        icon.className = "fas fa-sun"; // Change to sun icon for dark mode
      }
    });
  }

  // User dropdown functionality
  const userButton = document.getElementById("userButton");
  const userDropdown = document.getElementById("userDropdown");

  if (userButton && userDropdown) {
    userButton.addEventListener("click", function (e) {
      e.stopPropagation(); // Prevent click event from propagating to the document
      userDropdown.classList.toggle("show");

      // Update chevron icon based on dropdown state
      const chevron =
        userButton.querySelector("i.fas.fa-chevron-down") ||
        userButton.querySelector("i.fas.fa-chevron-up");
      if (userDropdown.classList.contains("show")) {
        if (chevron) chevron.className = "fas fa-chevron-up";
      } else {
        if (chevron) chevron.className = "fas fa-chevron-down";
      }
    });

    // Close dropdown when clicking outside
    document.addEventListener("click", function () {
      if (userDropdown.classList.contains("show")) {
        userDropdown.classList.remove("show");
        const chevron = userButton.querySelector("i.fas.fa-chevron-up");
        if (chevron) chevron.className = "fas fa-chevron-down";
      }
    });
  }
});
