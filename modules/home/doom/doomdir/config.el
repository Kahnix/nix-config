;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Font, icon font and theme come from Nix (Stylix), generated into nix.el by
;; ../doom.nix so they follow the rest of the system.
(load! "nix")

(setq display-line-numbers-type 'relative
      scroll-margin 10)

;; Show the which-key popup almost immediately after a prefix (Doom: 1s).
(setq which-key-idle-delay 0.05
      which-key-idle-secondary-delay 0.05)

;; Emacs runs as a daemon (services.emacs in ../doom.nix), which loads
;; everything in `doom-incremental-packages' at startup. Queue the heavy
;; packages Doom only loads on first use (~1.5s for magit, ~0.5s for eglot),
;; so the first `SPC g g' or code buffer in a client is instant.
(doom-load-packages-incrementally '(magit eglot popup etags ffap compile grep))

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
