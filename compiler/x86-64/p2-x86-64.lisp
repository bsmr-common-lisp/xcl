;;; p2-x86-64.lisp
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

(defknown emit-clear-values (*) t)
(defun emit-clear-values (&key preserve)
  (setq preserve (designator-list preserve))
  (let ((thread-register (compiland-thread-register *current-compiland*)))
    (cond ((and (eq thread-register :r12)
                (not (memq :r12 preserve)))
           (inst :movb #xff `(,+values-length-offset+ :r12)))
          (t
           (note "EMIT-CLEAR-VALUES: emitting call to RT_current_thread_clear_values~%")
           (dolist (reg preserve)
             (inst :push reg))
           (emit-call "RT_current_thread_clear_values")
           (dolist (reg (nreverse preserve))
             (inst :pop reg))))))

(defknown emit-return () t)
(defun emit-return ()
  (emit-byte #xc3))

(defknown emit-exit () t)
(defun emit-exit()
  (inst :exit))

(defknown emit-call-n (t t t) t)
(defun emit-call-n (address target n)
  (declare (ignore n))
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-0 (t t) t)
(defun emit-call-0 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-1 (t t) t)
(defun emit-call-1 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-2 (t t) t)
(defun emit-call-2 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-3 (t t) t)
(defun emit-call-3 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-4 (t t) t)
(defun emit-call-4 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-5 (t t) t)
(defun emit-call-5 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-6 (t t) t)
(defun emit-call-6 (address target)
  (emit-call address)
  (move-result-to-target target))

(defknown emit-call-7 (t t) t)
(defun emit-call-7 (address target)
  (emit-call address)
  (move-result-to-target target))

;; index-displacement index => displacement
;; 0 => -8
;; 1 => -16
;; 2 => -24
;; etc.
(defknown index-displacement (fixnum) fixnum)
(defun index-displacement (index)
  (declare (type fixnum index))
  (* (1+ index) (- +bytes-per-word+)))

(defknown emit-move-local-to-register (t t) t)
(defun emit-move-local-to-register (index to)
  (declare (type fixnum index))
  (let ((displacement (index-displacement index)))
    (aver (minusp displacement))
;;     (cond ((>= displacement -128)
;;            (let ((displacement-byte (ldb (byte 8 0) displacement)))
;;              (case to
;;                (:r8
;;                 (emit-bytes #x4c #x8b #x45 displacement-byte))
;;                (:r9
;;                 (emit-bytes #x4c #x8b #x4d displacement-byte))
;;                (:r12
;;                 (emit-bytes #x4c #x8b #x65 displacement-byte))
;;                (t
;;                 (let* ((mod #b01)
;;                        (reg (register-number to))
;;                        (rm  (register-number :rbp))
;;                        (modrm-byte (make-modrm-byte mod reg rm)))
;;                   (emit-bytes #x48 #x8b modrm-byte displacement-byte))))))
;;           (t
;;            (case to
;;              (:r8
;;               (emit-bytes #x4c #x8b #x85)
;;               (emit-raw-dword displacement))
;;              (:r9
;;               (emit-bytes #x4c #x8b #x8d)
;;               (emit-raw-dword displacement))
;;              (:r12
;;               (emit-bytes #x4c #x8b #xa5)
;;               (emit-raw-dword displacement))
;;              (t
;;               (let* ((mod #b10)
;;                      (reg (register-number to))
;;                      (rm  (register-number :rbp))
;;                      (modrm-byte (make-modrm-byte mod reg rm)))
;;                 (emit-bytes #x48 #x8b modrm-byte)
;;                 (emit-raw-dword displacement))))))
    (inst :mov `(,displacement :rbp) to)
    ))

(defknown emit-move-register-to-local (t t) t)
(defun emit-move-register-to-local (from index)
  (declare (type fixnum index))
  (let ((displacement (index-displacement index)))
    (aver (minusp displacement))
    (cond ((eq from :r12)
           (cond ((>= displacement -128)
                  (let ((displacement-byte (ldb (byte 8 0) displacement)))
                    (emit-bytes #x4c #x89 #x65)
                    (emit-byte displacement-byte)))
                 (t
                  (emit-bytes #x4c #x89 #xa5)
                  (emit-raw-dword displacement))))
          ((>= displacement -128)
           (let* ((displacement-byte (ldb (byte 8 0) displacement))
                  (mod #b01)
                  (reg (register-number from))
                  (rm  (register-number :rbp))
                  (modrm-byte (make-modrm-byte mod reg rm)))
;;              (emit (make-instruction :bytes
;;                                      4
;;                                      (list #x48 #x89 modrm-byte displacement-byte)))
;;              (inst :bytes #x48 #x89 modrm-byte displacement-byte)
             (emit-bytes #x48 #x89 modrm-byte displacement-byte)
             ))
          (t
           (let* ((mod #b10)
                  (reg (register-number from))
                  (rm  (register-number :rbp))
                  (modrm-byte (make-modrm-byte mod reg rm)))
             (emit-bytes #x48 #x89 modrm-byte)
             (emit-raw-dword displacement))))))

(defknown emit-move-var-to-register (var t) t)
(defun emit-move-var-to-register (var register)
  (declare (type var var))
;;   (aver (fixnump (var-index var)))
;;   (emit-move-local-to-register (var-index var) register)
  (inst :mov var register)
  )

(defknown emit-move-register-to-var (var t) t)
(defun emit-move-register-to-var (register var)
  (declare (type var var))
;;   (aver (fixnump (var-index var)))
;;   (emit-move-register-to-local register (var-index var))
  (inst :mov register var)
  )

(defun %emit-move-relative-to-register (from-reg displacement to-reg)
;;   (cond ((<= 0 displacement 127)
;;          (let* ((mod #b01)
;;                 (reg (register-number to-reg))
;;                 (rm  (register-number from-reg))
;;                 (modrm-byte (make-modrm-byte mod reg rm)))
;;            (emit (make-instruction :bytes
;;                                    4
;;                                    (list #x48 #x8b modrm-byte displacement)))))
;;         ((<= 0 displacement #x7fffffff)
;;          (let* ((mod #b10)
;;                 (reg (register-number to-reg))
;;                 (rm  (register-number from-reg))
;;                 (modrm-byte (make-modrm-byte mod reg rm)))
;;            (emit-bytes #x48 #x8b modrm-byte)
;;            (emit-raw-dword displacement)))
;;         (t
;;          (compiler-unsupported "%EMIT-MOVE-RELATIVE-TO-REGISTER unsupported situation"))))
  (inst :mov `(,displacement ,from-reg) to-reg))

(defknown emit-move-relative-to-register (t t t) t)
(defun emit-move-relative-to-register (from-reg index to-reg)
  (cond ((and (eq from-reg :rsp)
              (eql index 0)
              (eq to-reg :r8))
         (emit-bytes #x4c #x8b #x04 #x24))
        (t
         (let ((displacement (* index +bytes-per-word+)))
           (%emit-move-relative-to-register from-reg displacement to-reg)))))

(defknown %emit-move-register-to-relative (t t t) t)
(defun %emit-move-register-to-relative (from-reg to-reg displacement)
  (when (extended-register-p to-reg)
    (compiler-unsupported "EMIT-MOVE-REGISTER-TO-RELATIVE unsupported to-reg ~S" to-reg))
  (let ((prefix-byte (if (extended-register-p from-reg) #x4c #x48)))
    (cond ((and (eq from-reg :rax)
                (eq to-reg   :rsp))
           (cond ((zerop displacement)
                  (emit-bytes prefix-byte #x89 #x04 #x24))
                 ((< 0 displacement 128)
                  (emit-bytes prefix-byte #x89 #x44 #x24 displacement))
                 ((< 0 displacement #x7fffffff)
                  (emit-bytes prefix-byte #x89 #x84 #x24)
                  (emit-raw-dword displacement))
                 (t
                  (unsupported))))
          ((<= 0 displacement 127)
           (let* ((mod #b01)
                  (reg (register-number from-reg))
                  (rm  (register-number to-reg))
                  (modrm-byte (make-modrm-byte mod reg rm)))
             (emit-bytes prefix-byte #x89 modrm-byte displacement)))
          ((<= 0 displacement #x7fffffff)
           (let* ((mod #b10)
                  (reg (register-number from-reg))
                  (rm  (register-number to-reg))
                  (modrm-byte (make-modrm-byte mod reg rm)))
             (emit-bytes prefix-byte #x89 modrm-byte)
             (emit-raw-dword displacement)))
          (t
           (compiler-unsupported "EMIT-MOVE-REGISTER-TO-RELATIVE unsupported situation")))))

(defknown emit-move-register-to-relative (t t t) t)
(defun emit-move-register-to-relative (from-reg to-reg index)
  (when (extended-register-p to-reg)
    (compiler-unsupported "EMIT-MOVE-REGISTER-TO-RELATIVE unsupported to-reg ~S" to-reg))
  (let ((prefix-byte (if (extended-register-p from-reg) #x4c #x48))
        (displacement (* index +bytes-per-word+)))
    (cond ((and (eq from-reg :rax)
                (eq to-reg   :rsp))
           (cond ((zerop displacement)
                  (emit-bytes prefix-byte #x89 #x04 #x24))
                 ((< 0 displacement 128)
                  (emit-bytes prefix-byte #x89 #x44 #x24 displacement))
                 ((< 0 displacement #x7fffffff)
                  (emit-bytes prefix-byte #x89 #x84 #x24)
                  (emit-raw-dword displacement))
                 (t
                  (unsupported))))
          ((<= 0 displacement 127)
           (let* ((mod #b01)
                  (reg (register-number from-reg))
                  (rm  (register-number to-reg))
                  (modrm-byte (make-modrm-byte mod reg rm)))
             (emit-bytes prefix-byte #x89 modrm-byte displacement)))
          ((<= 0 displacement #x7fffffff)
           (let* ((mod #b10)
                  (reg (register-number from-reg))
                  (rm  (register-number to-reg))
                  (modrm-byte (make-modrm-byte mod reg rm)))
             (emit-bytes prefix-byte #x89 modrm-byte)
             (emit-raw-dword displacement)))
          (t
           (compiler-unsupported "EMIT-MOVE-REGISTER-TO-RELATIVE unsupported situation")))))

(defun emit-qword (n)
  (let ((x (value-to-ub64 n)))
    (let ((code (list (ldb (byte 8  0) x)
                      (ldb (byte 8  8) x)
                      (ldb (byte 8 16) x)
                      (ldb (byte 8 24) x)
                      (ldb (byte 8 32) x)
                      (ldb (byte 8 40) x)
                      (ldb (byte 8 48) x)
                      (ldb (byte 8 56) x))))
;;       (emit (make-instruction :bytes 8 code))
;;       (emit (list* :bytes code))
      (emit (make-ir2-instruction :bytes code nil))
      )))

(defknown emit-raw-dword (t) t)
(defun emit-raw-dword (n)
  (let ((code (list (ldb (byte 8  0) n)
                    (ldb (byte 8  8) n)
                    (ldb (byte 8 16) n)
                    (ldb (byte 8 24) n))))
;;     (emit (make-instruction :bytes 4 code))
;;     (emit (list* :bytes code))
    (emit (make-ir2-instruction :bytes code nil))
    ))

(defknown emit-dword (t) t)
(defun emit-dword (n)
  (let ((x (value-to-ub64 n)))
    (aver (<= x #x7fffffff))
    (emit-raw-dword x)))

(defun emit-raw-qword (n)
  (let ((code (list (ldb (byte 8 0) n)
                    (ldb (byte 8 8) n)
                    (ldb (byte 8 16) n)
                    (ldb (byte 8 24) n)
                    (ldb (byte 8 32) n)
                    (ldb (byte 8 40) n)
                    (ldb (byte 8 48) n)
                    (ldb (byte 8 56) n))))
;;     (emit (make-instruction :bytes 8 code))
;;     (emit (list* :bytes code))
    (emit (make-ir2-instruction :bytes code nil))
    ))

(defun emit-raw (x)
  (let ((code (list (ldb (byte 8 0) x)
                    (ldb (byte 8 8) x)
                    (ldb (byte 8 16) x)
                    (ldb (byte 8 24) x))))
;;     (emit (make-instruction :bytes 4 code))
;;     (emit (list* :bytes code))
    (emit (make-ir2-instruction :bytes code nil))
    ))

(defknown emit-move-immediate (t t) t)
(defun emit-move-immediate (n target)
  (when (eq target :return)
    (setq target :rax))
  (cond ((and (eql n 0)
              (memq target '(:rax :rcx :rdx :rbx :rsp :rbp :rsi :rdi)))
         (let ((reg32 (reg32 target)))
           (inst :xor reg32 reg32)))
        (t
         (inst :mov (value-to-ub64 n) target))))

(defun emit-move-immediate-dword-to-register (n reg)
  (cond ((eql n 0)
         (emit-byte #x31) ; XOR reg/mem32, reg32
         (emit-byte (make-modrm-byte #b11 (register-number reg) (register-number reg))))
        (t
         (emit-byte (+ #xb8 (register-number reg)))
         (emit-raw n))))

(defun emit-int-3 ()
  (emit-byte #xcc))

(defknown emit-push-immediate (t) t)
(defun emit-push-immediate (arg)
  (when (fixnump arg)
    (let ((n (value-to-ub64 arg)))
      (when (< n 128)
        (emit-bytes #x48 #x6a) ; push immediate byte (sign-extended to 64 bits)
        (emit-byte n)
        (return-from emit-push-immediate))))
  (emit-move-immediate arg :rax)
  (inst :push :rax)
  (clear-register-contents :rax))

(defknown move-result-to-target (t) t)
(defun move-result-to-target (target)
  (case target
    ((:rax nil)
     ;; nothing to do
     )
    ((:rcx :rdx :rbx :rsp :rbp :rsi :rdi :r8 :r9 :r10 :r11 :r12 :r13 :r14 :r15)
     (inst :mov :rax target)
     (clear-register-contents target))
    (:stack
     (inst :push :rax))
    (:return
     (emit-exit))
    (t
     (break)
     (compiler-unsupported "MOVE-RESULT-TO-TARGET target = ~S" target))))

(defknown emit-move-function-to-register (t t) t)
(defun emit-move-function-to-register (symbol register)
  (declare (type symbol form))
  (inst :move-immediate `(:function ,symbol) register))

(defknown p2-constant (t t) t)
(defun p2-constant (form target)
  (when target
    (cond ((or (fixnump form)
               (characterp form))
           (case target
             (:stack
              (emit-push-immediate form))
             ((:rax :rcx :rdx :rbx :rsp :rbp :rsi :rdi)
              (if (eql form 0)
                  (let ((reg32 (reg32 target)))
                    (inst :xor reg32 reg32))
                  (inst :mov (value-to-ub64 form) target))
              (clear-register-contents target))
             ((:r8 :r9 :r10 :r11 :r12 :r13 :r14 :r15)
              (emit-move-immediate form target)
              (clear-register-contents target))
             (:return
              (if (eql form 0)
                  (inst :xor :eax :eax)
                  (inst :mov (value-to-ub64 form) :rax))
              (clear-register-contents :rax)
              (emit-exit))
             (t
              (compiler-unsupported "P2-CONSTANT: unsupported target ~S" target))))
          ((or (numberp form)
               (symbolp form)
               (arrayp form)
               (listp form)
               (characterp form)
               (hash-table-p form)
               (packagep form)
               (functionp form) ; REVIEW
               (classp form))
           ;; REVIEW following code is for small data model (-mcmodel=small)
           (case target
             (:stack
              (inst :move-immediate (list :constant-32 form) :eax)
              (inst :push :rax)
              (clear-register-contents :rax))
             ((:rax :rcx :rdx :rbx :rsp :rbp :rsi :rdi)
              (inst :move-immediate (list :constant-32 form) (reg32 target))
              (clear-register-contents target))
             ((:r8 :r9 :r10 :r11 :r12 :r13 :r14 :r15)
              (inst :move-immediate (list :constant-32 form) target)
              (clear-register-contents target))
             (:return
              (inst :move-immediate (list :constant-32 form) :eax)
              (clear-register-contents :rax)
              (emit-exit))
             (t
              (compiler-unsupported "P2-CONSTANT: unsupported target ~S" target))))
          (t
           (compiler-unsupported "P2-CONSTANT: unsupported type ~S" (type-of form))))))

(defun p2-load-time-value (form target)
  (mumble "p2-load-time-value~%")
  (cond ((compile-file-p)
         (let* ((name (gensym)))
           (dump-top-level-form `(defvar ,name ,(cadr form)) *compile-file-output-stream*)
           (p2-constant name :rdi)
           (emit-call-1 'symbol-global-value target)))
        (t
         (p2-constant (eval (cadr form)) target))))

(defun p2-block (form target)
  (let* ((block (cadr form))
         (last-special-binding-var (block-last-special-binding-var block))
         (*visible-blocks* (cons block *visible-blocks*))
         (BLOCK-EXIT (make-label))
         (compiland *current-compiland*)
         (thread-register (compiland-thread-register compiland)))
    (declare (type cblock block))
    (declare (type compiland compiland))
    (when last-special-binding-var
      (aver thread-register)
      (cond (thread-register
             (inst :mov thread-register :rdi)
;;              (mumble "p2 block ~S emitting call to RT_thread_last_special_binding~%"
;;                         (block-name block))
             (emit-call "RT_thread_last_special_binding"))
            (t
             (emit-call "RT_current_thread_last_special_binding")))
;;       (emit-move-register-to-local :rax (var-index last-special-binding-var))
      (inst :mov :rax last-special-binding-var)
      )
    (setf (block-exit block) BLOCK-EXIT)
    (setf (block-target block) target)
    (cond ((block-non-local-return-p block)
;;            (mumble "p2-block ~S non-local return case~%" (block-name block))
           (let ((block-var (block-block-var block)))
             (aver block-var)
             (aver thread-register)
             (p2-symbol (block-name block) :rsi)
             (inst :mov thread-register :rdi)
             (emit-call "RT_enter_block")
             (emit-move-register-to-var :rax block-var)
             (inst :mov :rax :rdi)
             (emit-call "RT_frame_jmp")
             (inst :mov :rax :rdi)
             (emit-call "setjmp")
             (inst :test :al :al)
             (let ((LABEL1 (make-label)))
               (emit-jmp-short :nz LABEL1)
               (p2-progn-body (block-body block) :rax)
               (inst :push :rax) ; save result
               (inst :mov thread-register :rdi) ; thread
               (emit-move-var-to-register block-var :rsi) ; block
               (inst :sub +bytes-per-word+ :rsp) ; align stack
               (emit-call "RT_leave_block")
               (inst :add +bytes-per-word+ :rsp)
               (inst :pop :rax) ; restore result
               (emit-jmp-short t BLOCK-EXIT)
               (label LABEL1)
               (inst :mov thread-register :rdi) ; thread
               (emit-move-var-to-register block-var :rsi) ; block
               (emit-call "RT_block_non_local_return")
               (label BLOCK-EXIT))))
          (t
;;            (mumble "p2-block ~S default case, proceeding to progn body~%" (block-name block))
           (p2-progn-body (block-body block) :rax)
           (label BLOCK-EXIT)))
    (when last-special-binding-var
      ;; save rax
      (inst :push :rax)
      ;; fix stack alignment
      (inst :sub +bytes-per-word+ :rsp)
      ;; restore last special binding
      (cond (thread-register
             (p2-var-ref (make-var-ref last-special-binding-var) :rsi)
             (inst :mov thread-register :rdi)
;;              (mumble "p2 block ~S emitting call to RT_thread_set_last_special_binding~%"
;;                         (block-name block))
             (emit-call "RT_thread_set_last_special_binding"))
            (t
             (p2-var-ref (make-var-ref last-special-binding-var) :rdi)
             (emit-call "RT_current_thread_set_last_special_binding")))
      ;; restore rax
      (inst :add +bytes-per-word+ :rsp)
      (inst :pop :rax)
      )
    (move-result-to-target target)))

(defun p2-return-from (form target)
  (declare (ignore target))
  (let* ((name (second form))
         (result-form (third form))
         (block (find-visible-block name))
         (compiland *current-compiland*))
    (declare (type cblock block))
    (declare (type compiland compiland))
;;     (unless block
;;       (error "No block named ~S is currently visible." name))
;;     (mumble "p2-return-from block ~S~%" name)
    (aver (not (null (block-exit block))))
    (emit-clear-values) ; REVIEW
    (p2 result-form :rax)
    (cond ((eq (block-compiland block) compiland)
;;            (mumble "p2-return-from block ~S local return case~%" name)
           (dolist (enclosing-block *visible-blocks*)
             (declare (type cblock enclosing-block))
             (when (eq enclosing-block block)
               (return))
             (when (block-tagbody-var enclosing-block)
               (aver (compiland-thread-register compiland))
               (emit-move-var-to-register (block-tagbody-var enclosing-block) :rsi)
               (inst :mov :r12 :rdi) ; thread
               (inst :push :rax) ; save result
               (inst :push :rax) ; stack alignment
               (emit-call "RT_leave_tagbody")
               (inst :pop :rax) ; stack alignment
               (inst :pop :rax)) ; restore result
             (when (equal (block-name enclosing-block) '(UNWIND-PROTECT))
               (aver (block-cleanup-label enclosing-block))
               (inst :push :rax)
               (emit-call (block-cleanup-label enclosing-block))
               (inst :pop :rax)))
           (emit-jmp-short t (block-exit block)))
          (t
           ;; non-local return
;;            (mumble "p2-return-from block ~S non-local return case~%" name)
           (let ((thread-register (compiland-thread-register compiland)))
             (aver thread-register)
             (inst :push :rax) ; result
             (p2-symbol name :rsi)
             (inst :mov thread-register :rdi)
             (inst :pop :rdx) ; result
             (emit-call "RT_return_from")))))) ; doesn't return

(defun p2-catch (form target)
  (let* ((block (cadr form))
         (block-var (block-block-var block))
         (thread-register (compiland-thread-register *current-compiland*)))
    (declare (type cblock block))
    (aver block-var)
    (aver thread-register)
    (p2 (cadr (block-form block)) :rsi)
    (inst :mov thread-register :rdi)
    (emit-call "RT_enter_catch")
    (emit-move-register-to-var :rax block-var) ; catch-frame
    (inst :mov :rax :rdi)
    (emit-call "RT_frame_jmp")
    (inst :mov :rax :rdi)
    (emit-call "setjmp")
    (inst :test :al :al)
    (let ((LABEL1 (make-label))
          (EXIT (make-label)))
      (emit-jmp-short :nz LABEL1)
      (let ((*visible-blocks* (cons block *visible-blocks*)))
        (p2-progn-body (block-body block) :rax))
      (inst :push :rax) ; save result
      (inst :mov thread-register :rdi) ; thread
      (emit-move-var-to-register block-var :rsi) ; catch-frame
      (inst :sub +bytes-per-word+ :rsp) ; align stack
      (emit-call "RT_leave_catch")
      (inst :add +bytes-per-word+ :rsp)
      (inst :pop :rax) ; restore result
      (emit-jmp-short t EXIT)
      (label LABEL1)
      ;; caught THROW
      (inst :mov thread-register :rdi) ; thread
      (emit-move-var-to-register block-var :rsi) ; catch-frame
      (emit-call "RT_caught_throw")
      (label EXIT))
    (move-result-to-target target)))

(defun p2-throw (form target)
  (aver (length-eql form 3))
  (let ((tag-form (cadr form))
        (result-form (caddr form))
        (thread-register (compiland-thread-register *current-compiland*)))
    (aver thread-register)
    (p2 tag-form :rax)
    (inst :push :rax)
    (emit-clear-values) ; REVIEW
    (p2 result-form :rdx)
    (inst :pop :rsi)
    (inst :mov thread-register :rdi)
    (emit-call "RT_throw") ; doesn't return
    (move-result-to-target target)))

(defun p2-test-numeric-comparison (test-form label) ; jump to label if test fails
  (unless (length-eql test-form 3)
    (return-from p2-test-numeric-comparison nil))
  (let* ((op (%car test-form))
         (args (%cdr test-form))
         (arg1 (%car args))
         (arg2 (%cadr args))
         (type1 (derive-type arg1))
         (type2 (derive-type arg2)))
;;     (mumble "p2-test-numeric-comparison ~S type1 = ~S~A type2 = ~S~A~%"
;;             op
;;             type1
;;             (if (fixnum-type-p type1) " (fixnum)" "")
;;             type2
;;             (if (fixnum-type-p type2) " (fixnum)" ""))
    (cond ((and (fixnum-type-p type1)
                (fixnum-type-p type2))
           (cond ((and (fixnump arg1)
                       (fixnump arg2))
                  (if (funcall op arg1 arg2) :consequent :alternate))
                 ((eq op 'two-arg-=)
                  ;; = fixnums are EQ
                  (return-from p2-test-numeric-comparison (p2-test-eq test-form label)))
                 ((eq op 'two-arg-/=)
                  ;; /= fixnums are NEQ
                  (return-from p2-test-numeric-comparison (p2-test-neq test-form label)))
                 (t
                  (process-2-args args '(:rax :rdx) t)
                  (inst :cmp :rdx :rax)
                  (emit-jmp-short (ecase op
                                    (two-arg-<  :nl)
                                    (two-arg->  :ng)
                                    (two-arg-<= :g)
                                    (two-arg->= :l)
                                    (two-arg-=  :ne)
                                    (two-arg-/= :e))
                                  label)
                  t)))
          ((or (float-type-p type1) (float-type-p type2))
           ;; full call
           (process-2-args args '(:rdi :rsi) t)
           (emit-call op)
           (inst :compare-immediate nil :rax)
           (emit-jmp-short :z label)
           t)
          (t
           (process-2-args args '(:rax :rdx) t)
           ;; arg1 in rax, arg2 in rdx
           (let ((FULL-CALL (make-label))
                 (EXIT (make-label)))
             (unless (fixnum-type-p type1)
               (inst :test +fixnum-tag-mask+ :al)
               (emit-jmp-short :nz FULL-CALL))
             (unless (fixnum-type-p type2)
               (inst :test +fixnum-tag-mask+ :dl)
               (emit-jmp-short :nz FULL-CALL))
             ;; falling through, both args are fixnums
             (inst :cmp :rdx :rax)
             (emit-jmp-short (ecase op
                               (two-arg-<  :nl)
                               (two-arg->  :ng)
                               (two-arg-<= :g)
                               (two-arg->= :l)
                               (two-arg-=  :ne)
                               (two-arg-/= :e))
                             label)
             (emit-jmp-short t EXIT)
             (let ((*current-segment* :elsewhere))
               (label FULL-CALL)
               (inst :mov :rdx :rsi)
               (inst :mov :rax :rdi)
               (emit-call op)
               (inst :compare-immediate nil :rax)
               (emit-jmp-short :z label)
               (emit-jmp-short t EXIT))
             (label EXIT))
           t))))

(defknown %p2-test-runtime-predicate (t t t) t)
(defun %p2-test-runtime-predicate (form label-if-true label-if-false)
  (when (check-arg-count form 1) ; runtime predicates are unary
    (let* ((op (%car form))
           (runtime-name (gethash2-1 op *runtime-predicates*))
           (arg (%cadr form)))
      (when runtime-name
        (process-1-arg arg :rdi t)
        (emit-call runtime-name)
        (inst :test :al :al)
        (when label-if-true
          (emit-jmp-short :nz label-if-true))
        (when label-if-false
          (emit-jmp-short :z label-if-false))
        t))))

(defknown p2-test-runtime-predicate (t t) t)
(defun p2-test-runtime-predicate (test-form label)
  (%p2-test-runtime-predicate test-form nil label))

(defknown p2-runtime-predicate (t t) t)
(defun p2-runtime-predicate (form target)
  (when (check-arg-count form 1)
    (let* ((op (%car form))
           (runtime-name (gethash2-1 op *runtime-predicates*))
           (arg (%cadr form)))
      (when runtime-name
        (process-1-arg arg :rdi t)
        (emit-call runtime-name)
        (move-result-to-target target)
        t))))

(defknown common-label-error-not-list (t) t)
(defun common-label-error-not-list (compiland register)
  (declare (type compiland compiland))
  (declare (type keyword register))
  (let* ((common-labels (compiland-common-labels compiland))
         (key (intern (concatenate 'string "ERROR-NOT-LIST-" (symbol-name register))))
         (label (gethash key common-labels)))
    (unless label
      (setq label (make-label))
      (let ((*current-segment* :elsewhere))
        (label label)
        (unless (eq register :rdi)
          (inst :mov register :rdi))
        (emit-call 'error-not-list)
        (emit-exit)
        (setf (gethash key common-labels) label)))
    label))

(defun p2-test-endp (test-form label-if-false)
  (when (check-arg-count test-form 1)
    (let ((arg (%cadr test-form)))
      (process-1-arg arg :rdi t)
      (let* ((EXIT (make-label)))
        (unless (zerop *safety*)
          (let ((ERROR-NOT-LIST (common-label-error-not-list *current-compiland* :rdi)))
            (inst :mov :rdi :rax)
            (inst :and +lowtag-mask+ :al)
            (clear-register-contents :rax)
            (inst :cmp +list-lowtag+ :al)
            (emit-jmp-short :ne ERROR-NOT-LIST)))
        (inst :compare-immediate nil :rdi)
        (emit-jmp-short :e EXIT)
        (emit-jmp-short t label-if-false)
        (label EXIT)))
    t))

(defknown %p2-test-eq (t t t) t)
(defun %p2-test-eq (test-form label-if-true label-if-false)
  (when (check-arg-count test-form 2)
    (let* ((args (%cdr test-form))
           (arg1 (%car args))
           (arg2 (%cadr args)))
      (when (or (characterp arg1) (fixnump arg1))
        (let ((temp arg1))
          (setq arg1 arg2
                arg2 temp))
        (setq args (list arg1 arg2)))
      (cond ((characterp arg2)
             (process-1-arg arg1 :rax t)
             (inst :cmp (+ (ash (char-code arg2) +character-shift+) +character-lowtag+) :rax))
            ((and (fixnump arg2)
                  (typep (fixnumize arg2) '(signed-byte 32)))
             (process-1-arg arg1 :rax t)
             (inst :cmp (fixnumize arg2) :rax))
            (t
             (process-2-args args '(:rax :rdx) t)
             (inst :cmp :rdx :rax)))
      (when label-if-true
        (emit-jmp-short :e label-if-true))
      (when label-if-false
        (emit-jmp-short :ne label-if-false)))
    t))

(defknown p2-test-eq (t t) t)
(defun p2-test-eq (test-form label)
  (%p2-test-eq test-form nil label))

(defknown %p2-test-neq (t t t) t)
(defun %p2-test-neq (test-form label-if-true label-if-false)
  (when (check-arg-count test-form 2)
    (let* ((args (%cdr test-form))
           (arg1 (%car args))
           (arg2 (%cadr args)))
      (when (or (characterp arg1) (fixnump arg1))
        (mumble "%p2-test-neq swapping args~%")
        (let ((temp arg1))
          (setq arg1 arg2
                arg2 temp))
        (setq args (list arg1 arg2)))
      (cond ((characterp arg2)
             (process-1-arg arg1 :rax t)
             (inst :cmp (+ (ash (char-code arg2) +character-shift+) +character-lowtag+) :rax))
            ((and (fixnump arg2)
                  (typep (fixnumize arg2) '(signed-byte 32)))
             (process-1-arg arg1 :rax t)
             (inst :cmp (fixnumize arg2) :rax))
            (t
             (process-2-args args '(:rax :rdx) t)
             (inst :cmp :rdx :rax)))
      (when label-if-true
        (emit-jmp-short :ne label-if-true))
      (when label-if-false
        (emit-jmp-short :e label-if-false)))
    t))

(defknown p2-test-neq (t t) t)
(defun p2-test-neq (test-form label)
  (%p2-test-neq test-form nil label))

(defknown %p2-test-equal (t t) t)
(defun %p2-test-equal (test-form label-if-true label-if-false)
  (when (check-arg-count test-form 2)
    (process-2-args (%cdr test-form) '(:rdi :rsi) t)
    (emit-call "RT_equal")
    (inst :test :al :al)
    (when label-if-true
      (emit-jmp-short :nz label-if-true))
    (when label-if-false
      (emit-jmp-short :z label-if-false))
    t))

(defknown p2-test-equal (t t) t)
(defun p2-test-equal (test-form label)
  (%p2-test-equal test-form nil label))

(defknown %p2-test-two-arg-= (t t) t)
(defun %p2-test-two-arg-= (test-form label-if-true label-if-false)
  (when (check-arg-count test-form 2)
    (let* ((args (%cdr test-form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (type1 (derive-type arg1))
           (type2 (derive-type arg2)))
      (cond ((and (fixnum-type-p type1)
                  (fixnum-type-p type2))
             (process-2-args args '(:rax :rdx) t)
             (inst :cmp :rdx :rax)
             (when label-if-true
               (emit-jmp-short :e label-if-true))
             (when label-if-false
               (emit-jmp-short :ne label-if-false)))
            (t
             (process-2-args args '(:rdi :rsi) t)
             (emit-call "RT_equals")
             (inst :test :al :al)
             (when label-if-true
               (emit-jmp-short :nz label-if-true))
             (when label-if-false
               (emit-jmp-short :z label-if-false)))))
    t))

(defknown p2-test-two-arg-= (t t) t)
(defun p2-test-two-arg-= (test-form label)
  (%p2-test-two-arg-= test-form nil label))

(defknown %p2-test-eql (t t) t)
(defun %p2-test-eql (test-form label-if-true label-if-false)
  (when (check-arg-count test-form 2)
    (let* ((args (%cdr test-form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (type1 (derive-type arg1))
           type2)
      (cond ((or (fixnum-type-p type1)
                 (eq type1 'CHARACTER)
                 (eq type1 'SYMBOL)
                 (fixnum-type-p (setq type2 (derive-type arg2)))
                 (eq type2 'CHARACTER)
                 (eq type2 'SYMBOL))
             (%p2-test-eq test-form label-if-true label-if-false))
            (t
             (process-2-args args '(:rdi :rsi) t)
             (emit-call "RT_eql")
             (inst :test :al :al)
             (when label-if-true
               (emit-jmp-short :nz label-if-true))
             (when label-if-false
               (emit-jmp-short :z label-if-false)))))
    t))

(defknown p2-test-eql (t t) t)
(defun p2-test-eql (test-form label)
  (%p2-test-eql test-form nil label))

(defknown %p2-test-not/null (t t t) t)
(defun %p2-test-not/null (form label-if-true label-if-false)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (process-1-arg arg :rax t)
      (inst :compare-immediate nil :rax)
      (when label-if-true
        (emit-jmp-short :e label-if-true))
      (when label-if-false
        (emit-jmp-short :ne label-if-false)))
    t))

(defknown %p2-test-characterp (t t t) t)
(defun %p2-test-characterp (form label-if-true label-if-false)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (process-1-arg arg :rax t)
      (inst :and +lowtag-mask+ :al)
      (clear-register-contents :rax)
      (inst :cmp +character-lowtag+ :al)
      (when label-if-true
        (emit-jmp-short :e label-if-true))
      (when label-if-false
        (emit-jmp-short :ne label-if-false)))
    t))

(defknown p2-test-characterp (t t) t)
(defun p2-test-characterp (test-form label)
  (%p2-test-characterp test-form nil label))

(defknown %p2-test-consp (t t t) t)
(defun %p2-test-consp (form label-if-true label-if-false)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (EXIT (make-label)))
      (process-1-arg arg :rax t)
      (inst :compare-immediate nil :rax)
      (if label-if-false
          (emit-jmp-short :e label-if-false)
          (emit-jmp-short :e EXIT))
      (inst :and +lowtag-mask+ :al)
      (clear-register-contents :rax)
      (inst :cmp +list-lowtag+ :al)
      (when label-if-true
        (emit-jmp-short :e label-if-true))
      (when label-if-false
        (emit-jmp-short :ne label-if-false))
      (label EXIT))
    t))

(defknown p2-test-consp (t t) t)
(defun p2-test-consp (test-form label)
  (%p2-test-consp test-form nil label))

(defknown %p2-test-symbolp (t t t) t)
(defun %p2-test-symbolp (form label-if-true label-if-false)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (derived-type (derive-type arg)))
      (cond ((eq derived-type 'SYMBOL)
             (p2 arg nil) ; for effect
             (when label-if-true
               (emit-jmp-short t label-if-true)))
            (t
             (let ((EXIT (make-label)))
               (process-1-arg arg :rax t)
               (inst :compare-immediate nil :rax)
               (if label-if-true
                   (emit-jmp-short :e label-if-true)
                   (emit-jmp-short :e EXIT))
               (inst :and +lowtag-mask+ :al)
               (clear-register-contents :rax)
               (inst :cmp +symbol-lowtag+ :al)
               (when label-if-true
                 (emit-jmp-short :e label-if-true))
               (when label-if-false
                 (emit-jmp-short :ne label-if-false))
               (label EXIT)))))
    t))

(defknown p2-test-symbolp (t t) t)
(defun p2-test-symbolp (test-form label)
  (%p2-test-symbolp test-form nil label))

(defun p2-test-atom (test-form label)
  (when (check-arg-count test-form 1)
    (let ((arg (%cadr test-form))
          (EXIT (make-label)))
      (process-1-arg arg :rax t)
      (inst :compare-immediate nil :rax)
      (emit-jmp-short :e EXIT)
      (inst :and +lowtag-mask+ :al)
      (clear-register-contents :rax)
      (inst :cmp +list-lowtag+ :al)
      (emit-jmp-short :e label)
      (label EXIT))
    t))

(defknown %p2-test-fixnump (t t t) t)
(defun %p2-test-fixnump (form label-if-true label-if-false)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (process-1-arg arg :rax t)
      (inst :test +fixnum-tag-mask+ :al)
      (when label-if-true
        (emit-jmp-short :e label-if-true))
      (when label-if-false
        (emit-jmp-short :ne label-if-false)))
    t))

(defknown p2-test-fixnump (t t) t)
(defun p2-test-fixnump (test-form label)
  (%p2-test-fixnump test-form nil label))

(defun %p2-test-zerop (form label-if-true label-if-false)
  (when (check-arg-count form 1)
    (let* ((arg (cadr form))
           (type (derive-type arg)))
      (process-1-arg arg :rax t)
      (inst :test :rax :rax)
      (cond ((and (neq type :unknown)
                  (subtypep type 'INTEGER))
             (when label-if-true
               (emit-jmp-short :z label-if-true))
             (when label-if-false
               (emit-jmp-short :nz label-if-false)))
            (t
             (let ((EXIT (make-label))
                   (thread-register nil))
               (when label-if-true
                 (emit-jmp-short :z label-if-true))
               (emit-jmp-short :z EXIT)
               (cond ((use-fast-call-p)
                      (inst :mov :rax :rdi)
                      (emit-call 'zerop))
                     ((setq thread-register (compiland-thread-register *current-compiland*))
                      (inst :mov :rax :rdx)
;;                       (emit-move-function-to-register 'zerop :rsi)
                      (inst :move-immediate (list :function 'zerop) :rsi)

                      (inst :mov thread-register :rdi)
                      (emit-call "RT_thread_call_function_1"))
                     (t
                      (inst :mov :rax :rsi)
;;                       (emit-move-function-to-register 'zerop :rdi)
                      (inst :move-immediate (list :function 'zerop) :rdi)
                      (emit-call "RT_current_thread_call_function_1")))
               (inst :compare-immediate nil :rax)
               (when label-if-true
                 (emit-jmp-short :ne label-if-true))
               (when label-if-false
                 (emit-jmp-short :e label-if-false))
               (label EXIT)))))
    t))

(defknown p2-test-zerop (t t) t)
(defun p2-test-zerop (test-form label)
  (%p2-test-zerop test-form nil label))

(defun p2-test-form-default (test-form label) ; jump to label if test fails
  (p2 test-form :rax)
  (unless (single-valued-p test-form)
    (emit-clear-values :preserve :rax))
  (inst :compare-immediate nil :rax)
  (emit-jmp-short :e label))

(defknown p2-if-and (t t) t)
(defun p2-if-and (form target)
  (let* ((test (second form))
         (consequent (third form))
         (alternate (fourth form))
         (subforms (cdr test)))
;;     (mumble "p2-if-and called~%")
    (aver (and (consp test) (eq (car test) 'AND)))
    (case (length subforms)
      (0
       (p2 consequent target))
      (1
       (p2-if (list 'IF (%car subforms) consequent alternate) target))
      (t
       (let ((LABEL1 (make-label))
             (LABEL2 (make-label)))
         (dolist (subform subforms)
           (let ((op (and (consp subform) (%car subform))))
;;              (when op
;;                (mumble "p2-if-and op = ~S~%" op))
             (cond ((eq op 'EQ)
                    (%p2-test-eq subform nil LABEL1))
                   ((eq op 'NEQ)
                    (%p2-test-neq subform nil LABEL1))
                   ((eq op 'EQUAL)
                    (%p2-test-equal subform nil LABEL1))
                   ((eq op 'EQL)
                    (%p2-test-eql subform nil LABEL1))
                   ((eq op 'TWO-ARG-=)
                    (%p2-test-two-arg-= subform nil LABEL1))
                   ((memq op '(NOT NULL))
                    (%p2-test-not/null subform nil LABEL1))
                   ((eq op 'CONSP)
                    (%p2-test-consp subform nil LABEL1))
                   ((eq op 'FIXNUMP)
                    (%p2-test-fixnump subform nil LABEL1))
                   ((eq op 'SYMBOLP)
                    (%p2-test-symbolp subform nil LABEL1))
                   ((eq op 'ZEROP)
                    (%p2-test-zerop subform nil LABEL1))
                   ((gethash op *runtime-predicates*)
                    (p2-runtime-predicate subform :rax)
                    (inst :test :al :al)
                    (emit-jmp-short :z LABEL1))
                   (t
;;                     (when op
;;                       (mumble "p2-if-and default case op = ~S~%" op))
                    (process-1-arg subform :rax t)
                    (inst :compare-immediate nil :rax)
                    (emit-jmp-short :e LABEL1)))))
         (p2 consequent target)
         (emit-jmp-short t LABEL2)
         (label LABEL1)
         (clear-register-contents)
         (clear-constraints)
         (p2 alternate target)
         (label LABEL2)
         (clear-register-contents)
         (clear-constraints))))))

(defknown p2-and (t t) t)
(defun p2-and (form target)
  ;; "AND passes back multiple values from the last subform but not from
  ;; subforms other than the last."
  (let ((subforms (cdr form)))
    (case (length subforms)
      (0
       (p2 t target))
      (1
       (p2 (%car subforms) target))
      (t
       (let (;(*constraints* *constraints*)
             (FAIL (make-label))
             (DONE (make-label)))
         (loop
           (let ((subform (car subforms))
                 (tail (cdr subforms)))
             (cond ((null tail)
                    ;; last subform
                    (process-1-arg subform :rax nil)
                    (move-result-to-target target)
                    (unless (eq target :return)
                      (emit-jmp-short t DONE))
                    (return))
                   (t
                    ;; not the last subform
                    (process-1-arg subform :rax t)
                    (inst :compare-immediate nil :rax)
                    (emit-jmp-short :e FAIL)
                    (maybe-add-constraint subform)
                    (setq subforms tail)
                    ))))
         (label FAIL)
         (p2 nil target)
         (label DONE))
       (clear-register-contents)
       (clear-constraints)))))

(defknown p2-if-or (t t) t)
(defun p2-if-or (form target)
  (let* ((test (second form))
         (consequent (third form))
         (alternate (fourth form))
         (subforms (cdr test)))
    (case (length subforms)
      (0
       (p2 alternate target))
      (1
       (p2-if (list 'IF (%car subforms) consequent alternate) target))
      (t
       (let ((LABEL1 (make-label))
             (LABEL2 (make-label)))
         (dolist (subform subforms)
           (let ((op (and (consp subform) (%car subform))))
             (cond ((eq op 'EQ)
                    (%p2-test-eq subform LABEL1 nil))
                   ((eq op 'NEQ)
                    (%p2-test-neq subform LABEL1 nil))
                   ((eq op 'EQUAL)
                    (%p2-test-equal subform LABEL1 nil))
                   ((eq op 'EQL)
                    (%p2-test-eql subform LABEL1 nil))
                   ((eq op 'TWO-ARG-=)
                    (%p2-test-two-arg-= subform LABEL1 nil))
                   ((memq op '(NOT NULL))
                    (%p2-test-not/null subform LABEL1 nil))
                   ((eq op 'CONSP)
                    (%p2-test-consp subform LABEL1 nil))
                   ((eq op 'FIXNUMP)
                    (%p2-test-fixnump subform LABEL1 nil))
                   ((eq op 'SYMBOLP)
                    (%p2-test-symbolp subform LABEL1 nil))
                   ((eq op 'ZEROP)
                    (%p2-test-zerop subform LABEL1 nil))
                   ((gethash op *runtime-predicates*)
                    (p2-runtime-predicate subform :rax)
                    (inst :test :al :al)
                    (emit-jmp-short :nz LABEL1))
                   (t
;;                     (when op
;;                       (mumble "p2-if-or default case op = ~S~%" op))
                    (process-1-arg subform :rax t)
                    (inst :compare-immediate nil :rax)
                    (emit-jmp-short :ne LABEL1)))))
         (p2 alternate target)
         (emit-jmp-short t LABEL2)
         (label LABEL1)
         ;; many ways to get here, so register contents could be anything
         (clear-register-contents)
         (clear-constraints)
         (p2 consequent target)
         (label LABEL2)
         (clear-register-contents)
         (clear-constraints))))))

(defknown p2-or (t t) t)
(defun p2-or (form target)
  (let ((args (cdr form)))
    (case (length args)
      (0
       (p2 nil target))
      (1
       (p2 (%car args) target))
      (2
       (let ((arg1 (%car args))
             (arg2 (%cadr args))
             (EXIT (make-label)))
         (process-1-arg arg1 :rax t)
         (inst :compare-immediate nil :rax)
         (emit-jmp-short :ne EXIT)
         (process-1-arg arg2 :rax nil)
         (label EXIT)
         (clear-register-contents)
         (clear-constraints)
         (move-result-to-target target)))
      (t
       ;; (or a b c d e f) => (or a (or b c d e f))
       (let ((new-form `(or ,(%car args) (or ,@(%cdr args)))))
         (p2-or new-form target))))))

(defun emit-move-register-to-closure-var (reg var compiland)
  (aver (fixnump (compiland-closure-data-index compiland)))
  (emit-move-local-to-register (compiland-closure-data-index compiland) :r11)
  (inst :mov `(,(* (var-closure-index var) +bytes-per-word+) :r11) :r11)
  (inst :mov reg '(:r11))
  (clear-register-contents :r11) ; REVIEW
  (clear-var-registers var)
  (set-register-contents reg var))

(defun emit-move-closure-var-to-register (var reg compiland)
  (aver (fixnump (compiland-closure-data-index compiland)))
  (emit-move-local-to-register (compiland-closure-data-index compiland) :r11)
  (inst :mov `(,(* (var-closure-index var) +bytes-per-word+) :r11) :r11)
  (inst :mov '(:r11) reg)
  (clear-register-contents :r11) ; REVIEW
  (set-register-contents reg var))

(defknown bind-var (var) t)
(defun bind-var (var)
  (declare (type var var))
  (aver (eq (var-derived-type var) :unknown))
  (let ((initform (var-initform var)))
    (cond ((var-constant-p var)
           ; nothing to do
           )
          ((var-special-p var)
           (let ((thread-register (compiland-thread-register *current-compiland*)))
             (aver thread-register)
             (when (var-ref-p initform)
               (let ((var-ref-var (var-ref-var initform)))
                 (when (and (var-special-p var-ref-var)
                            (eq (var-name var-ref-var) (var-name var)))
                   (p2-symbol (var-name var) :rsi)
                   (inst :mov thread-register :rdi)
                   (emit-call "RT_thread_bind_special_to_current_value")
                   (return-from bind-var))))
             (p2 initform :rdx)
             (p2-symbol (var-name var) :rsi)
             (inst :mov thread-register :rdi)
             (emit-call "RT_thread_bind_special")))
          ((zerop (var-reads var))
           (p2 initform nil))
          ((var-closure-index var)
           ;; each new binding gets a new value cell
           (p2 initform :rdi)
           (emit-call "RT_make_value_cell_1")
           (aver (fixnump (compiland-closure-data-index *current-compiland*)))
           (emit-move-local-to-register (compiland-closure-data-index *current-compiland*) :rdi)
           (inst :mov :rax `(,(* (var-closure-index var) +bytes-per-word+) :rdi)))
          (t
           (let ((derived-type (derive-type initform))
                 reg)
;;              (mumble "bind-var ~S derived-type = ~S writes = ~S~%"
;;                      (var-name var) derived-type (var-writes var))
             (cond ((and (var-ref-p initform)
                         (setq reg (find-register-containing-var (var-ref-var initform))))
                    (inst :mov reg var)
                    (set-register-contents reg (list var (var-ref-var initform))))
;;                    ((var-register var)
;; ;;                     (mumble "bind-var ~S var-register case~%" (var-name var))
;;                     (p2 initform (var-register var))
;;                     (when (integerp initform)
;;                       (add-type-constraint var `(INTEGER ,initform ,initform))))
                   (t
;;                     (mumble "bind-var ~S default case~%" (var-name var))
                    (p2 initform :rax)
                    (inst :mov :rax var)
                    (set-register-contents :rax var)
                    (when (integerp initform)
                      (add-type-constraint var `(INTEGER ,initform ,initform)))))
             (when (zerop (var-writes var))
;;                (mumble "bind-var setting var-derived-type ~S to ~S~%"
;;                        (var-name var) derived-type)
               (setf (var-derived-type var) derived-type))))))
  (p2-check-var-type var t))

(defun p2-let-vars (vars)
  (let ((specials nil)
        (must-clear-values nil))
    (dolist (var vars)
      (declare (type var var))
      (cond ((var-special-p var)
             (push var specials)
             (p2 (var-initform var) :stack)
             (p2-constant (var-name var) :stack))
            (t
             (bind-var var)))
      (unless must-clear-values
        (unless (single-valued-p (var-initform var))
          (note "P2-LET-VARS: not single-valued: ~S~%" (var-initform var))
          (setq must-clear-values t))))
    (dolist (var specials)
      (declare (ignore var))
      (cond ((compiland-thread-register *current-compiland*)
             (inst :pop :rsi) ; name
             (inst :pop :rdx) ; value
             (inst :mov :r12 :rdi)
             (emit-call "RT_thread_bind_special"))
            (t
             (note "P2-LET-VARS: emitting call to RT_current_thread_bind_special~%")
             (inst :pop :rdi) ; name
             (inst :pop :rsi) ; value
             (emit-call "RT_current_thread_bind_special"))))
    (dolist (var vars)
      (push var *visible-variables*))
    (when must-clear-values
      (emit-clear-values))))

(defun p2-let*-vars (vars)
  (let ((must-clear-values nil))
    (dolist (var vars)
      (declare (type var var))
      (bind-var var)
      (push var *visible-variables*)
      (unless must-clear-values
        (unless (single-valued-p (var-initform var))
          (note "P2-LET*-VARS: not single-valued: ~S~%" (var-initform var))
          (setq must-clear-values t))))
    (when must-clear-values
      (emit-clear-values))))

(defun p2-let/let* (form target)
  (declare (type cons form))
  (aver (memq (car form) '(LET LET*)))
  (aver (length-eql form 2))
  (let* ((*visible-variables* *visible-variables*)
         (block (cadr form))
         (*visible-blocks* (cons block *visible-blocks*))
         (vars (block-vars block))
         (body (block-body block))
         (thread-register nil))
    (declare (type cblock block))
    (when (block-last-special-binding-var block)
      (setq thread-register (compiland-thread-register *current-compiland*))
      (cond (thread-register
             (inst :mov thread-register :rdi)
             (emit-call "RT_thread_last_special_binding"))
            (t
             (note "P2-LET/LET*: emitting call to RT_current_thread_last_special_binding~%")
             (emit-call "RT_current_thread_last_special_binding")))
;;       (emit-move-register-to-local :rax (var-index (block-last-special-binding-var block)))
      (emit-move-register-to-var :rax (block-last-special-binding-var block))
      )
    (if (eq (car form) 'LET)
        (p2-let-vars  vars)
        (p2-let*-vars vars))
    ;; make free specials visible
    (dolist (var (block-free-specials block))
      (push var *visible-variables*))
    (let ((*speed*  *speed*)
          (*space*  *space*)
          (*safety* *safety*)
          (*debug*  *debug*)
          (*inline-declarations* *inline-declarations*)
          ;;(*explain* *explain*)
          )
      (process-optimization-declarations (cddr (block-form block)))
      (cond ((block-last-special-binding-var block)
             (p2-progn-body body :stack)
             ;; fix stack alignment
             (inst :sub +bytes-per-word+ :rsp)
             ;; restore last special binding`
             (cond (thread-register
                    (inst :mov thread-register :rdi)
                    (p2-var-ref (make-var-ref (block-last-special-binding-var block)) :rsi)
                    (emit-call "RT_thread_set_last_special_binding"))
                   (t
                    (p2-var-ref (make-var-ref (block-last-special-binding-var block)) :rdi)
                    (note "P2-LET/LET*: emitting call to RT_current_thread_set_last_special_binding~%")
                    (emit-call "RT_current_thread_set_last_special_binding")))
             (inst :add +bytes-per-word+ :rsp)
             (inst :pop :rax)
             (move-result-to-target target))
            (t
             (p2-progn-body body target))))))

(defun p2-m-v-b (form target)
  (declare (type cons form))
  (aver (length-eql form 2))
  (aver (eq (%car form) 'MULTIPLE-VALUE-BIND))
  (let* ((*visible-variables* *visible-variables*)
         (block (cadr form))
         (last-special-binding-var (block-last-special-binding-var block))
         (values-form (caddr (block-form block)))
         (vars (block-vars block))
         (body (block-body block))
         (numvars (length vars))
         (compiland *current-compiland*)
         (thread-reg (compiland-thread-register compiland)))
    (declare (type cblock block))
    (aver thread-reg)
    (when last-special-binding-var
      (inst :mov thread-reg :rdi)
      (emit-call "RT_thread_last_special_binding")
      (emit-move-register-to-var :rax last-special-binding-var))
    (p2 values-form :rsi)
    ; primary value returned by values-form is now in rsi
    (inst :mov numvars :rdx)
    (inst :mov thread-reg :rdi)
    (emit-call "RT_thread_get_values")
    ;; pointer to values vector is now in rax
    (let ((base-reg :rax)
          (value-reg :rdx)
          (index 0))
      (unless (eq base-reg :rax)
        (inst :mov :rax base-reg))
      ;; pointer to values array is now in base-reg
      (dolist (var vars)
        (declare (type var var))
        (inst :mov `(,index ,base-reg) value-reg)
        (clear-register-contents value-reg)
        (incf index +bytes-per-word+)
        (cond ((var-special-p var)
               (inst :push base-reg)
               (unless (eq value-reg :rdx)
                 (inst :mov value-reg :rdx))
               (p2-constant (var-name var) :rsi)
               (inst :mov thread-reg :rdi)
               (emit-call "RT_thread_bind_special")
               (inst :pop base-reg))
              ((var-closure-index var)
               (inst :push base-reg)
               ;; each new binding gets a new value cell
               (inst :mov value-reg :rdi)
               (emit-call "RT_make_value_cell_1")
               (aver (fixnump (compiland-closure-data-index compiland)))
               (emit-move-local-to-register (compiland-closure-data-index compiland) :rdi)
               (inst :mov :rax `(,(* (var-closure-index var) +bytes-per-word+) :rdi))
               (inst :pop base-reg))
              (t
               (inst :mov value-reg var)
               (set-register-contents value-reg var)))))
    (dolist (var vars)
      (p2-check-var-type var nil)
      (push var *visible-variables*))
    (emit-clear-values)
    (cond (last-special-binding-var
           (p2-progn-body body :stack)
           ;; fix stack alignment
           (inst :sub +bytes-per-word+ :rsp)
           (emit-move-var-to-register last-special-binding-var :rsi)
           (inst :mov thread-reg :rdi)
           (emit-call "RT_thread_set_last_special_binding")
           (inst :add +bytes-per-word+ :rsp)
           (inst :pop :rax)
           (move-result-to-target target))
          (t
           (p2-progn-body body target)))))

(defun p2-m-v-c (form target)
  (aver (length-eql form 2))
  (aver (eq (%car form) 'MULTIPLE-VALUE-CALL))
  (let* ((node (%cadr form))
         (function-form (%cadr (m-v-c-node-form node)))
         (values-producing-forms (cddr (node-form node)))
         (thread-register (compiland-thread-register *current-compiland*))
         (function-var (m-v-c-node-function-var node))
         (address-var (m-v-c-node-values-address-var node))
         (length-var (m-v-c-node-values-length-var node))
         (size (* multiple-values-limit (length values-producing-forms) +bytes-per-word+)))
    (aver (eq thread-register :r12))
    (process-1-arg function-form :rax t)
    (inst :mov :rax function-var)
    (inst :sub size :rsp)
    (inst :mov :rsp address-var)
    (inst :xor :eax :eax)
    (inst :mov :rax length-var)
    (clear-register-contents)
    (dolist (values-producing-form values-producing-forms)
      (p2 values-producing-form :rax)
      (clear-register-contents)
      (inst :mov length-var :rcx)
      (inst :mov address-var :rdx)
      (inst :mov :rax :rsi)
      (inst :mov thread-register :rdi)
      (emit-call "RT_accumulate_values")
      (inst :mov :rax length-var))
    ;; done evaluating values-producing forms
    ;; RT_thread_multiple_value_call(thread, callable, vector-address, vector-length)
    (inst :mov length-var :rcx) ; length
    (inst :mov address-var :rdx) ; address
    (inst :mov function-var :rsi) ; function designator
    (inst :mov thread-register :rdi) ; thread
    (emit-call "RT_thread_multiple_value_call")
    (inst :add size :rsp)
    (move-result-to-target target)))

(defun p2-progv (form target)
  (declare (type cons form))
  (aver (eq (car form) 'PROGV))
  (aver (length-eql form 2))
  (let* ((*visible-variables* *visible-variables*)
         (block (cadr form))
         (*visible-blocks* (cons block *visible-blocks*))
         (args (cdr (block-form block)))
         (body (cddr args)))
    (declare (type cblock block))
    (aver (not (null (compiland-thread-register *current-compiland*))))
    (aver (not (null (block-last-special-binding-var block))))
    (inst :mov :r12 :rdi)
    (emit-call "RT_thread_last_special_binding")
    (inst :mov :rax (block-last-special-binding-var block))
    (process-2-args args '(:rsi :rdx) t)
    (inst :mov :r12 :rdi)
    (emit-call "RT_progv_bind_vars")
    (p2-progn-body body :stack)
    (inst :mov (block-last-special-binding-var block) :rsi)
    (inst :mov :r12 :rdi)
    ;; fix stack alignment
    (inst :sub +bytes-per-word+ :rsp)
    (emit-call "RT_thread_set_last_special_binding")
    (inst :add +bytes-per-word+ :rsp)
    (inst :pop :rax) ; result
    (move-result-to-target target)))

(defun p2-m-v-l (form target)
  (aver (length-eql form 2))
  (aver (eq (%car form) 'MULTIPLE-VALUE-LIST))
  (emit-clear-values)
  (p2 (%cadr form) :rdi)
  (emit-call "RT_multiple_value_list")
  (move-result-to-target target))

(defun p2-tagbody (form target)
  (aver (eq (car form) 'TAGBODY))
  (aver (block-p (cadr form)))
  (let* ((block (cadr form))
         (*visible-blocks* (cons block *visible-blocks*))
         (*visible-tags* *visible-tags*)
         (body (block-body block)))
    (declare (type cblock block))
;;     (mumble "p2-tagbody ~S entering tagbody~%" (block-name block))
    (cond ((block-non-local-go-p block)
;;            (mumble "p2-tagbody ~S non-local go case~%" (block-name block))
           (let ((thread-register (compiland-thread-register *current-compiland*))
                 (tagbody-var (block-tagbody-var block)))
             (aver thread-register)
             (aver tagbody-var)
             (inst :mov thread-register :rdi) ; thread
;;              (mumble "p2-tagbody ~S emitting call to RT_add_tagbody~%" (block-name block))
             (emit-call "RT_add_tagbody")
             (inst :mov :rax tagbody-var)
             ;; process tags
             (let ((index 0))
               (dolist (tag (block-tags block))
                 (declare (type tag tag))
                 (push tag *visible-tags*)
                 (when (tag-non-local-go-p tag)
;;                    (when (eq (tag-name tag) nil)
;;                      ;; this shouldn't normally happen
;;                      (mumble "p2-tagbody emitting call to RT_add_tag for tag ~S~%" (tag-name tag)))
                   (setf (tag-index tag) index)
                   (p2-constant (tag-name tag) :rsi)
                   (emit-move-immediate-dword-to-register index :rcx)
                   (inst :mov tagbody-var :rdx)
                   (inst :mov thread-register :rdi)
;;                    (mumble "p2-tagbody ~S emitting call to RT_add_tag for tag ~S~%"
;;                               (block-name block) (tag-name tag))
                   (emit-call "RT_add_tag")
                   (incf index))))
             (inst :mov tagbody-var :rdi)
;;              (mumble "p2-tagbody ~S emitting call to RT_frame_jmp~%" (block-name block))
             (emit-call "RT_frame_jmp")
             (inst :mov :rax :rdi)
;;              (mumble "p2-tagbody ~S emitting call to setjmp~%" (block-name block))
             (emit-call "setjmp")
             (inst :test :al :al)
             (let ((LABEL1 (make-label))
                   (LABEL2 (make-label)))
               (emit-jmp-short :nz LABEL1)
               (p2-tagbody-1 body)
               (emit-jmp-short t LABEL2)
               (label LABEL1)
               ;; non-local GO
               ;; FIXME dec %rax
;;                (emit-bytes #x48 #x83 #xe8 #x01) ; sub $0x1,%rax
               (inst :sub 1 :rax)
               ;; convert index in rax to byte offset
               (emit-bytes #x48 #x6b #xc0 #x05) ; imul $0x5,%rax,%rax
               (emit-bytes #xe8 #x00 #x00 #x00 #x00) ; call next instruction
               (inst :pop :rdx) ; rip in rdx
               (inst :add :rdx :rax)
               (inst :add #x0a :rax)
               (emit-bytes #xff #xe0) ; jmpq *%rax
               (dolist (tag (block-tags block))
                 (when (tag-non-local-go-p tag)
                   (emit-jmp :jump-table (tag-label tag)))) ; 5 bytes each
               (label LABEL2))
             (emit-move-var-to-register tagbody-var :rsi)
             (inst :mov thread-register :rdi) ; thread
             (emit-call "RT_leave_tagbody")))
          (t
;;            (mumble "p2-tagbody ~S default case~%" (block-name block))
           ;; make tags visible
           (dolist (tag (block-tags block))
             (push tag *visible-tags*))
           (p2-tagbody-1 body)))
    ;; TAGBODY returns NIL
    (p2 nil target)
;;     (mumble "p2-tagbody leaving tagbody~%")
    ))

(defun p2-go (form target)
  (declare (ignore target))
  (let* ((name (cadr form))
         (tag (find-visible-tag name))
         (tag-block (tag-block tag))
         (compiland *current-compiland*))
    (declare (type compiland compiland))
    (unless tag
      (error "p2-go tag ~S not found" name))
;;     (mumble "p2-go tag ~S found in ~S~%" name (block-name tag-block))
    (cond ((eq (tag-compiland tag) compiland)
           (dolist (enclosing-block *visible-blocks*)
             (declare (type cblock enclosing-block))
             (cond ((eq enclosing-block tag-block)
                    (return))
                   ((equal (block-name enclosing-block) '(UNWIND-PROTECT))
                    (aver (block-cleanup-label enclosing-block))
                    (emit-call (block-cleanup-label enclosing-block)))
                   ((equal (block-name enclosing-block) '(CATCH))
                    (aver (block-block-var enclosing-block))
                    (aver (compiland-thread-register compiland))
                    (inst :mov (compiland-thread-register compiland) :rdi) ; thread
                    (emit-move-var-to-register (block-block-var enclosing-block) :rsi) ; catch-frame
                    (emit-call "RT_leave_catch"))
                   ((and (consp (block-name enclosing-block))
                         (eq (%car (block-name enclosing-block)) 'TAGBODY))
                    ;; nothing to do
                    )
                   ((block-last-special-binding-var enclosing-block)
                    (aver (compiland-thread-register compiland))
                    (p2-var-ref (make-var-ref (block-last-special-binding-var enclosing-block)) :rsi)
                    (inst :mov :r12 :rdi)
;;                     (mumble "p2-go emitting call to RT_thread_set_last_special_binding for enclosing block ~S~%"
;;                                (block-name enclosing-block))
                    (emit-call "RT_thread_set_last_special_binding"))))
;;            (mumble "p2-go emitting jump to ~S~%" name)
           (emit-jmp-short t (tag-label tag)))
          (t
           (p2-constant name :rsi)
           (aver (compiland-thread-register compiland))
           (inst :mov :r12 :rdi)
;;            (mumble "p2-go emitting call to RT_non_local_go~%")
           (emit-call "RT_non_local_go")))))

(defun p2-unwind-protect (form target)
  (aver (length-eql form 2))
  (let* ((block (cadr form))
         (protected-form (cadr (block-form block)))
         (cleanup-forms (cddr (block-form block)))
         (thread-register (compiland-thread-register *current-compiland*))
         (uwp-var (block-uwp-var block))
         (uwp-values-var (block-uwp-values-var block))
         (CLEANUP (make-label))
         (START (make-label)))
    (declare (type cblock block))
    (setf (block-cleanup-label block) CLEANUP)
    (emit-bytes #xe8 #x00 #x00 #x00 #x00) ; call next instruction (leave return address on stack)
    (emit-jmp t START)

    (label CLEANUP)
    (clear-register-contents)
    (clear-constraints)
    ;; This is an external entry point called by RT_unwind_to(), so we need to
    ;; set up the thread register explicitly here.
    (emit-call "RT_current_thread")
    (inst :mov :rax thread-register)
    ;; "If a non-local exit occurs during execution of cleanup-forms, no special
    ;; action is taken. The cleanup-forms of UNWIND-PROTECT are not protected by
    ;; that UNWIND-PROTECT."
    (inst :mov thread-register :rdi)
    (emit-move-var-to-register uwp-var :rsi) ; uwp
    (emit-call "RT_leave_unwind_protect")
    (p2-progn-body cleanup-forms nil)
    (inst :ret) ; end of cleanup subroutine

    (label START)
    (clear-register-contents)
    (clear-constraints)
    (inst :mov thread-register :rdi)
    (inst :pop :rsi) ; return address left by call above
    (inst :add 5 :rsi) ; code
    (inst :mov :rbp :rdx) ; rbp
    (emit-call "RT_enter_unwind_protect") ; returns uwp
    (emit-move-register-to-var :rax uwp-var)
    (emit-clear-values)
    (let ((*visible-blocks* (cons block *visible-blocks*)))
      (p2 protected-form :rsi))
    (inst :mov thread-register :rdi)
    (emit-call-2 "RT_thread_copy_values" :rax) ; REVIEW stack alignment
    (emit-move-register-to-var :rax uwp-values-var)
    (emit-call CLEANUP)
    (emit-move-var-to-register uwp-values-var :rsi)
    (inst :mov thread-register :rdi) ; thread
    (emit-call-2 "RT_thread_set_values" target)))

(defknown p2-flet (t t) t)
(defun p2-flet (form target)
  (let ((*local-functions* *local-functions*)
        (*visible-variables* *visible-variables*)
        (local-functions (cadr form))
        (compiland *current-compiland*)
        var)
    (dolist (local-function local-functions)
      (declare (type local-function local-function))
      (setq var (local-function-var local-function))
      (p2-flet-process-compiland local-function)
      (cond ((local-function-ctf local-function)
             (mumble "p2-flet case 1~%")
             (aver var)
             (cond ((var-closure-index var)
                    (let* ((closure-data-index (compiland-closure-data-index compiland)))
                      (aver (fixnump closure-data-index))
                      (emit-move-local-to-register closure-data-index :rsi)
                      (p2-constant (local-function-ctf local-function) :rdi)
                      (emit-call "RT_make_compiled_closure")
                      (emit-move-register-to-closure-var :rax var compiland)))
                   (t
                    (let* ((closure-data-index (compiland-closure-data-index compiland)))
                      (aver (fixnump closure-data-index))
                      (emit-move-local-to-register closure-data-index :rsi)
                      (p2-constant (local-function-ctf local-function) :rdi)
                      (emit-call "RT_make_compiled_closure")
                      (inst :mov :rax var)))))
            ((local-function-ctf-name local-function)
             (mumble "p2-flet case 2~%")
             (aver var)
             (cond ((var-closure-index var)
                    (let* ((closure-data-index (compiland-closure-data-index compiland)))
                      (aver (fixnump closure-data-index))
                      (emit-move-local-to-register closure-data-index :rsi)
                      (inst :move-immediate (list :function (local-function-ctf-name local-function)) :rdi)
                      (emit-call "RT_make_compiled_closure")
                      (emit-move-register-to-closure-var :rax var compiland)))
                   (t
                    (let* ((closure-data-index (compiland-closure-data-index compiland)))
                      (aver (fixnump closure-data-index))
                      (emit-move-local-to-register closure-data-index :rsi)
                      (emit-move-function-to-register (local-function-ctf-name local-function) :rdi)
                      (emit-call "RT_make_compiled_closure")
                      (inst :mov :rax var)))))
            ((local-function-function local-function)
             (mumble "p2-flet case 3~%")
             (cond ((var-closure-index var)
                    (p2-constant (local-function-function local-function) :rax)
                    (emit-move-register-to-closure-var :rax var compiland))
                   (t
                    ;; nothing to do
                    )))
            (t
             (mumble "p2-flet case 4~%")
             (aver (local-function-callable-name local-function))
             (cond ((var-closure-index var)
                    (p2-constant (local-function-callable-name local-function) :rdi)
                    (emit-call 'symbol-function)
                    (emit-move-register-to-closure-var :rax var compiland))
                   (t
                    ;; nothing to do
                    )))))
    (dolist (local-function local-functions)
      (push local-function *local-functions*))
    (multiple-value-bind (body declarations)
        (parse-body (cddr form))
      (declare (ignore declarations)) ; REVIEW
      (p2-progn-body body target))))

(defknown p2-labels (t t) t)
(defun p2-labels (form target)
  (let ((*local-functions* *local-functions*)
        (*visible-variables* *visible-variables*)
        (local-functions (cadr form)))
    (dolist (local-function local-functions)
      (declare (type local-function local-function))
;;       (let* ((compiland (local-function-compiland local-function))
;;              (callable-name
;;               (gensym (concatenate 'string
;;                                    (write-to-string (labels-debug-name compiland))
;;                                    "-"))))
;;         (setf (local-function-callable-name local-function) callable-name))
      (push local-function *local-functions*))
    (dolist (local-function local-functions)
      (p2-labels-process-compiland local-function)
;;       (cond ((local-function-ctf local-function)
;;              (let* ((compiland *current-compiland*)
;;                     (closure-data-index
;;                      (compiland-closure-data-index compiland)))
;;                (aver (fixnump closure-data-index))
;;                (emit-move-immediate (local-function-ctf local-function) :rdi)
;;                (emit-move-local-to-register closure-data-index :rsi)
;;                (emit-call "RT_make_compiled_closure")
;;                (inst :push :rax)
;;                (aver (not (null (local-function-callable-name local-function))))
;;                (p2-constant (local-function-callable-name local-function) :rdi)
;;                (inst :pop :rsi)
;;                (emit-call 'set-fdefinition)))
;;             ((local-function-ctf-name local-function)
;;              (let* ((compiland *current-compiland*)
;;                     (closure-data-index
;;                      (compiland-closure-data-index compiland)))
;;                (aver (fixnump closure-data-index))
;;                (emit-move-function-to-register (local-function-ctf-name local-function) :rdi)
;;                (emit-move-local-to-register closure-data-index :rsi)
;;                (emit-call "RT_make_compiled_closure")
;;                (inst :push :rax)
;;                (aver (not (null (local-function-callable-name local-function))))
;;                (p2-constant (local-function-callable-name local-function) :rdi)
;;                (inst :pop :rsi)
;;                (emit-call 'set-fdefinition))))
      (cond ((local-function-ctf local-function)
             (mumble "p2-labels local-function-ctf case~%")
             (aver (local-function-var local-function))
             (aver (var-closure-index (local-function-var local-function)))
             (let* ((compiland *current-compiland*)
                    (closure-data-index (compiland-closure-data-index compiland)))
               (aver (fixnump closure-data-index))
               (emit-move-local-to-register closure-data-index :rsi)
               (p2-constant (local-function-ctf local-function) :rdi)
               (emit-call "RT_make_compiled_closure")
               (emit-move-register-to-closure-var :rax (local-function-var local-function) compiland)))
            ((local-function-ctf-name local-function)
             (aver (local-function-var local-function))
             (aver (var-closure-index (local-function-var local-function)))
             (let* ((compiland *current-compiland*)
                    (closure-data-index (compiland-closure-data-index compiland)))
               (aver (fixnump closure-data-index))
               (emit-move-local-to-register closure-data-index :rsi)
               (emit-move-function-to-register (local-function-ctf-name local-function) :rdi)
               (emit-call "RT_make_compiled_closure")
               (emit-move-register-to-closure-var :rax (local-function-var local-function) compiland)))
            ((local-function-function local-function)
             (let* ((compiland *current-compiland*))
               (p2-constant (local-function-function local-function) :rax)
               (emit-move-register-to-closure-var :rax (local-function-var local-function) compiland)))
            (t
             (aver (local-function-callable-name local-function))
             (let* ((compiland *current-compiland*))
               (p2-constant (local-function-callable-name local-function) :rdi)
               (emit-call 'symbol-function)
               (emit-move-register-to-closure-var :rax (local-function-var local-function) compiland)))))
    (multiple-value-bind (body declarations)
        (parse-body (cddr form))
      (declare (ignore declarations)) ; REVIEW
      (p2-progn-body body target))))

(defun p2-multiple-value-prog1 (form target)
  (let* ((block (cadr form))
         (subforms (cdr (block-form block)))
         (thread-register (compiland-thread-register *current-compiland*)))
    (when (null subforms)
      (compiler-error
       "Wrong number of arguments for ~A (expected at least 1, but received 0)."
       'MULTIPLE-VALUE-PROG1))
    (emit-clear-values)
    (p2 (car subforms) :rsi) ; primary value
    (inst :mov thread-register :rdi)
    (emit-call-2 "RT_thread_copy_values" :rax) ; REVIEW stack alignment
    (inst :mov :rax (block-values-var block))
    (dolist (subform (cdr subforms))
      (p2 subform nil))
    (inst :mov (block-values-var block) :rsi)
    (inst :mov thread-register :rdi) ; thread
    (emit-call-2 "RT_thread_set_values" target)))

(defknown p2-closure (t t) t)
(defun p2-closure (compiland target)
  (declare (type compiland compiland))
  (aver (compiland-child-p compiland))
  (let ((compile-file-p (compile-file-p))
        (minargs (compiland-minargs compiland))
        (maxargs (compiland-maxargs compiland))
        code
        ctf
        compiled-function)
    (let ((*current-compiland* compiland)
          (*code* nil))
      (p2-compiland compiland)
      (setq code *code*))
    (cond (*closure-vars*
           (cond (compile-file-p
                  (dump-top-level-form
                   `(multiple-value-bind (final-code final-constants)
                        (generate-code-vector ',code ',(compiland-constants compiland))
                      (set-fdefinition ',(compiland-name compiland)
                                       (make-closure-template-function
                                        ',(compiland-name compiland)
                                        final-code
                                        ,minargs
                                        ,maxargs
                                        final-constants)))
                   *compile-file-output-stream*))
                 (t
                  ;; not compile-file-p
                  (multiple-value-bind (final-code final-constants)
                      (generate-code-vector code (compiland-constants compiland))
                    (setq ctf
                          (make-closure-template-function
                           (compiland-name compiland)
                           final-code
                           minargs
                           maxargs
                           final-constants)))
                  (push ctf (compiland-constants (compiland-parent compiland)))))
           (inst :mov (length *closure-vars*) :rsi) ; length in rsi
           (emit-move-local-to-register (compiland-closure-data-index *current-compiland*) :rdi)
           (emit-call "RT_copy_closure_data_vector") ; returns copy of data vector in rax
           (inst :mov :rax :rsi)
           (cond (compile-file-p
                  (emit-move-function-to-register (compiland-name compiland) :rdi))
                 (t
                  (emit-move-immediate ctf :rdi)))
           (emit-call "RT_make_compiled_closure"))
          (t
           ;; no closure vars
           (cond (compile-file-p
                  (dump-top-level-form
                   `(multiple-value-bind (final-code final-constants)
                        (generate-code-vector ',code ',(compiland-constants compiland))
                      (set-fdefinition ',(compiland-name compiland)
                                       (make-compiled-function
                                        ',(compiland-name compiland)
                                        final-code
                                        ,minargs
                                        ,maxargs
                                        final-constants)))
                   *compile-file-output-stream*)
                  (emit-move-function-to-register (compiland-name compiland) :rax))
                 (t
                  ;; not compile-file-p
                  (multiple-value-bind (final-code final-constants)
                      (generate-code-vector code (compiland-constants compiland))
                    (setq compiled-function
                          (make-compiled-function
                           (compiland-name compiland)
                           final-code
                           minargs
                           maxargs
                           final-constants)))
                  (save-local-variable-information compiled-function)
                  (emit-move-immediate compiled-function :rax)
                  ;; REVIEW escaping closures will never be gc'ed
                  (push compiled-function (compiland-constants *current-compiland*)))))))
  (move-result-to-target target))

(defun p2-function (form target)
  (let ((arg (cadr form))
        local-function)
    (cond ((symbolp arg) ; #'foo
           (cond ((setq local-function (find-local-function arg))
                  (mumble "p2-function local function case~%")
                  (cond ((local-function-callable-name local-function)
                         (emit-move-function-to-register (local-function-callable-name local-function) :rax)
                         (clear-register-contents :rax)
                         (move-result-to-target target))
                        ((local-function-function local-function)
                         (emit-move-immediate (local-function-function local-function) :rax)
                         (clear-register-contents :rax)
                         (move-result-to-target target))
                        ((local-function-var local-function)
                         (p2-var-ref (make-var-ref (local-function-var local-function)) target))
                        (t
                         (compiler-unsupported "p2-function local function case unsupported situation")))
                  )
                 ((kernel-function-p arg)
                  (case target
                    (:stack
                     (emit-byte #xb8) ; mov imm32,%eax
                     (emit-function arg)
                     (inst :push :rax)
                     (clear-register-contents :rax))
                    ((:rax :rcx :rdx :rbx :rsp :rbp :rsi :rdi)
                     (emit-byte (+ #xb8 (register-number target))) ; mov imm32,reg
                     (emit-function arg)
                     (clear-register-contents target))
                    ((:r8 :r9)
                     (emit-bytes #x49 #xc7)
                     (emit-byte (if (eq target :r8) #xc0 #xc1))
                     (emit-function arg)
                     (clear-register-contents target))
                    (:return
                     (emit-byte #xb8) ; mov imm32,%eax
                     (emit-function arg)
                     (emit-exit)
                     (clear-register-contents :rax))
                    (t
                     (compiler-unsupported "P2-FUNCTION: unsupported target ~S" target))))
                 (t
                  (p2-constant arg :rdi)
                  (emit-call "RT_symbol_function")
                  (move-result-to-target target))))
          ((setf-function-name-p arg)
           (cond ((setq local-function (find-local-function arg))
;;                   (compiler-unsupported "P2-FUNCTION: local setf functions are not supported yet")
                  (cond ((local-function-callable-name local-function)
                         (emit-move-function-to-register (local-function-callable-name local-function) :rax)
                         (clear-register-contents :rax)
                         (move-result-to-target target))
                        ((local-function-function local-function)
                         (emit-move-immediate (local-function-function local-function) :rax)
                         (clear-register-contents :rax)
                         (move-result-to-target target))
                        ((local-function-var local-function)
                         (p2-var-ref (make-var-ref (local-function-var local-function)) target))
                        (t
                         (compiler-unsupported "p2-function local setf function case unsupported situation")))
                  )
                 (t
                  (p2-constant (cadr arg) :rdi)
                  (emit-call "RT_symbol_setf_function")
                  (move-result-to-target target))
                 ((compiland-p arg)
                  (p2-closure arg target))))
          ((compiland-p arg)
           (p2-closure arg target))
          (t
           (compiler-unsupported "P2-FUNCTION unsupported situation")))))

(defknown p2-schar (t t) t)
(defun p2-schar (form target)
  (when (length-eql form 3)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1)
      (cond ((zerop *safety*)
             (process-2-args args '(:rax :rdx) t) ; string in rax, index in rdx
             (inst :add (- +simple-string-data-offset+ +typed-object-lowtag+) :rax)
             (unbox-fixnum :rdx)
             (clear-register-contents :rax :rdx)
             (inst :add :rax :rdx)
             (emit-bytes #x48 #x0f #xb6 #x02)                   ; movzbq (%rdx),%rax
             (inst :shl +character-shift+ :rax)
             (emit-bytes #x48 #x83 #xc8 +character-lowtag+)     ; or $0x6,%rax
             (move-result-to-target target))
            ((and (neq (setq type1 (derive-type arg1)) :unknown)
                  (subtypep type1 'SIMPLE-STRING))
             (p2-function-call (list '%SCHAR arg1 arg2) target))
            (t
             (p2-function-call form target))))
    t))

(defknown p2-svref (t t) t)
(defun p2-svref (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (type1 (derive-type arg1))
           (type2 (derive-type arg2))
           size)
      (cond ((or (zerop *safety*)
                 (and (integer-type-p type2)
                      (subtypep type1 'SIMPLE-VECTOR)
                      (setq size (derive-vector-size type1))
                      (subtypep type2 (list 'INTEGER 0 (1- size)))))
             ;; FIXME use relative addressing instead of computing the address in rax
             (cond ((fixnump arg2)
                    (process-1-arg arg1 :rax t)
                    (clear-register-contents :rax)
                    (let ((offset (+ (- +simple-vector-data-offset+ +typed-object-lowtag+)
                                     (* arg2 +bytes-per-word+))))
                      (cond ((reg64-p target)
                             (inst :mov `(,offset :rax) target))
                            (t
                             (inst :mov `(,offset :rax) :rax)
                             (move-result-to-target target))))
                    )
                   (t
                    (process-2-args args '(:rax :rdx) t) ; vector in rax, index in rdx
                    (clear-register-contents :rax :rdx)
                    (inst :add (- +simple-vector-data-offset+ +typed-object-lowtag+) :rax)
                    ;; index is in rdx
                    ;; unbox it
                    (unbox-fixnum :rdx)
                    (inst :shl 3 :rdx) ; multiply by 8 to get byte offset
                    (inst :add :rdx :rax)
                    (cond ((reg64-p target)
                           (inst :mov '(:rax) target))
                          (t
                           (inst :mov '(:rax) :rax)
                           (move-result-to-target target))))))
            (;(subtypep type1 'simple-vector)
             t
;;              (mumble "p2-svref %svref case~%")
             (mumble "p2-svref default case~%")
             (process-2-args args '(:rax :rdx) t) ; vector in rax, tagged index in rdx

             (unless (subtypep type1 'SIMPLE-VECTOR)
               (mumble "p2-svref checking arg1~%")
               (let* ((common-labels (compiland-common-labels *current-compiland*))
                      (SVREF-ERROR-NOT-SIMPLE-VECTOR (gethash :svref-error-not-simple-vector common-labels)))
                 (when SVREF-ERROR-NOT-SIMPLE-VECTOR
                   (mumble "p2-svref re-using label~%"))
                 (unless SVREF-ERROR-NOT-SIMPLE-VECTOR
                   (setq SVREF-ERROR-NOT-SIMPLE-VECTOR (make-label))
                   (let ((*current-segment* :elsewhere))
                     (label SVREF-ERROR-NOT-SIMPLE-VECTOR)
                     (p2-symbol 'SIMPLE-VECTOR :rsi)
                     (emit-call '%type-error)
                     ;; FIXME
                     (emit-exit))
                   (setf (gethash :svref-error-not-simple-vector common-labels) SVREF-ERROR-NOT-SIMPLE-VECTOR))
                 (inst :mov :rax :rdi)
                 (inst :and +lowtag-mask+ :al)
                 (clear-register-contents :rax :rdi)
                 (inst :cmp +typed-object-lowtag+ :al)
                 (emit-jmp-short :ne SVREF-ERROR-NOT-SIMPLE-VECTOR)
                 (inst :mov :rdi :rax)
                 (inst :sub +typed-object-lowtag+ :rax)
                 (inst :mov '(8 :rax) :rax) ; widetag in rax
                 (aver (typep +simple-vector-widetag+ '(signed-byte 32)))
                 (inst :cmp +simple-vector-widetag+ :rax)
                 (emit-jmp-short :ne SVREF-ERROR-NOT-SIMPLE-VECTOR)
                 (inst :mov :rdi :rax) ; vector in rax
                 ))

             (unless (fixnum-type-p (derive-type arg2))
               (let* ((common-labels (compiland-common-labels *current-compiland*))
                      (SVREF-ERROR-NOT-FIXNUM (gethash :svref-error-not-fixnum common-labels)))
                 (unless SVREF-ERROR-NOT-FIXNUM
                   (setq SVREF-ERROR-NOT-FIXNUM (make-label))
                   (let ((*current-segment* :elsewhere)
                         (*register-contents* (copy-register-contents)))
                     (label SVREF-ERROR-NOT-FIXNUM)
                     (inst :mov :rdx :rdi)
                     (p2-symbol 'FIXNUM :rsi)
                     (emit-call '%type-error)
                     ;; FIXME
                     (emit-exit))
                   (setf (gethash :svref-error-not-fixnum common-labels) SVREF-ERROR-NOT-FIXNUM))
                 (inst :test +fixnum-tag-mask+ :dl)
                 (emit-jmp-short :nz SVREF-ERROR-NOT-FIXNUM)))
             (let* ((displacement (- +vector-capacity-offset+ +typed-object-lowtag+))
                    (common-labels (compiland-common-labels *current-compiland*))
                    (SVREF-ERROR-BAD-INDEX (gethash :svref-error-bad-index common-labels)))
               (unless SVREF-ERROR-BAD-INDEX
                 (setq SVREF-ERROR-BAD-INDEX (make-label))
                 (let ((*current-segment* :elsewhere)
                       (*register-contents* (copy-register-contents)))
                   (label SVREF-ERROR-BAD-INDEX)
                   ;; we want raw index in rdi, raw length in rsi
                   (inst :mov :rdx :rdi)
                   (inst :mov :rcx :rsi)
                   (emit-call "RT_bad_index")
                   ;; FIXME
                   (emit-exit))
                 (setf (gethash :svref-error-bad-index common-labels) SVREF-ERROR-BAD-INDEX))
               (inst :mov `(,displacement :rax) :rcx) ; raw length in rcx
               (clear-register-contents :rcx)
               (unbox-fixnum :rdx)
               (inst :cmp :rdx :rcx)
               (emit-jmp-short :le SVREF-ERROR-BAD-INDEX)
               (inst :shl 3 :rdx) ; multiply by 8 to get offset in bytes
               (inst :add (- +simple-vector-data-offset+ +typed-object-lowtag+) :rax)
               (inst :add :rdx :rax)
               (clear-register-contents :rax :rdx)
               (inst :mov '(:rax) :rax)
               (move-result-to-target target))
             (when (var-ref-p arg1)
               (unless (subtypep type1 'SIMPLE-VECTOR)
                 (add-type-constraint (var-ref-var arg1) 'SIMPLE-VECTOR)))
             )
;;             (t
;;              (mumble "p2-svref full call type1 = ~S type2 = ~S~%" (derive-type arg1) (derive-type arg2))
;;              (p2-function-call form target)
;;              (when (var-ref-p arg1)
;;                (add-type-constraint (var-ref-var arg1) 'SIMPLE-VECTOR))
;;              )
            ))
    t))

(defknown p2-vector-ref (t t) t)
(defun p2-vector-ref (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (type1 (derive-type arg1))
           type2
           size)
      (cond ((eq type1 :unknown)
             nil)
            ((subtypep type1 'simple-vector)
             (p2-svref form target)
             t)
            ((subtypep type1 '(simple-array (unsigned-byte 8) (*)))
             (cond ((or (zerop *safety*)
                        (and (neq (setq type2 (derive-type arg2)) :unknown)
                             (integer-type-p type2)
                             (setq size (derive-vector-size type1))
                             (subtypep type2 (list 'INTEGER 0 (1- size)))))
;;                     (unless (zerop *safety*)
;;                       (mumble "p2-vector-ref (simple-array (unsigned-byte 8) (~D)) optimized case~%" size))
                    (process-2-args args '(:rax :rdx) t) ; vector in rax, index in rdx
                    (clear-register-contents :rax :rdx)
                    (inst :add (- +simple-vector-data-offset+ +typed-object-lowtag+) :rax)

                    ;; index is in rdx
                    ;; get rid of the fixnum shift
                    (unbox-fixnum :rdx)

                    (inst :add :rdx :rax)
                    (emit-bytes #x48 #x0f #xb6 #x00) ; movzbq (%rax),%rax
                    (inst :shl +fixnum-shift+ :rax)
                    (move-result-to-target target)
                    t)
                   (t
                    (p2 (list* '%VECTOR-REF args) target)
                    t)))
            ((subtypep type1 '(simple-array (unsigned-byte 32) (*)))
             (cond ((or (zerop *safety*)
                        (and (neq (setq type2 (derive-type arg2)) :unknown)
                             (integer-type-p type2)
                             (setq size (derive-vector-size type1))
                             (subtypep type2 (list 'INTEGER 0 (1- size)))))
;;                     (unless (zerop *safety*)
;;                       (mumble "p2-vector-ref (simple-array (unsigned-byte 32) (~D)) optimized case~%" size))
                    (process-2-args args '(:rax :rdx) t) ; vector in rax, index in rdx
                    (clear-register-contents :rax)
                    (inst :add (- +simple-vector-data-offset+ +typed-object-lowtag+) :rax)

                    ;; index is in rdx
                    ;; get rid of the fixnum shift and multiply by 4 to get the offset in bytes
                    ;; (emit-bytes #x48 #xc1 #xfa +fixnum-shift+)         ; sar $0x2,%rdx
                    ;; (emit-bytes #x48 #xc1 #xe2 #x02)                   ; shl $0x2,%rdx
                    ;; nothing to do!

                    (inst :add :rdx :rax)
                    (emit-bytes #x8b #x00) ; mov (%rax),%eax
                    (inst :shl +fixnum-shift+ :rax)
                    (move-result-to-target target)
                    t)
                   (t
                    (p2 (list* '%VECTOR-REF args) target)
                    t)))
            ((subtypep type1 'vector)
             (p2 (list* '%VECTOR-REF args) target)
             t)
            (t
             nil)))))

(defknown p2-vector-set (t t) t)
(defun p2-vector-set (form target)
  (when (check-arg-count form 3)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (type1 (derive-type arg1)))
      (cond ((eq type1 :unknown)
             nil)
            ((subtypep type1 'SIMPLE-VECTOR)
             (p2-svset form target))
            ((subtypep type1 '(simple-array (unsigned-byte 8) (*)))
             (cond ((zerop *safety*)
                    ;; FIXME this trashes the first three argument registers, which breaks things
                    ;; if this code ends up in a trivial leaf function...
                    (process-3-args args '(:rdi :rsi :rdx) t) ; vector in rdi, index in rsi, new element in rdx

                    (inst :mov :rdi :rax)
                    (clear-register-contents :rax)
                    (inst :add (- +simple-vector-data-offset+ +typed-object-lowtag+) :rax)

                    ;; index is in rsi
                    ;; unbox it
                    (unbox-fixnum :rsi)

                    (inst :add :rsi :rax)

                    ;; new element is in rdx
                    (when target
                      (inst :push :rdx)) ; save it for return value

                    ;; unbox it
                    (unbox-fixnum :rdx)

                    ;; store it in the array
                    (emit-bytes #x88 #x10) ; mov %dl,(%rax)

                    ;; return value
                    (when target
                      (inst :pop :rax))

                    (move-result-to-target target)
                    t)
                   (t
                    (p2 (list* '%VECTOR-SET args) target)
                    t)))
            ((subtypep type1 'vector)
             (p2 (list* '%VECTOR-SET args) target)
             t)
            (t
             (mumble "p2-vector-set full call type1 = ~S type2 = ~S~%"
                     type1 (derive-type (%cadr args)))
             nil)))))

(defknown p2-svset (t t) t)
(defun p2-svset (form target)
  (when (check-arg-count form 3)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (arg3 (%caddr args))
           (type1 (derive-type arg1))
           (type2 (derive-type arg2))
           size)
      (cond ((or (zerop *safety*)
                 (and (integer-type-p type2)
                      (subtypep type1 'SIMPLE-VECTOR)
                      (setq size (derive-vector-size type1))
                      (subtypep type2 (list 'INTEGER 0 (1- size)))))
             (process-3-args args '(:rax :rdx :rcx) t) ; vector in rax, index in rdx, new element in rcx
             (clear-register-contents :rax :rdx)
             (inst :add (- +simple-vector-data-offset+ +typed-object-lowtag+) :rax)
             ;; index is in rdx
             ;; unbox it
             (unbox-fixnum :rdx)
             (inst :shl 3 :rdx) ; multiply by 8 to get byte offset
             (inst :add :rdx :rax)
             ;; new element is in rcx
             (when target
               (inst :push :rcx)) ; save it for return value
             ;; store it in the array
             (inst :mov :rcx '(:rax))
             ;; return value
             (cond ((reg64-p target)
                    (inst :pop target))
                   (target
                    (inst :pop :rax)
                    (move-result-to-target target)))
             t)
            ((and (neq type1 :unknown)
                  (subtypep type1 'SIMPLE-VECTOR))
             (p2-function-call (list '%SVSET arg1 arg2 arg3) target)
             t)
            (t
             nil)))))

(defknown p2-symbol (symbol t) t)
(defun p2-symbol (form target)
  (declare (type symbol form))
  (cond ((compile-file-p)
         (p2-constant form target))
        (t
         (emit-move-immediate form target))))

(defknown process-1-arg (t t t) t)
(defun process-1-arg (arg reg clear-values-p)
  (case reg
    (:default
     (setq reg :rdi))
    (:register
     (when (var-ref-p arg)
       (setq reg (find-register-containing-var (var-ref-var arg)))
       (when reg
         (return-from process-1-arg reg)))
     (setq reg :rax)))
  (p2 arg reg)
  (when clear-values-p
    (unless (single-valued-p arg)
      (emit-clear-values :preserve reg)))
  reg)

(defknown process-2-args (t t t) t)
(defun process-2-args (args regs clear-values-p)
  (when (eq regs :default)
    (setq regs '(:rdi :rsi)))
  (let* ((arg1 (car args))
         (arg2 (cadr args))
         (reg1 (car regs))
         (reg2 (cadr regs)))
    (cond ((and (constant-or-local-var-ref-p arg1)
                (constant-or-local-var-ref-p arg2))
           (p2 arg1 reg1)
           (p2 arg2 reg2))
          ((or (numberp arg1) (characterp arg1))
           ;; order of evaluation doesn't matter
           (p2 arg2 reg2)
           (when clear-values-p
             (unless (single-valued-p arg2)
               (emit-clear-values :preserve reg2)))
           (p2 arg1 reg1))
          ((constant-or-local-var-ref-p arg2)
           (p2 arg1 reg1)
           (when clear-values-p
             (unless (single-valued-p arg1)
               (emit-clear-values :preserve reg1)))
           (p2 arg2 reg2))
          (t
           (p2 arg1 :stack)
           (inst :push :rax) ; align stack
           (p2 arg2 reg2)
           (when clear-values-p
             (unless (and (single-valued-p arg1)
                          (single-valued-p arg2))
               (emit-clear-values :preserve reg2)))
           (inst :pop reg1) ; unalign stack
           (inst :pop reg1) ; this is the value we want in reg1
           (clear-register-contents reg1)))))

(defknown process-3-args (t t t) t)
(defun process-3-args (args regs clear-values-p)
  (when (eq regs :default)
    (setq regs '(:rdi :rsi :rdx)))
  (let* ((arg1 (car args))
         (arg2 (cadr args))
         (arg3 (caddr args))
         (reg1 (car regs))
         (reg2 (cadr regs))
         (reg3 (caddr regs)))
    (cond ((every #'constant-or-local-var-ref-p args)
           (p2 arg1 reg1)
           (p2 arg2 reg2)
           (p2 arg3 reg3))
          (t
           (p2 arg1 :stack) ; stack is misaligned after this
           (cond ((constant-or-local-var-ref-p arg2)
                  (p2 arg2 :stack))
                 (t
                  (inst :push :rax) ; realign stack before call
                  (p2 arg2 :rax)
                  (inst :mov :rax '(:rsp))))
           (p2 arg3 reg3)
           (when clear-values-p
             (unless (and (single-valued-p arg1)
                          (single-valued-p arg2)
                          (single-valued-p arg3))
               (emit-clear-values :preserve reg3)))
           (inst :pop reg2)
           (inst :pop reg1)
           (clear-register-contents reg1 reg2)))))

(defknown process-4-args (t t t) t)
(defun process-4-args (args regs clear-values-p)
  (let* ((arg1 (%car args))
         (arg2 (%cadr args))
         (arg3 (%caddr args))
         (arg4 (cadddr args))
         (reg1 (%car regs))
         (reg2 (%cadr regs))
         (reg3 (%caddr regs))
         (reg4 (cadddr regs)))
    (cond ((every #'constant-or-local-var-ref-p args)
           (p2 arg1 reg1)
           (p2 arg2 reg2)
           (p2 arg3 reg3)
           (p2 arg4 reg4))
          (t
           (p2 arg1 :stack) ; stack is misaligned after this
           (inst :sub (* +bytes-per-word+ 3) :rsp) ; realign stack with room for two more values
           (p2 arg2 :rax)
           (inst :mov :rax '(16 :rsp))
           (p2 arg3 :rax)
           (inst :mov :rax '(8 :rsp))
           (p2 arg4 reg4)
           (when clear-values-p
             (dolist (arg args)
               (unless (single-valued-p arg)
                 (emit-clear-values :preserve reg4)
                 (return))))
           (inst :pop reg3) ; unalign stack
           (inst :pop reg3)
           (inst :pop reg2)
           (inst :pop reg1)
           (clear-register-contents reg1 reg2 reg3)))))

(defknown process-5-args (t t t) t)
(defun process-5-args (args regs clear-values-p)
  (let ((arg1 (%car args))
        (arg2 (%cadr args))
        (arg3 (%caddr args))
        (arg4 (fourth args))
        (arg5 (fifth args))
        (reg1 (%car regs))
        (reg2 (%cadr regs))
        (reg3 (%caddr regs))
        (reg4 (fourth regs))
        (reg5 (fifth regs)))
    (cond ((every #'constant-or-local-var-ref-p args)
           (p2 arg1 reg1)
           (p2 arg2 reg2)
           (p2 arg3 reg3)
           (p2 arg4 reg4)
           (p2 arg5 reg5))
          (t
           (inst :sub (* +bytes-per-word+ 6) :rsp) ; 6 instead of 5 for stack alignment
           (flet ((process-arg (arg n)
                    (let ((displacement (* +bytes-per-word+ (- 4 n))))
                      (cond ((and (fixnump arg)
                                  (typep (ash arg +fixnum-shift+) '(signed-byte 32)))
                             (inst :movq (ash arg +fixnum-shift+) `(,displacement :rsp)))
                            (t
                             (p2 arg :rax)
                             (inst :mov :rax `(,displacement :rsp)))))))
             (let ((n 0))
               (dolist (arg args)
                 (process-arg arg n)
                 (incf n))))
           (when clear-values-p
             (dolist (arg args)
               (unless (single-valued-p arg)
                 (emit-clear-values)
                 (return))))
           (inst :pop reg5)
           (inst :pop reg4)
           (inst :pop reg3)
           (inst :pop reg2)
           (inst :pop reg1)
           (clear-register-contents reg1 reg2 reg3 reg4 reg5)
           (inst :add +bytes-per-word+ :rsp)))))

(defknown process-args (t t t) t)
(defun process-args (args regs clear-values-p)
  (ecase (length args)
    (0) ; nothing to do
    (1 (process-1-arg (%car args) (%car regs) clear-values-p))
    (2 (process-2-args args regs clear-values-p))
    (3 (process-3-args args regs clear-values-p))
    (4 (process-4-args args regs clear-values-p))
    (5 (process-5-args args regs clear-values-p))))

(defknown p2-function-call-0 (t t) t)
(defun p2-function-call-0 (op target)
  (let ((compiland *current-compiland*)
        (kernel-function-p (kernel-function-p op))
        thread-register)
    (declare (type compiland compiland))
    (cond ((use-fast-call-p)
           (cond ((and kernel-function-p
                       (eql (function-arity op) 0)
                       (function-code (symbol-function op)))
                  (emit-call op))
                 (kernel-function-p
;;                   (emit-move-function-to-register op :rdi)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_fast_call_function_0"))
                 ((and (eq op (compiland-name compiland))
                       (eql (compiland-arity compiland) 0))
                  (emit-recurse))
                 (t
                  (p2-symbol op :rdi)
                  (emit-call "RT_fast_call_symbol_0"))))
          ;; not use-fast-call-p
          ((setq thread-register (compiland-thread-register compiland))
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_0"))
                 (t
                  (p2-symbol op :rsi)
;;                   (inst :mov thread-register :rdi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_symbol_0"))))
          (t
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_current_thread_call_function_0"))
                 (t
                  (p2-symbol op :rdi)
                  (emit-call "RT_current_thread_call_symbol_0"))))))
  (move-result-to-target target))

(defknown p2-function-call-1 (t t t) t)

(defun p2-function-call-1 (op args target)
  (let ((arg (%car args))
        (compiland *current-compiland*)
        (kernel-function-p (kernel-function-p op))
        (use-fast-call-p (use-fast-call-p))
        thread-register)
    (declare (type compiland compiland))
    (cond (kernel-function-p
           (cond ((and (eql (function-arity op) 1)
                       (function-code (symbol-function op))
                       (or use-fast-call-p
                           (memq :safe (function-attributes op))))
                  (process-1-arg arg :rdi t)
                  (emit-call op))
                 (use-fast-call-p
                  (process-1-arg arg :rsi t)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_fast_call_function_1"))
                 ;; not use-fast-call-p
                 ((setq thread-register (compiland-thread-register compiland))
                  (process-1-arg arg :rdx nil)
                  ;; RT_thread_call_function_1() calls thread->clear_values()
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_1"))
                 ;; no thread register
                 (t
                  (process-1-arg arg :rsi nil)
                  ;; RT_current_thread_call_function_1() calls thread->clear_values()
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_current_thread_call_function_1"))))
           ;; not kernel-function-p
          (use-fast-call-p
           (cond ((and (eq op (compiland-name compiland))
                       (eql (compiland-arity compiland) 1))
                  (process-1-arg arg :rdi t)
                  (emit-recurse))
                 (t
                  (process-1-arg arg :rsi t)
                  (p2-symbol op :rdi)
                  (emit-call "RT_fast_call_symbol_1"))))
          ;; not use-fast-call-p
          ((setq thread-register (compiland-thread-register compiland))
           (process-1-arg arg :rdx nil)
           ;; RT_thread_call_symbol_1() calls thread->clear_values()
           (p2-symbol op :rsi)
           (inst :mov thread-register :rdi)
           (emit-call "RT_thread_call_symbol_1"))
          ;; no thread register
          (t
           (process-1-arg arg :rsi nil)
           ;; RT_current_thread_call_symbol_1() calls thread->clear_values()
           (p2-symbol op :rdi)
           (emit-call "RT_current_thread_call_symbol_1"))))
  (move-result-to-target target))

(defknown p2-function-call-2 (t t t) t)
(defun p2-function-call-2 (op args target)
  (let ((compiland *current-compiland*)
        (kernel-function-p (kernel-function-p op))
        (use-fast-call-p (use-fast-call-p))
        thread-register)
    (declare (type compiland compiland))
    (cond (kernel-function-p
           (cond ((and (eql (function-arity op) 2)
                       (function-code (symbol-function op))
                       (or use-fast-call-p
                           (memq :safe (function-attributes op))))
                  (process-2-args args '(:rdi :rsi) t)
                  (emit-call op))
                 (use-fast-call-p
                  (process-2-args args '(:rsi :rdx) t)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_fast_call_function_2"))
                 ;; not use-fast-call-p
                 ((setq thread-register (compiland-thread-register compiland))
                  (process-2-args args '(:rdx :rcx) nil)
                  ;; RT_thread_call_function_2() calls thread->clear_values()
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_2"))
                 ;; no thread register
                 (t
                  (process-2-args args '(:rsi :rdx) nil)
                  ;; RT_current_thread_call_function_2() calls thread->clear_values()
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_current_thread_call_function_2"))))
          ;; not kernel-function-p
          (use-fast-call-p
           (cond ((and (eq op (compiland-name compiland))
                       (eql (compiland-arity compiland) 1))
                  (process-2-args args '(:rdi :rsi) t)
                  (emit-recurse))
                 (t
                  (process-2-args args '(:rsi :rdx) t)
                  (p2-symbol op :rdi)
                  (emit-call "RT_fast_call_symbol_2"))))
          ;; not use-fast-call-p
          ((setq thread-register (compiland-thread-register compiland))
           (process-2-args args '(:rdx :rcx) nil)
           ;; RT_thread_call_symbol_2() calls thread->clear_values()
           (p2-symbol op :rsi)
           (inst :mov thread-register :rdi)
           (emit-call "RT_thread_call_symbol_2"))
          ;; no thread register
          (t
           (process-2-args args '(:rsi :rdx) nil)
           ;; RT_current_thread_call_symbol_2() calls thread->clear_values()
           (p2-symbol op :rdi)
           (emit-call "RT_current_thread_call_symbol_2"))))
  (move-result-to-target target))

(defknown p2-function-call-3 (t t t) t)
(defun p2-function-call-3 (op args target)
  (let ((compiland *current-compiland*)
        (kernel-function-p (kernel-function-p op))
        (use-fast-call-p (use-fast-call-p))
        thread-register)
    (declare (type compiland compiland))
    (cond (kernel-function-p
           (cond ((and (eql (function-arity op) 3)
                       (function-code (symbol-function op))
                       (or use-fast-call-p
                           (memq :safe (function-attributes op))))
                  (process-3-args args '(:rdi :rsi :rdx) t)
                  (emit-call op))
                 (use-fast-call-p
                  (process-3-args args '(:rsi :rdx :rcx) t)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_fast_call_function_3"))
                 ;; not use-fast-call-p
                 ((setq thread-register (compiland-thread-register compiland))
                  (process-3-args args '(:rdx :rcx :r8) nil)
                  ;; RT_thread_call_function_3() calls thread->clear_values()
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_3"))
                 ;; no thread register
                 (t
                  (process-3-args args '(:rsi :rdx :rcx) nil)
                  ;; RT_current_thread_call_function_2() calls thread->clear_values()
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_current_thread_call_function_3"))))
          ;; not kernel-function-p
          (use-fast-call-p
           (cond ((and (eq op (compiland-name compiland))
                       (eql (compiland-arity compiland) 3))
                  (process-3-args args '(:rdi :rsi :rdx) t)
                  (emit-recurse))
                 (t
                  (process-3-args args '(:rsi :rdx :rcx) t)
                  (p2-symbol op :rdi)
                  (emit-call "RT_fast_call_symbol_3"))))
          ;; not use-fast-call-p
          ((setq thread-register (compiland-thread-register compiland))
           ;; RT_thread_call_symbol_3() calls thread->clear_values()
           (process-3-args args '(:rdx :rcx :r8) nil)
           (p2-symbol op :rsi)
           (inst :mov thread-register :rdi)
           (emit-call "RT_thread_call_symbol_3"))
          (t
           ;; RT_current_thread_call_symbol_3() calls thread->clear_values()
           (process-3-args args '(:rsi :rdx :rcx) nil)
           (p2-symbol op :rdi)
           (emit-call "RT_current_thread_call_symbol_3"))))
  (move-result-to-target target))

(defknown p2-function-call-4 (t t t) t)
(defun p2-function-call-4 (op args target)
  (let ((compiland *current-compiland*)
        (kernel-function-p (kernel-function-p op))
        thread-register)
    (declare (type compiland compiland))
    (cond ((use-fast-call-p)
           (cond ((and kernel-function-p
                       (eql (function-arity op) 4)
                       (function-code (symbol-function op)))
                  (process-4-args args '(:rdi :rsi :rdx :rcx) t)
                  (emit-call op))
                 (kernel-function-p
                  (process-4-args args '(:rsi :rdx :rcx :r8) t)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_fast_call_function_4"))
                 ((and (eq op (compiland-name compiland))
                       (eql (compiland-arity compiland) 4))
                  (process-4-args args '(:rdi :rsi :rdx :rcx) t)
                  (emit-recurse))
                 (t
                  (process-4-args args '(:rsi :rdx :rcx :r8) t)
                  (p2-symbol op :rdi)
                  (emit-call "RT_fast_call_symbol_4"))))
          ;; not use-fast-call-p
          ((setq thread-register (compiland-thread-register compiland))
           ;; RT_thread_call_symbol_4() calls thread->clear_values()
           (process-4-args args '(:rdx :rcx :r8 :r9) nil)
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_4"))
                 (t
                  (p2-symbol op :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_symbol_4"))))
          (t
           ;; RT_current_thread_call_symbol_4() calls thread->clear_values()
           (process-4-args args '(:rsi :rdx :rcx :r8) nil)
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_current_thread_call_function_4"))
                 (t
                  (p2-symbol op :rdi)
                  (emit-call "RT_current_thread_call_symbol_4"))))))
  (move-result-to-target target))

(defknown p2-function-call-5 (t t t) t)
(defun p2-function-call-5 (op args target)
  (let ((compiland *current-compiland*)
        (kernel-function-p (kernel-function-p op))
        thread-register)
    (declare (type compiland compiland))
    (cond ((use-fast-call-p)
           (cond ((and kernel-function-p
                       (eql (function-arity op) 5)
                       (function-code (symbol-function op)))
                  (process-5-args args '(:rdi :rsi :rdx :rcx :r8) t)
                  (emit-call op))
                 (kernel-function-p
                  (process-5-args args '(:rsi :rdx :rcx :r8 :r9) t)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_fast_call_function_5"))
                 ((and (eq op (compiland-name compiland))
                       (eql (compiland-arity compiland) 5))
                  (process-5-args args '(:rdi :rsi :rdx :rcx :r8) t)
                  (emit-recurse))
                 (t
                  (process-5-args args '(:rsi :rdx :rcx :r8 :r9) t)
                  (p2-symbol op :rdi)
                  (emit-call "RT_fast_call_symbol_5"))))
          ((setq thread-register (compiland-thread-register compiland))
           ;; not use-fast-call-p
           (cond (kernel-function-p
                  (process-5-args args '(:rdx :rcx :r8 :r9 :rax) nil)
                  (inst :push :rax)
                  (inst :push :rax) ; stack alignment
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_5")
                  (inst :add (* +bytes-per-word+ 2) :rsp))
                 (t
                  (process-5-args args '(:rdx :rcx :r8 :r9 :rax) nil)
                  (inst :push :rax)
                  (inst :push :rax) ; stack alignment
                  (p2-symbol op :rsi)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_symbol_5")
                  (inst :add (* +bytes-per-word+ 2) :rsp))))
          (t
           ;; not use-fast-call-p
           (cond (kernel-function-p
                  (process-5-args args '(:rsi :rdx :rcx :r8 :r9) nil)
                  (inst :move-immediate `(:function ,op) :rdi)
                  (emit-call "RT_current_thread_call_function_5"))
                 (t
                  (process-5-args args '(:rsi :rdx :rcx :r8 :r9) nil)
                  (p2-symbol op :rdi)
                  (emit-call "RT_current_thread_call_symbol_5"))))))
  (move-result-to-target target))

(defknown p2-function-call-6 (t t t) t)
(defun p2-function-call-6 (op args target)
  (let ((arg1 (%car args))
        (arg2 (%cadr args))
        (arg3 (%caddr args))
        (arg4 (fourth args))
        (arg5 (fifth args))
        (arg6 (sixth args))
        (kernel-function-p (kernel-function-p op))
        (use-fast-call-p (use-fast-call-p))
        thread-register)
    ;; We're only going to store five values on the stack, but we want to keep
    ;; the stack aligned, so we make room for six.
    (inst :sub (* 6 +bytes-per-word+) :rsp)
    ;; evaluate args left to right
    (p2 arg1 :rax)
    (emit-move-register-to-relative :rax :rsp 5)
    (p2 arg2 :rax)
    (emit-move-register-to-relative :rax :rsp 4)
    (p2 arg3 :rax)
    (emit-move-register-to-relative :rax :rsp 3)
    (p2 arg4 :rax)
    (emit-move-register-to-relative :rax :rsp 2)
    (p2 arg5 :rax)
    (emit-move-register-to-relative :rax :rsp 1)
    ;; leave arg6 in rax
    (p2 arg6 :rax)
    (when use-fast-call-p
      (dolist (arg args)
        (unless (single-valued-p arg)
          (emit-clear-values :preserve :rax)
          (return))))
    (cond ((and use-fast-call-p
                kernel-function-p
                (eql (function-arity op) 6)
                (function-code (symbol-function op)))
           (inst :mov :rax :r9)
           (inst :add +bytes-per-word+ :rsp)
           (inst :pop :r8)
           (inst :pop :rcx)
           (inst :pop :rdx)
           (inst :pop :rsi)
           (inst :pop :rdi)
           (emit-call op))
          (use-fast-call-p
           (inst :add +bytes-per-word+ :rsp)
           (inst :pop :r9)
           (inst :pop :r8)
           (inst :pop :rcx)
           (inst :pop :rdx)
           (inst :pop :rsi)
           (inst :push :rax) ; arg6 is passed on the stack
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rdi)
                  (inst :call "RT_fast_call_function_6"))
                 (t
                  (p2-symbol op :rdi)
                  (inst :call "RT_fast_call_symbol_6")))
           (inst :add +bytes-per-word+ :rsp))
          ;; not use-fast-call-p
          ((setq thread-register (compiland-thread-register *current-compiland*))
           (inst :add +bytes-per-word+ :rsp)
           (inst :pop :r11) ; temporary for arg5
           (inst :pop :r9)
           (inst :pop :r8)
           (inst :pop :rcx)
           (inst :pop :rdx)
           (inst :push :rax) ; arg6 is passed on the stack
           (inst :push :r11) ; arg5 is passed on the stack
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rsi)
                  (inst :mov thread-register :rdi)
                  (inst :call "RT_thread_call_function_6"))
                 (t
                  (p2-symbol op :rsi)
                  (inst :mov thread-register :rdi)
                  (inst :call "RT_thread_call_symbol_6")))
           (inst :add (* +bytes-per-word+ 2) :rsp))
          (t
           ;; no thread register
           (inst :add +bytes-per-word+ :rsp)
           (inst :pop :r9)
           (inst :pop :r8)
           (inst :pop :rcx)
           (inst :pop :rdx)
           (inst :pop :rsi)
           (inst :push :rax) ; arg6 is passed on the stack
           (cond (kernel-function-p
                  (inst :move-immediate `(:function ,op) :rdi)
                  (inst :call "RT_current_thread_call_function_6"))
                 (t
                  (p2-symbol op :rdi)
                  (inst :call "RT_current_thread_call_symbol_6")))
           (inst :add +bytes-per-word+ :rsp)))
    (clear-register-contents)
    (move-result-to-target target)))

(defknown p2-function-call-n (t t t t) t)
(defun p2-function-call-n (numargs op args target)
  (aver (< 0 numargs call-arguments-limit)) ; FIXME compiler-error
  (let ((kernel-function-p (kernel-function-p op))
        (use-fast-call-p (use-fast-call-p))
        op-register
        numargs-register
        args-register
        thread-register)
    (cond (use-fast-call-p
           (setq op-register :rdi)
           (setq numargs-register :rsi)
           (setq args-register :rdx))
          ((setq thread-register (compiland-thread-register *current-compiland*))
           (setq op-register :rsi)
           (setq numargs-register :rdx)
           (setq args-register :rcx))
          (t
           ;; not use-fast-call-p, no thread register
           (setq op-register :rdi)
           (setq numargs-register :rsi)
           (setq args-register :rdx)))
    (let ((size (* (if (oddp numargs) (1+ numargs) numargs) +bytes-per-word+))
          (index 0))
      (inst :sub size :rsp)
      (dolist (arg args)
        (p2 arg :rax)
        (emit-move-register-to-relative :rax :rsp index)
        (incf index))
      (when use-fast-call-p
        ;; RT_current_thread_call_symbol() calls thread->clear_values(), RT_fast_call_symbol() does not
        (dolist (arg args)
          (unless (single-valued-p arg)
            (emit-clear-values)
            (return))))
      (inst :mov :rsp args-register)
      (emit-move-immediate-dword-to-register numargs numargs-register)
      (cond (kernel-function-p
             (inst :move-immediate `(:function ,op) op-register)
             (cond (use-fast-call-p
                    (emit-call "RT_fast_call_function"))
                   (thread-register
                    (inst :mov thread-register :rdi)
                    (emit-call "RT_thread_call_function"))
                   (t
                    (emit-call "RT_current_thread_call_function"))))
            (t
             ;; not a kernel function
             (p2-symbol op op-register)
             (cond (use-fast-call-p
                    (emit-call "RT_fast_call_symbol"))
                   (thread-register
                    (inst :mov thread-register :rdi)
                    (emit-call "RT_thread_call_symbol"))
                   (t
                    (emit-call "RT_current_thread_call_symbol")))))
      (inst :add size :rsp)))
  (move-result-to-target target))

(defknown p2-local-function-call (t t) t)
(defun p2-local-function-call (form target)
  (declare (type cons form))
  (let* ((op (car form))
         (args (cdr form))
         (numargs (length args))
         (compiland *current-compiland*)
         (thread-register (compiland-thread-register compiland))
         (local-function (find-local-function op))
         (use-fast-call-p (use-fast-call-p))
         op-register
         arg-registers
         runtime-name)
    (declare (type compiland compiland))
    (declare (type local-function local-function))
    (aver thread-register)
    (cond ((<= 0 numargs 4)
           (cond (use-fast-call-p
                  (setq op-register   (first  +call-argument-registers+)) ; rdi
                  (setq arg-registers (subseq +call-argument-registers+ 1 (+ 1 numargs)))
                  (setq runtime-name  (format nil "RT_fast_call_function_~D" numargs)))
                 (t
                  ;; rdi is reserved for thread
                  (setq op-register   (second +call-argument-registers+)) ; rsi
                  (setq arg-registers (subseq +call-argument-registers+ 2 (+ 2 numargs)))
                  (setq runtime-name  (format nil "RT_thread_call_function_~D" numargs))))
           (aver (memq op-register '(:rdi :rsi)))
           (cond ((local-function-callable-name local-function)
                  ;; COMPILE-FILE, no closure vars
                  (mumble "p2-local-function-call local-function-callable-name case~%")
                  (emit-move-function-to-register (local-function-callable-name local-function)
                                                  op-register)
                  (clear-register-contents op-register)
                  (when args
                    (inst :push op-register)
                    (process-args args arg-registers use-fast-call-p)
                    (inst :pop op-register)
                    (clear-register-contents op-register)))
                 ((local-function-function local-function)
                  ;; COMPILE, no closure vars
                  (mumble "p2-local-function-call local-function-function case~%")
                  (process-args args arg-registers use-fast-call-p)
                  (emit-move-immediate (local-function-function local-function) op-register)
                  (clear-register-contents op-register))
                 (t
                  (mumble "p2-local-function-call local-function-var case~%")
                  (p2-var-ref (make-var-ref (local-function-var local-function)) :rax)
                  (inst :push :rax)
                  (process-args args arg-registers use-fast-call-p)
                  (inst :pop op-register)
                  (clear-register-contents op-register)))
           (unless use-fast-call-p
             (inst :mov thread-register :rdi))
           (emit-call runtime-name)
           (move-result-to-target target))
          ((eql numargs 5)
           (p2-local-function-call-5 op args target))
          (t
           ;; more than 4 arguments
           (compiler-unsupported "P2-LOCAL-FUNCTION-CALL numargs = ~D not supported" numargs)))))

(defknown p2-local-function-call-5 (t t t) t)
(defun p2-local-function-call-5 (op args target)
  (let* ((compiland *current-compiland*)
         (thread-register (compiland-thread-register compiland))
         (local-function (find-local-function op))
         (use-fast-call-p (use-fast-call-p))
         (op-register (if use-fast-call-p :rdi :rsi)))
    (declare (type compiland compiland))
    (declare (type local-function local-function))
    (aver thread-register)
    (cond ((local-function-callable-name local-function)
           ;; COMPILE-FILE, no closure vars
           (cond (use-fast-call-p
                  (mumble "p2-local-function-call-5 local-function-callable-name use-fast-call-p case~%")
                  (emit-move-function-to-register (local-function-callable-name local-function)
                                                  op-register)
                  (clear-register-contents op-register)
                  (inst :push op-register)
                  (process-5-args args '(:rsi :rdx :rcx :r8 :r9) t)
                  (inst :pop op-register)
                  (emit-call "RT_fast_call_function_5"))
                 (t
                  (mumble "p2-local-function-call-5 local-function-callable-name default case~%")
                  (process-5-args args '(:rdx :rcx :r8 :r9 :rax) nil)
                  (inst :push :rax) ; arg5 is passed on the stack
                  (inst :push :rax) ; align stack
                  (emit-move-function-to-register (local-function-callable-name local-function)
                                                  op-register)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_5")
                  (inst :add (* +bytes-per-word+ 2) :rsp))))
          ((local-function-function local-function)
           ;; COMPILE, no closure vars
           (cond (use-fast-call-p
                  (mumble "p2-local-function-call-5 local-function-function use-fast-call-p case~%")
                  (process-5-args args '(:rsi :rdx :rcx :r8 :r9) t)
                  (emit-move-immediate (local-function-function local-function) op-register)
                  (emit-call "RT_fast_call_function_5"))
                 (t
                  (mumble "p2-local-function-call-5 local-function-function default case~%")
                  (process-5-args args '(:rdx :rcx :r8 :r9 :rax) nil)
                  (inst :push :rax) ; arg5 is passed on the stack
                  (inst :push :rax) ; align stack
                  (emit-move-immediate (local-function-function local-function) op-register)
                  (inst :mov thread-register :rdi)
                  (emit-call "RT_thread_call_function_5")
                  (inst :add (* +bytes-per-word+ 2) :rsp))))
          (use-fast-call-p
           (mumble "p2-local-function-call-5 use-fast-call-p case~%")
           (p2-var-ref (make-var-ref (local-function-var local-function)) op-register)
           (inst :push op-register)
           (process-5-args args '(:rsi :rdx :rcx :r8 :r9) t)
           (inst :pop op-register)
           (emit-call "RT_fast_call_function_5"))
          (t
           (mumble "p2-local-function-call-5 default case~%")
           (p2-var-ref (make-var-ref (local-function-var local-function)) op-register)
           (inst :push op-register)
           (process-5-args args '(:rdx :rcx :r8 :r9 :rax) nil)
           (inst :pop op-register)
           (inst :push :rax) ; arg5 is passed on the stack
           (inst :push :rax) ; align stack
           (inst :mov thread-register :rdi)
           (emit-call "RT_thread_call_function_5")
           (inst :add (* +bytes-per-word+ 2) :rsp))))
  (move-result-to-target target))

(defknown p2-symbol-global-value (t t) t)
(defun p2-symbol-global-value (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg))
           (LABEL (make-label)))
      (when (eq type 'SYMBOL)
        (process-1-arg arg :rax t)
        (clear-register-contents :rax)
        (inst :compare-immediate nil :rax)
        (emit-jmp-short :e LABEL)
        (let ((displacement (- +symbol-value-offset+ +symbol-lowtag+)))
          (inst :mov `(,displacement :rax) :rax))
        (label LABEL)
        (move-result-to-target target)
        t))))

(defknown p2-symbol-name (t t) t)
(defun p2-symbol-name (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg))
           (LABEL1 (make-label))
           (LABEL2 (make-label)))
      (when (eq type 'SYMBOL)
        (process-1-arg arg :rax t)
        (clear-register-contents :rax)
        (inst :compare-immediate nil :rax)
        (emit-jmp-short :e LABEL1)
        (let ((displacement (- +symbol-name-offset+ +symbol-lowtag+)))
          (inst :mov `(,displacement :rax) :rax))
        (inst :add +typed-object-lowtag+ :rax)
        (move-result-to-target target)
        (emit-jmp-short t LABEL2)
        (label LABEL1)
        (p2-constant +nil-symbol-name+ target)
        (label LABEL2)
        t))))

(defknown p2-symbol-package (t t) t)
(defun p2-symbol-package (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg))
           (LABEL1 (make-label))
           (LABEL2 (make-label)))
      (when (eq type 'SYMBOL)
        (process-1-arg arg :rax t)
        (clear-register-contents :rax)
        (inst :compare-immediate nil :rax)
        (emit-jmp-short :e LABEL1)
        (let ((displacement (- +symbol-package-offset+ +symbol-lowtag+)))
          (inst :mov `(,displacement :rax) :rax))
        (move-result-to-target target)
        (emit-jmp-short t LABEL2)
        (label LABEL1)
        (p2-constant +common-lisp-package+ target)
        (label LABEL2)
        t))))

(defknown p2-var-ref (t t) t)
(defun p2-var-ref (form target)
  (declare (type var-ref form))
  (when (null target)
    ;; nothing to do
    (return-from p2-var-ref))
  (unless (or (memq target '(:stack :return))
              (eql (register-bit-size target) 64))
    (error "unsupported target ~S" target))
  (let ((var (var-ref-var form)))
    (declare (type var var))
    (cond ((var-constant-p var)
           (p2-constant (var-constant-value var) target))
          ((var-special-p var)
           (let ((name (var-name var)))
             (cond ((constantp name)
                    ;; REVIEW
                    (let ((value (symbol-value name)))
                      (cond  ((or (not (compile-file-p))
                                  (integerp value)
                                  (characterp value)
                                  (stringp value))
                              (p2-constant value target))
                             (t
                              (p2-symbol-global-value `(symbol-global-value ',name) target)))))
                   ((compiland-thread-register *current-compiland*)
                    (inst :mov :r12 :rdi)
                    (p2-symbol name :rsi)
                    (emit-call-2 "RT_thread_symbol_value" target))
                   (t
                    (note "P2-VAR-REF: emitting call to RT_current_thread_symbol_value~%")
                    (p2-symbol name :rdi)
                    (emit-call-1 "RT_current_thread_symbol_value" target)))))
          ((var-closure-index var)
           (emit-move-closure-var-to-register var :rax *current-compiland*)
           (set-register-contents :rax var)
           (move-result-to-target target))
;;           ((var-register var)
;;            (let ((reg (var-register var)))
;;              (case target
;;                (:stack
;;                 (inst :push reg))
;;                (:return
;;                 (when (neq reg :rax)
;;                   (inst :mov reg :rax))
;;                 (emit-exit))
;;                (t
;;                 (when (neq reg target)
;;                   (inst :mov reg target)
;;                   (set-register-contents target var))))))
          (t
           (let ((reg (find-register-containing-var var)))
             (if reg
                 (case target
                   (:stack
                    (inst :push reg))
                   (:return
                    (when (neq reg :rax)
                      (inst :mov reg :rax))
                    (emit-exit))
                   (t
                    (when (neq reg target)
                      (inst :mov reg target)
                        (set-register-contents target var))))
                 (case target
                   (:stack
                    (inst :push var))
                   (:return
                    (inst :mov var :rax)
                    (emit-exit))
                   (t
                    (aver (reg64-p target))
                    (inst :mov var target)
                    (set-register-contents target var)))))))))

(defun p2-setq (form target)
  (aver (length-eql form 3))
  (let* ((args (%cdr form))
         (name (%car args))
         (value-form (%cadr args))
         (var (find-visible-var name))
         derived-type)
    (cond ((or (null var)
               (var-special-p var))
           (let ((thread-register (compiland-thread-register *current-compiland*)))
             (cond (thread-register
                    (p2 value-form :rdx)
                    (unless (single-valued-p value-form)
                      (note "P2-SETQ: not single-valued: ~S~%" value-form)
                      (emit-clear-values :preserve :rdx))
                    (p2-constant name :rsi)
                    (inst :mov thread-register :rdi)
                    (emit-call "RT_thread_set_symbol_value"))
                   (t
                    (cond ((single-valued-p value-form)
                           (p2 value-form :rsi))
                          (t
                           (note "P2-SETQ: not single-valued: ~S~%" value-form)
                           (p2 value-form :rsi)
                           (emit-clear-values :preserve :rsi)))
                    (p2-constant name :rdi)
                    (note "P2-SETQ: emitting call to RT_current_thread_set_symbol_value~%")
                    (emit-call "RT_current_thread_set_symbol_value"))))
           (move-result-to-target target))
;;           ((var-register var)
;;            (setq derived-type (derive-type value-form))
;;            (let ((reg (var-register var)))
;;              (process-1-arg value-form reg t)
;;              (clear-var-registers var)
;;              (case target
;;                ((nil)
;;                 ;; nothing to do
;;                 )
;;                (:stack
;;                 (inst :push reg))
;;                (:return
;;                 (when (neq reg :rax)
;;                   (inst :mov reg :rax))
;;                 (emit-exit))
;;                (t
;;                 (unless (eq reg target)
;;                   (inst :mov reg target)
;;                   (set-register-contents target var))))))
          (t
           (cond ((var-closure-index var)
                  (process-1-arg value-form :rax t)
                  (emit-move-register-to-closure-var :rax var *current-compiland*))
                 (t
                  (setq derived-type (derive-type value-form))
                  (process-1-arg value-form :rax t)
                  (inst :mov :rax var)))
           (clear-var-registers var)
           (set-register-contents :rax var)
           (move-result-to-target target)))
    (when var
;;       (mumble "p2-setq calling remove-constraints var = ~S~%" (var-name var))
      (remove-constraints var)
      (when (and derived-type (neq derived-type :unknown))
;;         (mumble "p2-setq calling add-type-constraint var = ~S type = ~S~%"
;;                 (var-name var) derived-type)
        (add-type-constraint var derived-type)))
;;     (move-result-to-target target)
    ))

(defun p2-two-arg-< (form target)
  (declare (type cons form))
  (let* ((args (cdr form))
         (arg1 (car args))
         (arg2 (cadr args))
         (not-less (gensym))
         (full-call (gensym))
         (exit (gensym)))
    (cond ((and (length-eql args 2)
                (fixnump arg2))
           ;; as in (< n 2), for example
           (p2 arg1 :rax)
           (unless (single-valued-p arg1)
             (emit-clear-values :preserve :rax))
           (emit-bytes #xa8 +fixnum-tag-mask+) ; test $0x7,%al
           (emit-jmp-short :nz FULL-CALL)
           ;; falling through, arg1 is a fixnum
           (emit-move-immediate arg2 :rdx)
           (emit-bytes #x48 #x39 #xd0)   ; cmp %rdx,%rax
           (emit-jmp-short :nl NOT-LESS)
           (p2-symbol t :rax)
           (emit-jmp-short t EXIT)
           (label NOT-LESS)
           (p2-symbol nil :rax)
           (emit-jmp-short t exit)
           (label FULL-CALL)
           ;; arg2 is a fixnum literal
           (emit-move-immediate arg2 :rsi)
           ;; arg1 is already in rax
           (inst :mov :rax :rdi)
           (emit-call 'two-arg-<)
           (label EXIT)
           (move-result-to-target target)
           t)
          ((length-eql args 2)
           (process-2-args args '(:rax :rdx) t)
           (emit-bytes #xa8 +fixnum-tag-mask+) ; test $0x7,%al
           (emit-jmp-short :nz FULL-CALL)
           (emit-bytes #xf6 #xc2 +fixnum-tag-mask+) ; test $0x7,%dl
           (emit-jmp-short :nz FULL-CALL)
           ;; falling through, both args are fixnums
           (emit-bytes #x48 #x39 #xd0)   ; t %rdx,%rax
           (emit-jmp-short :nl NOT-LESS)
           (p2-symbol t :rax)
           (emit-jmp-short t EXIT)
           (label NOT-LESS)
           (p2-symbol nil :rax)
           (emit-jmp-short t exit)
           (label FULL-CALL)
           (inst :mov :rdx :rsi)
           (inst :mov :rax :rdi)
           (emit-call 'two-arg-<)
           (label EXIT)
           (move-result-to-target target)
           t))))

(defknown p2-two-arg-- (t t) t)
(defun p2-two-arg-- (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1
           type2
           result-type)
      (when (and (numberp arg1)
                 (numberp arg2))
        (p2-constant (two-arg-- arg1 arg2) target)
        (return-from p2-two-arg-- t))
      (setq type1       (derive-type arg1)
            type2       (derive-type arg2)
            result-type (derive-type form))
      (unless (fixnump arg2)
        (when (and (integer-constant-value type2)
                   (flushable arg2))
;;           (mumble "p2-two-arg-- setting arg2 to ~S~%" (integer-constant-value type2))
          (setq arg2 (integer-constant-value type2))))
      (cond ((eql arg2 0)
;;              (mumble "p2-two-arg-- case 0~%")
             (process-1-arg arg1 :rax t)
             (move-result-to-target target))
            ((and (fixnum-type-p type1)
                  (fixnum-type-p type2)
                  (fixnum-type-p result-type))
             (cond ((and (fixnump arg2)
                         (typep (fixnumize arg2) '(signed-byte 32)))
                    (cond ((reg64-p target)
                           (process-1-arg arg1 target t)
                           (inst :sub (fixnumize arg2) target)
                           (clear-register-contents target))
                          (t
                           (process-1-arg arg1 :rax t)
                           (inst :sub (fixnumize arg2) :rax)
                           (clear-register-contents :rax)
                           (move-result-to-target target))))
                   (t
                    (process-2-args args '(:rax :rdx) t)
                    (inst :sub :rdx :rax)
                    (clear-register-contents :rax)
                    (move-result-to-target target))))
            ((and (fixnump arg2)
                  (typep (fixnumize arg2) '(signed-byte 32)))
             (let ((FULL-CALL (make-label))
                   (EXIT (make-label)))
               (process-1-arg arg1 :rax t)
               ;; save arg1 in case we need to do a full call
               (inst :mov :rax :rdi)
               (clear-register-contents :rdi)
               (unless (fixnum-type-p type1)
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz FULL-CALL))
               (inst :sub (fixnumize arg2) :rax)
               (clear-register-contents :rax)
               (emit-jmp-short :o FULL-CALL)
               (label EXIT)
               (move-result-to-target target)
               (let ((*current-segment* :elsewhere))
                 (label FULL-CALL)
                 (inst :mov (fixnumize arg2) :rsi)
                 (emit-call 'two-arg--)
                 (emit-jmp-short t EXIT))))
            ((or (float-type-p type1)
                 (float-type-p type2))
             (cond ((and (subtypep type1 'DOUBLE-FLOAT)
                         (subtypep type2 'DOUBLE-FLOAT))
                    (mumble "p2-two-arg-- double-float case~%")
                    (process-2-args args '(:rdi :rsi) t)
                    (emit-call '%double-float--)
                    (move-result-to-target target))
                   (t
                    ;; full call
                    (mumble "p2-two-arg-- float case~%")
                    (process-2-args args '(:rdi :rsi) t)
                    (emit-call 'two-arg--)
                    (move-result-to-target target))))
            (t
             (let ((FULL-CALL (make-label))
                   (EXIT (make-label)))
               (process-2-args args '(:rax :rdx) t)
               ;; save arg1 in case we need to do a full call
               (inst :mov :rax :rdi)
               (clear-register-contents :rdi)
               (unless (fixnum-type-p type1)
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz FULL-CALL))
               (unless (fixnum-type-p type2)
                 (inst :test +fixnum-tag-mask+ :dl)
                 (emit-jmp-short :nz FULL-CALL))
               ;; falling through, both args are fixnums
               (inst :sub :rdx :rax)
               (clear-register-contents :rax)
               (emit-jmp-short :o FULL-CALL)
               (label EXIT)
               (move-result-to-target target)
               (let ((*current-segment* :elsewhere))
                 (label FULL-CALL)
                 (inst :mov :rdx :rsi)
                 (emit-call 'two-arg--)
                 (emit-jmp-short t EXIT))))))
    t))

(defknown p2-two-arg-+ (t t) t)
(defun p2-two-arg-+ (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1
           type2
           result-type)
      (when (and (numberp arg1)
                 (numberp arg2))
        (p2-constant (two-arg-+ arg1 arg2) target)
        (return-from p2-two-arg-+ t))
      (when (fixnump arg1)
        (let ((temp arg1))
          (setq arg1 arg2
                arg2 temp))
        (setq args (list arg1 arg2)))
      (setq type1       (derive-type arg1)
            type2       (derive-type arg2)
            result-type (derive-type form))
      (unless (fixnump arg2)
        (when (and (integer-constant-value type2)
                   (flushable arg2))
;;           (mumble "p2-two-arg-+ setting arg2 to ~S~%" (integer-constant-value type2))
          (setq arg2 (integer-constant-value type2))))
;;       (let ((*print-structure* nil))
;;         (mumble "arg1 = ~S type1 = ~S~%" arg1 type1)
;;         (mumble "arg2 = ~S type2 = ~S~%" arg2 type2))
      (cond ((eql arg2 0)
;;              (mumble "p2-two-arg-+ case 0~%")
             (process-1-arg arg1 :rax t)
             (move-result-to-target target))
            ((and (fixnum-type-p type1)
                  (fixnum-type-p type2)
                  (fixnum-type-p result-type))
             (cond ((and (fixnump arg2)
                         (typep (fixnumize arg2) '(signed-byte 32)))
                    (cond ((reg64-p target)
;;                            (mumble "p2-two-arg-+ case 1a target = ~S~%" target)
                           (process-1-arg arg1 target t)
                           (inst :add (fixnumize arg2) target)
                           (clear-register-contents target))
                          (t
;;                            (mumble "p2-two-arg-+ case 1b target = ~S~%" target)
                           (process-1-arg arg1 :rax t)
                           (inst :add (fixnumize arg2) :rax)
                           (clear-register-contents :rax)
                           (move-result-to-target target))))
                   (t
;;                     (mumble "p2-two-arg-+ case 1c target = ~S~%" target)
                    (process-2-args args '(:rax :rdx) t)
                    (inst :add :rdx :rax)
                    (clear-register-contents :rax)
                    (move-result-to-target target))))
            ((and (fixnump arg2)
                  (typep (fixnumize arg2) '(signed-byte 32)))
;;              (mumble "p2-two-arg-+ case 2~%")
             (let ((FULL-CALL (gensym))
                   (EXIT (gensym)))
               (process-1-arg arg1 :rax t)
               (unless (constant-or-local-var-ref-p arg1)
                 (inst :mov :rax :rdi))
               (unless (fixnum-type-p type1)
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz FULL-CALL))
               ;; falling through, both args are fixnums
               (cond ((typep (fixnumize arg2) '(signed-byte 8))
                      (inst :add (fixnumize arg2) :rax)
                      (clear-register-contents :rax))
                     (t
                      (inst :mov (fixnumize arg2) :rdx)
                      (inst :add :rdx :rax)
                      (clear-register-contents :rax :rdx)))
               (emit-jmp-short :o FULL-CALL)
               (label EXIT)
               (move-result-to-target target)
               (let ((*current-segment* :elsewhere))
                 (label FULL-CALL)
                 (clear-register-contents)
                 (when (constant-or-local-var-ref-p arg1)
                   (process-1-arg arg1 :rdi nil))
                 (inst :mov (fixnumize arg2) :rsi)
                 (emit-call 'two-arg-+)
                 (emit-jmp-short t EXIT))))
            ((or (float-type-p type1)
                 (float-type-p type2))
             (cond ((and (subtypep type1 'DOUBLE-FLOAT)
                         (subtypep type2 'DOUBLE-FLOAT))
                    (mumble "p2-two-arg-+ double-float case~%")
                    (process-2-args args '(:rdi :rsi) t)
                    (emit-call '%double-float-+)
                    (move-result-to-target target))
                   (t
                    ;; full call
                    (mumble "p2-two-arg-+ float case~%")
                    (process-2-args args '(:rdi :rsi) t)
                    (emit-call 'two-arg-+)
                    (move-result-to-target target))))
            (t
;;              (mumble "p2-two-arg-+ case 3~%")
             (let ((FULL-CALL (make-label))
                   (EXIT (make-label)))
               (process-2-args args '(:rax :rdx) t)
               (inst :mov :rax :rdi)
;;                (mumble "type1 = ~S type2 = ~S~%" type1 type2)
               (unless (fixnum-type-p type1)
;;                  (let ((*print-structure* nil))
;;                    (mumble "testing arg1 ~S~%" arg1))
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz FULL-CALL))
               (unless (fixnum-type-p type2)
;;                  (let ((*print-structure* nil))
;;                    (mumble "testing arg2 ~S~%" arg2))
                 (inst :test +fixnum-tag-mask+ :dl)
                 (emit-jmp-short :nz FULL-CALL))
               ;; falling through, both args are fixnums
               (inst :add :rdx :rax)
               (emit-jmp-short :o FULL-CALL)
               (label EXIT)
               (move-result-to-target target)
               (let ((*current-segment* :elsewhere))
                 (label FULL-CALL)
                 (inst :mov :rdx :rsi)
                 (emit-call 'two-arg-+)
                 (emit-jmp-short t EXIT))))))
    t))

(defun p2-two-arg-* (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args)))
      (when (and (numberp arg1)
                 (numberp arg2))
        (p2-constant (two-arg-* arg1 arg2) target)
        (return-from p2-two-arg-* t))
      (when (numberp arg1)
        (let ((temp arg1))
          (setq arg1 arg2
                arg2 temp
                args (list arg1 arg2))))
      (let* ((type1 (derive-type arg1))
             (type2 (derive-type arg2)))
        (cond ((and (integer-constant-value type1)
                    (integer-constant-value type2)
                    (flushable arg1)
                    (flushable arg2))
               (mumble "p2-two-arg-* integer-constant-value case~%")
               (p2-constant (two-arg-* (integer-constant-value type1) (integer-constant-value type2))
                            target)
               (return-from p2-two-arg-* t))
              ((or (float-type-p type1)
                   (float-type-p type2))
               ;; full call
               (mumble "p2-two-arg-* float case~%")
               (process-2-args args '(:rdi :rsi) t)
               (emit-call 'two-arg-*)
               (move-result-to-target target)
               (return-from p2-two-arg-* t)))
        (let* ((result-type (derive-type form)))
          (mumble "p2-two-arg-* type1 = ~S type2 = ~S~%" type1 type2)
          (mumble "p2-two-arg-* result-type = ~S~%" result-type)
          (cond ((and (fixnum-type-p type1)
                      (fixnum-type-p type2)
                      (fixnum-type-p result-type))
                 (mumble "p2-two-arg-* fixnum case~%")
                 (cond ((and (fixnump arg2)
                             (memql arg2 '(0 1 2 4 8 16 32 64 128 256)))
                        (mumble "p2-two-arg-* special case arg2 = ~S~%" arg2)
                        (unless (and (eql arg2 0) (flushable arg1))
                          (process-1-arg arg1 :rax t))
                        (case arg2
                          (0
                           (inst :xor :eax :eax))
                          (1
                           ;; nothing to do
                           )
                          (2
                           (inst :shl :rax))
                          (t
                           (let ((shift (cdr (assoc arg2 '((  4 . 2)
                                                           (  8 . 3)
                                                           ( 16 . 4)
                                                           ( 32 . 5)
                                                           ( 64 . 6)
                                                           (128 . 7)
                                                           (256 . 8))))))
                             (mumble "shift = ~S~%" shift)
                             (inst :shl shift :rax))))
                        (move-result-to-target target))
                       (t
                        (process-2-args args '(:rax :rdx) t)
                        ;; arg1 in rax, arg2 in rdx
                        (unbox-fixnum :rax)
                        ;; note that we need to unbox only one of the args, so the result will end up boxed
                        (emit-bytes #x48 #x0f #xaf #xc2) ; imul %rdx,%rax
                        (move-result-to-target target))))
                (t
                 (mumble "p2-two-arg-* default case~%")
                 (let ((OVERFLOW (make-label))
                       (FULL-CALL (make-label))
                       (EXIT (make-label)))
                   (process-2-args args '(:rax :rdx) t)
                   ;; arg1 in rax, arg2 in rdx
                   (unless (fixnum-type-p type1)
                     (inst :test +fixnum-tag-mask+ :al)
                     (emit-jmp-short :nz FULL-CALL))
                   (unless (fixnum-type-p type2)
                     (inst :test +fixnum-tag-mask+ :dl)
                     (emit-jmp-short :nz FULL-CALL))
                   ;; falling through, both args are fixnums
                   ;; save arg1 in rcx in case overflow occurs and we need to do a full call
                   ;; FIXME if the result is known to be not a fixnum, we should just do a full call right away
                   (inst :mov :rax :rcx)
                   (unbox-fixnum :rax)
                   ;; note that we need to unbox only one of the args, so the result will end up boxed
                   (emit-bytes #x48 #x0f #xaf #xc2) ; imul %rdx,%rax
                   (unless (fixnum-type-p result-type)
                     (case target
                       (:return
                        (emit-jmp-short :o OVERFLOW)
                        ;; falling through: no overflow, we're done
                        (emit-exit)
                        (label OVERFLOW))
                       (t
                        ;; if no overflow, we're done
                        (emit-jmp-short :no EXIT)))
                     (inst :mov :rcx :rax)
                     (label FULL-CALL)
                     (inst :mov :rdx :rsi)
                     (inst :mov :rax :rdi)
                     (emit-call 'two-arg-*)
                     (label EXIT))
                   (move-result-to-target target)))))))
    t))

(defknown p2-%char-code (t t) t)
(defun p2-%char-code (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (process-1-arg arg :rax t)
      (inst :sub +character-lowtag+ :al)
      (inst :shr :eax)
      (clear-register-contents :rax)
      (move-result-to-target target)
      t)))

(defun p2-char-code (form target)
  (when (check-arg-count form 1)
    (cond ((zerop *safety*)
           (p2-%char-code form target))
          ((eq (derive-type (%cadr form)) 'CHARACTER)
           (p2-%char-code form target))
          (t
           nil))))

(defknown p2-%code-char (t t) t)
(defun p2-%code-char (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (process-1-arg arg :rax t)
      (inst :shl :eax)
      (inst :add +character-lowtag+ :al)
      (clear-register-contents :rax)
      (move-result-to-target target)
      t)))

(defun p2-code-char (form target)
  (when (check-arg-count form 1)
    (let (type)
      (cond ((zerop *safety*)
             (p2-%code-char form target))
            ((and (neq (setq type (derive-type (%cadr form))) :unknown)
                  (subtypep type '(integer 0 #.char-code-limit)))
             (p2-%code-char form target))
            (t
             nil)))))

(defknown p2-%car (t t) t)
(defun p2-%car (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form)))
      (cond ((reg64-p target)
             (process-1-arg arg target t)
             (inst :mov `(-1 ,target) target)
             (clear-register-contents target))
            (t
             (process-1-arg arg :rax t)
             (inst :mov '(-1 :rax) :rax)
             (clear-register-contents :rax)
             (move-result-to-target target)))
      t)))

(defknown p2-car (t t) t)
(defun p2-car (form target)
  (when (zerop *safety*)
    (return-from p2-car (p2-%car form target)))
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg)))
      (cond ((eq type 'LIST)
             (p2-%car form target))
            ((cons-type-p type)
             (p2-%car form target))
            (t
             (process-1-arg arg :rdi t)
             (let ((ERROR (common-label-error-not-list *current-compiland* :rdi)))
               (inst :mov :rdi :rax)
               (clear-register-contents :rax)
               (inst :and +lowtag-mask+ :al)
               (inst :cmp +list-lowtag+ :al)
               (emit-jmp-short :ne ERROR)
               (inst :mov '(-1 :rdi) :rax)
               (move-result-to-target target)
               (when (var-ref-p arg)
                 (add-type-constraint (var-ref-var arg) 'LIST))))))
    t))

(defknown p2-%cdr (t t) t)
(defun p2-%cdr (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (cond ((reg64-p target)
             (process-1-arg arg target t)
             (inst :mov `(7 ,target) target)
             (clear-register-contents target))
            (t
             (process-1-arg arg :rax t)
             (inst :mov '(7 :rax) :rax)
             (clear-register-contents :rax)
             (move-result-to-target target))))
    t))

(defknown p2-cdr (t t) t)
(defun p2-cdr (form target)
  (when (zerop *safety*)
    (return-from p2-cdr (p2-%cdr form target)))
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg)))
      (cond ((eq type 'LIST)
             (p2-%cdr form target))
            ((cons-type-p type)
             (p2-%cdr form target))
            (t
             (process-1-arg arg :rdi t)
             (let ((ERROR (common-label-error-not-list *current-compiland* :rdi)))
               (inst :mov :rdi :rax)
               (clear-register-contents :rax)
               (inst :and +lowtag-mask+ :al)
               (inst :cmp +list-lowtag+ :al)
               (emit-jmp-short :ne ERROR)
               (inst :mov '(7 :rdi) :rax)
               (move-result-to-target target)
               (when (var-ref-p arg)
                 (add-type-constraint (var-ref-var arg) 'LIST))))))
    t))

(defknown p2-rplaca (t t) t)
(defun p2-rplaca (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (type1 (derive-type arg1)))
      (when (cons-type-p type1)
        (process-2-args args '(:rax :rdx) t)
        (inst :mov :rdx '(-1 :rax))
        (move-result-to-target target)
        t))))

(defknown p2-setcar (t t) t)
(defun p2-setcar (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (type1 (derive-type arg1)))
      (when (cons-type-p type1)
        (process-2-args args '(:rdx :rax) t)
        (inst :mov :rax '(-1 :rdx))
        (move-result-to-target target)
        t))))

(defknown p2-rplacd (t t) t)
(defun p2-rplacd (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (type1 (derive-type arg1)))
      (when (cons-type-p type1)
        (process-2-args args '(:rax :rdx) t)
        (inst :mov :rdx '(7 :rax))
        (move-result-to-target target)
        t))))

(defun p2-setcdr (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (type1 (derive-type arg1)))
      (when (cons-type-p type1)
        (process-2-args args '(:rdx :rax) t)
        (inst :mov :rax '(7 :rdx))
        (move-result-to-target target)
        t))))

(defun p2-require-boolean (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form))
          type)
      (cond ((zerop *safety*)
             (p2 arg target))
            ((and (neq (setq type (derive-type arg)) :unknown)
                  (subtypep type 'BOOLEAN))
               (p2 arg target))
            (t
             (process-1-arg arg :rax t)
             (let* ((EXIT (make-label))
                    (common-labels (compiland-common-labels *current-compiland*))
                    (ERROR (gethash :error-not-boolean common-labels)))
               (unless ERROR
                 (setq ERROR (make-label))
                 (let ((*current-segment* :elsewhere))
                   (label ERROR)
                   ;; arg is in rax
                   (inst :mov :rax :rdi)
                   (p2-symbol 'BOOLEAN :rsi)
                   (emit-call '%type-error)
                   (emit-exit) ; FIXME
                   (setf (gethash :error-not-boolean common-labels) ERROR)))
               (inst :compare-immediate nil :rax)
               (emit-jmp-short :e EXIT)
               (inst :compare-immediate t :rax)
               (emit-jmp-short :ne ERROR)
               (label EXIT)
               (when target
                 (move-result-to-target target))))))
    t))

(defun p2-require-list (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form))
          type)
      (cond ((zerop *safety*)
             (p2 arg target))
            ((and (neq (setq type (derive-type arg)) :unknown)
                  (subtypep type 'LIST))
             (p2 arg target))
            (t
             (process-1-arg arg :rax t)
             (let ((ERROR (common-label-error-not-list *current-compiland* :rax)))
               (inst :push :rax)
               (inst :and +lowtag-mask+ :al)
               (inst :cmp +list-lowtag+ :al)
               (inst :pop :rax)
               (emit-jmp-short :ne ERROR)
               (when (var-ref-p arg)
                 (set-register-contents :rax (var-ref-var arg)))
               (when target
                 (move-result-to-target target))))))
    t))

(defun p2-require-symbol (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form))
          type)
      (cond ((zerop *safety*)
             (p2 arg target))
            ((eq (setq type (derive-type arg)) 'SYMBOL)
             (p2 arg target))
            (t
             (process-1-arg arg :rax t)
             (let* ((EXIT (make-label))
                    (common-labels (compiland-common-labels *current-compiland*))
                    (ERROR (gethash :error-not-symbol common-labels)))
               (unless ERROR
                 (setq ERROR (make-label))
                 (let ((*current-segment* :elsewhere))
                   (label ERROR)
                   ;; arg is already in rdi
                   (p2-symbol 'SYMBOL :rsi)
                   (emit-call '%type-error)
                   (emit-exit) ; FIXME
                   (setf (gethash :error-not-symbol common-labels) ERROR)))
               (inst :compare-immediate nil :rax)
               (emit-jmp-short :e EXIT)
               (when target
                 (inst :push :rax))
               (inst :and +lowtag-mask+ :al)
               (inst :cmp +symbol-lowtag+ :al)
               (when target
                 (inst :pop :rax))
               (emit-jmp-short :ne ERROR)
               (label EXIT)
               (when target
                 (move-result-to-target target))))))
    t))

(defknown p2-%cadr (t t) t)
(defun p2-%cadr (form target)
  (when (check-arg-count form 1)
    (process-1-arg (%cadr form) :rax t)
    (inst :mov '(7 :rax) :rax)
    ;; FIXME if target is a register, do the move in one step
    (inst :mov '(-1 :rax) :rax)
    (clear-register-contents :rax)
    (move-result-to-target target)
    t))

(defknown p2-%cddr (t t) t)
(defun p2-%cddr (form target)
  (when (check-arg-count form 1)
    (process-1-arg (%cadr form) :rax t)
    ;; FIXME if target is a register, do the move in one step
    (inst :mov '(7 :rax) :rax)
    (inst :mov '(7 :rax) :rax)
    (clear-register-contents :rax)
    (move-result-to-target target)
    t))

(defknown p2-%caddr (t t) t)
(defun p2-%caddr (form target)
  (when (check-arg-count form 1)
    (process-1-arg (%cadr form) :rax t)
    (inst :mov '(7 :rax) :rax)
    (inst :mov '(7 :rax) :rax)
    ;; FIXME if target is a register, do the move in one step
    (inst :mov '(-1 :rax) :rax)
    (clear-register-contents :rax)
    (move-result-to-target target)
    t))

(defun p2-endp (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (process-1-arg arg :rdi t)
      (let* ((LABEL1 (make-label))
             (LABEL2 (make-label))
             (ERROR (make-label)))
          (let ((*current-segment* :elsewhere))
            (label ERROR)
            ;; arg is already in rdi
            (emit-call 'error-not-list)
            (emit-exit) ; FIXME
            )
        (inst :mov :edi :eax)
        (inst :and +lowtag-mask+ :al)
        (inst :cmp +list-lowtag+ :al)
        (emit-jmp-short :ne ERROR)
        (inst :compare-immediate nil :rdi)
        (emit-jmp-short :e LABEL1)
        (p2 nil :rax)
        (emit-jmp-short t LABEL2)
        (label LABEL1)
        (p2 t :rax)
        (label LABEL2)
        (clear-register-contents :rax)
        (when target
          (move-result-to-target target))
        t))))

(defknown p2-eq (t t) t)
(defun p2-eq (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (EXIT (make-label)))
      (when (or (characterp arg1) (fixnump arg1))
        (let ((temp arg1))
          (setq arg1 arg2
                arg2 temp))
        (setq args (list arg1 arg2)))
      (cond ((characterp arg2)
             (process-1-arg arg1 :rax t)
             (inst :cmp (+ (ash (char-code arg2) +character-shift+) +character-lowtag+) :rax))
            ((and (fixnump arg2)
                  (typep (fixnumize arg2) '(signed-byte 32)))
             (process-1-arg arg1 :rax t)
             (inst :cmp (fixnumize arg2) :rax))
            (t
             (process-2-args args '(:rax :rdx) t)
             (inst :cmp :rdx :rax)))
      (p2-symbol t :rax)
      (inst :jmp-short :e EXIT)
      (p2-symbol nil :rax)
      (label EXIT)
      (clear-register-contents :rax)
      (move-result-to-target target))
    t))

(defknown p2-neq (t t) t)
(defun p2-neq (form target)
  (when (check-arg-count form 2)
    (let* ((EXIT (make-label)))
      (process-2-args (%cdr form) '(:rax :rdx) t)
      (inst :cmp :rdx :rax)
      (p2-symbol t :rax)
      (emit-jmp-short :ne EXIT)
      (p2-symbol nil :rax)
      (label EXIT)
      (clear-register-contents :rax)
      (move-result-to-target target))
    t))

(defun p2-funcall (form target)
  (when (and (> (length form) 1)
             ;; If the operator names a special operator or macro, we need to
             ;; signal a program error (not a type error) in safe code.
             (< *safety* 3))
    (let* ((operator-form (%cadr form))
           (operator-derived-type (derive-type operator-form))
           (args (cddr form))
           (numargs (length args))
           (use-fast-call-p (use-fast-call-p))
           (thread-register (compiland-thread-register *current-compiland*)))
      (cond ((and (consp operator-form)
                  (eq (%car operator-form) 'QUOTE)
                  (length-eql operator-form 2)
                  (symbolp (%cadr operator-form)))
;;              (mumble "p2-funcall optimization 1~%")
             (p2-function-call (list* (%cadr operator-form) args) target)
             t)
            ((and (consp operator-form)
                  (eq (%car operator-form) 'FUNCTION)
                  (length-eql operator-form 2)
                  (symbolp (%cadr operator-form)))
             (aver thread-register)
             (let* ((name (%cadr operator-form))
                    (kernel-function-p (kernel-function-p name)))
               (cond ((or kernel-function-p
                          (memq name *functions-defined-in-current-file*))
                      (case numargs
                        (1
                         (cond ((and use-fast-call-p
                                     kernel-function-p
                                     (eql (function-arity name) 1)
                                     (function-code (symbol-function name)))
                                (process-1-arg (%car args) :rdi t)
                                (emit-call name))
                               (use-fast-call-p
                                (process-1-arg (%car args) :rsi t)
                                (emit-move-function-to-register name :rdi)
                                (emit-call "RT_fast_call_function_1"))
                               (t
                                (process-1-arg (%car args) :rdx nil)
                                (emit-move-function-to-register name :rsi)
                                (inst :mov thread-register :rdi)
                                (emit-call "RT_thread_call_function_1")))
                         (move-result-to-target target))
                        (t
                         (mumble "p2-funcall optimization 2 needs work! numargs = ~D~%" numargs)
                         (p2-function-call (list* name args) target))))
                     (t
                      (p2-function-call (list* name args) target))))
             t)
            ((eq operator-derived-type 'SYMBOL)
;;              (mumble "p2-funcall optimization 3~%")
             (case numargs
               (1
                (cond (use-fast-call-p
                       (process-2-args (cdr form) '(:rdi :rsi) t)
                       (emit-call "RT_fast_call_symbol_1")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-2-args (cdr form) '(:rsi :rdx) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_symbol_1")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 1a~%")
                       nil)))
               (4
                (cond (use-fast-call-p
                       (process-5-args (cdr form) '(:rdi :rsi :rdx :rcx :r8) t)
                       (emit-call "RT_fast_call_symbol_4")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-5-args (cdr form) '(:rsi :rdx :rcx :r8 :r9) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_symbol_4")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 1b~%")
                       nil)))
               (t
                (mumble "p2-funcall not optimized 2~%")
                nil)))
            ((eq operator-derived-type 'FUNCTION)
;;              (mumble "p2-funcall optimization 4~%")
             (case numargs
               (0
                (cond (use-fast-call-p
                       (process-1-arg (cadr form) :rdi t)
                       (emit-call "RT_fast_call_function_0")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-1-arg (cadr form) :rsi nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_function_0")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 3a~%")
                       nil)
                      ))
               (1
                (cond (use-fast-call-p
                       (process-2-args (cdr form) '(:rdi :rsi) t)
                       (emit-call "RT_fast_call_function_1")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-2-args (cdr form) '(:rsi :rdx) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_function_1")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 3b~%")
                       nil)
                      ))
               (2
                (cond (use-fast-call-p
                       (process-3-args (cdr form) '(:rdi :rsi :rdx) t)
                       (emit-call "RT_fast_call_function_2")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-3-args (cdr form) '(:rsi :rdx :rcx) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_function_2")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 4a~%")
                       nil)
                      ))
               (3
                (cond (use-fast-call-p
                       (process-4-args (cdr form) '(:rdi :rsi :rdx :rcx) t)
                       (emit-call "RT_fast_call_function_3")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-4-args (cdr form) '(:rsi :rdx :rcx :r8) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_function_3")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 4b~%")
                       nil)
                      ))
               (4
                (cond (use-fast-call-p
                       (process-5-args (cdr form) '(:rdi :rsi :rdx :rcx :r8) t)
                       (emit-call "RT_fast_call_function_4")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-5-args (cdr form) '(:rsi :rdx :rcx :r8 :r9) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_call_function_4")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 4c~%")
                       nil)
                      ))
               (t
                (mumble "p2-funcall not optimized 5 numargs = ~D~%" numargs)
                nil)
               ))
            (t
;;              (mumble "p2-funcall optimization 5~%")
             (case numargs
               (0
                (cond (use-fast-call-p
                       (process-1-arg (cadr form) :rdi t)
                       (emit-call "RT_fast_funcall_0")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-1-arg (cadr form) :rsi nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_funcall_0")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 6~%")
                       nil)))
               (1
                (cond (use-fast-call-p
                       (process-2-args (cdr form) '(:rdi :rsi) t)
                       (emit-call "RT_fast_funcall_1")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-2-args (cdr form) '(:rsi :rdx) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_funcall_1")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 7~%")
                       nil)))
               (2
                (cond (use-fast-call-p
                       (process-3-args (cdr form) '(:rdi :rsi :rdx) t)
                       (emit-call "RT_fast_funcall_2")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-3-args (cdr form) '(:rsi :rdx :rcx) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_funcall_2")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 8~%")
                       nil)))
               (3
                (cond (use-fast-call-p
                       (process-4-args (cdr form) '(:rdi :rsi :rdx :rcx) t)
                       (emit-call "RT_fast_funcall_3")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-4-args (cdr form) '(:rsi :rdx :rcx :r8) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_funcall_3")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 9~%")
                       nil)))
               (4
                (cond (use-fast-call-p
                       (process-5-args (cdr form) '(:rdi :rsi :rdx :rcx :r8) t)
                       (emit-call "RT_fast_funcall_4")
                       (move-result-to-target target)
                       t)
                      (thread-register
                       (process-5-args (cdr form) '(:rsi :rdx :rcx :r8 :r9) nil)
                       (inst :mov thread-register :rdi)
                       (emit-call "RT_thread_funcall_4")
                       (move-result-to-target target)
                       t)
                      (t
                       (mumble "p2-funcall not optimized 10~%")
                       nil)))
               (t
                (mumble "p2-funcall not optimized 11 numargs = ~D~%" numargs)
                nil)))))))

(defun p2-length (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg)))
      (cond ((and (neq type :unknown)
                  (subtypep type '(SIMPLE-ARRAY * 1)))
             (let ((reg (process-1-arg arg :register t))
                   (displacement (- +vector-capacity-offset+ +typed-object-lowtag+)))
               (cond ((reg64-p target)
                      (mumble "p2-length reg64-p target reg = ~S~%" reg)
                      (inst :mov `(,displacement ,reg) target)
                      (clear-register-contents target)
                      (inst :shl +fixnum-shift+ target))
                     (t
                      (mumble "p2-length other target reg = ~S~%" reg)
                      (inst :mov `(,displacement ,reg) :rax)
                      (clear-register-contents :rax)
                      (inst :shl +fixnum-shift+ :rax)
                      (move-result-to-target target)))))
            ((and (neq type :unknown)
                  (subtypep type 'VECTOR))
             (p2 arg :rdi)
             (emit-call-1 '%vector-length target))
            ((and (neq type :unknown)
                  (subtypep type 'LIST))
             (setf (car form) '%list-length)
             (p2-function-call form target))
            (t
             (p2-function-call form target)
             (when (var-ref-p arg)
               (add-type-constraint (var-ref-var arg) 'SEQUENCE)))))
    t))

;; FIXME teach p2-function-call-3 about safe calls
(defun p2-list3 (form target)
  (when (check-arg-count form 3)
    (process-3-args (%cdr form) '(:rdi :rsi :rdx) t)
    (emit-call 'list3)
    (move-result-to-target target)
    t))

;; FIXME teach p2-function-call-4 about safe calls
(defun p2-list4 (form target)
  (when (check-arg-count form 4)
    (process-4-args (%cdr form) '(:rdi :rsi :rdx :rcx) t)
    (emit-call 'list4)
    (move-result-to-target target)
    t))

(defun p2-min/max (form target)
  (let* ((op (car form))
         (args (cdr form)))
    (when (length-eql args 2)
      (let* ((arg1 (%car args))
             (arg2 (%cadr args))
             (type1 (derive-type arg1))
             (type2 (derive-type arg2)))
        (process-2-args args '(:rax :rdx) t)
        ;; arg1 in rax, arg2 in rdx
        (let ((FULL-CALL (gensym))
              (EXIT (gensym)))
          (unless (fixnum-type-p type1)
            (inst :test +fixnum-tag-mask+ :al)
            (emit-jmp-short :nz FULL-CALL))
          (unless (fixnum-type-p type2)
            (inst :test +fixnum-tag-mask+ :dl)
            (emit-jmp-short :nz FULL-CALL))
          ;; falling through, both args are fixnums
          (inst :cmp :rdx :rax)
          (emit-jmp-short (ecase op
                            ((min two-arg-min) :l)
                            ((max two-arg-max) :g))
                          EXIT)
          (inst :mov :rdx :rax)
          (clear-register-contents :rax)
          (unless (and (fixnum-type-p type1)
                       (fixnum-type-p type2))
            (emit-jmp-short t EXIT)
            (label FULL-CALL)
            (inst :mov :rdx :rsi)
            (inst :mov :rax :rdi)
            (emit-call op))
          (label EXIT)
          (move-result-to-target target)))
      t)))

(defun p2-gethash (form target)
  (let* ((op (car form))
         (args (cdr form))
         (arg2 (second args))
         (type2 (derive-type arg2))
         (numargs (length args))
         thread-register)
    (cond ((and (eq type2 :unknown)
                (not (zerop *safety*)))
           nil)
          ((or (zerop *safety*)
               (subtypep type2 'HASH-TABLE))
           (case numargs
             (2
              (ecase op
                (gethash2-1
                 (process-2-args args :default t)
                 (emit-call-2 '%gethash2-1 target))
                (gethash2
                 (cond ((setq thread-register (compiland-thread-register *current-compiland*))
                        (process-2-args args '(:rsi :rdx) t)
                        (inst :mov thread-register :rdi)
                        (emit-call-3 "RT_gethash2" target))
                       (t
                        (process-2-args args :default t)
                        (emit-call-2 op target)))))
              t)
             (3
              (cond ((setq thread-register (compiland-thread-register *current-compiland*))
                     (process-3-args args '(:rsi :rdx :rcx) t)
                     (inst :mov thread-register :rdi)
                     (emit-call-4 "RT_gethash3" target))
                    (t
                     (process-3-args args :default t)
                     (emit-call-3 'gethash3 target)))
              t)
             (t
              ;; wrong number of arguments
              nil)))
          (t
           ;; error
           nil))))

(defun p2-ash (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1
           type2)
      (when (and (integerp arg1) (integerp arg2))
        (p2-constant (ash arg1 arg2) target)
        (return-from p2-ash t))
      (setq type1 (derive-type arg1)
            type2 (derive-type arg2))

;;       (mumble "p2-ash result type = ~S~%" (derive-type form))
;;       (mumble "p2-ash type1 = ~S type2 = ~S~%" type1 type2)

      (cond ((and (integer-constant-value type1)
                  (integer-constant-value type2))
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
             (p2-constant (ash (integer-constant-value type1) (integer-constant-value type2))
                          target)
             t)
            ((and (eql (integer-constant-value type2) 0)
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
                  (fixnum-type-p (derive-type form)))
;;              (mumble "arg2 = ~S~%" arg2)
             (let ((shift (integer-constant-value type2)))
;;                (mumble "shift = ~S~%" shift)
               (cond ((and shift
                           (< shift 0)
                           (> shift -64))
                      (cond ((flushable arg2)
;;                              (mumble "p2-ash new optimized case 1~%")
                             (process-1-arg arg1 :rax t)
                             (emit-bytes #x48 #xc1 #xf8 (- shift)) ; sar imm8,%rax
                             (emit-bytes #x48 #x83 #xe0 #xfc) ; and $0xfc,%rax
;;                              (emit-bytes #x83 #xe0 #xfc) ; and $0xfc,%eax
                             )
                            (t
;;                              (mumble "p2-ash new optimized case 2~%")
                             (process-2-args args '(:rax :rcx) t)
                             (unbox-fixnum :rcx)
                             (emit-bytes #x48 #xf7 #xd9) ; neg %rcx
                             (emit-bytes #x48 #xd3 #xf8) ; sar %cl,%rax
                             ;; zero out tag bits
                             (emit-bytes #x48 #x83 #xe0 #xfc) ; and $0xfc,%rax
;;                              (emit-bytes #x83 #xe0 #xfc) ; and $0xfc,%eax
                             ))
                      (move-result-to-target target)
                      t)
                     ((and shift
                           (>= shift 0)
                           (< shift 64))
                      (cond ((flushable arg2)
;;                              (mumble "p2-ash new optimized case 3~%")
                             (process-1-arg arg1 :rax t)
                             (unless (eql shift 0)
                               (emit-bytes #x48 #xc1 #xe0 shift)) ; shl imm8,%rax
                             )
                            (t
;;                              (mumble "p2-ash new optimized case 4~%")
                             (process-2-args args '(:rax :rcx) t)
                             (unbox-fixnum :rcx)
                             (emit-bytes #x48 #xd3 #xe0) ; shl %cl,%rax
                             ))
                      (move-result-to-target target)
                      t)
;;                      ((subtypep type2 '(INTEGER -63 -1))
                      ((subtypep type2 '(INTEGER -63 0))
;;                       (mumble "p2-ash new optimized case 5~%")
                      (process-2-args args '(:rax :rcx) t)
                      (unbox-fixnum :rcx)
                      (emit-bytes #x48 #xf7 #xd9) ; neg %rcx
                      (emit-bytes #x48 #xd3 #xf8) ; sar %cl,%rax
                      ;; zero out tag bits
                      (emit-bytes #x48 #x83 #xe0 #xfc) ; and $0xfc,%rax
;;                       (emit-bytes #x83 #xe0 #xfc) ; and $0xfc,%eax
                      (move-result-to-target target)
                      t)
                     ((subtypep type2 '(INTEGER 0 63))
;;                       (mumble "p2-ash new optimized case 6~%")
                      (process-2-args args '(:rax :rcx) t)
                      (unbox-fixnum :rcx)
                      (emit-bytes #x48 #xd3 #xe0) ; shl %cl,%rax
                      (move-result-to-target target)
                      t)
                     (t
;;                       (mumble "p2-ash not optimized 2 type1 = ~S type2 = ~S~%" type1 type2)
                      nil))))
            ((and (integer-type-p type1)
                  (fixnum-type-p type2)
                  (eql (integer-constant-value type2) 0)
                  (flushable arg2))
;;              (mumble "p2-ash new optimized case 7~%")
             (p2 arg1 target)
             t)
            (t
;;              (mumble "p2-ash not optimized 3 type1 = ~S type2 = ~S~%" type1 type2)
             nil)
            ))))

(defun p2-logior/logxor (form target)
  (let* ((args (cdr form)))
    (when (length-eql args 2)
      (let* ((op (%car form))
             (arg1 (%car args))
             (arg2 (%cadr args))
             type1
             type2
             (FULL-CALL (make-label))
             (EXIT (make-label))
             thread-register)
        (when (fixnump arg1)
          (let ((temp arg1))
            (setq arg1 arg2
                  arg2 temp))
          (setq args (list arg1 arg2)))
        (setq type1 (derive-type arg1)
              type2 (derive-type arg2))
;;         (mumble "p2-logior/logxor type1 = ~S type2 = ~S~%" type1 type2)
        (cond ((and (eql arg2 0)
                    (integer-type-p type1))
               ;;                (mumble "p2-logior/logxor arg2 is 0~%")
               (process-1-arg arg1 :rax t)
               (move-result-to-target target))
              ((and (eql (integer-constant-value type1) 0)
                    (integer-type-p type2))
               (unless (flushable arg1)
                 (p2 arg1 nil)
                 (unless (single-valued-p arg1)
                   (emit-clear-values)))
               (process-1-arg arg2 :rax t)
               (move-result-to-target target))
              ((and (eql (integer-constant-value type2) 0)
                    (integer-type-p type1))
               (cond ((flushable arg2)
                      (process-1-arg arg1 :rax t)
                      (move-result-to-target target))
                     (t
                      (process-1-arg arg1 :stack t)
                      (p2 arg2 nil)
                      (unless (single-valued-p arg2)
                        (emit-clear-values))
                      (cond ((eq target :stack)
                             ; nothing to do
                             )
                            ((reg32-p target)
                             (inst :pop target))
                            (t
                             (inst :pop :rax)
                             (move-result-to-target target))))))
              (t
               (process-2-args args '(:rax :rdx) t)
               ;; arg1 in rax, arg2 in rdx
               (unless (fixnum-type-p type1)
                 (inst :test 3 :al)
                 (emit-jmp-short :nz FULL-CALL))
               (unless (fixnum-type-p type2)
                 (inst :test 3 :dl)
                 (emit-jmp-short :nz FULL-CALL))
               ;; falling through, both args are fixnums
               (ecase op
                 ((logior two-arg-logior)
                  (emit-bytes #x48 #x09 #xd0)) ; or %rdx,%rax
                 ((logxor two-arg-logxor)
                  (emit-bytes #x48 #x31 #xd0))) ; xor %rdx,%rax
               (clear-register-contents :rax)
               (label EXIT)
               (move-result-to-target target)
               (unless (and (fixnum-type-p type1)
                            (fixnum-type-p type2))
                 (let ((*current-segment* :elsewhere))
                   (label FULL-CALL)
                   (let ((two-arg-op (case op
                                       (logior 'two-arg-logior)
                                       (logxor 'two-arg-logxor)
                                       (t      op))))
                     (cond ((or (use-fast-call-p)
                                (and (integer-type-p type1)
                                     (integer-type-p type2)))
                            (inst :mov :rdx :rsi)
                            (inst :mov :rax :rdi)
                            (emit-call two-arg-op))
                           ((setq thread-register (compiland-thread-register *current-compiland*))
                            ;; arg2 is already in rdx
                            (inst :mov :rdx :rcx)
                            (inst :mov :rax :rdx)
                            (emit-move-function-to-register two-arg-op :rsi)
                            (inst :mov thread-register :rdi)
                            (emit-call "RT_thread_call_function_2"))
                           (t
                            ;; no thread register
                            (mumble "p2-logior/logxor no thread register~%")
                            ;; arg2 is already in rdx
                            (inst :mov :rax :rsi)
                            (emit-move-function-to-register two-arg-op :rdi)
                            (emit-call "RT_current_thread_call_function_2")))
                     (emit-jmp-short t EXIT)))))))
      t)))

(defun p2-logand (form target)
  (let ((args (cdr form)))
    (when (length-eql args 2)
      (let* ((arg1 (%car args))
             (arg2 (%cadr args))
             type1
             type2
             thread-register)
        (when (and (integerp arg1) (integerp arg2))
          (p2-constant (logand arg1 arg2) target)
          (return-from p2-logand t))
        (setq type1 (derive-type arg1)
              type2 (derive-type arg2))
;;         (mumble "p2-logand type1 = ~S type2 = ~S~%" type1 type2)
        (when (and (integer-constant-value type1)
                   (integer-constant-value type2)
                   (flushable arg1)
                   (flushable arg2))
          (p2-constant (logand (integer-constant-value type1) (integer-constant-value type2))
                       target)
          (return-from p2-logand t))
        (cond ((and (eql arg1 -1) (integer-type-p arg2))
;;                (mumble "p2-logand case 1~%")
;;                (p2 arg2 target)
               (process-1-arg arg2 :rax t)
               (move-result-to-target target)
               )
              ((and (eql arg2 -1) (integer-type-p arg1))
;;                (mumble "p2-logand case 2~%")
;;                (p2 arg1 target)
               (process-1-arg arg1 :rax t)
               (move-result-to-target target)
               )
              ((and (fixnum-type-p type1)
                    (fixnum-type-p type2))
;;                (mumble "p2-logand case 3~%")
               (process-2-args args '(:rax :rdx) t)
               (inst :and :rdx :rax)
               (clear-register-contents :rax)
               (move-result-to-target target)
               )
              ((and (integer-type-p type1)
                    (fixnum-type-p type2)
                    (subtypep type1 '(unsigned-byte 64))
                    (subtypep type2 '(unsigned-byte 64)))
;;                (mumble "p2-logand case 4~%")
               (process-2-args args '(:rax :rdx) t)
               (let ((FULL-CALL (gensym))
                     (EXIT (gensym)))
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz FULL-CALL)
                 (inst :and :rdx :rax)
                 (clear-register-contents :rax)
                 (label EXIT)
                 (move-result-to-target target)
                 (let ((*current-segment* :elsewhere))
                   (label FULL-CALL)
                   (inst :push :rdx)
                   (inst :mov :rax :rdi)
                   (emit-call "RT_unsigned_bignum_to_raw_ub64")
                   (inst :pop :rdx)
                   (inst :shr +fixnum-shift+ :rdx)
                   (inst :and :rdx :rax)
                   (inst :shl +fixnum-shift+ :rax)
                   (emit-jmp-short t EXIT)))
               )
              (t
;;                (let ((*print-structure* nil))
;;                  (mumble "p2-logand arg1 = ~S arg2 = ~S~%" arg1 arg2))
;;                (mumble "p2-logand type1 = ~S type2 = ~S~%" type1 type2)
;;                (mumble "p2-logand case 5~%")
               (process-2-args args '(:rax :rdx) t)
               (let ((FULL-CALL (gensym))
                     (EXIT (gensym)))
                 (unless (fixnum-type-p type1)
                   (inst :test +fixnum-tag-mask+ :al)
                   (emit-jmp-short :nz FULL-CALL))
                 (unless (fixnum-type-p type2)
                   (inst :test +fixnum-tag-mask+ :dl)
                   (emit-jmp-short :nz FULL-CALL))
                 ;; reaching here, both args are fixnums
                 (inst :and :rdx :rax)
                 (label EXIT)
                 (move-result-to-target target)
                 (let ((*current-segment* :elsewhere))
                   (label FULL-CALL)
                   (cond ((or (use-fast-call-p)
                              (and (integer-type-p type1)
                                   (integer-type-p type2)))
                          (inst :mov :rdx :rsi)
                          (inst :mov :rax :rdi)
                          (emit-call 'two-arg-logand))
                         ((setq thread-register (compiland-thread-register *current-compiland*))
                          ;; arg2 is already in rdx
                          (inst :mov :rdx :rcx)
                          (inst :mov :rax :rdx)
                          (emit-move-function-to-register 'two-arg-logand :rsi)
                          (inst :mov thread-register :rdi)
                          (emit-call "RT_thread_call_function_2"))
                         (t
                          ;; no thread register
                          (mumble "p2-logand no thread register~%")
                          ;; arg2 is already in rdx
                          (inst :mov :rax :rsi)
                          (emit-move-function-to-register 'two-arg-logand :rdi)
                          (emit-call "RT_current_thread_call_function_2")))
                   (emit-jmp-short t EXIT))))))
      t)))

(defun p2-zerop (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (type (derive-type arg))
           (EXIT (make-label)))
      (process-1-arg arg :rdi t)
      (clear-register-contents :rdi :rax)
      (inst :test :rdi :rdi)
      (cond ((and (neq type :unknown)
                  (subtypep type 'INTEGER))
             (p2-symbol t :rax)
             (emit-jmp-short :z EXIT)
             (p2-symbol nil :rax))
            (t
             (let ((FULL-CALL (gensym)))
               (emit-jmp-short :nz FULL-CALL)
               (p2-symbol t :rax)
               (emit-jmp-short t EXIT)
               (label FULL-CALL)
               (emit-call 'zerop))))
      (label EXIT)
      (move-result-to-target target))
    t))

(defun p2-not/null (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (derived-type (derive-type arg)))
      (cond ((and (consp arg)
                  (memq (%car arg) '(NOT NULL)))
             (p2 (cadr arg) :rax)
             (unless (single-valued-p (cadr arg))
               (emit-clear-values :preserve :rax))
             (p2-symbol nil :rdx)
             (clear-register-contents :rax :rdx)
;;              (emit-bytes #x48 #x39 #xd0) ; cmp %rdx,%rax
             (inst :cmp :rdx :rax)
             (cond ((eq target :return)
                    (let ((LABEL1 (make-label)))
                      (emit-jmp-short :ne LABEL1)
                      (p2-symbol nil :rax)
                      (emit-exit)
                      (label LABEL1)
                      (p2-symbol t :rax)
                      (emit-exit)))
                   (t
                    (let ((LABEL1 (make-label))
                          (LABEL2 (make-label)))
                      (emit-jmp-short :ne LABEL1)
                      (p2-symbol nil :rax)
                      (emit-jmp-short t LABEL2)
                      (label LABEL1)
                      (p2-symbol t :rax)
                      (label LABEL2)
                      (move-result-to-target target)))))
            ((eq derived-type 'NULL)
             (p2 arg nil) ; for effect
             (inst :move-immediate t :rax)
             (move-result-to-target target))
            (t
             (let ((NO (make-label))
                   (EXIT (make-label)))
               (process-1-arg arg :rax t)
               (p2-symbol nil :rdx)
               (clear-register-contents :rax :rdx)
               (emit-bytes #x48 #x39 #xd0) ; cmp %rdx,%rax
               (emit-jmp-short :ne NO)
               (p2-symbol t :rax)
               (emit-jmp-short t EXIT)
               (label NO)
               (p2-symbol nil :rax)
               (label EXIT)
               (move-result-to-target target)))))
    t))

(defun p2-consp (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (derived-type (derive-type arg)))
      (cond ((cons-type-p derived-type)
             (p2 arg nil) ; for effect
             (p2 t target))
            (t
             (let ((NO (make-label))
                   (EXIT (make-label)))
               (process-1-arg arg :rax t)
               (inst :compare-immediate nil :rax)
               (emit-jmp-short :e NO)
               (inst :and +lowtag-mask+ :al)
               (clear-register-contents :rax)
               (inst :cmp +list-lowtag+ :al)
               (emit-jmp-short :ne NO)
               (p2 t :rax)
               (emit-jmp-short t EXIT)
               (label NO)
               (p2 nil :rax)
               (label EXIT)
               (move-result-to-target target)))))
      t))

(defun p2-characterp (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form))
          (NO (make-label))
          (EXIT (make-label)))
      (process-1-arg arg :rax t)
      (inst :and +lowtag-mask+ :al)
      (clear-register-contents :rax)
      (inst :cmp +character-lowtag+ :al)
      (cond ((eq target :return)
             (emit-jmp-short :ne NO)
             (p2-symbol t :rax)
             (emit-exit)
             (label NO)
             (p2-symbol nil :rax)
             (emit-exit))
            (t
             (emit-jmp-short :ne NO)
             (p2-symbol t :rax)
             (emit-jmp-short t EXIT)
             (label NO)
             (p2-symbol nil :rax)
             (label EXIT)
             (move-result-to-target target))))
    t))

(defun p2-integerp (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form))
          (EXIT (make-label))
          (BIGNUMP (make-label)))
      (process-1-arg arg :rax t)
      (inst :test +fixnum-tag-mask+ :al)
      (emit-jmp-short :nz BIGNUMP)
      (p2-symbol t target)
      (label EXIT)
      (move-result-to-target target)
      (let ((*current-segment* :elsewhere))
        (label BIGNUMP)
        (inst :mov :rax :rdi)
        (emit-call-1 'bignump target)
        (emit-jmp-short t EXIT)))
    t))

(defun p2-symbolp (form target)
  (when (check-arg-count form 1)
    (let* ((arg (%cadr form))
           (YES (make-label))
           (NO (make-label))
           (EXIT (make-label)))
      (process-1-arg arg :rax t)
      (inst :compare-immediate nil :rax)
      (emit-jmp-short :e YES)
      (inst :and +lowtag-mask+ :al)
      (clear-register-contents :rax)
      (inst :cmp +symbol-lowtag+ :al)
      (emit-jmp-short :ne NO)
      (label YES)
      (p2 t target)
      (emit-jmp-short t EXIT)
      (label NO)
      (p2 nil target)
      (label EXIT))
    t))

(defun p2-require-type (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1)
      (cond ((zerop *safety*)
             (p2 arg1 target))
            ((and (quoted-form-p arg2)
                  (neq (setq type1 (derive-type arg1)) :unknown)
                  (subtypep type1 (%cadr arg2)))
             (p2 arg1 target))
            (t
             (process-2-args args '(:rsi :rdx) t)
             (p2-symbol 'require-type :rdi)
             (emit-call-3 "RT_fast_call_symbol_2" target))))
    t))

(defun p2-require-cons (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (cond ((zerop *safety*)
             (p2 arg target))
            ((cons-type-p (derive-type arg))
             (p2 arg target))
            (t
             (let ((FAIL (make-label)))
               (process-1-arg arg :rax t)
               (inst :compare-immediate nil :rax)
               (emit-jmp-short :e FAIL)
               (inst :push :rax)
               (inst :and +lowtag-mask+ :al)
               (inst :cmp +list-lowtag+ :al)
               (inst :pop :rax)
               (emit-jmp-short :ne FAIL)
               (move-result-to-target target)
               (let ((*current-segment* :elsewhere))
                 (label FAIL)
                 (inst :mov :rax :rdi)
                 (p2-symbol 'CONS :rsi)
                 (emit-call '%type-error)
                 (emit-exit) ; FIXME
                 )
               (when (var-ref-p arg)
                 (set-register-contents :rax (var-ref-var arg)))))))
    t))

(defun p2-require-fixnum (form target)
  (when (check-arg-count form 1)
    (let ((arg (%cadr form)))
      (cond ((zerop *safety*)
             (p2 arg target))
            ((fixnum-type-p (derive-type arg))
             (p2 arg target))
            (t
             (process-1-arg arg :rax t)
             (let* ((common-labels (compiland-common-labels *current-compiland*))
                    (FAIL (gethash :error-not-fixnum common-labels)))
               (unless FAIL
                 (setq FAIL (make-label))
                 (let ((*current-segment* :elsewhere)
                       (*register-contents* (copy-register-contents)))
                   (label FAIL)
                   (inst :mov :rax :rdi)
                   (p2-symbol 'FIXNUM :rsi)
                   (emit-call '%type-error)
                   (emit-exit) ; FIXME
                   (setf (gethash :error-not-fixnum common-labels) FAIL)))
               (inst :test +fixnum-tag-mask+ :al)
               (emit-jmp-short :nz FAIL)
               (move-result-to-target target)
               (when (var-ref-p arg)
                 (add-type-constraint (var-ref-var arg) 'FIXNUM))))))
    t))

(defun p2-check-fixnum-bounds (form target)
  (when (check-arg-count form 3)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (arg3 (%caddr args))
           (type1 (derive-type arg1)))
      (cond ((zerop *safety*)
             (p2 arg1 target))
            ((and (fixnump arg2)
                  (fixnump arg3)
                  (neq type1 :unknown)
                  (subtypep type1 (list 'INTEGER arg2 arg3)))
             (p2 arg1 target))
            ((and (fixnump arg2)
                  (fixnump arg3)
                  (typep (fixnumize arg2) '(signed-byte 32))
                  (typep (fixnumize arg3) '(signed-byte 32)))
             (let ((ERROR (make-label)))
               (let ((*current-segment* :elsewhere)
                     (*register-contents* nil))
                 (label ERROR)
                 (inst :push :rax)
                 (inst :mov (fixnumize arg3) :rdx)
                 (inst :mov (fixnumize arg2) :rsi)
                 (p2-symbol 'INTEGER :rdi)
                 (emit-call-3 'LIST3 :rsi)
                 (inst :pop :rdi)
                 (emit-call '%type-error)
                 (emit-exit)) ; FIXME
               (process-1-arg arg1 :rax t)
               (unless (fixnum-type-p type1)
                 (inst :test +fixnum-tag-mask+ :al)
                 (emit-jmp-short :nz ERROR))
               (inst :cmp (fixnumize arg2) :rax)
               (emit-jmp-short :l ERROR)
               (inst :cmp (fixnumize arg3) :rax)
               (emit-jmp-short :g ERROR)
               (when target
                 (move-result-to-target target))))
            (t
             (mumble "p2-check-fixnum-bounds full call~%")
             (process-3-args args :default t)
             (emit-call-3 'check-fixnum-bounds target))))
    t))

(defun p2-require-vector (form target)
  (let ((op (%car form))
        (arg (%cadr form))
        type)
    (aver (eq op 'require-vector))
    (cond ((zerop *safety*)
           (p2 arg target))
          ((and (neq (setq type (derive-type arg)) :unknown)
                (subtypep type 'VECTOR))
           (p2 arg target))
          (t
           (mumble "p2-require-vector~%")
           (let* ((common-labels (compiland-common-labels *current-compiland*))
                  (REQUIRE-VECTOR-ERROR (gethash :require-vector-error common-labels)))
             (when REQUIRE-VECTOR-ERROR
               (mumble "p2-require-vector re-using label~%"))
             (unless REQUIRE-VECTOR-ERROR
               (setq REQUIRE-VECTOR-ERROR (make-label))
               (let ((*current-segment* :elsewhere))
                 (label REQUIRE-VECTOR-ERROR)
                 (p2-symbol 'VECTOR :rsi)
                 (emit-call '%type-error)
                 ;; FIXME
                 (emit-exit))
               (setf (gethash :require-vector-error common-labels) REQUIRE-VECTOR-ERROR))
             (process-1-arg arg :rax t)
             (inst :mov :rax :rdi)
             (inst :and +lowtag-mask+ :al)
             (clear-register-contents :rax :rdi)
             (inst :cmp +typed-object-lowtag+ :al)
             (emit-jmp-short :ne REQUIRE-VECTOR-ERROR)
             (inst :mov :rdi :rax)
             (inst :sub +typed-object-lowtag+ :rax)
             (inst :mov '(8 :rax) :rax) ; widetag in rax
             (aver (typep +widetag-vector-bit+ '(signed-byte 32)))
             (inst :and +widetag-vector-bit+ :rax)
             (emit-jmp-short :z REQUIRE-VECTOR-ERROR)
             (when target
               (inst :mov :rdi :rax)
               (move-result-to-target target))))))
  t)

(defun p2-require-simple-vector (form target)
  (let ((op (%car form))
        (arg (%cadr form))
        type)
    (aver (eq op 'require-simple-vector))
    (cond ((zerop *safety*)
           (p2 arg target))
          ((and (neq (setq type (derive-type arg)) :unknown)
                (subtypep type 'SIMPLE-VECTOR))
           (p2 arg target))
          (t
           (mumble "p2-require-simple-vector~%")
           (let* ((common-labels (compiland-common-labels *current-compiland*))
                  (REQUIRE-SIMPLE-VECTOR-ERROR (gethash :require-simple-vector-error common-labels)))
             (when REQUIRE-SIMPLE-VECTOR-ERROR
               (mumble "p2-require-simple-vector re-using label~%"))
             (unless REQUIRE-SIMPLE-VECTOR-ERROR
               (setq REQUIRE-SIMPLE-VECTOR-ERROR (make-label))
               (let ((*current-segment* :elsewhere))
                 (label REQUIRE-SIMPLE-VECTOR-ERROR)
                 (p2-symbol 'SIMPLE-VECTOR :rsi)
                 (emit-call '%type-error)
                 ;; FIXME
                 (emit-exit))
               (setf (gethash :require-simple-vector-error common-labels) REQUIRE-SIMPLE-VECTOR-ERROR))
             (process-1-arg arg :rax t)
             (inst :mov :rax :rdi)
             (inst :and +lowtag-mask+ :al)
             (clear-register-contents :rax :rdi)
             (inst :cmp +typed-object-lowtag+ :al)
             (emit-jmp-short :ne REQUIRE-SIMPLE-VECTOR-ERROR)
             (inst :mov :rdi :rax)
             (inst :sub +typed-object-lowtag+ :rax)
             (inst :mov '(8 :rax) :rax) ; widetag in rax
             (aver (typep +simple-vector-widetag+ '(signed-byte 32)))
             (inst :cmp +simple-vector-widetag+ :rax)
             (emit-jmp-short :ne REQUIRE-SIMPLE-VECTOR-ERROR)
             (when target
               (inst :mov :rdi :rax)
               (move-result-to-target target))
             (when (var-ref-p arg)
               (mumble "p2-require-simple-vector adding type constraint for ~S~%"
                          (var-name (var-ref-var arg)))
               (add-type-constraint (var-ref-var arg) 'SIMPLE-VECTOR))))))
  t)

(defun p2-%type-error (form target)
  (when (check-arg-count form 2)
    (process-2-args (%cdr form) '(:rdi :rsi) t)
    (emit-call '%type-error)
    (move-result-to-target target)
    t))

(defun p2-structure-ref (form target)
  (when (check-arg-count form 2)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           type1)
      (cond ((and (fixnump arg2)
                  (or (zerop *safety*)
                      (and (neq (setq type1 (derive-type arg1)) :unknown)
                           (subtypep type1 'structure-object))))
             (let ((displacement (+ (- +typed-object-lowtag+)
                                    +structure-slots-offset+
                                    (* arg2 +bytes-per-word+)))
                   (reg (if (reg64-p target) target :rax)))
               (process-1-arg arg1 reg t)
               (inst :mov `(,displacement ,reg) reg)
               (clear-register-contents reg)
               (unless (eq reg target)
                 (move-result-to-target target))
               t))
            (t
             (mumble "p2-structure-ref not optimized~%")
             nil)))))

(defun p2-structure-set (form target)
  (when (check-arg-count form 3)
    (let* ((args (%cdr form))
           (arg1 (%car args))
           (arg2 (%cadr args))
           (arg3 (%caddr args))
           type1)
      (cond ((and (fixnump arg2)
                  (or (zerop *safety*)
                      (and (neq (setq type1 (derive-type arg1)) :unknown)
                           (subtypep type1 'structure-object))))
             (cond ((and (constant-or-local-var-ref-p arg1) (constant-or-local-var-ref-p arg3))
                    (process-1-arg arg1 :rdx t)
                    (process-1-arg arg3 :rax t))
                   (t
                    (process-1-arg arg1 :rax t)
                    (inst :push :rax)
                    ;; REVIEW stack alignment
                    (process-1-arg arg3 :rax t)
                    (inst :pop :rdx)))
             (clear-register-contents :rdx)
             (let ((displacement (+ (- +typed-object-lowtag+)
                                    +structure-slots-offset+
                                    (* arg2 +bytes-per-word+))))
               (inst :mov :rax `(,displacement :rdx)))
             (move-result-to-target target)
             t)
            (t
             nil)))))

(defun p2-values (form target)
  (let* ((args (cdr form))
         (numargs (length args))
         (thread-reg (compiland-thread-register *current-compiland*)))
    (aver (eq thread-reg :r12))
    (case numargs
      (0
       (p2-symbol nil :rax)
       (inst :movb numargs `(,+values-length-offset+ ,thread-reg))
       (move-result-to-target target)
       t)
      (1
       (process-1-arg (%car args) :rax t)
       (move-result-to-target target)
       t)
      (2
       (process-2-args args '(:rax :rdx) nil)
       (inst :mov :rax `(,+values-offset+ ,thread-reg))
       (inst :mov :rdx `(,(+ +values-offset+ +bytes-per-word+) ,thread-reg))
       (inst :movb numargs `(,+values-length-offset+ ,thread-reg))
       (move-result-to-target target)
       t)
      (3
       (process-3-args args '(:rax :rdx :rcx) nil)
       (inst :mov :rax `(,+values-offset+ ,thread-reg))
       (inst :mov :rdx `(,(+ +values-offset+ +bytes-per-word+) ,thread-reg))
       (inst :mov :rcx `(,(+ +values-offset+ (* +bytes-per-word+ 2)) ,thread-reg))
       (inst :movb numargs `(,+values-length-offset+ ,thread-reg))
       (move-result-to-target target)
       t)
      (4
       (process-4-args args '(:rax :rdx :rcx :rsi) nil)
       (inst :mov :rax `(,+values-offset+ ,thread-reg))
       (inst :mov :rdx `(,(+ +values-offset+ +bytes-per-word+) ,thread-reg))
       (inst :mov :rcx `(,(+ +values-offset+ (* +bytes-per-word+ 2)) ,thread-reg))
       (inst :mov :rsi `(,(+ +values-offset+ (* +bytes-per-word+ 3)) ,thread-reg))
       (inst :movb numargs `(,+values-length-offset+ ,thread-reg))
       (move-result-to-target target)
       t))))

(defknown allocate-locals (t t) t)
(defun allocate-locals (compiland index)
  (declare (type index index))
  (let ((locals (reverse *local-variables*))
        (stack-used 0))
    (when locals
      (dolist (var locals)
        (declare (type var var))
        (unless (var-special-p var)
          (when (eq (var-compiland-id var) (compiland-id compiland))
            (aver (null (var-index var)))
            (unless (or (var-register var) (var-closure-index var))
              (setf (var-index var) index)
              (incf index)))))
      (let* ((numvars (let ((count 0))
                        (dolist (var locals count)
                          (declare (type var var))
                          ;; We don't need to allocate space on the stack for
                          ;; closure vars or specials.
                          (unless (or (var-special-p var)
                                      (var-closure-index var))
                            (when (var-index var)
                              (incf count))))))
             (numbytes (* numvars +bytes-per-word+)))
        (incf stack-used numvars)
        (cond ((<= numvars 4)
               (dotimes (i numvars)
                 (inst :push :rax)))
              (t
               (inst :sub numbytes :rsp)))))
    stack-used))

(defknown trivial-allocate-locals (t) t)
(defun trivial-allocate-locals (compiland)
    (let ((locals (reverse *local-variables*)))
      (when locals
        (dolist (var locals)
          (declare (type var var))
          (unless (var-special-p var)
            (when (eq (var-compiland-id var) (compiland-id compiland))
              (aver (null (var-index var)))
              (aver (null (var-register var)))
              (aver (null (var-closure-index var)))
              (inst :allocate-local var)))))))

;; 1. required arguments only, 6 or fewer: rdi, rsi, rdx, rcx, r8, r9

;; 2. required arguments only, more than 6: numargs in rdi, args vector in rsi
;; (this is set up by the caller; see P2-FUNCTION-CALL-N)

;; 3. &rest but not &optional or &key: P2-FUNCTION-PROLOG calls RT_restify()

;; 4. &optional and/or &key, with or without &rest: P2-FUNCTION-PROLOG calls RT_process_args()

;; There might be closure variables...

;; Separate cases for top-level with no children, top-level parent, child.

;; A parent can also be a child.

;; (defknown p2-trivial-leaf-function-prolog (t) t)
;; (defun p2-trivial-leaf-function-prolog (compiland)
;;   (declare (type compiland compiland))
;;   (mumble "p2-trivial-leaf-function-prolog ~S~%" (compiland-name compiland))
;;   (setf (compiland-omit-frame-pointer compiland) t)
;;   (clear-register-contents)
;;   t)

(defknown p2-trivial-function-prolog (t) t)
(defun p2-trivial-function-prolog (compiland)
  (declare (type compiland compiland))
  (clear-register-contents)
  (inst :save-thread-register)
  (inst :save-registers)
  (inst :enter-frame)
  (dolist (var (compiland-arg-vars compiland))
    (inst :initialize-arg-var var))
  (trivial-allocate-locals compiland)
  (inst :align-stack)
  (inst :initialize-thread-register)
  (clear-register-contents)
  t)

(defknown allocate-closure-data-vector (t t) t)
(defun allocate-closure-data-vector (compiland numvars)
  ;; preserve argument registers around call!
  (let ((regs +call-argument-registers+)
        (arity (compiland-arity compiland)))
    (when (and arity (< arity 6))
      (setq regs (subseq regs 0 arity)))
    (dolist (reg regs)
      (inst :push reg))
    (emit-move-immediate-dword-to-register (* numvars +bytes-per-word+) :rdi)
    (emit-call "RT_allocate_closure_data_vector")
    (dolist (reg (reverse regs))
      (inst :pop reg))))

(defknown p2-child-function-prolog (compiland) t)
(defun p2-child-function-prolog (compiland)
  (declare (type compiland compiland))
  ;; "The end of the input argument area shall be aligned on a 16 byte boundary.
  ;; In other words, the value (%rsp - 8) is always a multiple of 16 when control is
  ;; transferred to the function entry point."
  (let ((stack-used -1)) ; we want this to be an even number when we're done
    (cond ((or t (compiland-arg-vars compiland) *local-variables* *closure-vars*)
           (when (compiland-needs-thread-var-p compiland)
             (inst :push :r12)
             (incf stack-used))
           (inst :push :rbp)
           (incf stack-used)
           (inst :mov :rsp :rbp))
          (t
           (setf (compiland-omit-frame-pointer compiland) t)))

    (let ((index 0)
          (call-argument-registers nil))
      (aver (and *closure-vars* (compiland-child-p compiland)))
      (setf (compiland-closure-data-index compiland) index)
      (incf index)
      (inst :push :rdi)
      (incf stack-used)
      (dolist (var (compiland-arg-vars compiland))
        (declare (type var var))
        (cond ((var-arg-register var)
               ;; closure data is passed in rdi, so we need to make some adjustments...
               (let ((new-register (case (var-arg-register var)
                                     (:rdi :rsi)
                                     (:rsi :rdx)
                                     (:rdx :rcx)
                                     (:rcx :r8)
                                     (:r8  :r9)
                                     (t
                                      (compiler-unsupported "P2-CHILD-FUNCTION-PROLOG unsupported register ~S"
                                                            (var-arg-register var))))))
                 (setf (var-arg-register var) new-register)
                 (push new-register call-argument-registers)))
              (t
               ;; no register, nothing to do
               nil)))
      (when call-argument-registers
        (setq call-argument-registers (nreverse call-argument-registers)))

      (when (some 'var-used-non-locally-p (compiland-arg-vars compiland))
        (inst :push :rsi)
        (inst :push :rdx)
        (inst :push :rcx)
        (inst :push :r8)
        (inst :push :r9)
;;         (dolist (reg call-argument-registers)
;;           (inst :push reg))
        (inst :mov (length *closure-vars*) :rsi) ; length in rsi
        ;; address of closure data vector is already in rdi
        (emit-call "RT_copy_closure_data_vector") ; returns copy of data vector in rax
        (emit-move-register-to-local :rax (compiland-closure-data-index compiland))
        (inst :mov :rax :rdi)
        (inst :pop :r9)
        (inst :pop :r8)
        (inst :pop :rcx)
        (inst :pop :rdx)
        (inst :pop :rsi)
;;         (dolist (reg (reverse call-argument-registers))
;;           (inst :pop reg))

        ;; address of closure data vector is in rdi
        (dolist (var (compiland-arg-vars compiland))
          (declare (type var var))
          (when (var-used-non-locally-p var)
            ;; var's closure index was assigned at the end of P1-COMPILAND
            (aver (fixnump (var-closure-index var)))
            (when (var-arg-register var)
              (aver (null (var-index var)))
              ;; FIXME efficiency
              (inst :push :rdi)
              (dolist (reg call-argument-registers)
                (inst :push reg))

              (inst :push (var-arg-register var))

              ;; each new binding gets a new value cell
              (emit-call "RT_make_value_cell")
              (aver (fixnump (compiland-closure-data-index compiland)))
              (emit-move-local-to-register (compiland-closure-data-index compiland) :rdi)
              (inst :mov :rax `(,(* (var-closure-index var) +bytes-per-word+) :rdi))

              (inst :pop (var-arg-register var))

              (inst :mov (var-arg-register var) :rax)
              (emit-move-register-to-closure-var :rax var compiland)

              (dolist (reg (reverse call-argument-registers))
                (inst :pop reg))
              (inst :pop :rdi)

              (setf (var-arg-register var) nil)))))

      (let ((lambda-list (cadr (compiland-lambda-expression compiland))))
        (cond ((or (memq '&optional lambda-list)
                   (memq '&key lambda-list)
                   (and (compiland-arity compiland)
                        (> (compiland-arity compiland) 6)))
               (inst :mov :rsi :rdi)
               (inst :mov :rdx :rsi)
               (let ((prototype (coerce-to-function (list 'LAMBDA lambda-list nil))))
                 (inst :move-immediate (list :constant-32 prototype) :edx))

               (let* ((names (lambda-list-names lambda-list))
                      (n (length names))
                      (numbytes (* n +bytes-per-word+)))
                 (cond ((<= n 4)
                        (dotimes (i n)
                          (inst :push :rax)))
                       ((< numbytes 128)
                        (emit-bytes #x48 #x83 #xec) ; sub imm8,%rsp
                        (emit-byte numbytes))
                       (t
                        (emit-bytes #x48 #x81 #xec) ; sub imm32,%rsp
                        (emit-raw-dword numbytes)))
                 (inst :mov :rsp :rcx)
                 ;; REVIEW do we need to make sure the stack is aligned for this call?
                 ;; fix stack alignment
                 (inst :sub +bytes-per-word+ :rsp)
                 (emit-call "RT_process_args")
                 (inst :add +bytes-per-word+ :rsp)
                 (incf index n))

               ;; address of args array is now in rax
               (when (some #'var-used-non-locally-p (compiland-arg-vars compiland))
                 (inst :mov :rax :rcx)) ; address of args array in rcx
               (let ((base (1- index)))
                 (dolist (var (compiland-arg-vars compiland))
                   (declare (type var var))
                   (aver (var-arg-index var))
                   (when (var-index var)
                     (aver (not 2)))
                   (cond ((var-closure-index var)
                          (emit-move-relative-to-register :rcx (var-arg-index var) :rax)
                          (emit-move-register-to-closure-var :rax var compiland))
                         (t
                          (setf (var-index var) (- base (var-arg-index var))))))))
              ((null (compiland-arity compiland))
               ;; &rest arg
               (dolist (var (compiland-arg-vars compiland))
                 (declare (type var var))
                 (aver (null (var-index var)))
                 (cond ((var-arg-register var)
                        (setf (var-index var) index)
                        (incf index)
                        (inst :push (var-arg-register var))
                        (incf stack-used)
                        (setf (var-arg-register var) nil))
                       ((eq (var-kind var) :required)
                        (aver (not (null (var-arg-index var))))

                        ;; arg vector is in rdx
                        (emit-move-relative-to-register :rdx (var-arg-index var) :rax)

                        (setf (var-index var) index)
                        (incf index)
                        (inst :push :rax)
                        (incf stack-used)
                        (setf (var-arg-index var) nil))
                       ((eq (var-kind var) :rest)
                        (aver (not (null (var-arg-index var))))
                        (aver (null (var-index var)))
                        ;; reserve space for rest var
                        (unless (var-closure-index var)
                          (inst :push :rax)
                          (incf stack-used)
                          (setf (var-index var) index)
                          (incf index)))
                       (t
                        (compiler-unsupported "unsupported var-kind ~S" (var-kind var)))))

               (let ((start 0)
                     ;(end nil)
                     (restvar nil))
                 (dolist (var (compiland-arg-vars compiland))
                   (case (var-kind var)
                     (:required
                      (incf start))
                     (:rest
                      (setq restvar var)
                      (aver (or (var-index restvar)
                                (var-closure-index restvar)))
                      (return))))
                 (when (> start 2)
                   ;; FIXME what's this about?
                   (compiler-unsupported "P2-CHILD-FUNCTION-PROLOG too many required args"))
                 ;; closure data is in rdi, numargs is in rsi, arg vector is in rdx
                 (inst :mov :rdx :rdi) ; arg vector
                 (inst :mov :rsi :rdx) ; numargs
                 (emit-move-immediate-dword-to-register start :rsi)
                 ;; REVIEW do we need to make sure the stack is aligned for this call?
                 (emit-call "RT_restify")
                 (cond ((var-index restvar)
                        (emit-move-register-to-local :rax (var-index restvar)))
                       (t
                        (aver (fixnump (var-closure-index restvar)))
                        (emit-move-register-to-closure-var :rax restvar compiland)))))
              (t
               (dolist (var (compiland-arg-vars compiland))
                 (declare (type var var))
                 (aver (null (var-index var)))
                 (cond ((var-arg-register var)
                        (setf (var-index var) index)
                        (incf index)
                        (inst :push (var-arg-register var))
                        (incf stack-used)
                        (set-register-contents (var-arg-register var) var)
                        (setf (var-arg-register var) nil))
                       ((eq (var-kind var) :required)
                        (unless (var-closure-index var)
                          (aver (not (null (var-arg-index var))))
                          (let ((n (* (var-arg-index var) 8)))
                            (unless (<= 0 n 255)
                              (compiler-unsupported "too many vars"))
                            (emit-bytes #x48 #x8b #x46) ; mov n(%rsi),%rax
                            (emit-byte n))
                          (setf (var-index var) index)
                          (incf index)
                          (inst :push :rax)
                          (incf stack-used)
                          (setf (var-arg-index var) nil)))
                       ((eq (var-kind var) :rest)
                        ;; shouldn't happen
                        (mumble "P2-FUNCTION-PROLOG shouldn't happen~%")
                        (aver nil))
                       (t
                        (compiler-unsupported "unsupported var-kind ~S" (var-kind var))))))
              ))

      (incf stack-used (allocate-locals compiland index))
      (when (oddp stack-used)
        (inst :push :rax))

      (when (compiland-thread-register compiland)
        (emit-call "RT_current_thread")
        (inst :mov :rax (compiland-thread-register compiland)))

      ))
  t)

(defknown p2-function-prolog (compiland) t)
(defun p2-function-prolog (compiland)
  (declare (type compiland compiland))
  (let ((arity (compiland-arity compiland)))
    (when (and arity
               (<= arity 6)
               (null *closure-vars*))
      (return-from p2-function-prolog (p2-trivial-function-prolog compiland))))

  (when (and *closure-vars* (compiland-child-p compiland))
    (return-from p2-function-prolog (p2-child-function-prolog compiland)))

;;   (mumble "p2-function-prolog called~%")

  ;; "The end of the input argument area shall be aligned on a 16 byte boundary.
  ;; In other words, the value (%rsp - 8) is always a multiple of 16 when control is
  ;; transferred to the function entry point."
  (let ((stack-used -1))
    (cond ((or t (compiland-arg-vars compiland) *local-variables* *closure-vars*)
           (when (compiland-needs-thread-var-p compiland)
             (inst :push :r12)
             (incf stack-used))
           (inst :push :rbp)
           (incf stack-used)
           (inst :mov :rsp :rbp))
          (t
           (setf (compiland-omit-frame-pointer compiland) t)))

    (let ((index 0))
      (when (and *closure-vars* (null (compiland-parent compiland))) ; top-level compiland
        (allocate-closure-data-vector compiland (length *closure-vars*)) ; leaves address in rax
        (inst :push :rax) ; address of closure data vector
        (incf stack-used)
        (setf (compiland-closure-data-index compiland) index)
        (incf index)
        (dolist (var (compiland-arg-vars compiland))
          (when (var-used-non-locally-p var)
            ;; var's closure index was assigned at the end of P1-COMPILAND
            (aver (fixnump (var-closure-index var)))
            (when (var-arg-register var)
              (aver (null (var-index var)))
              (emit-move-register-to-closure-var (var-arg-register var) var compiland)
              (setf (var-arg-register var) nil)))))

      (let ((lambda-list (cadr (compiland-lambda-expression compiland))))
        (cond ((or (memq '&optional lambda-list)
                   (memq '&key lambda-list)
                   (and (compiland-arity compiland)
                        (> (compiland-arity compiland) 6)))
               ;; numargs in rdi, arg vector in rsi
               (let ((prototype (coerce-to-function (list 'LAMBDA lambda-list nil))))
                 (inst :move-immediate (list :constant-32 prototype) :edx))

               (let* ((names (lambda-list-names lambda-list))
                      (n (length names))
                      (numbytes (* n +bytes-per-word+)))
                 (inst :sub numbytes :rsp)
                 (inst :mov :rsp :rcx) ; address of values vector for RT_process_args
                 (emit-call "RT_process_args")
                 (incf index n))

               ;; address of values vector is now in rax
               (when (some #'var-used-non-locally-p (compiland-arg-vars compiland))
                 (inst :mov :rax :rcx)) ; address of args array in rcx
               (let ((base (1- index)))
                 (dolist (var (compiland-arg-vars compiland))
                   (declare (type var var))
                   (cond ((var-used-non-locally-p var)
                          (aver (fixnump (var-arg-index var)))
                          (aver (fixnump (var-closure-index var)))
                          (emit-move-relative-to-register :rcx (var-arg-index var) :rax)
                          (emit-move-register-to-closure-var :rax var compiland))
                         (t
                          (aver (var-arg-index var))
                          (when (var-index var)
                            (aver (not 2)))
                          (aver (null (var-closure-index var)))
                          (setf (var-index var) (- base (var-arg-index var))))))))
              ((null (compiland-arity compiland))
               ;; &rest arg
               (dolist (var (compiland-arg-vars compiland))
                 (declare (type var var))
                 (aver (null (var-index var)))
                 (cond ((var-arg-register var)
                        (setf (var-index var) index)
                        (incf index)
                        (inst :push (var-arg-register var))
                        (incf stack-used)
                        (setf (var-arg-register var) nil))
                       ((eq (var-kind var) :required)
                        (aver (not (null (var-arg-index var))))
                        (let ((n (* (var-arg-index var) +bytes-per-word+)))
                          (unless (<= 0 n 255)
                            (compiler-unsupported "too many vars"))
                          (emit-bytes #x48 #x8b #x46) ; mov n(%rsi),%rax
                          (emit-byte n))
                        (cond ((var-closure-index var)
                               (emit-move-register-to-closure-var :rax var compiland))
                              (t
                               (setf (var-index var) index)
                               (incf index)
                               (inst :push :rax)
                               (incf stack-used)))
                        (setf (var-arg-index var) nil))
                       ((eq (var-kind var) :rest)
                        (aver (not (null (var-arg-index var))))
                        (aver (null (var-index var)))
                        (cond ((var-closure-index var)
                               (aver (fixnump (var-closure-index var)))
                               ; nothing to do
                               )
                              (t
                               ;; reserve space for rest var
                               (inst :push :rax)
                               (incf stack-used)
                               (setf (var-index var) index)
                               (incf index))))
                       (t
                        (compiler-unsupported "unsupported var-kind ~S" (var-kind var)))))

               (let ((start 0)
                     ;(end nil)
                     (restvar nil))
                 (dolist (var (compiland-arg-vars compiland))
                   (declare (type var var))
                   (case (var-kind var)
                     (:required
                      (incf start))
                     (:rest
                      (setq restvar var)
                      (aver (or (var-index restvar) (var-closure-index restvar)))
                      (return))))
                 ;; at this point numargs is in rdi, arg vector is in rsi
                 (inst :mov :rdi :rdx)
                 (inst :mov :rsi :rdi)
                 (emit-move-immediate-dword-to-register start :rsi)
                 ;; REVIEW do we need to make sure the stack is aligned for this call?
                 (when (oddp stack-used)
                   (inst :sub +bytes-per-word+ :rsp))
                 (emit-call "RT_restify")
                 (when (oddp stack-used)
                   (inst :add +bytes-per-word+ :rsp))
                 (cond ((var-closure-index restvar)
                        (emit-move-register-to-closure-var :rax restvar compiland))
                       (t
                        (emit-move-register-to-local :rax (var-index restvar))))))
              (t
               (dolist (var (compiland-arg-vars compiland))
                 (declare (type var var))
                 (aver (null (var-index var)))
                 (cond ((var-arg-register var)
                        (setf (var-index var) index)
                        (incf index)
                        (inst :push (var-arg-register var))
                        (incf stack-used)
                        (set-register-contents (var-arg-register var) var)
                        (setf (var-arg-register var) nil))
                       ((eq (var-kind var) :required)
                        (unless (var-closure-index var)
                          (aver (not (null (var-arg-index var))))
                          (let ((n (* (var-arg-index var) 8)))
                            (unless (<= 0 n 255)
                              (compiler-unsupported "too many vars"))
                            (emit-bytes #x48 #x8b #x46) ; mov n(%rsi),%rax
                            (emit-byte n))
                          (setf (var-index var) index)
                          (incf index)
                          (inst :push :rax)
                          (incf stack-used)
                          (setf (var-arg-index var) nil)))
                       ((eq (var-kind var) :rest)
                        ;; shouldn't happen
                        (mumble "P2-FUNCTION-PROLOG shouldn't happen~%")
                        (aver nil))
                       (t
                        (compiler-unsupported "unsupported var-kind ~S" (var-kind var))))))
              ))

      (incf stack-used (allocate-locals compiland index))

      ;; fix stack alignment if necessary
      (when (oddp stack-used)
        (inst :push :rax))

      (when (compiland-thread-register compiland)
        (emit-call "RT_current_thread")
        (inst :mov :rax (compiland-thread-register compiland)))

      ))
  t)
