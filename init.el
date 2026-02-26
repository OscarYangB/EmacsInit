; Visuals ;------------------------------------------------------------------------------------  -*- lexical-binding: t; -*-
(toggle-frame-fullscreen)
(tool-bar-mode -1)
(menu-bar-mode -1)
(setq-default truncate-lines t)
(setq blink-cursor-interval 0.3)

(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(load-theme 'zenburn t)
(set-frame-font "commitmonov143 12" nil t)

; Miscellaneous ; -----------------------------------------------------------------------------
(setq-default tab-width 4)
(setq-default indent-tabs-mode t)

(setq ring-bell-function 'ignore)
(setq auto-save-default nil)
(setq make-backup-files nil)

(setq confirm-kill-processes nil)

(add-hook 'before-save-hook #'delete-trailing-whitespace)

(global-auto-revert-mode)

(setq package-native-compile t)

; Keybinds ;------------------------------------------------------------------------------------
(global-unset-key (kbd "RET"))
(global-set-key (kbd "RET") 'reindent-then-newline-and-indent)

(global-unset-key (kbd "C-<tab>"))
(global-set-key (kbd "C-<tab>") 'other-window)

(global-unset-key (kbd "C-S-<tab>"))
(global-set-key (kbd "C-S-<tab>") 'other-window-backward)

(global-unset-key (kbd "C-y"))
(global-set-key (kbd "C-y") 'comment-dwim)

(define-key key-translation-map (kbd "C-q") (kbd "C-g"))
(define-key key-translation-map (kbd "C-g") (kbd "C-q"))

(global-unset-key (kbd "C-o"))
(global-set-key (kbd "C-o") 'project-find-file)

(global-unset-key (kbd "C-w"))
(global-set-key (kbd "C-w") 'delete-window)

(global-unset-key (kbd "C-p"))
(global-set-key (kbd "C-p") 'project-shell)

(global-unset-key (kbd "C-u"))
(global-set-key (kbd "C-u") 'bookmark-set)

(global-unset-key (kbd "C-M-u"))
(global-set-key (kbd "C-M-u") 'list-bookmarks)

(global-unset-key (kbd "C-f"))
(global-set-key (kbd "C-f") 'isearch-forward)
(define-key isearch-mode-map (kbd "C-f") 'isearch-repeat-forward)

(global-unset-key (kbd "C-S-f"))
(global-set-key (kbd "C-S-f") 'isearch-backward)
(define-key isearch-mode-map (kbd "C-S-f") 'isearch-repeat-backward)

(global-unset-key (kbd "C-\\"))

(defun indent-lines(&optional N)
  (interactive)
  (if (region-active-p)
      (indent-rigidly (region-beginning) (region-end) 4)
    (indent-rigidly (line-beginning-position)
					(line-end-position)
					(* (or N 1) 4))))

(defun unindent-lines(&optional N)
  (interactive)
  (if (region-active-p)
      (indent-rigidly (region-beginning) (region-end) -4)
    (indent-rigidly (line-beginning-position)
					(line-end-position)
					(* (or N -1) 4))))

(global-unset-key (kbd "<tab>"))
(global-set-key (kbd "<tab>") 'indent-lines)

(global-unset-key (kbd "S-<tab>"))
(global-set-key (kbd "S-<tab>") 'unindent-lines)

; Modern Keybinds ; ------------------------------------------------------------------------------------
; Copyright (C) 2024  Arthur Miller
(require 'bind-key)

(defgroup cua-mini nil
  "Enable CUA-style key bindings"
  :prefix "cua-mini-"
  :group 'convenience
  :group 'emulations
  :group 'editing-basics)

(defcustom cua-mini-default-mode 'inherit
  "Default major mode to use when creating a new buffer.

It should either be a cons, (mode-name . file-extension), or a special
value \='inherit which means to create a new buffer in the same major mode and
with the same file extension (if any) as the current buffer."
  :type 'symbol
  :group 'cua-mini)

(defun mark-whole-line ()
    "Combinition of C-a, mark, C-e"
    (interactive)
    (move-beginning-of-line nil)
    (set-mark-command nil)
    (move-end-of-line nil)
)

(defun cua-mini-copy ()
  "Copy selection to clipboard."
  (interactive)
  (if (region-active-p)
      (call-interactively #'kill-ring-save)
    (mark-whole-line)
    (call-interactively #'kill-ring-save)))

(defun cua-mini-cut ()
  "Delete a selection and copy its content to clipboard."
  (interactive)
  (if (region-active-p)
      (call-interactively #'kill-region)
    (mark-whole-line)
    (call-interactively #'kill-region)))

(defun cua-mini-new ()
  "Create a new file in memory."
  (interactive)
  (let ((name "New File")
        mode extension buffer)
    (if (eq cua-mini-default-mode 'inherit)
        (setf mode major-mode
              extension (file-name-extension (buffer-name (current-buffer))))
      (setf mode (car cua-mini-default-mode)
            extension (cdr cua-mini-default-mode)))
    (when extension
      (setf name (format "%s.%s"
                         name
                         (substring extension
                                    0 (string-match-p "<[0-9]+>" extension)))))
    (setf buffer (get-buffer-create (generate-new-buffer-name name)))
    (with-current-buffer buffer (call-interactively mode))
    (pop-to-buffer-same-window buffer)))

(defvar-local c-c-map (make-sparse-keymap))

(defvar-keymap cua-mini-mode-map
  :doc "Keymap for CUA-style key bindings"
  "C-<SPC>" ctl-x-map
  "C-`" #'cua-mini-copy ; Going to be C-c once we do a translation map
  "C-S-<SPC>" global-map
  "C-n" #'cua-mini-new
  "C-s" #'save-buffer
  "C-x" #'cua-mini-cut
  "C-z" #'undo
  "C-S-z" #'undo-redo
  "C-v" #'yank
  "C-d" #'move-end-of-line)

(define-key key-translation-map [?\C-c] [?\C-`])
(define-key key-translation-map [?\C-`] [?\C-c])

(defun cua-mini-on ()
  (override-global-mode +1))

(defun cua-mini-off ()
  (override-global-mode -1))

(define-minor-mode cua-mini-mode
  "Enable CUA-style key bindings"
  :lighter " xcv" :global t
  (let ((override-global-map cua-mini-mode-map))
    (if cua-mini-mode
        (cua-mini-on)
      (cua-mini-off))))

(define-globalized-minor-mode global-cua-mini-mode cua-mini-mode
  (lambda () (cua-mini-mode +1)))

(provide 'cua-mini)

(cua-mini-mode)

; Packages ;------------------------------------------------------------------------------
(require 'package)
(add-to-list 'package-archives
    '("MELPA" .
      "http://melpa.org/packages/"))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-show-quick-access t nil nil "Customized with use-package company")
 '(package-selected-packages
   '(ag avy company dap-mode flycheck helm-xref hydra lsp-mode
		lsp-pyright magit projectile rustic smartparens treemacs
		which-key winpulse yasnippet))
 '(package-vc-selected-packages '((winpulse :url "https://github.com/xenodium/winpulse"))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(with-eval-after-load 'treemacs
  (setq treemacs-collapse-dirs 0)
  (define-key treemacs-mode-map (kbd "<left>") #'treemacs-COLLAPSE-action)
  (treemacs-git-mode -1))

(helm-mode)
(require 'helm-xref)
(define-key global-map [remap find-file] #'helm-find-files)
(define-key global-map [remap execute-extended-command] #'helm-M-x)
(define-key global-map [remap switch-to-buffer] #'helm-mini)

(which-key-mode)
(add-hook 'c-mode-hook 'lsp)
(add-hook 'c++-mode-hook 'lsp)

(defun my-c++-mode-hook ()
  (setq c-basic-offset 4)
  (c-set-offset 'substatement-open 0))
(add-hook 'c++-mode-hook 'my-c++-mode-hook)

(setq c-basic-offset 4)

(setq gc-cons-threshold (* 100 1024 1024)
      read-process-output-max (* 1024 1024)
      treemacs-space-between-root-nodes nil
      company-idle-delay 0.0
	  company-tooltip-idle-delay 0.0
      company-minimum-prefix-length 1
      lsp-idle-delay 0.01)

(with-eval-after-load 'lsp-mode
  (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)
  (require 'dap-cpptools)
  (yas-global-mode))

(setq lsp-semantic-tokens-enable t)
  (setq lsp-clients-clangd-args '("-j=8"
                                "--background-index"
                                "--clang-tidy"
								"--enable-config"
								"--experimental-modules-support"
								"--header-insertion=never"))

(require 'flycheck)
(set-face-attribute 'flycheck-error nil :underline '(:color "red" :style wave))

(use-package lsp-pyright
  :ensure t
  :custom (lsp-pyright-langserver-command "basedpyright")
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp)
						  (setq python-indent 4))))  ; or lsp-deferred

(with-eval-after-load 'company
  (define-key company-active-map (kbd "<tab>") #'company-select-next-or-abort)
  (define-key company-active-map (kbd "S-<tab>") #'company-select-previous-or-abort)
  (define-key company-active-map (kbd "<up>") nil)
  (define-key company-active-map (kbd "<down>") nil)
  (define-key company-active-map (kbd "C-s") nil))

(with-eval-after-load 'yasnippet
  (define-key yas-keymap (kbd "<right>") 'yas-next-field)
  (define-key yas-keymap (kbd "<left>") 'yas-prev-field))

(with-eval-after-load 'magit
  (setq magit-git-executable "C:/Program Files/Git/bin/git.exe")
  (define-key magit-mode-map (kbd "<C-tab>") nil)
  (define-key magit-mode-map (kbd "<tab>") #'magit-section-cycle)
  (remove-hook 'magit-status-sections-hook 'magit-insert-status-headers)
  (remove-hook 'magit-status-sections-hook 'magit-insert-stashes)
  (remove-hook 'magit-status-sections-hook 'magit-insert-unpulled-from-upstream)
  (remove-hook 'magit-status-sections-hook 'magit-insert-unpushed-to-upstream-or-recent)
  (remove-hook 'magit-status-sections-hook 'magit-insert-unpulled-from-pushremote)
  (remove-hook 'magit-status-sections-hook 'magit-insert-merge-log)
  (remove-hook 'magit-status-sections-hook 'magit-insert-am-sequence)
  (remove-hook 'magit-status-sections-hook 'magit-insert-sequencer-sequence)
  (remove-hook 'magit-status-sections-hook 'magit-insert-bisect-output)
  (remove-hook 'magit-status-sections-hook 'magit-insert-bisect-rest)
  (remove-hook 'magit-status-sections-hook 'magit-insert-bisect-log)
  (remove-hook 'magit-status-sections-hook 'magit-insert-unpushed-to-pushremote)
  (remove-hook 'magit-status-sections-hook 'magit-insert-rebase-sequence))

; Package Input ; --------------------------------------------------------------------------------------
(global-unset-key (kbd "C-t"))
(define-key key-translation-map (kbd "C-t") 'treemacs)

(global-unset-key (kbd "C-e"))
(global-set-key (kbd "C-e") `helm-mini)

(global-unset-key (kbd "C-r"))
(global-set-key (kbd "C-r") 'lsp-find-references)

(global-unset-key (kbd "C-S-r"))
(global-set-key (kbd "C-S-r") 'lsp-rename)

(global-unset-key (kbd "C-q")) ; C-q refers to C-g after the keyswap earlier
(global-set-key (kbd "C-q") 'lsp-find-definition)

(global-unset-key (kbd "C-M-f"))
(global-set-key (kbd "C-M-f") 'projectile-ag)

(global-unset-key (kbd "C-j"))
(global-set-key (kbd "C-j") 'xref-go-back)

(global-unset-key (kbd "C-l"))
(global-set-key (kbd "C-l") 'xref-go-forward)

(global-unset-key (kbd "C-k"))
(global-set-key (kbd "C-k") 'lsp-clangd-find-other-file)

(global-unset-key (kbd "C-b"))
(global-set-key (kbd "C-b") 'dap-breakpoint-toggle)

(global-unset-key (kbd "C-S-b"))
(global-set-key (kbd "C-S-b") 'dap-breakpoint-delete-all)

(global-unset-key (kbd "M-b"))
(global-set-key (kbd "M-b") 'dap-debug)

(global-unset-key (kbd "C-1"))
(global-set-key (kbd "C-1") 'dap-step-in)

(global-unset-key (kbd "C-2"))
(global-set-key (kbd "C-2") 'dap-next)

(global-unset-key (kbd "C-3"))
(global-set-key (kbd "C-3") 'dap-step-out)

(global-unset-key (kbd "C-4"))
(global-set-key (kbd "C-4") 'dap-continue)

(define-key input-decode-map [?\C-i] [C-i])
(global-unset-key (kbd "<C-i>"))
(global-set-key (kbd "<C-i>") 'dap-ui-expressions-add)

(define-key input-decode-map [?\C-\S-i] [C-S-i])
(global-unset-key (kbd "<C-S-i>"))
(global-set-key (kbd "<C-S-i>") 'dap-ui-expressions-remove)


(define-key input-decode-map [?\C-m] [C-m])
(global-unset-key (kbd "<C-m>"))
(global-set-key (kbd "<C-m>") 'magit)

(global-unset-key (kbd "C-/"))
(global-set-key (kbd "C-/") 'lsp-describe-thing-at-point)

(with-eval-after-load 'dap-mode
  (add-hook 'dap-session-created-hook
    (lambda (a)
	  (global-set-key (kbd "M-b") 'dap-delete-session)))
  (add-hook 'dap-terminated-hook
    (lambda (a)
	  (global-set-key (kbd "M-b") 'dap-debug)))
  (setq dap-auto-show-output nil))

(use-package pixel-scroll
  :custom
  (pixel-scroll-precision-interpolation-factor 1.0)
  :bind
  (([remap scroll-up-command]   . pixel-scroll-up-command)
   ([remap scroll-down-command] . pixel-scroll-down-command))
  :hook
  (dashboard-after-initialize . pixel-scroll-precision-mode)
  :config
  (defun pixel-scroll-up-command ()
    "Similar to `scroll-up-command' but with pixel scrolling."
    (interactive)
	(move-to-window-line -2)
    (pixel-scroll-precision-interpolate (- (* 20 (line-pixel-height)))))
  (defun pixel-scroll-down-command ()
    "Similar to `scroll-down-command' but with pixel scrolling."
    (interactive)
	(move-to-window-line 1)
    (pixel-scroll-precision-interpolate (* 20 (line-pixel-height)))))

(global-set-key (kbd "M-<down>") 'pixel-scroll-up-command)
(global-set-key (kbd "M-<up>") 'pixel-scroll-down-command)

(require 'smartparens)
(smartparens-global-mode)
(defun indent-between-pair (&rest _ignored)
  (newline)
  (indent-according-to-mode)
  (forward-line -1)
  (indent-according-to-mode))

(sp-local-pair 'prog-mode "{" nil :post-handlers '((indent-between-pair "RET")))
(sp-local-pair 'prog-mode "[" nil :post-handlers '((indent-between-pair "RET")))
(sp-local-pair 'prog-mode "(" nil :post-handlers '((indent-between-pair "RET")))

(setq completion-ignore-case t)

(defun backward-delete-word (arg)
  "Delete characters backward until encountering the beginning of a word.
With argument ARG, do this that many times."
 (interactive "p")
 (delete-region (point) (progn (backward-word arg) (point))))

(global-set-key (kbd "C-<backspace>") 'backward-delete-word)

; Custom Dialogue Mode ; --------------------------------------------------------------------------------------
(defvar my-highlights nil "first element for `font-lock-defaults'")

(setq my-highlights
      '(("\\(goto:.*\\)" . (1 'font-lock-keyword-face))
		("\\(#.*\\)" . (1 'font-lock-comment-face))
		("\\(var:.*\\)" . (1 'font-lock-keyword-face))
		("\\(end\\)" . (1 'font-lock-keyword-face))
		("\\([^\s^\n^]*:\\)" . (1 'font-lock-variable-name-face))
		("\\(\\[.*\\]\\)" . (1 'font-lock-function-name-face))))

(defun my-nesting-indent-line-function ()
  "Indent according to nesting of balanced pairs in the current mode."
  (interactive)
  (save-excursion
    (back-to-indentation)
    (while (eq ?\) (char-syntax (following-char)))
      (forward-char))
    (indent-line-to
     (* standard-indent (syntax-ppss-depth (syntax-ppss (point))))))
  (back-to-indentation))

(define-derived-mode dlg-mode fundamental-mode "dlg-mode"
  "major mode for editing dialogue."
  (setq font-lock-defaults '(my-highlights))
  (set (make-local-variable 'indent-line-function) #'my-nesting-indent-line-function))

(add-to-list 'auto-mode-alist '("\\.dlg\\'" . dlg-mode))

(use-package winpulse
  :vc (:url "https://github.com/xenodium/winpulse"
       :rev :newest)
  :config
  (winpulse-mode +1))
