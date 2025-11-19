(defvar virgil-decls
  '("class" "component" "def" "enum" "extends" "export" "fun" "in" "import" "layout" "new" "packing" "private" "struct" "super" "thread" "type" "var" )
  "Virgil declaration keywords.")

(defvar virgil-stmts
  '("if" "case" "else" "while" "break" "continue" "match" "return" "for")
  "Virgil statement keywords.")

(defvar virgil-builtins
  '("void" "int" "byte" "bool" "short" "long" "Array" "array" "Ref" "ref" "Range" "range" "true" "false" "this" "null" "string" "float" "double")
  "Virgil builtin types and values.")

(defvar virgil-decls-regexp (regexp-opt virgil-decls 'words))
(defvar virgil-stmts-regexp (regexp-opt virgil-stmts 'words))
(defvar virgil-builtins-regexp (regexp-opt virgil-builtins 'words))

(setq virgil-font-lock-keywords
  `(
    ("#[[:word:]-]+" . font-lock-type-face)
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

(defvar compilation-error-regexp-alist-alist nil "List compilation error parsing regexps")
(setq compilation-error-regexp-alist-alist (cons
  '(virgil
"^\\[\\(.+;.+?m\\)?\\(?1:.*\\.v3\\)\\(.+;.+?m\\)? @ \\(.+;.+?m\\)?\\(?2:[0-9]+\\):\\(?3:[0-9]+\\)\\(.+;.+?m\\)?\\]"
   1 2 3) compilation-error-regexp-alist-alist))
;; Pattern is (without the extra blackslashes, etc.: ^[_color__filename__color_ @ _color__line_:_col__color_]
;; where _color_ is an optional ANSI escape code sequence for color (ESC [ digits ; digits m), _filename_ is
;; a file name ending in .v3, and _line_ and _col_ are decimal numbers.  The color is optional mostly to be
;; robust to the future and case error messages have such escape sequences filtered out, e.g., by ansi2txt.
(defvar compilation-error-regexp-alist nil)
(add-to-list 'compilation-error-regexp-alist 'virgil)
