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

(require 'undercover)
(undercover "*.el"
            (:report-format 'codecov)
            (:report-file "coverage-final.json")
            (:send-report nil))

(require 'satysfi-ts-mode)

(provide 'satysfi-ts-mode-test)
;;; satysfi-ts-mode-test.el ends here
