#lang racket
;;; https://docs.racket-lang.org/shell-pipeline/pipeline.html?q=pipe

(require db)
(require shell/pipeline)

(struct docset (name path conn elems))

(define (connect-to sqlite3-db)
  (sqlite3-connect
   #:database sqlite3-db
   #:mode 'read-only))

(define docset-path
  "/home/rgrau/.docsets/~a.docset/Contents/Resources/docSet.dsidx")

(define (docset-path-for name)
  (format docset-path name))

(define (list-all-entries dbconn)
  (rows-result-rows
   (query dbconn "select name, path from searchIndex")))

(define (make-docset name)
  (let* ((path (docset-path-for name))
         (conn (connect-to path))
         (elems (list-all-entries conn)))
    (docset name path conn elems)))

(define docset-names '("AllegroLisp" "Clojure"))

(define (connections)
  (map make-docset docset-names))

(define (all-elems)
  (append-map (lambda (x) (docset-elems x))
              (connections)))

(define (-n)
  (let ((n 0))
    (map (lambda (x)
           (set! n (+ 1 n))
           (string-join (list* (number->string n) (vector->list x)) ))
         (all-elems))))

(define (get-path-from-str str)
  (list-ref (-n) (string->number (car (string-split str " ")))))

(define (choose-entry)
  ;(run-pipeline `(,(string-join (-n) "\n")) '(dmenu) `(,get-path-from-str))
  (run-pipeline `(,tt) '(dmenu) `(,get-path-from-str))
)
