import { Controller } from "@hotwired/stimulus"

// 入力フォームの補助操作（クリア）を扱うコントローラー
export default class extends Controller {
  static targets = ["content", "contentSection", "errorModalContainer", "contentCount", "resultFrame"]
  static values = { maxLength: Number }

  connect() {
    console.log("[rephrase] connect", {
      hasContentTarget: this.hasContentTarget,
      hasErrorModalContainerTarget: this.hasErrorModalContainerTarget
    })
    this.refreshContentState()
  }

  // 原文テキストエリアだけをクリアする
  clearContent() {
    if (!this.hasContentTarget) return

    this.contentTarget.value = ""
    this.validateContent()
    this.contentTarget.focus()
  }

  refreshContentState() {
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
  }

  validateContent() {
    if (!this.hasContentTarget) return

    const maxLength = this.maxLengthValue || 300
    const length = this.contentTarget.value.length
    const isTooLong = length > maxLength

    this.refreshContentState()
    if (!isTooLong) {
      this.clearErrorUi()
      return
    }

    this.renderClientError(true, length, maxLength)
  }

  submit(event) {
    console.log("[rephrase] submit", {
      contentLength: this.hasContentTarget ? this.contentTarget.value.length : 0
    })

    const maxLength = this.maxLengthValue || 300
    const rawContent = this.hasContentTarget ? this.contentTarget.value : ""
    const normalizedContent = rawContent.trim()
    const length = rawContent.length
    const isTooLong = length > maxLength
    const isBlank = normalizedContent.length === 0

    if (isBlank) {
      event.preventDefault()
      this.renderValidationModal(
        "入力文が空です。",
        "内容を入力してから、もう一度「言い換え実行」を押してください。"
      )
      this.contentTarget.focus()
      return
    }

    if (!isTooLong) {
      this.prepareSubmissionUi()
      return
    }

    event.preventDefault()
    this.renderValidationModal(
      `入力文が${maxLength}文字を${length - maxLength}文字超えています。`,
      `文字数を減らして${maxLength}文字以内にしてください。`
    )
    this.contentTarget.focus()
  }

  renderClientError(isTooLong, length, maxLength) {
    if (!this.hasErrorModalContainerTarget) return

    const existingAlert = document.getElementById("client-content-limit-modal")
    if (!isTooLong) {
      if (existingAlert) existingAlert.remove()
      return
    }

    const overflowCount = length - maxLength
    const markup = `
      <div id="client-content-limit-modal"
           class="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-slate-900/30 px-4"
           role="alertdialog"
           aria-modal="true"
           aria-labelledby="rephrase-error-modal-title"
           aria-describedby="rephrase-error-modal-description">
        <section class="pointer-events-auto w-full max-w-xl rounded-2xl border border-[var(--color-error)]/40 bg-white p-6 shadow-2xl dark:border-red-900/60 dark:bg-slate-900"
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

  renderValidationModal(causeText, actionText) {
    if (!this.hasErrorModalContainerTarget) return

    const markup = `
      <div id="client-content-limit-modal"
           class="pointer-events-none fixed inset-0 z-50 flex items-center justify-center bg-slate-900/30 px-4"
           role="alertdialog"
           aria-modal="true"
           aria-labelledby="rephrase-error-modal-title"
           aria-describedby="rephrase-error-modal-description">
        <section class="pointer-events-auto w-full max-w-xl rounded-2xl border border-[var(--color-error)]/40 bg-white p-6 shadow-2xl dark:border-red-900/60 dark:bg-slate-900"
                 data-modal-panel="true">
          <div class="flex items-start gap-3">
            <span class="material-symbols-outlined mt-0.5 text-2xl text-[var(--color-error)] dark:text-red-300">error</span>
            <div class="w-full space-y-3">
              <h2 id="rephrase-error-modal-title" class="text-lg font-bold text-slate-900 dark:text-slate-100">入力内容に修正が必要です</h2>
              <p id="rephrase-error-modal-description" class="text-sm text-slate-700 dark:text-slate-300">
                原因を確認して修正後に、もう一度「言い換え実行」を押してください。
              </p>
              <div class="rounded-lg border border-red-100 bg-red-50/60 px-3 py-2 text-sm leading-relaxed text-red-900 dark:border-red-900/50 dark:bg-red-950/20 dark:text-red-100">
                <span class="font-semibold">原因:</span> ${causeText}<br>
                <span class="font-semibold">対処:</span> ${actionText}
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

    this.errorModalContainerTarget.innerHTML = markup
  }

