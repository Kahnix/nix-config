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

;; nix-ts-mode aligns a line inside { ... } with the previous binding, but on
;; an empty line there is no node to start from, so it returned nil and RET or
;; `o' left the new line at column 0. Find that binding from the parent instead.
(after! nix-ts-mode
  (defadvice! +nix-ts-prev-sibling-on-blank-line-a (fn node parent bol &rest args)
    :around #'nix-ts-mode--prev-sibling-not-comment
    (if node
        (apply fn node parent bol args)
      (let (binding any)
        (dolist (child (treesit-node-children parent t))
          (when (< (treesit-node-start child) bol)
            (setq any child)
            (unless (equal (treesit-node-type child) "comment")
              (setq binding child))))
        (when-let* ((anchor (or binding any)))
          (treesit-node-start anchor))))))
