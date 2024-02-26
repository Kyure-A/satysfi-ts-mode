;;; satysfi-ts-mode.el --- Better major mode for SATySFi  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Kyure_A

;; Author: Kyure_A <twitter.com/kyureq>
;; Keywords: tools

;; Version: 0.0.1
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

;; Better major mode for SATySFi

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

(defgroup satysfi-ts-mode ()
  "Better major mode for SATySFi"
  :group 'tools
  :prefix "satysfi-ts-mode-"
  :link '(url-link "https://github.com/Kyure-A/satysfi-ts-mode"))

(defcustom satysfi-ts-mode-indent-offset 4
  "indent offset"
  :version "29.1"
  :type 'integer
  :safe 'integerp
  :group 'satysfi)

(defvar satysfi-ts-mode--syntax-table
  (let ((table (make-syntax-table)))
    (c-populate-syntax-table table)
    (modify-syntax-entry ?\n "> b" table)
    table)
  "hoge")

(defvar satysfi-ts-mode--indent-rules
  (let ((indent-end satysfi-ts-mode-indent-offset)
        (indent 0))
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
       ((node-is ">") parent-bol ,indent-end)
       ((node-is "}") parent-bol ,indent-end)
       ((node-is "]") parent-bol ,indent-end)
       ((node-is "|)") parent-bol ,indent-end)
       ((node-is "end") parent-bol ,indent-end)
       (no-node parent-bol ,indent-end)
       (catch-all parent-bol ,indent))))
  "indent rules")

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
    "false"
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
    "true"
    "type"
    "val"
    "when"
    "while"
    "with"
    "|")
  "keywords")

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
  "brackets")

(defvar satysfi-ts-mode--operator
  '("?:"
    "?->"
    "->"
    "<-"
    "="
    "!")
  "operator")

(defvar satysfi-ts-mode--include
  '("@stage:"
    "@require:"
    "@import:")
  "include")

(defvar satysfi-ts-mode)

(defvar satysfi-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'satysfi
   :feature 'bracket
   '([,@satysfi-ts-mode--brackets] @font-lock-bracket-face)
   
   :language 'satysfi
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'satysfi
   :feature 'function
   '(;; [(inline_text_embedding) (block_text_embedding) (math_text_embedding) (inline_cmd_name) (block_cmd_name) (math_cmd_name)] @font-lock-function-name-face  
     ;; embedding is special
     (block_cmd_name (module_name) @font-lock-function-name-face) ;; special
     (let_stmt pattern: (identifier) @font-lock-function-name-face [arg: (_) @font-lock-function-name-face optarg: (_) @font-lock-function-name-face])
     (let_rec_inner pattern: (identifier) @font-lock-function-name-face)
     (application function: (identifier) @font-lock-function-name-face)
     (application function: (modvar (identifier) @font-lock-function-name-face)))
   
   :language 'satysfi
   :feature 'include
   `([,@satysfi-ts-mode--include] @font-lock-keyword-face)

   :language 'satysfi
   :feature 'keyword
   `([,@satysfi-ts-mode--keywords] @font-lock-keyword-face)

   :language 'satysfi
   :feature 'operator
   `([,@satysfi-ts-mode--operator (binary_operator)] @font-lock-operator-face)
   
   :language 'satysfi
   :feature 'string
   `((literal_string) @font-lock-string-face)

   :language 'satysfi
   :feature 'type
   `((type-name) @font-lock-type-face))
  "font-lock settings")

(defvar satysfi-ts-mode-map (copy-keymap global-map))

(defun satysfi-ts-mode--indent ()
  (interactive)
  (dotimes (i satysfi-ts-mode-indent-offset t)
    (insert " ")))

(define-key satysfi-ts-mode-map (kbd "<tab>") 'satysfi-ts-mode--indent)

;;;###autoload
(define-derived-mode satysfi-ts-mode prog-mode "SATySFi"
  "Major mode for editing SATySFi files, powered by tree-sitter."
  :group 'satysfi
  :syntax-table satysfi-ts-mode--syntax-table
  (when (treesit-ready-p 'satysfi)
    (progn
      (treesit-parser-create 'satysfi)
      (c-ts-common-comment-setup)
      
      (setq-local c-ts-common-indent-offset 'satysfi-ts-mode-indent-offset)
      (setq-local treesit-simple-indent-rules satysfi-ts-mode--indent-rules)
      (setq-local treesit-font-lock-settings satysfi-ts-mode--font-lock-settings)

      (setq-local electric-indent-chars
                  (append "{}()<>" electric-indent-chars))

      (setq-local treesit-font-lock-feature-list
                  '((comment definition preprocessor)
                    (function constant keyword string type variables)
                    (annotation expression literal)
                    (bracket delimiter operator)))
      
      (treesit-major-mode-setup)))
  
  (when (treesit-ready-p 'satysfi)
    (add-to-list 'auto-mode-alist '("\\.saty$'" . satysfi-ts-mode))
    (add-to-list 'auto-mode-alist '("\\.satyh$'" . satysfi-ts-mode))))

;;;###autoload
(with-eval-after-load 'treesit
  (add-to-list 'treesit-language-source-alist
               '(satysfi "https://github.com/monaqa/tree-sitter-satysfi"))
  (treesit-install-language-grammar 'satysfi))

(provide 'satysfi-ts-mode)
;;; satysfi-ts-mode.el ends here
