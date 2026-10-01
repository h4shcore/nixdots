;;; init.el --- -*- lexical-binding: t; -*-; 

;; ui
(tool-bar-mode -1)            
(scroll-bar-mode -1)
(setq inhibit-splash-screen t)
(setq use-file-dialog nil)

;; straight.el
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

;; use-package
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)
(setq use-package-always-defer t)

;; disable startup echo
(use-package emacs
  :init
  (setq initial-scratch-message nil)
  (defun display-startup-echo-area-message ()
    (message "")))

;; adding alias
(use-package emacs
  :init
  (defalias 'yes-or-no-p 'y-or-n-p))

;; utf-8
(use-package emacs
  :init
  (set-charset-priority 'unicode)
  (setq locale-coding-system 'utf-8
        coding-system-for-read 'utf-8
        coding-system-for-write 'utf-8)
  (set-terminal-coding-system 'utf-8)
  (set-keyboard-coding-system 'utf-8)
  (set-selection-coding-system 'utf-8)
  (prefer-coding-system 'utf-8)
  (setq default-process-coding-system '(utf-8-unix . utf-8-unix)))

;; tabs width
(use-package emacs
  :init
  (setq-default indent-tabs-mode nil)
  (setq-default tab-width 2))

;; keybinds for osx and unix
(use-package emacs
  :init
  (cond
   ((eq system-type 'darwin)
    (setq mac-command-modifier 'super)
    (setq mac-option-modifier 'meta)
    (setq mac-control-modifier 'control))
   ((eq system-type 'gnu/linux)
    (setq x-command-modifier 'super)  ; Maps Windows/Super key to Super
    (setq x-alt-modifier 'meta)       ; Maps Alt key to Meta
    (setq x-ctrl-modifier 'control)))) ; Keeps Control as Control

;; evil-mode
(setq evil-want-keybinding nil) ; must be set before evil/evil-collection load
(use-package evil
  :demand ; No lazy loading
  :init
  (setq evil-want-C-u-scroll t) ; must be set before evil-mode runs
  :config
  (evil-mode 1))

;; fonts
(use-package emacs
  :init
  (set-face-attribute 'default nil
    :font "GeistMono Nerd Font"
    :height 160))

;; themes
(add-to-list 'custom-theme-load-path "~/.emacs.d/")
(load-theme 'matugen t)

;; number lines
(use-package emacs
  :init
  (defun ab/enable-line-numbers ()
    "Enable relative line numbers"
    (interactive)
    (display-line-numbers-mode)
    (setq display-line-numbers 'relative))
  (add-hook 'prog-mode-hook #'ab/enable-line-numbers))

;; doom modeline
(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; nerd-icons
(use-package nerd-icons)

;; cat
(use-package nyan-mode
  :init
  (nyan-mode))

;; project-manager (projectile)
(use-package projectile
  :demand
  :init
  (projectile-mode +1))

;; which-key
(use-package which-key
  :demand
  :init
  (setq which-key-idle-delay 0.5) ; Open after .5s instead of 1s
  :config
  (which-key-mode))

;; evil-keybinds
(use-package general
  :demand
  :config
  (general-evil-setup)

  (general-create-definer leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  (leader-keys
    "x" '(execute-extended-command :which-key "execute command")
    "r" '(restart-emacs :which-key "restart emacs")
    "i" '((lambda () (interactive) (find-file user-init-file)) :which-key "open init file")

    ;; Buffer
    "b" '(:ignore t :which-key "buffer")
    ;; Don't show an error because SPC b ESC is undefined, just abort
    "b <escape>" '(keyboard-escape-quit :which-key t)
    "bd"  'kill-current-buffer
  ))

;; projectile keybind
(use-package projectile
  :demand
  :general
  (leader-keys
    :states 'normal
    "SPC" '(projectile-find-file :which-key "find file")

    ;; Buffers
    "b b" '(projectile-switch-to-buffer :which-key "switch buffer")

    ;; Projects
    "p" '(:ignore t :which-key "projects")
    "p <escape>" '(keyboard-escape-quit :which-key t)
    "p p" '(projectile-switch-project :which-key "switch project")
    "p a" '(projectile-add-known-project :which-key "add project")
    "p r" '(projectile-remove-known-project :which-key "remove project"))
  :init
  (projectile-mode +1))

;; fuzzy finder
(use-package ivy
  :config
  (ivy-mode))

;; git
(use-package magit
  :general
  (leader-keys
    "g" '(:ignore t :which-key "git")
    "g <escape>" '(keyboard-escape-quit :which-key t)
    "g g" '(magit-status :which-key "status")
    "g l" '(magit-log :which-key "log"))
  (general-nmap
    "<escape>" #'transient-quit-one))

;; evil-collection
(use-package evil-collection
  :after evil
  :demand
  :config
  (evil-collection-init))

;; highlight uncommited gutter
(use-package diff-hl
  :init
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  :config
  (global-diff-hl-mode))
  
;; terminal
(use-package vterm-toggle
  :general
  (leader-keys
    "'" '(vterm-toggle :which-key "terminal")))
(setq vterm-shell (executable-find "fish"))

;; comments
(use-package evil-nerd-commenter
  :general
  (general-nvmap
    "gc" 'evilnc-comment-operator))

;; optimize gc
(use-package gcmh
  :demand
  :config
  (gcmh-mode 1))

;; dont use 'ESC' as the modifier
(use-package emacs
  :init
	(global-set-key (kbd "<escape>") 'keyboard-escape-quit))

;; exec-path-from-shell
(use-package exec-path-from-shell
  :init
  (exec-path-from-shell-initialize))

;; envrc (direnv / nix flake per-project envs)
(use-package envrc
  :demand
  :hook (after-init . envrc-global-mode)
  :general
  (leader-keys
    "e" '(:ignore t :which-key "envrc")
    "e <escape>" '(keyboard-escape-quit :which-key t)
    "e r" '(envrc-reload :which-key "reload")
    "e a" '(envrc-allow :which-key "allow")
    "e d" '(envrc-deny :which-key "deny")))

;; ruler for 80 chars
(use-package emacs
  :init
  (setq-default fill-column 80)
  (set-face-attribute 'fill-column-indicator nil
                      :foreground "#717C7C" ; katana-gray
                      :background "transparent")
  (global-display-fill-column-indicator-mode 1))

;; backup files
(use-package emacs
  :config
  (setq backup-directory-alist `(("." . "~/.saves"))))

;; lsp
(use-package company
  :init
  (global-company-mode))

;; eglot
(use-package emacs
  :hook (zig-mode . eglot-ensure)
  :hook (rust-mode . eglot-ensure)
  :hook (go-mode . eglot-ensure)
  :hook (typescript-mode . eglot-ensure)
  :general
  (leader-keys
    "l" '(:ignore t :which-key "lsp")
    "l <escape>" '(keyboard-escape-quit :which-key t)
    "l r" '(eglot-rename :which-key "rename")
    "l a" '(eglot-code-actions :which-key "code actions")))

;; treesitter
(use-package treesit-auto
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))
  
;; language support
(use-package markdown-mode
  :config
  (setq markdown-fontify-code-blocks-natively t))
(use-package zig-mode
  :general
  (leader-keys
    "m" '(:ignore t :which-key "mode")
    "m <escape>" '(keyboard-escape-quit :which-key t)
    "m b" '(zig-compile :which-key "build")
    "m r" '(zig-run :which-key "run")
    "m t" '(zig-test :which-key "test")))
(use-package rust-mode
  :general
  (leader-keys
    "m" '(:ignore t :which-key "mode")
    "m <escape>" '(keyboard-escape-quit :which-key t)
    "m b" '(rust-compile :which-key "build")
    "m r" '(rust-run :which-key "run")
    "m t" '(rust-test :which-key "test")
    "m k" '(rust-check :which-key "check")
    "m c" '(rust-run-clippy :which-key "clippy")))
(use-package go-mode)
(use-package gotest
  :general
  (leader-keys
    "m" '(:ignore t :which-key "mode")
    "m <escape>" '(keyboard-escape-quit :which-key t)
    "m t" '(go-test-current-project :which-key "test")
    "m r" '(go-run :which-key "run")))
(use-package typescript-mode)

;; search
(use-package rg
  :general
  (leader-keys
    "f" '(rg-menu :which-key "find")))

;; compile (SPC c c / SPC c r)
(use-package compile
  :straight nil
  :config
  (setq compilation-scroll-output t
        compilation-ask-about-save nil)
  :general
  (leader-keys
    "c" '(:ignore t :which-key "compile")
    "c <escape>" '(keyboard-escape-quit :which-key t)
    "c c" '(compile :which-key "compile")
    "c r" '(recompile :which-key "recompile")))
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("e184d8607cc9933f2ba8e180699365bdf8b6f311834a9e15c71947b38be0caa3" default)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
