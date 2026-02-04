import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["message", "hint"]

  connect() {
    const hour = new Date().getHours()
    const timeHint =
      hour < 11 ? "おはよう" : hour < 17 ? "こんにちは" : "こんばんは"

    const messages = [
      `${timeHint}。今日は何をする？`,
      "よしよし。いまの気分、少しだけ教えて？",
      "今日の運勢、さくっと見てみる？",
      "焦らなくて大丈夫。深呼吸してから決めよう。",
      "気になるジャンル、ひとつ選んでみる？",
    ]

    this.messageTarget.textContent =
      messages[Math.floor(Math.random() * messages.length)]

    if (this.hasHintTarget) this.hintTarget.textContent = "先生より"
  }

  go(event) {
    const id = event.currentTarget.dataset.targetId
    const el = document.getElementById(id)
    if (!el) return

    el.scrollIntoView({ behavior: "smooth", block: "start" })
  }
}
