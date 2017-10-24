#lang racket
;;; https://docs.racket-lang.org/shell-pipeline/pipeline.html?q=pipe

(require db)
(require shell/pipeline)

(struct docset (name path conn elems))

(define (connect-to sqlite3-db)
  (sqlite3-connect
   #:database sqlite3-db
   #:mode 'read-only))

(define docsets-path
  "/home/rgrau/.docsets/~a.docset/Contents/Resources/docSet.dsidx")

(define (docset-path-for name)
  (format docsets-path name))

(define (list-all-entries dbconn)
  ;; should be private
  (rows-result-rows
   (query dbconn "select name, path from searchIndex")))

(define (counter)
  (let ((n 0))
    (lambda ()
      (set! n (+ n 1))
      n)))

(define (make-docset name)
  (define (prepend-name l)
    (list* (format "~a ~a" name (car l)) (cdr l)))
  (let* ((path (docset-path-for name))
         (conn (connect-to path))
         (elems (map (compose prepend-name vector->list)
                     (list-all-entries conn))))
    (docset name path conn elems)))

(define docset-names '("AllegroLisp"))

(define (connections)
  (map make-docset docset-names))

(define (all-elems)
  (append-map (lambda (x) (docset-elems x))
              (connections)))

(define (-n l)
  (let ((c (counter)))
    (map (lambda (y)
           (cons (format "~a ~a"
                          (first y)
                          (second y))
                  (third y)))
         (map (lambda (x)
                (cons (c) x) )
              l))))

(define the-hash (make-hash (-n (all-elems))))

(define (get-path-from-str str)
  (list-ref (-n) (string->number (car (string-split str " ")))))

(define (get-all-entries h)
  (string-join (hash-keys h) "\n"))

(define (store-options opts)
  (let* ((tmpfile (make-temporary-file))
         (port (open-output-file tmpfile #:mode 'text #:exists 'truncate)))
    (display opts port)
    (close-output-port port)
    (hash-ref the-hash
              (string-trim (run-pipeline/out `(cat ,tmpfile) '(dmenu) )))))


(define (choose-entry)
  ;(run-pipeline `(,(string-join (-n) "\n")) '(dmenu) `(,get-path-from-str))
  (run-pipeline `(,(shellify get-all-entries)) '(dmenu)))


; (store-options (get-all-entries the-hash))
