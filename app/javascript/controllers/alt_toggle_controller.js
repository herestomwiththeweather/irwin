import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="alt-toggle"
export default class extends Controller {
  static targets = ['description']

  connect() {
  }

  toggle() {
    event.preventDefault()
    this.descriptionTarget.classList.toggle('hidden')
  }
}
