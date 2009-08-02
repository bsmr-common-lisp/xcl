;;; psetf.lisp

;; Copyright (C) 2002-2004, Yuji Minejima <ggb01164@nifty.ne.jp>
;; ALL RIGHTS RESERVED.
;;
;; $Id: data-and-control.lisp,v 1.17 2004/09/02 06:59:43 yuji Exp $
;;
;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;;  * Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;;  * Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in
;;    the documentation and/or other materials provided with the
;;    distribution.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
;; OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
;; SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
;; LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(in-package "SYSTEM")

(defmacro psetf (&rest pairs &environment env)
  (let ((numargs (length pairs)))
    (unless (evenp numargs)
      (error 'program-error
             :format-control "Odd number of arguments to ~S."
             :format-arguments (list 'psetf)))
    (if (< numargs 4)
	`(progn (setf ,@pairs) nil)
      (let ((setters nil))
	(labels ((expand (pairs)
                   (if pairs
		       (multiple-value-bind (temps vars newvals setter getter)
			   (get-setf-expansion (car pairs) env)
			 (declare (ignore getter))
			 (setq setters (cons setter setters))
			 `(let (,@(mapcar #'list temps vars))
			    (multiple-value-bind ,newvals ,(cadr pairs)
			      ,(expand (cddr pairs)))))
		     `(progn ,@setters nil))))
	  (expand pairs))))))
