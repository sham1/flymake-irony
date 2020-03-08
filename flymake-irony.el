;;; flymake-irony.el --- Flymake support for irony -*- lexical-binding: t -*-

;; Copyright (C) 2020 Jani Juhani Sinervo

;; Author: Jani Juhani Sinervo <jani@sinervo.fi>
;; Keywords: convenience, tools, c
;; Version: 0.1.0
;; URL: https://github.com/sham1/flymake-irony/
;; Package-Requires: ((emacs "26.1") (irony "1.4.0"))

;; This program is free software; you can redistribute it and/or modify
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

;; C, C++ and Objective-C support for Flymake, using Irony Mode.
;;
;; Usage:
;;
;;     (add-hook 'flymake-mode-hook #'flymake-irony-setup)

;;; Code:

(require 'irony)
(require 'irony-diagnostics)

(require 'flymake)

(eval-when-compile
  (require 'pcase))

(defun flymake-irony--build-error (diagnostic buffer)
  (let ((severity (irony-diagnostics-severity diagnostic)))
    (if (memq severity '(note warning error fatal))
	(let* ((line (irony-diagnostics-line diagnostic))
	       (column (irony-diagnostics-column diagnostic))
	       (linecol (flymake-diag-region buffer line column))
	       (diag-type (pcase severity
			    (`note :note)
			    (`warning :warning)
			    ((or `error `fatal) :error)))
	       (msg (irony-diagnostics-message diagnostic)))
	  (flymake-make-diagnostic buffer (car linecol)
				   (cdr linecol)
				   diag-type
				   msg)))))

(defun flymake-irony (report-fn &rest _args)
  (let ((buffer (current-buffer)))
    (irony-diagnostics-async
     #'(lambda (status &rest args)
	 (pcase status
	   (`error (funcall report-fn :panic (list :explanation (car args))))
	   (`cancelled (funcall report-fn '()))
	   (`success
	    (let* ((diagnostics (car args))
		   (errors (mapcar #'(lambda (diagnostic)
				       (flymake-irony--build-error
					diagnostic buffer))
				   diagnostics)))
	      (funcall report-fn errors))))))))

;;;###autoload
(defun flymake-irony-setup ()
  "Enable flycheck-irony."
  (interactive)
  (add-hook 'flymake-diagnostic-functions #'flymake-irony nil t))

(provide 'flymake-irony)

;;; flymake-irony.el ends here
