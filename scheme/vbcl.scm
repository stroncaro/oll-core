;; Very Basic Config Language
;;
;; VBCL parser
;;
;; Andrew Bernard 2017
;;
;; for guile 1.8

(define-module (oll-core scheme vbcl))
(export
 parse-vbcl-config
 file->list)

(use-modules (ice-9 regex))
(use-modules (ice-9 rdelim))
(use-modules (srfi srfi-1))
(use-modules (oll-core scheme iterator))


;; parse VBCL config file.
;; return an alist of settings.

(define parse-vbcl-config
  (lambda (lines)
    (let ((m #f)
	  (result '())
	  (iter (list-iter lines)))
      
      ;; helper functions
      (define matcher
	(lambda (pat line)
	  (set! m (string-match pat line))
	  (if m #t #f)))

      ;; main code body
      (let outer-lp ((elem (iter)))
	(if (equal? 'list-ended elem)
	    (begin
	      ;; done
	      result)
	    (begin
	      (cond
	       ;; comments
	       ((matcher "^#" elem)
		#t)
	       
	       ;; long text
	       ((matcher "(^[[:space:]]*(.*):[[:space:]]*<)" elem)
		;; inner loop
		;; put the pair in the alist. the data is a string of lines.
		(set! result
		      (cons
		       (cons (string-trim-right (match:substring m 2))
			     (parse-long-textline-entries iter))
		       result)))

	       ;; lists
	       ((matcher "(^[[:space:]]*(.*):[[:space:]]*\\[)" elem)
	       	;;put the pair in the alist. the data is a vector.
	       	(set! result (cons
	       		      (cons
	       		       (string-trim-right (match:substring m 2))
	       		       (list->vector (parse-list-entries iter)))
	       		       result)))

	       ;; name value pairs
	       ((matcher  "^[[:space:]]*(.*):[[:space:]]+([^[:space:]]+)" elem)
		;;put the pair in the alist.
		(set! result (cons
			      (cons
			       (string-trim-right (match:substring m 1))
			       (string-trim-right (match:substring m 2)))
			      result)))
	       )
	      (outer-lp (iter))
	      ))))))

;; inner loop processing, most easily isolated using functions

(define parse-long-textline-entries
  (lambda (iter)

    ;; return string of lines until end condition found - the delimiter
    ;; for this type of object: '>'.

    ;; needs to be a separate function to avoid altering the state in
    ;; the context from which it is run.

    (let ((m #f) 
	   (data ""))

      ;; helper
      (define matcher
	(lambda (pat line)
	  (set! m (string-match pat line))
	  (if m #t #f)))

      ;; main code body
      (let lp ((elem (iter)))
	(if (matcher "^[[:space:]]*>" elem)
	    data
	    (begin
	       (set! data (string-append data elem))
	      (lp (iter))))))))

(define parse-list-entries
  (lambda (iter)

    ;; return list of lines until end condition found - the delimiter
    ;; for this type of object: ']'.

    ;; needs to be a separate function to avoid altering the state in
    ;; the context from which it is run.
    
    (let* ((m #f)
	   (result '()))

      ;; helper
      (define matcher
	(lambda (pat line)
	  (set! m (string-match pat line))
	  (if m #t #f)))

      ;; main code body
      (let lp ((elem (iter)))
	(if (matcher "^[[:space:]]*]" elem)
	    (reverse result)
	    (begin
	      (set! result (cons (string-trim-right elem) result))
	      (lp (iter))))))))

;; read a file as a list of lines
(define file->list
  (lambda (file)
      (let ((h (open-input-file file))
	    (lines '()))
	(let lp ((line (read-line h 'concat)))
	  (if (eof-object? line)
	      (reverse lines)
	      (begin
		(set! lines (cons line lines))
		(lp (read-line h 'concat))))))))

