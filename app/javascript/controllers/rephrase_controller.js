import { Controller } from "@hotwired/stimulus"

// 入力フォームの補助操作（クリア）を扱うコントローラー
export default class extends Controller {
  static targets = ["content"]

  // 原文テキストエリアだけをクリアする
  clearContent() {
    if (!this.hasContentTarget) return

    this.contentTarget.value = ""
    this.contentTarget.focus()
  }

  // 送信後にsubmitボタン無効化が残るケースを防ぐ
  restoreFormState(event) {
    const submitter = event.detail?.formSubmission?.submitter
    if (submitter) {
      submitter.disabled = false
      submitter.removeAttribute("aria-disabled")
    }

    this.element.removeAttribute("aria-busy")
    this.element.querySelectorAll("button[type='submit'], input[type='submit']").forEach((el) => {
      el.disabled = false
      el.removeAttribute("aria-disabled")
    })
  }
}
