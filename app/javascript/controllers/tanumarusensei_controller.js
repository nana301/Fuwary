import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message"]

  connect() {
    console.log("🦝 tanumarusensei connected")
    const messages = [
      "ようこそ。今日は何を占ってみる？",
      "気になること、ひとつカードに聞いてみませんか？",
      "今の流れを、そっと占ってみましょう。",
      "迷っていることがあれば、ここから始めてみてね。",
      "今日はどんなメッセージが届くでしょうか？"
    ]

    this.messageTarget.textContent =
      messages[Math.floor(Math.random() * messages.length)]
  }

  go(event) {
    const id = event.currentTarget.dataset.targetId
    const el = document.getElementById(id)
    if (!el) return
    el.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
