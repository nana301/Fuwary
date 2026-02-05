import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]

  connect() {
    if (this.tabTargets.length > 0) {
      const first = this.tabTargets.find(t => t.classList.contains("tab-active")) || this.tabTargets[0]
      this.show(first)
    }
  }

  switch(event) {
    event.preventDefault()
    this.show(event.currentTarget)
  }

  show(tabEl) {
    const target = tabEl.dataset.tab

    this.tabTargets.forEach(t => t.classList.remove("tab-active"))
    tabEl.classList.add("tab-active")

    this.contentTargets.forEach(c => c.classList.add("hidden"))
    const panel = this.contentTargets.find(c => c.id === `tab-${target}`)
    if (panel) panel.classList.remove("hidden")
  }
}

