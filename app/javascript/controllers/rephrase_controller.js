import { Controller } from "@hotwired/stimulus"

// 入力フォームの補助操作（クリア）を扱うコントローラー
export default class extends Controller {
  static targets = ["content", "contentSection", "errorModalContainer", "contentCount"]
  static values = { maxLength: Number }

  connect() {
    this.validateContent()
  }

  // 原文テキストエリアだけをクリアする
  clearContent() {
    if (!this.hasContentTarget) return

    this.contentTarget.value = ""
    this.validateContent()
    this.contentTarget.focus()
  }

  validateContent() {
    if (!this.hasContentTarget) return

    const maxLength = this.maxLengthValue || 300
    const length = this.contentTarget.value.length
    const isTooLong = length > maxLength

    if (this.hasContentCountTarget) {
      this.contentCountTarget.textContent = `${length}/${maxLength}文字`
      this.contentCountTarget.classList.toggle("text-[var(--color-error)]", isTooLong)
      this.contentCountTarget.classList.toggle("font-semibold", isTooLong)
    }

    this.contentTarget.setAttribute("aria-invalid", String(isTooLong))
    if (this.hasContentSectionTarget) {
      this.contentSectionTarget.classList.toggle("border-[var(--color-error)]", isTooLong)
      this.contentSectionTarget.classList.toggle("bg-red-50/20", isTooLong)
      this.contentSectionTarget.classList.toggle("dark:bg-red-950/20", isTooLong)
    }

    this.renderClientError(isTooLong, length, maxLength)
  }

  preventInvalidSubmit(event) {
    const maxLength = this.maxLengthValue || 300
    const length = this.hasContentTarget ? this.contentTarget.value.length : 0
    const isTooLong = length > maxLength
    if (!isTooLong) return

    event.preventDefault()
    this.renderClientError(true, length, maxLength)
    this.contentTarget.focus()
  }

  renderClientError(isTooLong, length, maxLength) {
    if (!this.hasErrorModalContainerTarget) return

    const existingAlert = document.getElementById("rephrase-error-modal")
    if (!isTooLong) {
      if (existingAlert) existingAlert.remove()
      return
    }

    const overflowCount = length - maxLength
    const markup = `
      <div id="rephrase-error-modal"
           class="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/50 px-4"
           role="alertdialog"
           aria-modal="true"
           aria-labelledby="rephrase-error-modal-title"
           aria-describedby="rephrase-error-modal-description"
           data-action="click->rephrase#closeErrorModalOnBackdrop">
        <section class="w-full max-w-xl rounded-2xl border border-[var(--color-error)]/40 bg-white p-6 shadow-2xl dark:border-red-900/60 dark:bg-slate-900"
                 data-modal-panel="true">
          <div class="flex items-start gap-3">
            <span class="material-symbols-outlined mt-0.5 text-2xl text-[var(--color-error)] dark:text-red-300">error</span>
            <div class="w-full space-y-3">
              <h2 id="rephrase-error-modal-title" class="text-lg font-bold text-slate-900 dark:text-slate-100">入力内容に修正が必要です</h2>
              <p id="rephrase-error-modal-description" class="text-sm text-slate-700 dark:text-slate-300">
                原因を確認して修正後に、もう一度「言い換え実行」を押してください。
              </p>
              <div class="rounded-lg border border-red-100 bg-red-50/60 px-3 py-2 text-sm leading-relaxed text-red-900 dark:border-red-900/50 dark:bg-red-950/20 dark:text-red-100">
                <span class="font-semibold">原因:</span> 入力文が${maxLength}文字を${overflowCount}文字超えています。<br>
                <span class="font-semibold">対処:</span> 文字数を減らして${maxLength}文字以内にしてください。
              </div>
              <div class="pt-2 text-right">
                <button type="button"
                        class="rounded-full bg-[var(--color-error)] px-5 py-2 text-sm font-bold text-white transition-colors hover:bg-red-700"
                        data-action="rephrase#closeErrorModal">
                  閉じる
                </button>
              </div>
            </div>
          </div>
        </section>
      </div>
    `

    if (existingAlert) {
      existingAlert.outerHTML = markup
    } else {
      this.errorModalContainerTarget.innerHTML = markup
    }
  }

  closeErrorModal() {
    const modal = document.getElementById("rephrase-error-modal")
    if (modal) modal.remove()
  }

  closeErrorModalOnBackdrop(event) {
    const panel = event.target.closest("[data-modal-panel='true']")
    if (panel) return
    this.closeErrorModal()
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

    this.validateContent()
  }
}
