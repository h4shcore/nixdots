;;; init.el --- -*- lexical-binding: t; -*-

;;; Bootstrap ---------------------------------------------------------------

(setq custom-file (locate-user-emacs-file "custom.el"))

;; Must be set before straight loads: skip scanning every repo at startup.
(setq straight-check-for-modifications '(check-on-save find-when-checking)
      straight-vc-git-default-clone-depth 1)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name
        "straight/repos/straight.el/bootstrap.el"
        (or (bound-and-true-p straight-base-dir)
            user-emacs-directory)))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)
(setq straight-use-package-by-default t
      use-package-always-defer t)

(use-package gcmh
  :demand t
  :config (gcmh-mode 1))

;;; Core --------------------------------------------------------------------

(use-package emacs
  :straight nil
  :custom
  (use-short-answers t)
  (initial-scratch-message nil)
  (ring-bell-function #'ignore)
  (display-line-numbers-type 'relative)
  (scroll-conservatively 101)
  (fast-but-imprecise-scrolling t)
  (redisplay-skip-fontification-on-input t)
  (read-process-output-max (* 1024 1024)) ; faster LSP I/O
  (bidi-inhibit-bpa t)
  (hl-line-sticky-flag nil)                  ; highlight only in the focused window
  (tab-always-indent 'complete)
  (read-extended-command-predicate #'command-completion-default-include-p)
  :init
  (setq-default indent-tabs-mode nil
                tab-width 2
                fill-column 80
                bidi-paragraph-direction 'left-to-right)

  ;; utf-8 everywhere
  (set-language-environment "UTF-8")
  (prefer-coding-system 'utf-8)
  (setq default-process-coding-system '(utf-8-unix . utf-8-unix))

  ;; silence the startup echo-area message
  (advice-add #'display-startup-echo-area-message :override #'ignore)

  ;; backups / auto-saves live in the emacs dir, not next to the files
  (let ((backups (locate-user-emacs-file "backups/"))
        (autosaves (locate-user-emacs-file "auto-save/")))
    (make-directory backups t)
    (make-directory autosaves t)
    (setq backup-directory-alist `(("." . ,backups))
          auto-save-file-name-transforms `((".*" ,autosaves t))
          backup-by-copying t
          create-lockfiles nil))

  (when (eq system-type 'darwin)
    (setq mac-command-modifier 'super
          mac-option-modifier 'meta
          mac-control-modifier 'control))

  (global-set-key (kbd "<escape>") #'keyboard-escape-quit)
  :hook
  ((prog-mode . display-line-numbers-mode)
   (prog-mode . display-fill-column-indicator-mode)
   (prog-mode . hl-line-mode)
   (text-mode . hl-line-mode)
   (after-init . global-auto-revert-mode)
   (after-init . savehist-mode)
   (after-init . save-place-mode)
   (after-init . recentf-mode)
   (after-init . winner-mode)
   (after-init . electric-pair-mode)))

;;; Appearance --------------------------------------------------------------

(set-face-attribute 'default nil :font "CaskaydiaCove NF" :height 160)

(add-to-list 'custom-theme-load-path "~/.emacs.d/")
(condition-case err
    (load-theme 'matugen t)
  (error (message "matugen theme not loaded: %s" (error-message-string err))))

(set-face-attribute 'fill-column-indicator nil :foreground "#717C7C")

;; Use the Nerd Font you already render with. Without this nerd-icons asks for
;; "Symbols Nerd Font Mono"; if that isn't installed Emacs hunts for a fallback
;; font on every glyph (slow) and the icons come out oversized.
(use-package nerd-icons
  :custom (nerd-icons-font-family "Symbols Nerd Font"))

(use-package mood-line
  :custom
  ;; Full-word evil state label, coloured from the theme's font-lock faces.
  (mood-line-segment-modal-evil-state-alist
   '((normal   . ("NORMAL"   . font-lock-variable-name-face))
     (insert   . ("INSERT"   . font-lock-string-face))
     (visual   . ("VISUAL"   . font-lock-keyword-face))
     (replace  . ("REPLACE"  . font-lock-type-face))
     (motion   . ("MOTION"   . font-lock-constant-face))
     (operator . ("OPERATOR" . font-lock-function-name-face))
     (emacs    . ("EMACS"    . font-lock-builtin-face))))
  :hook (after-init . mood-line-mode)
  :config
  (setq mood-line-glyph-alist mood-line-glyphs-unicode)

  ;; status dot, file name, line:col, percent, nyan  |  branch, diagnostics
  (setq mood-line-format
        (mood-line-defformat
         :left
         (((mood-line-segment-modal) . " ")
          ((or (mood-line-segment-buffer-status) " ") . " ")
          ((mood-line-segment-buffer-name) . "  ")
          ((mood-line-segment-cursor-position) . " ")
          ((mood-line-segment-scroll) . "  ")
          (when (bound-and-true-p nyan-mode) (nyan-create)))
         :right
         (((mood-line-segment-vc) . "  ")
          ((mood-line-segment-checker) . "  "))))

  ;; Flat, roomier bar: pad the modeline with a box in its own background.
  (dolist (face '(mode-line mode-line-inactive))
    (let ((bg (face-background face nil t)))
      (when (stringp bg)
        (set-face-attribute face nil :box (list :line-width '(8 . 6) :color bg))))))

;; The cat itself; drawn inside the mood-line format above.
(use-package nyan-mode
  :custom (nyan-bar-length 16)
  :hook (after-init . nyan-mode))

;;; Evil + leader -----------------------------------------------------------

(use-package evil
  :demand t
  :init
  (setq evil-want-keybinding nil   ; required by evil-collection
        evil-want-C-u-scroll t
        evil-undo-system 'undo-redo)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :demand t
  :config
  (evil-collection-init))

(use-package which-key
  :custom (which-key-idle-delay 0.5)
  :hook (after-init . which-key-mode))

(use-package general
  :demand t
  :config
  (general-evil-setup)

  (general-create-definer leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  ;; Single place for the leader groups; packages add their own keys below.
  (leader-keys
    "x" '(execute-extended-command :which-key "execute command")
    "r" '(restart-emacs :which-key "restart emacs")
    "i" '((lambda () (interactive) (find-file user-init-file))
          :which-key "open init file")
    "b" '(:ignore t :which-key "buffer")
    "bd" '(kill-current-buffer :which-key "kill buffer")
    "w" '(:ignore t :which-key "window")
    "wv" '(split-window-right :which-key "split right")
    "ws" '(split-window-below :which-key "split below")
    "wd" '(delete-window :which-key "close window")
    "wo" '(delete-other-windows :which-key "only this window")
    "wh" '(evil-window-left :which-key "focus left")
    "wj" '(evil-window-down :which-key "focus down")
    "wk" '(evil-window-up :which-key "focus up")
    "wl" '(evil-window-right :which-key "focus right")
    "w=" '(balance-windows :which-key "balance")
    "wu" '(winner-undo :which-key "undo layout")
    "wr" '(winner-redo :which-key "redo layout")
    "d" '(:ignore t :which-key "diagnostics")
    "D" '(:ignore t :which-key "debug")
    "f" '(:ignore t :which-key "find")
    "t" '(:ignore t :which-key "tree")
    "p" '(:ignore t :which-key "projects")
    "g" '(:ignore t :which-key "git")
    "e" '(:ignore t :which-key "envrc")
    "l" '(:ignore t :which-key "lsp")
    "m" '(:ignore t :which-key "mode")
    "c" '(:ignore t :which-key "compile"))

  ;; Avoid "SPC <group> ESC is undefined" errors; just abort.
  (dolist (group '("b" "w" "d" "D" "f" "t" "p" "g" "e" "l" "m" "c"))
    (leader-keys (concat group " <escape>") '(keyboard-escape-quit :which-key t))))

(use-package evil-nerd-commenter
  :general
  (general-nvmap
    "gc" #'evilnc-comment-operator))

;;; Navigation / projects ---------------------------------------------------

(use-package vertico
  :custom (vertico-cycle t)
  :hook (after-init . vertico-mode))

;; Backspace deletes a whole path component in find-file.
(use-package vertico-directory
  :straight nil
  :after vertico
  :bind (:map vertico-map ("DEL" . vertico-directory-delete-char))
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :hook (after-init . marginalia-mode))

(use-package consult
  :custom
  ;; search/preview relative to the projectile root
  (consult-project-function (lambda (_may-prompt) (projectile-project-root)))
  :general
  (leader-keys
    "b b" '(consult-buffer :which-key "switch buffer")
    "f f" '(find-file :which-key "file")
    "f g" '(consult-ripgrep :which-key "grep")
    "f l" '(consult-line :which-key "line")
    "f i" '(consult-imenu :which-key "symbols")
    "f r" '(consult-recent-file :which-key "recent")))

(use-package embark
  :bind (("C-." . embark-act)
         ("C-;" . embark-dwim))
  :init
  ;; C-h after a prefix key shows a searchable list of its bindings.
  (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package projectile
  :custom (projectile-completion-system 'default)
  :hook (after-init . projectile-mode)
  :general
  (leader-keys
    "SPC" '(projectile-find-file :which-key "find file")
    "p p" '(projectile-switch-project :which-key "switch project")
    "p a" '(projectile-add-known-project :which-key "add project")
    "p r" '(projectile-remove-known-project :which-key "remove project")))

;;; File tree ---------------------------------------------------------------

(use-package treemacs
  :custom
  (treemacs-width 30)
  (treemacs-indentation 2)
  :config
  (treemacs-follow-mode 1)            ; keep the tree on the current file
  (treemacs-filewatch-mode 1)         ; auto-refresh on disk changes
  (treemacs-git-mode 'simple)         ; file-level git colours, no python/subprocess
  (treemacs-fringe-indicator-mode 'only-when-focused)
  ;; Roomy rows like the reference screenshot; raise/lower to taste.
  (add-hook 'treemacs-mode-hook (lambda () (setq-local line-spacing 6)))
  :general
  (leader-keys
    "t t" '(treemacs :which-key "toggle tree")
    "t s" '(treemacs-select-window :which-key "focus tree")
    "t f" '(treemacs-find-file :which-key "reveal current file")
    "t p" '(treemacs-add-and-display-current-project-exclusively
            :which-key "show only this project")))

(use-package treemacs-projectile
  :after (treemacs projectile))

(use-package treemacs-magit
  :after (treemacs magit))

;; Nerd Font folder/file icons (same family as the screenshot).
(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

;;; Git ---------------------------------------------------------------------

(use-package magit
  :general
  (leader-keys
    "g g" '(magit-status :which-key "status")
    "g l" '(magit-log :which-key "log"))
  :config
  ;; ESC closes a transient popup instead of needing C-g.
  (with-eval-after-load 'transient
    (define-key transient-map (kbd "<escape>") #'transient-quit-one)))

(use-package diff-hl
  :hook ((after-init . global-diff-hl-mode)
         (magit-pre-refresh . diff-hl-magit-pre-refresh)
         (magit-post-refresh . diff-hl-magit-post-refresh)))

;;; Terminal / environment --------------------------------------------------

(use-package vterm
  :custom (vterm-shell (or (executable-find "fish") shell-file-name)))

(use-package vterm-toggle
  :general
  (leader-keys
    "'" '(vterm-toggle :which-key "terminal")))

(use-package exec-path-from-shell
  :if (or (daemonp) (memq window-system '(mac ns x pgtk)))
  :demand t
  :config
  (exec-path-from-shell-initialize))

;; direnv / nix flake per-project envs
(use-package envrc
  :hook (after-init . envrc-global-mode)
  :general
  (leader-keys
    "e r" '(envrc-reload :which-key "reload")
    "e a" '(envrc-allow :which-key "allow")
    "e d" '(envrc-deny :which-key "deny")))

;;; Completion / LSP --------------------------------------------------------

(use-package corfu
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  (corfu-cycle t)
  :hook (after-init . global-corfu-mode)
  :config
  (corfu-popupinfo-mode 1))

;; Extra completion sources used as fallbacks after eglot / the major mode.
(use-package cape
  :init
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-dabbrev))

(use-package eglot
  :straight nil
  :custom (eglot-autoshutdown t)
  :hook ((c-mode c++-mode zig-mode rust-mode go-mode typescript-mode nix-mode)
         . eglot-ensure)
  :general
  (leader-keys
    "l r" '(eglot-rename :which-key "rename")
    "l a" '(eglot-code-actions :which-key "code actions")
    "l F" '(eglot-format-buffer :which-key "format (LSP)")))

(use-package flymake
  :straight nil
  :general
  (leader-keys
    "d n" '(flymake-goto-next-error :which-key "next error")
    "d p" '(flymake-goto-prev-error :which-key "previous error")
    "d l" '(consult-flymake :which-key "search diagnostics")
    "d b" '(flymake-show-buffer-diagnostics :which-key "buffer list")
    "d P" '(flymake-show-project-diagnostics :which-key "project list"))
  (general-nmap
    "]d" #'flymake-goto-next-error
    "[d" #'flymake-goto-prev-error))

;; Manual formatting only: nothing runs on save. SPC l f formats the buffer
;; with the external formatter for the mode (clang-format, rustfmt, gofmt...).
(use-package apheleia
  :general
  (leader-keys
    "l f" '(apheleia-format-buffer :which-key "format buffer")))

;; Debugger (DAP) client; works with gdb / lldb-dap / delve / codelldb.
(use-package dape
  :general
  (leader-keys
    "D d" '(dape :which-key "start debugger")
    "D b" '(dape-breakpoint-toggle :which-key "breakpoint")
    "D c" '(dape-continue :which-key "continue")
    "D n" '(dape-next :which-key "step over")
    "D i" '(dape-step-in :which-key "step in")
    "D o" '(dape-step-out :which-key "step out")
    "D r" '(dape-restart :which-key "restart")
    "D q" '(dape-quit :which-key "quit")))

;;; Languages ---------------------------------------------------------------

(use-package markdown-mode
  :custom (markdown-fontify-code-blocks-natively t))

(use-package zig-mode)
(use-package rust-mode)
(use-package go-mode)
(use-package gotest)
(use-package typescript-mode)
(use-package fish-mode)
(use-package nix-mode
  :mode "\\.nix\\'")

;; One "SPC m ..." menu that dispatches on the current major mode, so the
;; zig / rust / go bindings no longer overwrite each other.
(defconst ab/mode-actions
  '(((zig-mode)
     (build . zig-compile) (run . zig-run) (test . zig-test))
    ((rust-mode)
     (build . rust-compile) (run . rust-run) (test . rust-test)
     (check . rust-check) (clippy . rust-run-clippy))
    ((go-mode)
     (run . go-run) (test . go-test-current-project)))
  "Per-mode commands for the \"SPC m\" menu: ((MODES (ACTION . COMMAND)...)...).")

(defun ab/mode-action (action)
  "Run ACTION for the current major mode, if it defines one."
  (let* ((entry (seq-find (lambda (e) (apply #'derived-mode-p (car e)))
                          ab/mode-actions))
         (command (cdr (assq action (cdr entry)))))
    (if command
        (call-interactively command)
      (user-error "No %s action for %s" action major-mode))))

(defun ab/build () "Build for the current mode." (interactive) (ab/mode-action 'build))
(defun ab/run () "Run for the current mode." (interactive) (ab/mode-action 'run))
(defun ab/test () "Test for the current mode." (interactive) (ab/mode-action 'test))
(defun ab/check () "Check for the current mode." (interactive) (ab/mode-action 'check))
(defun ab/clippy () "Clippy for the current mode." (interactive) (ab/mode-action 'clippy))

(leader-keys
  "m b" '(ab/build :which-key "build")
  "m r" '(ab/run :which-key "run")
  "m t" '(ab/test :which-key "test")
  "m k" '(ab/check :which-key "check")
  "m c" '(ab/clippy :which-key "clippy"))

;;; Quality of life ---------------------------------------------------------

(use-package vundo
  :custom (vundo-glyph-alist vundo-unicode-symbols)
  :general
  (leader-keys
    "u" '(vundo :which-key "undo tree")))

(use-package hl-todo
  :hook (prog-mode . hl-todo-mode))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package helpful
  :bind (([remap describe-function] . helpful-callable)
         ([remap describe-variable] . helpful-variable)
         ([remap describe-command] . helpful-command)
         ([remap describe-key] . helpful-key)))

(use-package editorconfig
  :hook (after-init . editorconfig-mode))

;;; Compile -----------------------------------------------------------------

(use-package compile
  :straight nil
  :custom
  (compilation-scroll-output t)
  (compilation-ask-about-save nil)
  :hook (compilation-filter . ansi-color-compilation-filter)
  :general
  (leader-keys
    "c c" '(compile :which-key "compile")
    "c r" '(recompile :which-key "recompile")))

;;; Custom ------------------------------------------------------------------

(load custom-file 'noerror 'nomessage)

;;; init.el ends here
