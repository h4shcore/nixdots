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
   (after-init . global-auto-revert-mode)
   (after-init . savehist-mode)
   (after-init . save-place-mode)))

;;; Appearance --------------------------------------------------------------

(set-face-attribute 'default nil :font "MapleMono NF" :height 160)

(add-to-list 'custom-theme-load-path "~/.emacs.d/")
(condition-case err
    (load-theme 'matugen t)
  (error (message "matugen theme not loaded: %s" (error-message-string err))))

(set-face-attribute 'fill-column-indicator nil :foreground "#717C7C")

(use-package nerd-icons)

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode))

(use-package nyan-mode
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
    "p" '(:ignore t :which-key "projects")
    "g" '(:ignore t :which-key "git")
    "e" '(:ignore t :which-key "envrc")
    "l" '(:ignore t :which-key "lsp")
    "m" '(:ignore t :which-key "mode")
    "c" '(:ignore t :which-key "compile"))

  ;; Avoid "SPC <group> ESC is undefined" errors; just abort.
  (dolist (group '("b" "p" "g" "e" "l" "m" "c"))
    (leader-keys (concat group " <escape>") '(keyboard-escape-quit :which-key t))))

(use-package evil-nerd-commenter
  :general
  (general-nvmap
    "gc" #'evilnc-comment-operator))

;;; Navigation / projects ---------------------------------------------------

(use-package ivy
  :hook (after-init . ivy-mode))

(use-package projectile
  :hook (after-init . projectile-mode)
  :general
  (leader-keys
    "SPC" '(projectile-find-file :which-key "find file")
    "b b" '(projectile-switch-to-buffer :which-key "switch buffer")
    "p p" '(projectile-switch-project :which-key "switch project")
    "p a" '(projectile-add-known-project :which-key "add project")
    "p r" '(projectile-remove-known-project :which-key "remove project")))

(use-package rg
  :general
  (leader-keys
    "f" '(rg-menu :which-key "find")))

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

;;; Completion / LSP / tree-sitter -----------------------------------------

(use-package company
  :custom
  (company-idle-delay 0.2)
  (company-minimum-prefix-length 2)
  :hook (after-init . global-company-mode))

(use-package eglot
  :straight nil
  :custom (eglot-autoshutdown t)
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode
          zig-mode zig-ts-mode
          rust-mode rust-ts-mode
          go-mode go-ts-mode
          typescript-mode typescript-ts-mode tsx-ts-mode
          nix-mode nix-ts-mode)
         . eglot-ensure)
  :general
  (leader-keys
    "l r" '(eglot-rename :which-key "rename")
    "l a" '(eglot-code-actions :which-key "code actions")))

(use-package treesit-auto
  :demand t
  :custom (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

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
  '(((zig-mode zig-ts-mode)
     (build . zig-compile) (run . zig-run) (test . zig-test))
    ((rust-mode rust-ts-mode)
     (build . rust-compile) (run . rust-run) (test . rust-test)
     (check . rust-check) (clippy . rust-run-clippy))
    ((go-mode go-ts-mode)
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
