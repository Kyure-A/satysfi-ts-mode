;;; satysfi-ts-mode.el --- A tree-sitter based major-mode for SATySFi  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Kyure_A

;; Author: Kyure_A <twitter.com/kyureq>
;; Keywords: languages

;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; URL: https://github.com/Kyure-A/satysfi-ts-mode

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A tree-sitter based major-mode for SATySFi

;;; Code:

(require 'treesit)
(require 'cc-mode)
(require 'c-ts-common)

(declare-function treesit-parser-create "treesit.c")
(declare-function treesit-induce-sparse-tree "treesit.c")
(declare-function treesit-node-child "treesit.c")
(declare-function treesit-node-child-by-field-name "treesit.c")
(declare-function treesit-node-start "treesit.c")
(declare-function treesit-node-type "treesit.c")
(declare-function treesit-search-subtree "treesit.c")

(defcustom satysfi-ts-mode-indent-offset 4
  "Indent offset for `satysfi-ts-mode'."
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'satysfi)

(defvar satysfi-ts-mode--keywords
  '("and"
    "as"
    "block-cmd"
    "command"
    "constraint"
    "direct"
    "do"
    "else"
    "end"
    "fun"
    "if"
    "in"
    "inline-cmd"
    "let"
    "let-block"
    "let-inline"
    "let-math"
    "let-mutable"
    "let-rec"
    "match"
    "math-cmd"
    "module"
    "not"
    "of"
    "open"
    "sig"
    "struct"
    "then"
    "type"
    "val"
    "when"
    "while"
    "with"
    "|")
  "List of keywords used in the text of SATySFi.")

(defvar satysfi-ts-mode--brackets
  '("{"
    "${"
    "}"
    "("
    ")"
    "(|"
    "|)"
    "["
    "]")
  "List of brackets used in the text of SATySFi.")

(defvar satysfi-ts-mode--operators
  '("?:"
    "?->"
    "->"
    "<-"
    "="
    "!")
  "List of operators used in the text of SATySFi.")

(defvar satysfi-ts-mode--includes
  '("@stage:"
    "@require:"
    "@import:")
  "List of includes used in the text of SATySFi.")

(defvar satysfi-ts-mode--delimiters
  '(";"
    ":"
    ","
    "#")
  "List of delimiters used in the text of SATySFi.")

;; see https://github.com/monaqa/tree-sitter-satysfi/blob/master/queries/highlights.scm
(defvar satysfi-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'satysfi
   :feature 'bracket
   '([,@satysfi-ts-mode--brackets] @font-lock-bracket-face
     (block_text ["<" "'<"] @font-lock-bracket-face ">"  @font-lock-bracket-face))
   
   :language 'satysfi
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'satysfi
   :feature 'delimiter
   '([,@satysfi-ts-mode--delimiters (inline_text_bullet_star)] @font-lock-delimiter-face
     (inline_text_list "|" @font-lock-delimiter-face)
     (math_list "|" @font-lock-delimiter-face))
   
   :language 'satysfi
   :feature 'escape
   '((inline_literal_escaped) @font-lock-escape-face)
   
   :language 'satysfi
   :feature 'function
   '(;; stmt
     (let_stmt pattern: (identifier) @font-lock-function-name-face [arg: (_) @font-lock-function-name-face optarg: (_) @font-lock-function-name-face])
     (let_rec_inner pattern: (identifier) @font-lock-function-name-face)
     ;; expr
     (application function: (identifier) @font-lock-function-name-face)
     (application function: (modvar (identifier) @font-lock-function-name-face))
     ;; horizontal/vertical mode
     (block_cmd_name (module_name) @font-lock-builtin-face)
     [(inline_cmd_name) (block_cmd_name)] @font-lock-builtin-face
     [
      (inline_text_embedding)
      (block_text_embedding)
      ;;(math_text_embedding)
      ] @font-lock-builtin-face)
   
   :language 'satysfi
   :feature 'include
   `([,@satysfi-ts-mode--includes] @font-lock-builtin-face)

   :language 'satysfi
   :feature 'keyword
   `([,@satysfi-ts-mode--keywords] @font-lock-builtin-face)
   
   :language 'satysfi
   :feature 'namespace
   '([(module_name) (headers)] @font-lock-builtin-face
     ;; expr
     (modvar "." @font-lock-builtin-face))

   :language 'satysfi
   :feature 'number
   `([(literal_int) (literal_float) (literal_length) "true" "false"] @font-lock-number-face)
   
   :language 'satysfi
   :feature 'operator
   `([,@satysfi-ts-mode--operators (binary_operator)] @font-lock-operator-face
     ;; expr
     (math_token ["^" "_"] @font-lock-operator-face))

   :language 'satysfi
   :feature 'parameter
   '((type_param) @font-lock-function-name-face
     ;; stmt
     (let_inline_stmt [arg: (_) @font-lock-function-name-face optarg: (_) @font-lock-function-name-face])
     (let_block_stmt [arg: (_) @font-lock-function-name-face optarg: (_) @font-lock-function-name-face])
     ;; expr
     (lambda arg: (_) @font-lock-function-name-face)
     ;; horizontal/vertical mode
     (math_cmd_name) @font-lock-function-name-face)
   
   :language 'satysfi
   :feature 'string
   '((literal_string) @font-lock-string-face)

   :language 'satysfi
   :feature 'type
   '([(type_name) (variant_name)] @font-lock-type-face))
  "Font-lock settings for `satysfi-ts-mode'.")

