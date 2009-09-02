;;; install-p2-handlers.lisp
;;;
;;; Copyright (C) 2006-2009 Peter Graves <peter@armedbear.org>
;;;
;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the GNU General Public License
;;; as published by the Free Software Foundation; either version 2
;;; of the License, or (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program; if not, write to the Free Software
;;; Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

(in-package "COMPILER")

(defun install-p2-handler (symbol handler)
  (put symbol 'p2-handler handler))

;;; special operators and macros
(install-p2-handler 'and                        'p2-and)
(install-p2-handler 'block                      'p2-block)
(install-p2-handler 'catch                      'p2-catch)
(install-p2-handler 'declare                    'p2-declare)
(install-p2-handler 'flet                       'p2-flet)
(install-p2-handler 'function                   'p2-function)
(install-p2-handler 'go                         'p2-go)
(install-p2-handler 'if                         'p2-if)
(install-p2-handler 'labels                     'p2-labels)
(install-p2-handler 'let                        'p2-let/let*)
(install-p2-handler 'let*                       'p2-let/let*)
(install-p2-handler 'load-time-value            'p2-load-time-value)
(install-p2-handler 'locally                    'p2-locally)
(install-p2-handler 'multiple-value-bind        'p2-m-v-b)
(install-p2-handler 'multiple-value-list        'p2-m-v-l)
(install-p2-handler 'multiple-value-prog1       'p2-multiple-value-prog1)
(install-p2-handler 'or                         'p2-or)
(install-p2-handler 'progn                      'p2-progn)
(install-p2-handler 'progv                      'p2-progv)
(install-p2-handler 'quote                      'p2-quote)
(install-p2-handler 'return-from                'p2-return-from)
(install-p2-handler 'setq                       'p2-setq)
(install-p2-handler 'tagbody                    'p2-tagbody)
(install-p2-handler 'the                        'p2-the)
(install-p2-handler 'throw                      'p2-throw)
(install-p2-handler 'truly-the                  'p2-truly-the)
(install-p2-handler 'unwind-protect             'p2-unwind-protect)

;;; functions
(install-p2-handler '%caddr                     'p2-%caddr)
(install-p2-handler '%cadr                      'p2-%cadr)
(install-p2-handler '%car                       'p2-%car)
(install-p2-handler '%cddr                      'p2-%cddr)
(install-p2-handler '%cdr                       'p2-%cdr)
(install-p2-handler '%dpb                       'p2-%dpb)
(install-p2-handler '%type-error                'p2-%type-error)
(install-p2-handler '%typep                     'p2-typep)
(install-p2-handler 'apply                      'p2-apply)
(install-p2-handler 'ash                        'p2-ash)
(install-p2-handler 'car                        'p2-car)
(install-p2-handler 'cdr                        'p2-cdr)
(install-p2-handler 'char                       'p2-char)
(install-p2-handler 'char-code                  'p2-char-code)
(install-p2-handler 'char/=                     'p2-char/=)
(install-p2-handler 'char=                      'p2-char=)
(install-p2-handler 'characterp                 'p2-characterp)
(install-p2-handler 'check-fixnum-bounds        'p2-check-fixnum-bounds)
(install-p2-handler 'code-char                  'p2-code-char)
(install-p2-handler 'coerce                     'p2-coerce)
(install-p2-handler 'consp                      'p2-consp)
(install-p2-handler 'delete                     'p2-delete)
(install-p2-handler 'endp                       'p2-endp)
(install-p2-handler 'eq                         'p2-eq)
(install-p2-handler 'eql                        'p2-eql)
(install-p2-handler 'evenp                      'p2-oddp/evenp)
(install-p2-handler 'fill                       'p2-fill)
(install-p2-handler 'find                       'p2-find)
(install-p2-handler 'find-eql                   'p2-find)
(install-p2-handler 'first                      'p2-car)
(install-p2-handler 'funcall                    'p2-funcall)
(install-p2-handler 'gethash                    'p2-gethash)
(install-p2-handler 'gethash2                   'p2-gethash)
(install-p2-handler 'gethash2-1                 'p2-gethash)
(install-p2-handler 'gethash3                   'p2-gethash)
(install-p2-handler 'integerp                   'p2-integerp)
(install-p2-handler 'length                     'p2-length)
(install-p2-handler 'list3                      'p2-list3)
(install-p2-handler 'list4                      'p2-list4)
(install-p2-handler 'logand                     'p2-logand)
(install-p2-handler 'logior                     'p2-logior/logxor)
(install-p2-handler 'logxor                     'p2-logior/logxor)
(install-p2-handler 'make-array                 'p2-make-array)
(install-p2-handler 'mapc2                      'p2-mapc2)
(install-p2-handler 'mapcar2                    'p2-mapcar2)
(install-p2-handler 'max                        'p2-min/max)
(install-p2-handler 'memql                      'p2-memql)
(install-p2-handler 'min                        'p2-min/max)
(install-p2-handler 'minusp                     'p2-plusp/minusp)
(install-p2-handler 'neq                        'p2-neq)
(install-p2-handler 'not                        'p2-not/null)
(install-p2-handler 'nreverse                   'p2-reverse/nreverse)
(install-p2-handler 'null                       'p2-not/null)
(install-p2-handler 'oddp                       'p2-oddp/evenp)
(install-p2-handler 'plusp                      'p2-plusp/minusp)
(install-p2-handler 'position-eql               'p2-position-eql)
(install-p2-handler 'require-boolean            'p2-require-boolean)
(install-p2-handler 'require-character          'p2-require-character)
(install-p2-handler 'require-cons               'p2-require-cons)
(install-p2-handler 'require-fixnum             'p2-require-fixnum)
(install-p2-handler 'require-hash-table         'p2-require-hash-table)
(install-p2-handler 'require-integer            'p2-require-integer)
(install-p2-handler 'require-keyword            'p2-require-keyword)
(install-p2-handler 'require-list               'p2-require-list)
(install-p2-handler 'require-number             'p2-require-number)
(install-p2-handler 'require-simple-string      'p2-require-simple-string)
(install-p2-handler 'require-simple-vector      'p2-require-simple-vector)
(install-p2-handler 'require-stream             'p2-require-stream)
(install-p2-handler 'require-string             'p2-require-string)
(install-p2-handler 'require-structure-type     'p2-require-structure-type)
(install-p2-handler 'require-symbol             'p2-require-symbol)
(install-p2-handler 'require-type               'p2-require-type)
(install-p2-handler 'require-ub32               'p2-require-ub32)
(install-p2-handler 'require-vector             'p2-require-vector)
(install-p2-handler 'rest                       'p2-cdr)
(install-p2-handler 'reverse                    'p2-reverse/nreverse)
(install-p2-handler 'rplacd                     'p2-rplacd)
(install-p2-handler 'schar                      'p2-schar)
(install-p2-handler 'structure-ref              'p2-structure-ref)
(install-p2-handler 'structure-set              'p2-structure-set)
(install-p2-handler 'svref                      'p2-svref)
(install-p2-handler 'svset                      'p2-svset)
(install-p2-handler 'sxhash                     'p2-sxhash)
(install-p2-handler 'symbol-global-value        'p2-symbol-global-value)
(install-p2-handler 'symbol-name                'p2-symbol-name)
(install-p2-handler 'symbol-package             'p2-symbol-package)
(install-p2-handler 'symbolp                    'p2-symbolp)
(install-p2-handler 'two-arg-*                  'p2-two-arg-*)
(install-p2-handler 'two-arg-+                  'p2-two-arg-+)
(install-p2-handler 'two-arg--                  'p2-two-arg--)
(install-p2-handler 'two-arg-/                  'p2-two-arg-/)
(install-p2-handler 'two-arg-/=                 'p2-two-arg-/=)
(install-p2-handler 'two-arg-<                  'p2-two-arg-<)
(install-p2-handler 'two-arg-=                  'p2-two-arg-=)
(install-p2-handler 'two-arg-char/=             'p2-char/=)
(install-p2-handler 'two-arg-char=              'p2-char=)
(install-p2-handler 'two-arg-logand             'p2-logand)
(install-p2-handler 'two-arg-logior             'p2-logior/logxor)
(install-p2-handler 'two-arg-logxor             'p2-logior/logxor)
(install-p2-handler 'two-arg-max                'p2-min/max)
(install-p2-handler 'two-arg-min                'p2-min/max)
(install-p2-handler 'type-of                    'p2-type-of)
(install-p2-handler 'typep                      'p2-typep)
(install-p2-handler 'values                     'p2-values)
(install-p2-handler 'vector-ref                 'p2-vector-ref)
(install-p2-handler 'vector-set                 'p2-vector-set)
(install-p2-handler 'vector2                    'p2-vector2)
(install-p2-handler 'vector3                    'p2-vector3)
(install-p2-handler 'zerop                      'p2-zerop)