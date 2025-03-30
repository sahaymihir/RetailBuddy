import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle() {
    // Toggle the "light-mode" class on the body
    document.body.classList.toggle("light-mode");
    // Update the icon accordingly (optional)
    const icon = this.element.querySelector("i");
    if (document.body.classList.contains("light-mode")) {
      icon.className = "fas fa-moon";
    } else {
      icon.className = "fas fa-sun";
    }
  }
}
