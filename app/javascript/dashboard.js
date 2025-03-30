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
  
    // User dropdown functionality
    const userButton = document.getElementById("userButton");
    const userDropdown = document.getElementById("userDropdown");
    userButton.addEventListener("click", function(e) {
      e.stopPropagation();
      userDropdown.classList.toggle("show");
      const chevron = userButton.querySelector("i.fas.fa-chevron-down") || userButton.querySelector("i.fas.fa-chevron-up");
      if(userDropdown.classList.contains("show")){
        if(chevron) { chevron.className = "fas fa-chevron-up"; }
      } else {
        if(chevron) { chevron.className = "fas fa-chevron-down"; }
      }
    });
    
    // Close dropdown when clicking outside
    document.addEventListener("click", function() {
      if(userDropdown.classList.contains("show")){
        userDropdown.classList.remove("show");
        const chevron = userButton.querySelector("i.fas.fa-chevron-up");
        if(chevron) { chevron.className = "fas fa-chevron-down"; }
      }
    });
  });
  