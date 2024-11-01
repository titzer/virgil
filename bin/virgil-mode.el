(defvar virgil-decls
  '("class" "component" "def" "enum" "extends" "export" "fun" "in" "import" "layout" "new" "packing" "private" "struct" "super" "type" "var" )
  "Virgil declaration keywords.")

(defvar virgil-stmts
  '("if" "case" "else" "while" "break" "continue" "match" "return" "for")
  "Virgil statement keywords.")

(defvar virgil-builtins
  '("void" "int" "byte" "bool" "short" "long" "Array" "Ref" "ref" "Range" "true" "false" "this" "null" "string" "float" "double")
  "Virgil builtin types and values.")

(defvar virgil-decls-regexp (regexp-opt virgil-decls 'words))
(defvar virgil-stmts-regexp (regexp-opt virgil-stmts 'words))
(defvar virgil-builtins-regexp (regexp-opt virgil-builtins 'words))

(setq virgil-font-lock-keywords
  `(
    (,"#unboxed" . font-lock-type-face)
    (,"#boxed" . font-lock-type-face)
    (,"#packing" . font-lock-type-face)
    (,"#big-endian" . font-lock-type-face)
    (,virgil-decls-regexp . font-lock-keyword-face)
    (,virgil-stmts-regexp . font-lock-constant-face)
    (,virgil-builtins-regexp . font-lock-type-face)
))

(setq indent-tabs-mode t)
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
  (setq indent-tabs-mode t)

  (define-key virgil-mode-map [remap comment-dwim] 'virgil-comment-dwim)

  (modify-syntax-entry ?_ "w" virgil-mode-syntax-table)
  (modify-syntax-entry ?\/ ". 124b" virgil-mode-syntax-table)
  (modify-syntax-entry ?* ". 23" virgil-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" virgil-mode-syntax-table)
  
  (setq mode-name "Virgil mode")
)

(define-key virgil-mode-map (kbd "TAB") 'self-insert-command)