  closeErrorModal() {
    const clientModal = document.getElementById("client-content-limit-modal")
    const serverModal = document.getElementById("rephrase-error-modal")
    if (clientModal) clientModal.remove()
    if (serverModal) serverModal.remove()
  }

  clearErrorUi() {
    this.closeErrorModal()
    if (this.hasErrorModalContainerTarget) this.errorModalContainerTarget.innerHTML = ""
  }

  prepareSubmissionUi() {
    this.clearErrorUi()
    this.renderLoadingState()
  }

  renderLoadingState() {
    if (!this.hasResultFrameTarget) return

    this.resultFrameTarget.classList.add("opacity-70", "transition-opacity")
    this.resultFrameTarget.innerHTML = `
      <section class="space-y-4 animate-pulse" aria-live="polite" aria-label="言い換え結果を生成中です">
        <div class="h-6 w-32 rounded bg-slate-200 dark:bg-slate-700"></div>
        <div class="space-y-3">
          <div class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
            <div class="mb-3 h-4 w-24 rounded bg-slate-200 dark:bg-slate-700"></div>
            <div class="space-y-2">
              <div class="h-4 w-full rounded bg-slate-200 dark:bg-slate-700"></div>
              <div class="h-4 w-11/12 rounded bg-slate-200 dark:bg-slate-700"></div>
              <div class="h-4 w-9/12 rounded bg-slate-200 dark:bg-slate-700"></div>
            </div>
          </div>
          <div class="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-800 dark:bg-slate-900">
            <div class="mb-3 h-4 w-24 rounded bg-slate-200 dark:bg-slate-700"></div>
            <div class="space-y-2">
              <div class="h-4 w-full rounded bg-slate-200 dark:bg-slate-700"></div>
              <div class="h-4 w-10/12 rounded bg-slate-200 dark:bg-slate-700"></div>
              <div class="h-4 w-8/12 rounded bg-slate-200 dark:bg-slate-700"></div>
            </div>
          </div>
        </div>
      </section>
    `
  }

  focusResultArea() {
    const frame = document.getElementById("rephrase_result")
    if (!frame) return

    frame.classList.remove("opacity-70")
    frame.scrollIntoView({ behavior: "smooth", block: "start" })
    frame.setAttribute("tabindex", "-1")
    frame.focus({ preventScroll: true })
  }

  copyAllResults() {
    const frame = document.getElementById("rephrase_result")
    if (!frame) return

    const items = Array.from(frame.querySelectorAll("[data-result-content]"))
      .map((node) => node.getAttribute("data-result-content") || "")
      .map((text) => text.trim())
      .filter((text) => text.length > 0)
    if (items.length === 0) return

    const payload = items.map((text, index) => `${index + 1}. ${text}`).join("\n")
    navigator.clipboard?.writeText(payload).catch(() => {})
  }

  closeErrorModalOnBackdrop(event) {
    const panel = event.target.closest("[data-modal-panel='true']")
    if (panel) return
    this.closeErrorModal()
  }

  // 送信後にsubmitボタン無効化が残るケースを防ぐ
  restoreFormState(event) {
    const submitElements = this.element.querySelectorAll("input[type='submit'], button[type='submit']")
    console.log("[rephrase] restoreFormState:start", {
      eventType: event?.type,
      submitStates: Array.from(submitElements).map((el) => ({
        tag: el.tagName,
        disabled: el.disabled,
        value: el.value,
        text: el.textContent?.trim()
      }))
    })

    const submitter = event.detail?.formSubmission?.submitter
    if (submitter) {
      submitter.disabled = false
      submitter.removeAttribute("aria-disabled")
    }

    this.element.removeAttribute("aria-busy")
    submitElements.forEach((el) => {
      el.disabled = false
      el.removeAttribute("aria-disabled")
      const originalLabel = el.dataset.originalLabel
      if (originalLabel) {
        if (el.tagName === "INPUT") {
          el.value = originalLabel
        } else {
          el.textContent = originalLabel
        }
      }
    })

    this.refreshContentState()
    if (this.hasContentTarget) {
      const maxLength = this.maxLengthValue || 300
      if (this.contentTarget.value.length <= maxLength) this.clearErrorUi()
    }
    if (event?.type === "turbo:submit-end" && !document.getElementById("rephrase-error-modal")) {
      requestAnimationFrame(() => requestAnimationFrame(() => this.focusResultArea()))
    }

    console.log("[rephrase] restoreFormState:done", {
      eventType: event?.type,
      submitStates: Array.from(submitElements).map((el) => ({
        tag: el.tagName,
        disabled: el.disabled,
        value: el.value,
        text: el.textContent?.trim()
      }))
    })
  }
}
