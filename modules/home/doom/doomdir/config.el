;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Font, icon font and theme come from Nix (Stylix), generated into nix.el by
;; ../doom.nix so they follow the rest of the system.
(load! "nix")

(setq display-line-numbers-type 'relative
      scroll-margin 10)

;; Show the which-key popup almost immediately after a prefix (Doom: 1s).
(setq which-key-idle-delay 0.05
      which-key-idle-secondary-delay 0.05)

;; Doom defers most global modes (flycheck, smartparens, projectile, evil
;; bindings, ...) until the first file is opened, and the first code buffer
;; then loads eglot and its helpers, so that first `SPC f f' took ~3-5s. Do
;; both as soon as Emacs is idle after startup, like Doom does for a daemon.
(unless (daemonp)
  (run-with-idle-timer
   0.5 nil
   (lambda ()
     (dolist (hook '(doom-first-input-hook doom-first-buffer-hook doom-first-file-hook))
       (doom-run-hooks hook)
       (set hook nil))
     (mapc #'require '(eglot popup etags ffap compile grep)))))
