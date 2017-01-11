(defvar virgil-decls
  '("class" "component" "def" "extends" "in" "new" "private" "super" "type" "enum" "var")
  "Virgil declaration keywords.")

(defvar virgil-stmts
  '("if" "case" "else" "while" "break" "continue" "match" "return" "for")
  "Virgil statement keywords.")

(defvar virgil-builtins
  '("void" "int" "byte" "bool" "long" "Array" "true" "false" "this" "string")
  "Virgil builtin types and values.")

(defvar virgil-decls-regexp (regexp-opt virgil-decls 'words))
(defvar virgil-stmts-regexp (regexp-opt virgil-stmts 'words))
(defvar virgil-builtins-regexp (regexp-opt virgil-builtins 'words))

(setq virgil-font-lock-keywords
  `(
    (,virgil-decls-regexp . font-lock-keyword-face)
    (,virgil-stmts-regexp . font-lock-constant-face)
    (,virgil-builtins-regexp . font-lock-type-face)
))

(set-face-foreground 'font-lock-comment-face "yellow") 
(set-face-foreground 'font-lock-string-face "red") 
(set-variable font-lock-comment-face 'font-lock-comment-face)

;; TODO: the command to comment/uncomment text
;(defun virgil-comment-dwim (arg)
;"Comment or uncomment current line or region in a smart way.
;For detail, see `comment-dwim'."
;   (interactive "*P")
;   (require 'newcomment)
;   (let ((deactivate-mark nil) (comment-start "#") (comment-end ""))
;     (comment-dwim arg)))

(define-derived-mode virgil-mode fundamental-mode

  ;; code for syntax highlighting
  (setq font-lock-defaults '((virgil-font-lock-keywords)))

  (define-key virgil-mode-map [remap comment-dwim] 'virgil-comment-dwim)

  (modify-syntax-entry ?_ "w" virgil-mode-syntax-table)
  (modify-syntax-entry ?\/ ". 124b" virgil-mode-syntax-table)
  (modify-syntax-entry ?* ". 23" virgil-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" virgil-mode-syntax-table)
  
  (setq mode-name "Virgil mode")
)

(define-key virgil-mode-map (kbd "TAB") 'self-insert-command)

