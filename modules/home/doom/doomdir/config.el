;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Font, icon font and theme come from Nix (Stylix), generated into nix.el by
;; ../doom.nix so they follow the rest of the system.
(load! "nix")

(setq display-line-numbers-type 'relative
      scroll-margin 10)

;; Show the which-key popup almost immediately after a prefix (Doom: 1s), and
;; let it use up to half the frame so top-level `SPC' fits on fewer pages.
(setq which-key-idle-delay 0.05
      which-key-idle-secondary-delay 0.05
      which-key-side-window-max-height 0.5)

;; Keep the bottom echo area strictly 1 line tall (Helix style): never let
;; Eglot/Eldoc blow up the minibuffer with multi-line hover types as the cursor
;; moves. Press `K' (`+lookup/documentation') when you want the full type/doc
;; popup (`q' to close).
(setq eldoc-echo-area-use-multiline-p nil)

;; Emacs runs as a daemon (services.emacs in ../doom.nix), which loads
;; everything in `doom-incremental-packages' at startup. Queue the heavy
;; packages Doom only loads on first use (~1.5s for magit, ~0.5s for eglot),
;; so the first `SPC g g' or code buffer in a client is instant.
(doom-load-packages-incrementally '(magit eglot popup etags ffap compile grep))

;; Windows of `emacsclient -t' frames in Rex panes are Rex panes: splitting
;; opens a pane on this daemon, deleting closes it (github:Kahnix/emrex).
(require 'emrex)
(emrex-mode 1)

;; Eglot's default for nix-mode lists nil first (eglot-alternatives
;; '("nil" "rnix-lsp" "nixd")), so nil wins whenever it is installed. nil has
;; no nixpkgs package completion and no version inlay hints, which is why the
;; nixd settings in nix.el had no effect. Pin nixd for both nix modes.
(set-eglot-client! '(nix-mode nix-ts-mode) '("nixd"))

;; nixd answers each package in a nix file with its version as an inlay hint
;; ("omp  18.16.0"); Eglot only paints them once the mode is on. The rest of
;; the nixd setup -- where nixpkgs and the option sets live -- is generated
;; into nix.el by ../doom.nix, because it names this machine.
(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (when (and (fboundp 'eglot-inlay-hints-mode)
                       (memq major-mode '(nix-mode nix-ts-mode)))
              (eglot-inlay-hints-mode 1))))

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

;; typescript-ts-mode only counts `const x = ...' as a defun when the value is
;; a function, so `C-M-a'/`C-M-e' and `[['/`]]' skip every
;; `export const t = pgTable(...)' or Zod schema. Count every top-level
;; declaration instead.
(add-hook! '(typescript-ts-mode-hook tsx-ts-mode-hook)
  (defun +typescript-ts-all-declarations-are-defuns-h ()
    (when (consp treesit-defun-type-regexp)
      (setq-local treesit-defun-type-regexp (car treesit-defun-type-regexp)))
    (dolist (lang '(typescript tsx))
      (when-let* ((settings (assq lang treesit-thing-settings)))
        (setf (alist-get 'defun (cdr settings)) treesit-defun-type-regexp)))))

;; TypeScript projects: match what the repo itself runs (`pnpm typecheck',
;; `pnpm lint', `pnpm format') instead of whatever is on PATH.
;; - Type checking: TypeScript 7 ships no tsserver, so typescript-language-server
;;   would silently fall back to an older global TypeScript. Use the project's
;;   own native server (`tsc --lsp') when it has one.
;; - Linting: Eglot talks to one server per buffer, so rassumfrassum (`rass')
;;   multiplexes oxlint's diagnostics and fixes alongside it when the project
;;   has an .oxlintrc.json.
;; - Formatting: oxfmt through apheleia when the project has an .oxfmtrc.json.
(defun +ts--project-file (name)
  "Absolute path of NAME in the nearest directory above that contains it."
  (when-let* ((dir (locate-dominating-file default-directory name)))
    (expand-file-name name dir)))

(defun +ts--native-tsc ()
  "The project's TypeScript 7+ `tsc', which has a built-in language server."
  (when-let* ((tsc (+ts--project-file "node_modules/.bin/tsc"))
              (pkg (+ts--project-file "node_modules/typescript/package.json"))
              (version (alist-get 'version (json-read-file pkg))))
    (and (>= (string-to-number version) 7) tsc)))

(defun +ts-eglot-contact (_interactive)
  (let ((ts (if-let* ((tsc (+ts--native-tsc)))
                (list tsc "--lsp" "--stdio")
              (list "typescript-language-server" "--stdio"))))
    (if (+ts--project-file ".oxlintrc.json")
        `("rass" "--" ,@ts "--"
          ,(or (+ts--project-file "node_modules/.bin/oxlint") "oxlint") "--lsp")
      ts)))

(set-eglot-client! '(typescript-ts-mode tsx-ts-mode js-ts-mode) #'+ts-eglot-contact)

(after! apheleia
  (setf (alist-get 'oxfmt apheleia-formatters) '("oxfmt" "--stdin-filepath" filepath)))

(add-hook! '(typescript-ts-mode-hook tsx-ts-mode-hook js-ts-mode-hook)
  (defun +ts-use-oxfmt-h ()
    (when (+ts--project-file ".oxfmtrc.json")
      (setq-local +format-with 'oxfmt))))

;; Org notes and todos (`:lang org'): `SPC n n' or `SPC X' captures (pick a
;; template, write, `C-c C-c' to file it, `C-c C-k' to throw it away), `SPC n a'
;; is the agenda and `SPC n t' the TODO list. Doom keeps all of it under ~/org,
;; which nothing here created, so capture filled its buffer and then failed to
;; save ("Opening output file: No such file or directory") while the agenda and
;; TODO list had no files to scan.
(setq org-directory (expand-file-name "~/org")
      org-agenda-files (list org-directory))
(make-directory org-directory t)

;; Doom's "t" template writes `* [ ] ...' -- a checkbox, which neither
;; `org-todo-list' nor the agenda ever match. Capture a real TODO keyword
;; instead; "p t"/"p n" stay project-local (todo.org/notes.org at the repo
;; root) and "j" logs into journal.org.
(setq org-capture-templates
      (cons '("t" "Todo" entry (file+headline +org-capture-todo-file "Inbox")
              "* TODO %?\n%i\n%a" :prepend t)
            (assoc-delete-all "t" org-capture-templates)))
