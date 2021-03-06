;;; source-transforms.lisp
;;;
;;; Copyright (C) 2006-2011 Peter Graves <gnooth@gmail.com>
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

(define-source-transform not (x)
  `(if ,x nil t))

(define-source-transform null (x)
  `(if ,x nil t))

(define-source-transform if (&whole form &rest args)
  (let ((test-form (first args))
        (consequent (second args))
        (alternate (third args)))
    (cond ((and (consp test-form)
                (length-eql test-form 2)
                (memq (%car test-form) '(NOT NULL)))
           `(if ,(%cadr test-form) ,alternate ,consequent))
          (t
           form))))

(define-source-transform logtest (x y)
  `(not (zerop (logand ,x ,y))))

(defconstant +type-predicates+ (make-hash-table :test 'equal))

(progn
  (clrhash +type-predicates+)
  (dolist (pair '((ARRAY              . arrayp)
                  (ATOM               . atom)
                  (BASE-CHAR          . characterp)
                  (BIT-VECTOR         . bit-vector-p)
                  (CHARACTER          . characterp)
                  (CLASS              . classp)
                  (COMPLEX            . complexp)
                  (CONDITION          . conditionp)
                  (CONS               . consp)
                  (DOUBLE-FLOAT       . double-float-p)
                  (FIXNUM             . fixnump)
                  (FLOAT              . floatp)
                  (FUNCTION           . functionp)
                  (HASH-TABLE         . hash-table-p)
                  (INTEGER            . integerp)
                  (KEYWORD            . keywordp)
                  (LIST               . listp)
                  (NULL               . null)
                  (NUMBER             . numberp)
                  (PACKAGE            . packagep)
                  (PATHNAME           . pathnamep)
                  (RATIO              . ratiop)
                  (RATIONAL           . rationalp)
                  (READTABLE          . readtablep)
                  (REAL               . realp)
                  (SEQUENCE           . sequencep)
                  (SIMPLE-ARRAY       . simple-array-p)
                  (SIMPLE-BASE-STRING . simple-string-p)
                  (SIMPLE-BIT-VECTOR  . simple-bit-vector-p)
                  (SIMPLE-STRING      . simple-string-p)
                  (SIMPLE-VECTOR      . simple-vector-p)
                  (SINGLE-FLOAT       . single-float-p)
                  (STANDARD-CHAR      . %standard-char-p)
                  (STANDARD-OBJECT    . standard-object-p)
                  (STREAM             . streamp)
                  (STRING             . stringp)
                  (STRUCTURE-OBJECT   . structure-object-p)
                  (SYMBOL             . symbolp)
                  (VECTOR             . vectorp)))
    (setf (gethash (canonicalize-type (%car pair)) +type-predicates+) (%cdr pair))))


(define-source-transform %typep (&whole form &rest args)
  (if (length-eql args 2) ; no environment arg
      (let* ((object (%car args))
             (type-specifier (%cadr args))
             (type (and (quoted-form-p type-specifier)
                        (canonicalize-type (%cadr type-specifier))))
             (predicate (and type (gethash type +type-predicates+))))
        (cond (predicate
               `(,predicate ,object))
              ((fixnum-type-p type)
               `(fixnum-typep ,object ,(second type) ,(third type)))
              ((and (consp type)
                    (eq (%car type) 'OR))
               (let ((types (%cdr type))
                     (obj (gensym)))
                 `(let ((,obj ,object))
                    (or ,@(mapcar (lambda (x) `(%typep ,obj ',(canonicalize-type x))) types)))))
              (t
               form)))
      form))

(define-source-transform two-arg-= (&whole form &rest args)
  (cond ((length-eql args 2)
         (cond ((eql (%car args) 0)
                `(zerop ,(%cadr args)))
               ((eql (%cadr args) 0)
                `(zerop ,(%car args)))
               (t
                form)))
        (t
         form)))

(define-source-transform + (&whole form &rest args)
  (let ((numargs (length args)))
    (cond ((> numargs 2)
           `(two-arg-+ ,(%car args) (+ ,@(%cdr args))))
          ((eql numargs 2)
           `(two-arg-+ ,(%car args) ,(%cadr args)))
          (t
           form))))

(define-source-transform - (&whole form &rest args)
  (let ((numargs (length args)))
    (cond ((> numargs 2)
           `(two-arg-- ,(%car args) (+ ,@(%cdr args))))
          ((eql numargs 2)
           `(two-arg-- ,(%car args) ,(%cadr args)))
          (t
           form))))

(define-source-transform / (&whole form &rest args)
  (let ((numargs (length args)))
    (case numargs
      (1
       `(two-arg-/ 1 ,(%car args)))
      (2
       `(two-arg-/ ,(%car args) ,(%cadr args)))
      (t
       form))))

(define-source-transform max (&whole form &rest args)
  (cond ((length-eql args 2)
         `(two-arg-max ,(%car args) ,(%cadr args)))
        (t
         form)))

(define-source-transform min (&whole form &rest args)
  (cond ((length-eql args 2)
         `(two-arg-min ,(%car args) ,(%cadr args)))
        (t
         form)))

(define-source-transform last (&whole form &rest args)
  (if (length-eql args 1)
      `(last1 ,(%car args))
      form))

(define-source-transform find-class (&whole form &rest args)
  (if (length-eql args 1)
      `(find-class-1 ,(%car args))
      form))

(define-source-transform logand (&whole form &rest args)
  (cond ((> (length args) 2)
         `(logand ,(%car args) (logand ,@(%cdr args))))
        (t
         form)))

(define-source-transform logior (&whole form &rest args)
  (cond ((> (length args) 2)
         `(logior ,(car args) (logior ,@(%cdr args))))
        (t
         form)))

(define-source-transform logxor (&whole form &rest args)
  (let ((numargs (length args)))
    (cond ((> numargs 2)
           `(two-arg-logxor ,(%car args) (logxor ,@(%cdr args))))
          ((eql numargs 2)
           `(two-arg-logxor ,(%car args) ,(%cadr args)))
          (t
           form))))

(define-source-transform mapc2 (&whole form &rest args)
  (cond ((or (> *debug* *speed*)
             (> *space* *speed*))
         form)
        ((length-eql args 2)
         (let ((arg1 (%car args))
               (arg2 (%cadr args))
               (list (gensym)))
           `(let* ((,list ,arg2))
              (loop
                (when (endp ,list)
                  (return ,arg2))
                (funcall ,arg1 (%car ,list))
                (setq ,list (%cdr ,list))))))
        (t
         form)))

(define-source-transform mapcar2 (&whole form &rest args)
  (cond ((or (> *debug* *speed*)
             (> *space* *speed*))
         form)
        ((length-eql args 2)
         (let ((arg1 (%car args))
               (arg2 (%cadr args))
               (list (gensym))
               (result (gensym))
               (temp (gensym)))
           `(let* ((,list ,arg2)
                   (,result (list1 nil))
                   (,temp ,result))
              (loop
                (when (endp ,list)
                  (return (%cdr ,result)))
                (%rplacd ,temp (setq ,temp (list1 (funcall ,arg1 (%car ,list)))))
                (setq ,list (%cdr ,list))))))
        (t
         form)))

(define-source-transform funcall (&whole form &rest args)
  (if (< (length form) 2)
      form
      (let* ((operator-form (%cadr form))
             operator)
        (cond ((and (setq operator (and (quoted-form-p operator-form)
                                        (%cadr operator-form)))
                    (symbolp operator)
                    (kernel-function-p operator))
               `(,operator ,@(cdr args)))
              ((and (setq operator (and (consp operator-form)
                                        (length-eql operator-form 2)
                                        (eq (%car operator-form) 'FUNCTION)
                                        (%cadr operator-form)))
                    (symbolp operator)
                    (kernel-function-p operator))
               `(,operator ,@(cdr args)))
              (t
               form)))))

(define-source-transform assoc (&whole form &rest args)
  (case (length args)
    (2
     `(assql ,(%car args) ,(%cadr args)))
    (4
     (let ((arg3 (third args))
           (arg4 (fourth args)))
       (cond ((and (eq arg3 :test)
                   (member arg4 `(EQ #'EQ ,(list 'FUNCTION 'EQ)) :test #'equal))
              `(assq ,(%car args) ,(%cadr args)))
             ((and (eq arg3 :test)
                   (member arg4 `(EQL #'EQL ,(list 'FUNCTION 'EQL)) :test #'equal))
              `(assql ,(%car args) ,(%cadr args)))
             (t
              form))))
    (t
     form)))

(define-source-transform member (&whole form &rest args)
  (case (length args)
    (2
     `(memql ,(%car args) ,(%cadr args)))
    (4
     (let ((arg3 (third args))
           (arg4 (fourth args)))
       (cond ((and (eq arg3 :test)
                   (member arg4 `(EQ #'EQ ,(list 'FUNCTION 'EQ)) :test #'equal))
              `(memq ,(%car args) ,(%cadr args)))
             ((and (eq arg3 :test)
                   (member arg4 `(EQL #'EQL ,(list 'FUNCTION 'EQL)) :test #'equal))
              `(memql ,(%car args) ,(%cadr args)))
             (t
              form))))
    (t
     form)))

(defun transform-find/position (form item sequence rest)
  (let ((operator (car form))
        (test-form (ignore-errors (getf rest :test))))
    (when test-form
      (let (test two-arg-op)
        (cond ((setq test (and (quoted-form-p test-form) (%cadr test-form)))
               (when (setq two-arg-op (gethash test +two-arg-operators+))
                 (setf (getf rest :test) (list 'QUOTE two-arg-op))
                 (setq form `(,operator ,item ,sequence ,@rest))))
              ((setq test (and (consp test-form)
                               (length-eql test-form 2)
                               (eq (%car test-form) 'FUNCTION)
                               (%cadr test-form)))
               (when (setq two-arg-op (gethash test +two-arg-operators+))
                 (setf (getf rest :test) (list 'FUNCTION two-arg-op))
                 (setq form `(,operator ,item ,sequence ,@rest))))))))
  form)

(define-source-transform position (&whole form item sequence &rest rest)
  (transform-find/position form item sequence rest))

(define-source-transform find (&whole form item sequence &rest rest)
  (transform-find/position form item sequence rest))

(define-source-transform sys::backq-list (&rest args)
  (case (length args)
    (0
     nil)
    (1
     `(list1 ,@args))
    (2
     `(list2 ,@args))
    (3
     `(list3 ,@args))
    (4
     `(list4 ,@args))
    (5
     `(list5 ,@args))
    (t
     `(list ,@args))))

(define-source-transform sys::backq-list* (&rest args)
  `(list* ,@args))

(define-source-transform sys::backq-append (&rest args)
  (cond ((length-eql args 2)
         `(two-arg-append ,@args))
        (t
         `(append ,@args))))

(define-source-transform sys::backq-nconc (&rest args)
  `(nconc ,@args))

(define-source-transform sys::backq-cons (&rest args)
  `(cons ,@args))

(define-source-transform sbit (&whole form simple-bit-array &rest subscripts)
  (cond ((length-eql subscripts 1)
         (let ((vector (gensym))
               (index (gensym)))
           `(let ((,vector ,simple-bit-array)
                  (,index ,(%car subscripts)))
              (check-fixnum-bounds ,index 0 (1- (length (the simple-bit-vector ,vector))))
              (%sbit1 (truly-the simple-bit-vector ,vector) ,index))))
        (t
         form)))

(define-source-transform set-sbit1 (&whole form &rest args)
  (cond ((length-eql args 3)
         (let ((vector (gensym))
               (index (gensym))
               (new-value (gensym)))
           `(let ((,vector ,(%car args))
                  (,index ,(%cadr args))
                  (,new-value ,(%caddr args)))
              (check-fixnum-bounds ,index 0 (1- (length (the simple-bit-vector ,vector))))
              (%set-sbit1 (truly-the simple-bit-vector ,vector) ,index (the bit ,new-value)))))
        (t
         form)))

(define-source-transform caar (&whole form arg)
  (cond ((length-eql form 2)
         `(car (car ,arg)))
        (t
         form)))

(defun transform-cadr (form arg)
  (cond ((length-eql form 2)
         `(car (cdr ,arg)))
        (t
         form)))

(define-source-transform cadr (&whole form arg)
  (transform-cadr form arg))

(define-source-transform second (&whole form arg)
  (transform-cadr form arg))

(defun transform-caddr (form arg)
  (cond ((length-eql form 2)
         `(car (cdr (cdr ,arg))))
        (t
         form)))

(define-source-transform caddr (&whole form arg)
  (transform-caddr form arg))

(define-source-transform third (&whole form arg)
  (transform-caddr form arg))

(define-source-transform memq (&whole form item-arg list-arg)
  (cond ((and (quoted-form-p list-arg)
              (listp (%cadr list-arg)))
         (let ((item (gensym)))
           (labels ((rec (tail)
                         (if tail
                             `(if (eq item ',(car tail))
                                  ',tail
                                  ,(rec (cdr tail)))
                             nil)))
             `(let ((item ,item-arg)) ,(rec (%cadr list-arg))))))
        (t
         form)))

(define-source-transform byte-size (&whole form arg)
  (mumble "byte-size source-transform~%")
  (cond ((length-eql form 2)
         `(car ,arg))
        (t
         form)))

(define-source-transform byte-position (&whole form arg)
  (mumble "byte-position source-transform~%")
  (cond ((length-eql form 2)
         `(cdr ,arg))
        (t
         form)))

(define-source-transform read-byte (&whole form &rest args)
  (case (length args)
    (1
     `(%read-byte ,(%car args) t nil))
    (2
     `(%read-byte ,(%car args) ,(%cadr args) nil))
    (3
     `(%read-byte ,(%car args) ,(%cadr args) ,(%caddr args)))
    (t
     form)))

(defun transform-numeric-comparison (form)
  (let ((args (cdr form)))
    (case (length args)
      (3
       (let* ((op (%car form))
              (arg1 (%car args))
              (arg2 (%cadr args))
              (arg3 (%caddr args)))
         (cond ((and (eq arg1 arg3)
                     (memq op '(<= >=))
                     (fixnump arg1)
                     (fixnump arg3))
                (let* ((x (gensym)))
                  `(let* ((,x ,arg2))
                     (= ,x ,arg1))))
               (t
                (let* ((x (gensym))
                       (y (gensym))
                       (z (gensym))
                       (two-arg-op (ecase op
                                     (< 'two-arg-<)
                                     (> 'two-arg->)
                                     (<= 'two-arg-<=)
                                     (>= 'two-arg->=))))
                  `(let* ((,x ,arg1)
                          (,y ,arg2)
                          (,z ,arg3))
                     (when (,two-arg-op ,x ,y)
                       (,two-arg-op ,y ,z))))))))
      (t
       form))))

(define-source-transform < (&whole form &rest args)
  (transform-numeric-comparison form))

(define-source-transform > (&whole form &rest args)
  (transform-numeric-comparison form))

(define-source-transform <= (&whole form &rest args)
  (transform-numeric-comparison form))

(define-source-transform <= (&whole form &rest args)
  (transform-numeric-comparison form))
