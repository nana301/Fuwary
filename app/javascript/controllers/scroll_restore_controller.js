import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.y = null

    this._save = this.save.bind(this)
    this._restore = this.restore.bind(this)

    document.addEventListener("turbo:submit-start", this._save)
    document.addEventListener("turbo:before-stream-render", this._restore)
    document.addEventListener("turbo:render", this._restore)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this._save)
    document.removeEventListener("turbo:before-stream-render", this._restore)
    document.removeEventListener("turbo:render", this._restore)
  }

  save(event) {
    const form = event.target
    if (!(form instanceof HTMLFormElement)) return

    const action = form.getAttribute("action") || ""
    if (!action.includes("/draw")) return

    this.y = window.scrollY
  }

  restore() {
    if (typeof this.y !== "number") return

    requestAnimationFrame(() => window.scrollTo({ top: this.y }))
    requestAnimationFrame(() => requestAnimationFrame(() => window.scrollTo({ top: this.y })))
    setTimeout(() => window.scrollTo({ top: this.y }), 50)
  }
}
