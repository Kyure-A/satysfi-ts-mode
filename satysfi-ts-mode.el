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
    ;; (modify-syntax-entry ?_ "" table)
    table)
  "hoge")

(defvar satysfi-ts-mode--indent-rules
  (let ((offset satysfi-ts-mode-indent-offset))
    `((satysfi
       ((node-is ">") parent-bol 0)
       ((node-is "}") parent-bol 0)
       ((node-is "}") parent-bol 0)
       ((parent-is "tuple") parent-bol 0)
       ((parent-is "record") parent-bol 0)
       ((parent-is "list") parent-bol 0)
       (no-node parent-bol 0)
       (catch-all parent-bol satysfi-ts-mode-indent-offset))))
  "indent rules")

(defvar satysfi-ts-mode--keywords
  '( "and"
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

(defvar satysfi-ts-mode--font-lock-settings
  (treesit-font-lock-rules
   :language 'satysfi
   :feature 'comment
   '((comment) @font-lock-comment-face)

   :language 'satysfi
   :feature 'keywords
   `([,@satysfi-ts-mode--keywords] @font-lock-keyword-face)
   
   :language 'satysfi
   :feature 'string
   '((literal_string) @font-lock-string-face)

   :language 'satysfi
   :feature 'type
   '((type-name) @font-lock-type-face)
   
   ;; :language 'satysfi
   ;; :feature 'variables
   ;; '()
   )
  "font-lock settings")

(define-derived-mode satysfi-ts-mode prog-mode "SATySFi"
  "Major mode for editing SATySFi files, powered by tree-sitter."
  :group 'satysfi
  :syntax-table satysfi-ts-mode--syntax-table
  (when (treesit-ready-p 'satysfi)
    (progn
      (treesit-parser-create 'satysfi)
      (c-ts-common-comment-setup)

      (setq-local treesit-simple-indent-rules satysfi-ts-mode--indent-rules)
      (setq-local treesit-font-lock-settings satysfi-ts-mode--font-lock-settings)
      
      (treesit-major-mode-setup)
      
      (add-to-list 'auto-mode-alist '("\\.saty$'" . satysfi-ts-mode))
      (add-to-list 'auto-mode-alist '("\\.satyh$'" . satysfi-ts-mode)))
    
    (add-to-list
     'treesit-language-source-alist
     '(satysfi "https://github.com/monaqa/tree-sitter-satysfi"))
    (treesit-install-language-grammar 'satysfi)))

(provide 'satysfi-ts-mode)
;;; satysfi-ts-mode.el ends here
