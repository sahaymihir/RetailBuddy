// app/javascript/controllers/index.js
// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application"

// Eager load all controllers defined in the import map under controllers/**/*_controller
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)
// Lazy load controllers as they appear in the DOM (useful for larger apps)
// import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
// lazyLoadControllersFrom("controllers", application)

// --- Add this line if using eager loading ---
// import BillingController from "./billing_controller.js" // Check path if needed
// application.register("billing", BillingController)
// Note: If using eagerLoadControllersFrom, this manual registration might not be needed
// if your importmap correctly maps "controllers/billing_controller.js".