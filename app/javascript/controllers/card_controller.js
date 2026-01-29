import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["inner", "message"]

  connect() {
    setTimeout(() => {
      this.innerTarget.classList.add("rotate-y-180")
    }, 500)

    setTimeout(() => {
      this.messageTarget.classList.remove("opacity-0")
    }, 1200)
  }
}
