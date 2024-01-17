import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-form"
export default class extends Controller {
  static targets = ['template', 'addMediaAttachment']

  connect() {
    console.log('nested form connected!')
  }

  add_association(event) {
    event.preventDefault()
    var random_integer = Math.floor(Math.random() * 100000)
    var content = this.templateTarget.innerHTML.replace(/TEMPLATE_RECORD/g, random_integer)
    this.addMediaAttachmentTarget.insertAdjacentHTML('beforebegin', content)
  }
}
