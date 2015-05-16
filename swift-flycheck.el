;;; swift-flycheck.el --- Flycheck support for Apple's Swift programming language. -*- lexical-binding: t -*-

;; Copyright (C) 2014 Chris Barrett, Bozhidar Batsov, Arthur Evstifeev

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Flycheck support for Apple's Swift programming language.

(flycheck-def-option-var flycheck-swift-sdk-path nil swift
  "A path to the targeted SDK"
  :type '(choice (const :tag "Don't link against sdk" nil)
                 (string :tag "Targeted SDK path"))
  :safe #'stringp)

(flycheck-def-option-var flycheck-swift-linked-sources nil swift
  "Source files path to link against. Can be glob, i.e. *.swift"
  :type '(choice (const :tag "Don't use linked sources" nil)
                 (string :tag "Linked Sources"))
  :safe #'stringp)

(flycheck-def-option-var flycheck-swift-framework-search-paths nil swift
  "A list of framework search paths"
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swift-cc-include-search-paths nil swift
  "A list of include file search paths to pass to the Objective C compiler"
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p)

(flycheck-def-option-var flycheck-swift-target "i386-apple-ios8.1" swift
  "Target used by swift compiler"
  :type '(choice (const :tag "Don't specify target" nil)
                 (string :tag "Build target"))
  :safe #'stringp)

(flycheck-def-option-var flycheck-swift-import-objc-header nil swift
  "Objective C header file to import, if any"
  :type '(choice (const :tag "Don't specify objective C bridging header" nil)
                 (string :tag "Objective C bridging header path"))
  :safe #'stringp)

(flycheck-define-checker swift
  "Flycheck plugin for for Apple's Swift programming language."
  :command ("swift"
            "-frontend" "-parse"
            (option "-sdk" flycheck-swift-sdk-path)
            (option-list "-F" flycheck-swift-framework-search-paths)
            ;; Swift compiler will complain about redeclaration
            ;; if we will include original file along with
            ;; temporary source file created by flycheck.
            ;; We also don't want a hidden emacs interlock files.
            (eval
             (let (source file)
               (when flycheck-swift-linked-sources
                 (setq source (car (flycheck-substitute-argument 'source 'swift)))
                 (setq file (file-name-nondirectory source))
                 (cl-remove-if-not
                  #'(lambda (path)
                      (and
                       (eq (string-match ".#" path) nil)
                       (eq (string-match file path) nil)))
                  (file-expand-wildcards flycheck-swift-linked-sources)))))
            (option "-target" flycheck-swift-target)
            (option "-import-objc-header" flycheck-swift-import-objc-header)
            (eval
             (mapcan
              #'(lambda (path) (list "-Xcc" (concat "-I" path)))
              flycheck-swift-cc-include-search-paths))
            "-primary-file" source)
  :error-patterns
  ((error line-start (file-name) ":" line ":" column ": "
          "error: " (message) line-end)
   (warning line-start (file-name) ":" line ":" column ": "
            "warning: " (message) line-end))
  :modes swift-mode)

(add-to-list 'flycheck-checkers 'swift)

(provide 'swift-flycheck)

;;; swift-flycheck.el ends here
