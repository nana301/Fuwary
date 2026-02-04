import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  show() {
    document.getElementById("loading").classList.remove("hidden")
  }
}