(defvar satysfi-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (c-populate-syntax-table table)
    (modify-syntax-entry ?\n "> b" table)
    table)
  "Syntax table for `satysfi-ts-mode'.")

;; see https://github.com/monaqa/tree-sitter-satysfi/blob/master/queries/indents.scm
(defvar satysfi-ts-mode--indent-rules
  (let ((indent 0)
        (indent-end satysfi-ts-mode-indent-offset)
        (branch satysfi-ts-mode-indent-offset))
    `((satysfi
       ((parent-is "block_text") parent-bol ,indent)
       ((parent-is "inline_text") parent-bol ,indent)
       ((parent-is "inline_text_list") parent-bol ,indent)
       ((parent-is "inline_text_bullet_list") parent-bol ,indent)
       ((parent-is "inline_text_bullet_item") parent-bol ,indent)
       ((parent-is "inline_text_bullet_list") parent-bol ,indent)
       ((parent-is "cmd_expr_arg") parent-bol ,indent)
       
       ((parent-is "match_expr") parent-bol ,indent)
       ((parent-is "parened_expr") parent-bol ,indent)
       ((parent-is "list") parent-bol ,indent)
       ((parent-is "record") parent-bol ,indent)
       ((parent-is "tuple") parent-bol ,indent)
       
       ((parent-is "application") parent-bol ,indent)
       ((parent-is "binary_expr") parent-bol ,indent)
       
       ((parent-is "sig_stmt") parent-bol ,indent)
       ((parent-is "struct_stmt") parent-bol ,indent)
       ((parent-is "let_stmt") parent-bol ,indent)
       ((parent-is "let_inline_stmt") parent-bol ,indent)
       ((parent-is "let_block_stmt") parent-bol ,indent)
       ((parent-is "let_math_stmt") parent-bol ,indent)
       
       ((parent-is "match_arm") parent-bol ,indent)
       
       ((match ">" "block_text") parent-bol ,indent-end)
       ((match "}" "inline_text") parent-bol ,indent-end)
       ((match "}" "inline_text_list") parent-bol ,indent-end)
       ((match "}" "inline_text_bullet_list") parent-bol ,indent-end)
       ((match ")" "parened_expr") parent-bol ,indent-end)
       ((match ")" "cmd_expr_arg") parent-bol ,indent-end)

       
       ((match "]" "list") parent-bol ,indent-end)
       ((match "|)" "record") parent-bol ,indent-end)
       ((match ")" "tuple") parent-bol ,indent-end)

       ((node-is ")") parent-bol ,branch)
       ((node-is "]") parent-bol ,branch)
       ((node-is "}") parent-bol ,branch)
       ((node-is "|)") parent-bol ,branch)
       ((node-is "end") parent-bol ,branch)
       ((match ">" "block_text") parent-bol ,branch)
       
       (no-node parent-bol ,indent-end)
       (catch-all parent-bol ,indent))))
  "Indent rules for `satysfi-ts-mode'.")

(cl-defun satysfi-ts-mode--indent (&optional (offset satysfi-ts-mode-indent-offset))
  "Indent based on `satysfi-ts-mode-indent-offset' (OFFSET)."
  (interactive)
  (if (= offset 1)
      (insert " ")
    (insert " ")
    (satysfi-ts-mode--indent (- offset 1))))

(defvar satysfi-ts-mode-map
  (let ((km (make-sparse-keymap)))
    (define-key km (kbd "<tab>") 'satysfi-ts-mode--indent)
    km)
  "Mode map for `satysfi-ts-mode'.")

(defun satysfi-ts-mode-install-grammar ()
  "Install language grammar for SATySFi."
  (interactive)
  (add-to-list 'treesit-language-source-alist
               '(satysfi "https://github.com/monaqa/tree-sitter-satysfi"))
  (treesit-install-language-grammar 'satysfi))

;;;###autoload
(define-derived-mode satysfi-ts-mode prog-mode "SATySFi"
  "Major mode for editing SATySFi files, powered by tree-sitter."
  :group 'satysfi
  :syntax-table satysfi-ts-mode--syntax-table
  (if (treesit-ready-p 'satysfi)
      (progn
        (treesit-parser-create 'satysfi)
        (c-ts-common-comment-setup)
        (setq-local c-ts-common-indent-offset 'satysfi-ts-mode-indent-offset)
        (setq-local treesit-simple-indent-rules satysfi-ts-mode--indent-rules)
        (setq-local treesit-font-lock-settings satysfi-ts-mode--font-lock-settings)
        (setq-local electric-indent-chars
                    (append "{}()<>" electric-indent-chars))
        (setq-local treesit-font-lock-feature-list
                    '((comment escape)
                      (function constant keyword string number type include namespace parameter)
                      (annotation expression literal)
                      (bracket operator)))
        (treesit-major-mode-setup)
        (add-hook 'satysfi-ts-mode-hook (lambda () (setq comment-start "%") (setq comment-continue "") (setq comment-end "")))
        (add-to-list 'auto-mode-alist '("\\.saty\\'" . satysfi-ts-mode))
        (add-to-list 'auto-mode-alist '("\\.satyh\\'" . satysfi-ts-mode)))
    (message "satysfi-language-grammar is not installed. To install, run \"M-x satysfi-ts-mode-install-grammar\".")))

(provide 'satysfi-ts-mode)
;;; satysfi-ts-mode.el ends here
