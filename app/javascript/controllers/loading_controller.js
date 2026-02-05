import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  show() {
    this.panelTarget.classList.remove("hidden")
  }

  hide() {
    this.panelTarget.classList.add("hidden")
  }
}
