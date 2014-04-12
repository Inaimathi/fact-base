(in-package #:fact-base)

(defun make-index (indices)
  (let ((index (make-instance 'index)))
    (loop for ix in indices
       do (setf (gethash ix (table index))
		(make-hash-table :test 'equal)))
    index))

(defmethod indexed? ((state index) (ix-type symbol))
  (gethash ix-type (table state)))

(defmacro lookup-index (state &rest indices)
  (with-gensyms (ix ideal applicable?)
    `(let ((,ix (index ,state))
	   (,ideal))
       ,@(loop for i in indices 
	    for syms = (key->symbols i)
	    collect `(let ((,applicable? (and ,@syms)))
		       (when (and (null ,ideal) ,applicable?) (setf ,ideal ,i))
		       (when (and (indexed? ,ix ,i) ,applicable?)
			 (return-from decide-index 
			   (values (list ,i ,@syms) ,ideal)))))
       (values nil ,ideal))))

(defmethod decide-index ((state fact-base) &optional a b c)
  (lookup-index state :abc :ab :ac :bc :a :b :c))

(defmacro index-case (ix-type fact &rest indices)
  `(destructuring-bind (a b c) ,fact
     (case ,ix-type
       ,@(loop for i in indices
	    for syms = (key->symbols i)
	    collect `(,i (list ,@syms))))))

(defmethod format-index ((ix-type symbol) (fact list))
  (index-case 
   ix-type fact
   :abc :ab :ac :bc :a :b :c))

(defmethod map-insert! ((state index) (facts list))
  (dolist (f facts) (insert! state f)))

(defmethod insert! ((state index) (fact list))
  (loop for ix being the hash-keys of (table state)
     for ix-table being the hash-values of (table state)
     do (push fact (gethash (format-index ix fact) ix-table))))

(defmethod delete! ((state index) (fact list))
  (loop for ix being the hash-keys of (table state)
     for ix-table being the hash-values of (table state)
     for formatted = (format-index ix fact)
     do (setf (gethash formatted ix-table) 
	      (remove fact (gethash formatted ix-table) :test #'equal :count 1))
     unless (gethash formatted ix-table) do (remhash formatted ix-table)))

;;;;; Show methods
;; Entirely for debugging purposes. 
;; Do not use in production. 
;; Seriously.
(defmethod show (thing &optional (depth 0))
  (format t "~a~a" (make-string depth :initial-element #\space) thing))

(defmethod show ((tbl hash-table) &optional (depth 0))
  (loop for k being the hash-keys of tbl
     for v being the hash-values of tbl
     do (format t "~a~5@a ->~%" 
		(make-string depth :initial-element #\space) k)
     do (show v (+ depth 8))
     do (format t "~%")))

(defmethod show ((ix index) &optional (depth 0))
  (show (table ix) depth))
