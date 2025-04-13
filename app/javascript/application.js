document.addEventListener("DOMContentLoaded", function() {
    // Dark mode toggle functionality
    const themeToggle = document.getElementById("themeToggle");
    const body = document.body;
    themeToggle.addEventListener("click", function() {
      body.classList.toggle("light-mode");
      const icon = themeToggle.querySelector("i");
      if(body.classList.contains("light-mode")) {
        icon.className = "fas fa-moon";
      } else {
        icon.className = "fas fa-sun";
      }
    });
  });
  