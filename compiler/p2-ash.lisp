;;; p2-ash.lisp
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

;; REVIEW move to kernel?
(defconstant +bits-per-word+
  #+x86    32
  #+x86-64 64)

;; #+x86-64
(defun p2-ash (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args)))
      ;; REVIEW what about arguments of the wrong type in safe code?
      (when (null target)
        (p2 arg1 nil)
        (p2 arg2 nil)
        (maybe-emit-clear-values arg1 arg2)
        (return-from p2-ash t))
      (let* ((type1 (derive-type arg1))
             (type2 (derive-type arg2))
             (result-type (derive-type form))
             (shift (integer-constant-value type2)))
        (unless (fixnump arg1)
          (when (and (integer-constant-value type1)
                     (flushable arg1))
            (setq arg1 (integer-constant-value type1))))
        (unless (fixnump arg2)
          (when (and (integer-constant-value type2)
                     (flushable arg2))
            (setq arg2 (integer-constant-value type2))))
        (when (and (integerp arg1) (integerp arg2))
          (p2-constant (ash arg1 arg2) target)
          (return-from p2-ash t))
        (cond ((and (integer-constant-value type1)
                    shift)
               ;; both args evaluate to constants
               (mumble "p2-ash case 0~%")
               (let ((must-clear-values nil))
                 (unless (flushable arg1)
                   (p2 arg1 nil)
                   (unless (single-valued-p arg1)
                     (setq must-clear-values t)))
                 (unless (flushable arg2)
                   (p2 arg2 nil)
                   (unless (single-valued-p arg2)
                     (setq must-clear-values t)))
                 (when must-clear-values
                   (emit-clear-values)))
               (p2-constant (ash (integer-constant-value type1) shift) target)
               t)
              ((eql shift 0)
               ;; zero shift
               (cond ((flushable arg2)
                      (cond ((or (integer-type-p type1) (zerop *safety*))
                             (mumble "p2-ash zero shift case 1a~%")
                             (process-1-arg arg1 target t))
                            (t
                             (mumble "p2-ash zero shift case 1b~%")
                             (process-1-arg arg1 :default t)
                             (emit-call-1 'require-integer target)))) ; require-integer returns its argument
                     (t ; arg2 not flushable
                      (mumble "p2-ash zero shift case 1c~%")
                      (process-2-args args '(:rdi :rcx) t) ; FIXME don't emit an instruction to trash $cx
                      (emit-call-1 'require-integer target)))) ; require-integer returns its argument
              ((and (eql (integer-constant-value type1) 0)
                    (or (integer-type-p type2) (zerop *safety*)))
               ;; integer arg evaluates to 0, so shift arg doesn't matter (as long as it's an integer)
               (mumble "p2-ash case 2~%")
               (unless (flushable arg1)
                 (p2 arg1 nil))
               (unless (flushable arg2)
                 (p2 arg2 nil))
               (p2-constant 0 target))
              ((and (fixnum-type-p type1)
                    (fixnum-type-p type2)
                    (fixnum-type-p result-type))
               ;; args and result are all fixnum-type-p
               (cond ((and shift (< (abs shift) +bits-per-word+))
                      (aver (neq shift 0))
                      (cond ((flushable arg2)
                             (let ((reg (if (register-p target) target $ax)))
                               (process-1-arg arg1 reg t)
                               (cond ((< shift 0)
                                      (mumble "p2-ash all fixnum-type-p case 3a~%")
                                      (inst :sar (- shift) reg)
                                      (inst :and #xfc (reg8 reg))) ; clear tag bits
                                     (t
                                      (mumble "p2-ash all fixnum-type-p case 3b~%")
                                      (inst :shl shift reg)))
                               (clear-register-contents reg)
                               (unless (eq reg target)
                                 (move-result-to-target target))))
                            (t ; arg2 not flushable
                             (process-2-args args `(,$ax ,$cx) t)
                             (unbox-fixnum $cx)
                             (cond ((< shift 0)
                                    (mumble "p2-ash all fixnum-type-p case 3c~%")
                                    (inst :neg $cx)
                                    (inst :sar :cl $ax)
                                    (inst :and #xfc :al)) ; clear tag bits
                                   (t
                                    (mumble "p2-ash all fixnum-type-p case 3d~%")
                                    (inst :shl :cl $ax)))
                             (move-result-to-target target))))
                     ((subtypep type2 `(INTEGER ,(- (1- +bits-per-word+)) 0))
                      (mumble "p2-ash all fixnum-type-p case 3e type2 = ~S~%" type2)
                      (process-2-args args `(,$ax ,$cx) t)
                      (unbox-fixnum $cx)
                      (inst :neg $cx)
                      (inst :sar :cl $ax)
                      (inst :and #xfc :al) ; clear tag bits
                      (clear-register-contents $ax $cx)
                      (move-result-to-target target))
                     ((subtypep type2 `(INTEGER 0 ,(1- +bits-per-word+)))
                      (mumble "p2-ash all fixnum-type-p case 3f type2 = ~S~%" type2)
                      (process-2-args args `(,$ax ,$cx) t)
                      (unbox-fixnum $cx)
                      (inst :shl :cl $ax)
                      (clear-register-contents $ax $cx)
                      (move-result-to-target target))
                     (t
                      (mumble "p2-ash all fixnum-type-p case 3g~%")
                      (mumble "p2-ash full call 1 type1 = ~S type2 = ~S result-type = ~S~%"
                              type1 type2 result-type)
                      (process-2-args args :default t)
                      (emit-call-2 'ash target))))
              ((and shift (< shift 0) (> shift (- +bits-per-word+)))
               ;; negative shift, arg1 and/or result not known to be fixnum-type-p
               (let ((FULL-CALL (make-label))
                     (EXIT (make-label)))
                 (cond ((flushable arg2)
                        (mumble "p2-ash case 4a~%")
                        (process-1-arg arg1 $ax t)
                        (unless (fixnum-type-p type1)
                          (inst :test +fixnum-tag-mask+ :al)
                          (emit-jmp-short :nz FULL-CALL))
                        (inst :sar (- shift) $ax)
                        (inst :and #xfc :al) ; clear tag bits
                        (clear-register-contents $ax)
                        (unless (fixnum-type-p type1)
                          (emit-jmp-short t EXIT)
                          (let ((*current-segment* :elsewhere))
                            (label FULL-CALL)
                            #+x86    (progn
                                       (inst :push (fixnumize shift))
                                       (inst :push :eax))
                            #+x86-64 (progn
                                       (inst :mov :rax :rdi)
                                       (inst :mov (fixnumize shift) :rsi))
                            (emit-call 'ash)
                            #+x86    (inst :add (* 2 +bytes-per-word+) :esp)
                            (emit-jmp-short t EXIT))
                          (label EXIT)))
                       (t
                        (mumble "p2-ash case 4b~%")
                        (process-2-args args `(,$ax ,$cx) t)
                        (unless (fixnum-type-p type1)
                          (inst :test +fixnum-tag-mask+ :al)
                          (emit-jmp-short :nz FULL-CALL))
                        (inst :sar (- shift) $ax)
                        (inst :and #xfc :al) ; clear tag bits
                        (clear-register-contents $ax)
                        (unless (fixnum-type-p type1)
                          (emit-jmp-short t EXIT)
                          (let ((*current-segment* :elsewhere))
                            (label FULL-CALL)
                            #+x86    (progn
                                       (inst :push :ecx)
                                       (inst :push :eax))
                            #+x86-64 (progn
                                       (inst :mov :rax :rdi)
                                       (inst :mov :rcx :rsi))
                            (emit-call 'ash)
                            #+x86    (inst :add (* 2 +bytes-per-word+) :esp)
                            (emit-jmp-short t EXIT))
                          (label EXIT))))
                 (move-result-to-target target)))
              #+x86-64
              ((and shift (> shift 0) (< shift +bits-per-word+)
                    (fixnum-type-p type1)
                    (subtypep result-type `(unsigned-byte ,+bits-per-word+)))
               (mumble "p2-ash case 5~%")
               (process-2-args args '(:rax :rcx) t)
               (unbox-fixnum :rax)
               (unbox-fixnum :rcx)
               (inst :shl :cl :rax)
               (inst :mov :rax :rdi)
               (emit-call "RT_make_unsigned_integer")
               (move-result-to-target target))
              #+x86-64
              ((and (subtypep type1 'unsigned-byte)
                    (subtypep type2 `(integer ,(- (1- +bits-per-word+)) ,(1- +bits-per-word+)))
                    (subtypep result-type '(unsigned-byte 64)))
               (mumble "p2-ash case 6~%")
               (let ((FULL-CALL (make-label))
                     (RIGHT-SHIFT (make-label))
                     (BIGNUM (make-label))
                     (EXIT (make-label)))
                 (let ((*current-segment* :elsewhere))
                   (label BIGNUM)
                   (inst :mov :rax :rdi)
                   (emit-call "RT_make_unsigned_bignum")
                   (emit-jmp-short t EXIT)
                   (unless (fixnum-type-p type1)
                     (label FULL-CALL)
                     (emit-call 'ash))
                   (emit-jmp-short t EXIT))
                 (process-2-args args '(:rax :rcx) t)
                 (clear-register-contents :rax :rcx :rdi :rsi :rdx)
                 ;; save boxed args in case we need to do a full call
                 (inst :mov :rax :rdi)
                 (inst :mov :rcx :rsi)
                 (unless (fixnum-type-p type1)
                   (inst :test +fixnum-tag-mask+ :al)
                   (emit-jmp-short :nz FULL-CALL))
                 (unbox-fixnum :rcx)
                 (unbox-fixnum :rax)
                 (inst :test :rcx :rcx)
                 (emit-jmp-short :s RIGHT-SHIFT)
                 ;; left shift
                 (inst :shl :cl :rax)
                 (inst :mov (ldb (byte 64 0) (lognot most-positive-fixnum)) :rdx)
                 (inst :test :rax :rdx)
                 (emit-jmp-short :nz BIGNUM)
                 (box-fixnum :rax)
                 (emit-jmp-short t EXIT)
                 (label RIGHT-SHIFT)
                 (inst :neg :rcx)
                 (inst :sar :cl :rax)
                 ;; if number was a fixnum and shift is negative, result must be a fixnum
                 (box-fixnum :rax)
                 (label EXIT)
                 (move-result-to-target target)))
              (t
               (mumble "p2-ash default case type1 = ~S type2 = ~S result-type = ~S~%"
                       type1 type2 result-type)
               (process-2-args args :default t)
               (emit-call-2 'ash target)))))
    t))

;; #+x86-64
#+nil
(defun p2-ash (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1
           type2
           result-type
           shift)
      (when (null target)
        (p2 arg1 nil)
        (p2 arg2 nil)
        (maybe-emit-clear-values arg1 arg2)
        (return-from p2-ash t))
      (when (and (integerp arg1) (integerp arg2))
        (p2-constant (ash arg1 arg2) target)
        (return-from p2-ash t))
      (setq type1 (derive-type arg1)
            type2 (derive-type arg2)
            result-type (derive-type form)
            shift (integer-constant-value type2))
      (cond ((and (integer-constant-value type1)
                  shift)
             (let ((must-clear-values nil))
               (unless (flushable arg1)
                 (p2 arg1 nil)
                 (unless (single-valued-p arg1)
                   (setq must-clear-values t)))
               (unless (flushable arg2)
                 (p2 arg2 nil)
                 (unless (single-valued-p arg2)
                   (setq must-clear-values t)))
               (when must-clear-values
                 (emit-clear-values)))
             (p2-constant (ash (integer-constant-value type1) shift) target)
             t)
            ((and (eql shift 0)
                  (flushable arg2)
                  (or (integer-type-p type1)
                      (zerop *safety*)))
             (p2 arg1 target)
             (unless (single-valued-p arg1)
               (emit-clear-values :preserve target))
             t)
            ((and (eql (integer-constant-value type1) 0)
                  (or (integer-type-p type2)
                      (zerop *safety*)))
             (unless (flushable arg1)
               (p2 arg1 nil))
             (unless (flushable arg2)
               (p2 arg2 nil))
             (p2-constant 0 target)
             t)
            ((and (fixnum-type-p type1)
                  (fixnum-type-p type2)
                  (fixnum-type-p result-type))
             (cond ((and shift
                         (< shift 0)
                         (> shift -64))
                    (cond ((flushable arg2)
                           (process-1-arg arg1 :rax t)
                           (inst :sar (- shift) :rax)
                           (clear-register-contents :rax))
                          (t
                           (process-2-args args '(:rax :rcx) t)
                           (unbox-fixnum :rcx)
                           (inst :neg :rcx)
                           (emit-bytes #x48 #xd3 #xf8) ; sar %cl,%rax
                           (clear-register-contents :rax :rcx)))
                    ;; clear tag bits
                    (inst :and #xfc :al)
                    (move-result-to-target target)
                    t)
                   ((and shift
                         (>= shift 0)
                         (< shift 64))
                    (cond ((flushable arg2)
                           (process-1-arg arg1 :rax t)
                           (unless (eql shift 0)
                             (emit-bytes #x48 #xc1 #xe0 shift) ; shl imm8,%rax
                             (clear-register-contents :rax)))
                          (t
                           (process-2-args args '(:rax :rcx) t)
                           (unbox-fixnum :rcx)
                           (inst :shl :cl :rax)
                           (clear-register-contents :rax :rcx)))
                    (move-result-to-target target)
                    t)
                   ((subtypep type2 '(INTEGER -63 0))
                    (process-2-args args '(:rax :rcx) t)
                    (unbox-fixnum :rcx)
                    (inst :neg :rcx)
                    (inst :sar :cl :rax)
                    ;; zero out tag bits
                    (inst :and #xfc :al)
                    (clear-register-contents :rax)
                    (move-result-to-target target)
                    t)
                   ((subtypep type2 '(INTEGER 0 63))
                    (process-2-args args '(:rax :rcx) t)
                    (unbox-fixnum :rcx)
                    (inst :shl :cl :rax)
                    (clear-register-contents :rax)
                    (move-result-to-target target)
                    t)
                   (t
                    (mumble "p2-ash full call 1 type1 = ~S type2 = ~S result-type = ~S~%"
                            type1 type2 result-type)
                    (process-2-args args '(:rdi :rsi) t)
                    (emit-call 'ash)
                    (move-result-to-target target)
                    t)))
            ((and (integer-type-p type1)
                  (eql shift 0)
                  (flushable arg2))
             (p2 arg1 target)
             t)
            ((eql shift 0)
             ;; zero shift general case
             (process-2-args args '(:rax :rcx) t)
             (inst :mov :rax :rdi)
             (emit-call 'require-integer) ; require-integer returns its argument
             (move-result-to-target target)
             t)
            ((and shift
                  (< shift 0)
                  (> shift -64))
             (let ((FULL-CALL (make-label))
                   (EXIT (make-label)))
               (cond ((flushable arg2)
                      (process-1-arg arg1 :rax t)
                      (unless (fixnum-type-p type1)
                        (inst :test +fixnum-tag-mask+ :al)
                        (emit-jmp-short :nz FULL-CALL))
                      (inst :sar (- shift) :rax)
                      ;; zero out tag bits
                      (inst :and #xfc :al)
                      (clear-register-contents :rax)
                      (unless (fixnum-type-p type1)
                        (emit-jmp-short t EXIT)
                        (let ((*current-segment* :elsewhere))
                          (label FULL-CALL)
                          (inst :mov :rax :rdi)
                          (inst :mov (fixnumize shift) :rsi)
                          (emit-call 'ash)
                          (emit-jmp-short t EXIT))
                        (label EXIT)))
                     (t
                      (process-2-args args '(:rax :rcx) t)
                      (unless (fixnum-type-p type1)
                        (inst :test +fixnum-tag-mask+ :al)
                        (emit-jmp-short :nz FULL-CALL))
                      (inst :sar (- shift) :rax)
                      ;; zero out tag bits
                      (inst :and #xfc :al)
                      (clear-register-contents :rax)
                      (unless (fixnum-type-p type1)
                        (emit-jmp-short t EXIT)
                        (let ((*current-segment* :elsewhere))
                          (label FULL-CALL)
                          (inst :mov :rax :rdi)
                          (inst :mov :rcx :rsi)
                          (emit-call 'ash)
                          (emit-jmp-short t EXIT))
                        (label EXIT))))
               (move-result-to-target target))
             t)
            ((and shift
                  (> shift 0)
                  (<= shift 32)
                  (fixnum-type-p type1)
                  (subtypep result-type '(unsigned-byte 64)))
             (process-2-args args '(:rax :rcx) t)
             (unbox-fixnum :rax)
             (unbox-fixnum :rcx)
             (inst :shl :cl :rax)
             (inst :mov :rax :rdi)
             (emit-call "RT_make_unsigned_integer")
             (move-result-to-target target)
             t)
            ((and (subtypep type1 'unsigned-byte)
                  (subtypep type2 '(integer -31 31)) ; REVIEW
                  (subtypep result-type '(unsigned-byte 64)))
             (let ((FULL-CALL (make-label))
                   (RIGHT-SHIFT (make-label))
                   (BIGNUM (make-label))
                   (EXIT (make-label)))
               (let ((*current-segment* :elsewhere))
                 (label BIGNUM)
                 (inst :mov :rax :rdi)
                 (emit-call "RT_make_unsigned_bignum")
                 (emit-jmp-short t EXIT)
                 (unless (fixnum-type-p type1)
                   (label FULL-CALL)
                   (emit-call 'ash))
                 (emit-jmp-short t EXIT))
               (process-2-args args '(:rax :rcx) t)
               (clear-register-contents :rax :rcx :rdi :rsi :rdx)
               ;; save boxed args in case we need to do a full call
               (inst :mov :rax :rdi)
               (inst :mov :rcx :rsi)
               (unless (fixnum-type-p type1)
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz FULL-CALL))
               (unbox-fixnum :rcx)
               (unbox-fixnum :rax)
               (inst :test :rcx :rcx)
               (emit-jmp-short :s RIGHT-SHIFT)
               ;; left shift
               (inst :shl :cl :rax)
               (inst :mov (ldb (byte 64 0) (lognot most-positive-fixnum)) :rdx)
               (inst :test :rax :rdx)
               (emit-jmp-short :nz BIGNUM)
               (box-fixnum :rax)
               (emit-jmp-short t EXIT)
               (label RIGHT-SHIFT)
               (inst :neg :rcx)
               (inst :sar :cl :rax)
               ;; if number was a fixnum and shift is negative, result must be a fixnum
               (box-fixnum :rax)
               (label EXIT)
               (move-result-to-target target))
             t)
            (t
             (mumble "p2-ash full call 2 type1 = ~S type2 = ~S result-type = ~S~%"
                     type1 type2 result-type)
             (process-2-args args '(:rdi :rsi) t)
             (emit-call 'ash)
             (move-result-to-target target)
             t)))))

;; #+x86
#+nil
(defun p2-ash (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1
           type2
           result-type
           shift)
      (when (null target)
        (p2 arg1 nil)
        (p2 arg2 nil)
        (maybe-emit-clear-values arg1 arg2)
        (return-from p2-ash t))
      (when (and (integerp arg1) (integerp arg2))
        (p2-constant (ash arg1 arg2) target)
        (return-from p2-ash t))
      (setq type1 (derive-type arg1)
            type2 (derive-type arg2)
            result-type (derive-type form)
            shift (integer-constant-value type2))
      (cond ((and (integer-constant-value type1)
                  shift)
             (let ((must-clear-values nil))
               (unless (flushable arg1)
                 (p2 arg1 nil)
                 (unless (single-valued-p arg1)
                   (setq must-clear-values t)))
               (unless (flushable arg2)
                 (p2 arg2 nil)
                 (unless (single-valued-p arg2)
                   (setq must-clear-values t)))
               (when must-clear-values
                 (emit-clear-values)))
             (p2-constant (ash (integer-constant-value type1) shift) target)
             t)
            ((and (eql shift 0)
                  (flushable arg2)
                  (or (integer-type-p type1)
                      (zerop *safety*)))
             (p2 arg1 target)
             (unless (single-valued-p arg1)
               (emit-clear-values :preserve target))
             t)
            ((and (eql (integer-constant-value type1) 0)
                  (or (integer-type-p type2)
                      (zerop *safety*)))
             (unless (flushable arg1)
               (p2 arg1 nil))
             (unless (flushable arg2)
               (p2 arg2 nil))
             (p2-constant 0 target)
             t)
            ((and (fixnum-type-p type1)
                  (fixnum-type-p type2)
                  (fixnum-type-p result-type))
             (cond ((and shift
                         (< shift 0)
                         (> shift -32))
                    (cond ((flushable arg2)
                           (process-1-arg arg1 :eax t)
                           (inst :sar (- shift) :eax)
                           (clear-register-contents :eax))
                          (t
                           (process-2-args args '(:eax :ecx) t)
                           (unbox-fixnum :ecx)
                           (inst :neg :ecx)
                           (inst :sar :cl :eax)
                           (clear-register-contents :eax :ecx)))
                    ;; clear tag bits
                    (inst :and #xfc :al)
                    (move-result-to-target target)
                    t)
                   ((and shift
                         (>= shift 0)
                         (< shift 32))
                    (cond ((flushable arg2)
                           (process-1-arg arg1 :eax t)
                           (unless (eql shift 0)
                             (inst :shl shift :eax)
                             (clear-register-contents :eax)))
                          (t
                           (process-2-args args '(:eax :ecx) t)
                           (unbox-fixnum :ecx)
                           (emit-bytes #xd3 #xe0) ; shl %cl,%rax
                           (clear-register-contents :eax :ecx)))
                    (move-result-to-target target)
                    t)
                   (t
                    (mumble "p2-ash full call 1 type1 = ~S type2 = ~S result-type = ~S~%"
                            type1 type2 result-type)
                    (process-2-args args :stack t)
                    (emit-call-2 'ash target)
                    t)))
            ((and (subtypep type1 '(unsigned-byte 32))
                  (fixnum-type-p type2)
                  (fixnum-type-p result-type))
             (cond ((and shift
                         (< shift 0)
                         (> shift -32)
                         (flushable arg2))
                    (let ((EXIT (make-label))
                          (NOT-FIXNUM (make-label)))
                      (process-1-arg arg1 :eax t)
                      (inst :test +fixnum-tag-mask+ :al)
                      (emit-jmp-short :nz NOT-FIXNUM)
                      (cond ((> (- shift +fixnum-shift+) -32)
                             (inst :shr (- (- shift +fixnum-shift+)) :eax))
                            (t
                             (unbox-fixnum :eax)
                             (inst :shr (- shift) :eax)))
                      (box-fixnum :eax)
                      (emit-jmp-short t EXIT)
                      (label NOT-FIXNUM)
                      (inst :push :eax)
                      (emit-call-1 "RT_unsigned_byte_to_raw_ub32" :eax)
                      (inst :shr (- shift) :eax)
                      (box-fixnum :eax)
                      (label EXIT)
                      (move-result-to-target target))
                    t)
                   (t
                    (mumble "p2-ash full call 2 type1 = ~S type2 = ~S result-type = ~S~%"
                            type1 type2 result-type)
                    (process-2-args args :stack t)
                    (emit-call-2 'ash target)
                    t)))
            (t
             (mumble "p2-ash full call 3 type1 = ~S type2 = ~S result-type = ~S~%"
                     type1 type2 result-type)
             (process-2-args args :stack t)
             (emit-call-2 'ash target)
             t)))))
