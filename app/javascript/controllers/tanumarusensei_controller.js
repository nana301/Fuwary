import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    const messages = [
       "こんにちは。今日は、どんなことを占ってみましょうか？",
       "よろしければ、今のお気持ちから見てみますか？",
       "今日は、流れをゆっくり整えていく日にしてみてもよさそうですね。"
    ]
    this.messageTarget.textContent = messages[Math.floor(Math.random() * messages.length)]
  }

  go(event) {
    const id = event.currentTarget.dataset.targetId
    const el = document.getElementById(id)
    if (!el) return
    el.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
