(in-package :fact-base)

(defclass meta-base ()
  ((file-name :accessor file-name :initarg :file-name)
   (fact-base-table :accessor fact-base-table :initarg :fact-base-table 
		    :initform (make-hash-table :test 'equal))
   (indices :accessor indices :initarg :indices)))

(defmethod list-bases ((state meta-base))
  (alexandria:hash-table-keys (fact-base-table state)))

(defmethod next-id! ((state meta-base))
  (format nil "branch-~a" (+ 1 (hash-table-count (fact-base-table state)))))

(defun make-meta-base (&key (indices '(:a :b :c)) (file-name (cl-fad:pathname-as-directory (temp-file-name))))
  (let ((res (make-instance 'meta-base :file-name file-name :indices indices)))
    (new-fact-base! res :file-name "master" :indices indices)
    res))

(defmethod get-base ((state meta-base) fact-base-name)
  (gethash fact-base-name (fact-base-table state)))

(defmethod delete! ((state meta-base) (base fact-base))
  (when (get-base state (file-name base))
    (delete-file (merge-pathnames (file-name base) (file-name state)))
    (remhash (file-name base) (fact-base-table state))))

(defmethod write-delta! ((state meta-base) &key (file-name (file-name state)) (zero-delta? t))
  (loop for base being the hash-values of (fact-base-table state)
     for fname = (merge-pathnames (file-name base) file-name)
     do (write-delta! base :file-name fname :zero-delta? zero-delta?)))

(defmethod write! ((state meta-base) &key (file-name (file-name state)) (zero-delta? t))
  (loop for base being the hash-values of (fact-base-table state)
     for fname = (merge-pathnames (file-namestring (file-name base)) file-name)
     do (write! base :file-name fname :zero-delta? zero-delta?)))

(defmethod load! ((base-type (eql :meta-base)) (file-name string) &key (indices '(:a :b :c)))
  (let ((res (make-meta-base :indices indices :file-name (namestring (cl-fad:pathname-as-directory file-name)))))
    (loop for file in (cl-fad:list-directory file-name)
       do (add-fact-base! res (load! :fact-base (namestring file))))
    res))

(defmethod add-fact-base! ((state meta-base) (base fact-base))
  (unless (gethash (file-name base) (fact-base-table state))
    (setf (gethash (file-namestring (file-name base)) 
		   (fact-base-table state))
	  base)))

(defmethod new-fact-base! ((state meta-base) &key (file-name (temp-file-name)) (indices '(:a :b :c)))
  (add-fact-base! 
   state 
   (make-fact-base
    :indices indices
    :file-name (merge-pathnames file-name (file-name state)))))

(defmethod branch! ((state meta-base) (base fact-base) (branch-point list) &key (new-name (next-id! state)))
  (unless (get-base state new-name)
    (let* ((fname (merge-pathnames (file-namestring new-name) (file-name state)))
	   (tmp (make-fact-base :indices (indices state) :file-name fname)))
      (setf (history tmp) (history-slice base :max-time (list->timestamp branch-point)))
      (write! tmp :file-name fname)
      (add-fact-base! state (load! :fact-base (namestring fname))))))
