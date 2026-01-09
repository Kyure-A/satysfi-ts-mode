;;; satysfi-ts-mode-test.el --- Test for satysfi-ts-mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2024 Kyure_A

;; Author: Kyure_A <twitter.com/kyureq>

;; SPDX-License-Identifier:  GPL-3.0-or-later

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

;; Test for satysfi-ts-mode

;;; Code:

(require 'ert)
(require 'ert-x)
(require 'treesit)

(declare-function treesit-install-language-grammar "treesit.c")

(if (and (treesit-available-p) (boundp 'treesit-language-source-alist))
    (unless (treesit-language-available-p 'satysfi)
      (treesit-install-language-grammar 'satysfi)))

(require 'undercover)
(undercover "*.el"
            (:report-format 'codecov)
            (:report-file "coverage-final.json")
            (:send-report nil))

(require 'satysfi-ts-mode)

(defun satysfi-ts-mode-test--face-at (pos)
  "Return face or face list at POS."
  (let* ((face (get-text-property pos 'face))
         (lock-face (get-text-property pos 'font-lock-face))
         (combined (delq nil (append (if (listp face) face (list face))
                                     (if (listp lock-face) lock-face (list lock-face))))))
    (if combined combined nil)))

(defun satysfi-ts-mode-test--face-matches-p (pos face)
  "Return non-nil if FACE is applied at POS."
  (memq face (satysfi-ts-mode-test--face-at pos)))

(defun satysfi-ts-mode-test--pos (needle)
  "Return start position of NEEDLE in current buffer."
  (save-excursion
    (goto-char (point-min))
    (search-forward needle)
    (- (point) (length needle))))

(defmacro satysfi-ts-mode-test--with-buffer (content &rest body)
  "Create temp buffer with CONTENT and run BODY in `satysfi-ts-mode'."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,content)
     (satysfi-ts-mode)
     (skip-unless (treesit-ready-p 'satysfi))
     (font-lock-mode 1)
     (font-lock-ensure)
     ,@body))

(ert-deftest satysfi-ts-mode-test-font-lock-keywords-operators ()
  (satysfi-ts-mode-test--with-buffer
      "let x = true\nlet y = false\nlet z = a :: b\n"
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "true")
             'font-lock-builtin-face))
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "false")
             'font-lock-builtin-face))
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "::")
             'font-lock-operator-face))))

(ert-deftest satysfi-ts-mode-test-font-lock-type-operators ()
  (satysfi-ts-mode-test--with-buffer
      "type t = int * int\ntype u = [int?] math-cmd\n"
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "*")
             'font-lock-operator-face))
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "?")
             'font-lock-operator-face))))

(ert-deftest satysfi-ts-mode-test-font-lock-record-fields ()
  (satysfi-ts-mode-test--with-buffer
      "let r = (| foo = 1; bar = 2 |)\ntype rec = (| baz : int |)\n"
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "foo")
             'font-lock-property-face))
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "bar")
             'font-lock-property-face))
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "baz")
             'font-lock-property-face))))

(ert-deftest satysfi-ts-mode-test-font-lock-math-embedding ()
  (satysfi-ts-mode-test--with-buffer
      "let m = ${#foo}\n"
    (should (satysfi-ts-mode-test--face-matches-p
             (satysfi-ts-mode-test--pos "#")
             'font-lock-builtin-face))))

(provide 'satysfi-ts-mode-test)
;;; satysfi-ts-mode-test.el ends here
