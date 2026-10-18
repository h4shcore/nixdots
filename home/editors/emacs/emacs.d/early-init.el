;;; early-init.el --- -*- lexical-binding: t; -*-

;; Runs before the GUI and package system initialise.

;; Don't GC during startup; gcmh (init.el) takes over afterwards.
(setq gc-cons-threshold (* 128 1024 1024))

;; straight.el replaces package.el.
(setq package-enable-at-startup nil)

;; Strip UI chrome before the first frame is drawn (no flicker, no resize).
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars . nil) default-frame-alist)
(push '(horizontal-scroll-bars . nil) default-frame-alist)
(setq frame-inhibit-implied-resize t
      frame-resize-pixelwise t)

;; No dialogs / splash.
(setq use-file-dialog nil
      use-dialog-box nil
      inhibit-startup-screen t)

;; Quiet native-comp.
(setq native-comp-async-report-warnings-errors 'silent)

;;; early-init.el ends here
