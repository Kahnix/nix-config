;;; $DOOMDIR/init.el -*- lexical-binding: t; -*-

;; Enabled Doom modules. This directory is copied into the Nix store and Doom's
;; packages are built by nix-doom-emacs-unstraightened, so there is no
;; `doom sync`: edit this file and rebuild the system (`rebuild`) instead.
;; `SPC h d h` opens Doom's documentation and module index.

(doom! :completion
       (corfu +orderless)
       vertico

       :ui
       doom
       dashboard
       hl-todo
       indent-guides
       modeline
       ophints
       (popup +defaults)
       (vc-gutter +pretty)
       vi-tilde-fringe
       workspaces

       :editor
       (evil +everywhere)
       file-templates
       fold
       format
       snippets
       (whitespace +guess +trim)

       :emacs
       dired
       electric
       tramp
       undo
       vc

       :term
       vterm

       :checkers
       syntax

       :tools
       direnv
       editorconfig
       (eval +overlay)
       lookup
       (lsp +eglot)
       magit
       tree-sitter

       :os
       (:if (featurep :system 'macos) macos)
       tty

       :lang
       (cc +lsp +tree-sitter)
       emacs-lisp
       (go +lsp +tree-sitter)
       (javascript +lsp +tree-sitter)
       (json +tree-sitter)
       (lua +lsp)
       markdown
       (nix +lsp +tree-sitter)
       org
       (python +lsp +tree-sitter)
       (rust +lsp +tree-sitter)
       (sh +tree-sitter)
       (web +lsp)
       (yaml +lsp +tree-sitter)

       :config
       (default +bindings +smartparens))
