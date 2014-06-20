;;;; package.lisp

(defpackage #:fact-base
  (:use #:cl #:optima)
  (:shadow #:delete)
  (:import-from #:alexandria #:with-gensyms)
  (:import-from #:anaphora #:awhen #:aif #:it)
  (:export :fact-base :make-fact-base :current :delta
	   :file-name :next-id!
	   :for-all :lookup 
	   :multi-insert! :insert-new! :insert! :delete! 
	   :index! ;; :project! :project
	   :write! :load!))

