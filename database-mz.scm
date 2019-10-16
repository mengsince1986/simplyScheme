;;; The databse project of Simply_Scheme with additional features completed

;;; The database ADT: a filename, list of fields and list of records

(define (make-db filename fields records)
  (vector filename fields records))

(define (db-filename db)
  (vector-ref db 0))

(define (db-set-filename! db filename)
  (vector-set! db 0 filename))

(define (db-fields db)
  (vector-ref db 1))

(define (db-set-fields! db fields)
  (vector-set! db 1 fields))

(define (db-records db)
  (vector-ref db 2))

(define (db-set-records! db records)
  (vector-set! db 2 records))


;;; Stuff about the current state

(define current-state (vector #f))

(define (no-db?)
  (not (vector-ref current-state 0)))

(define (current-db)
  (if (no-db?)
      (error "No current database!")
      (vector-ref current-state 0)))

(define (set-current-db! db)
  (vector-set! current-state 0 db))

(define (current-fields)
  (db-fields (current-db)))

;; User commands

(define (new-db filename fields)
  (set-current-db! (make-db filename fields '()))
  'created)

(define (insert)
  (let ((new-record (get-record)))
    (db-insert new-record (current-db)))
  (if (ask "Insert another? ")
      (insert)
      'inserted))

(define (db-insert record db)
  (db-set-records! db (cons record (db-records db))))

(define (get-record)
  (get-record-loop 0
                   (make-vector (length (current-fields)))
                   (current-fields)))

(define (get-record-loop which-field record fields)
  (if (null? fields)
      record
      (begin (display "Value for ")
             (display (car fields))
             (display "--> ")
             (vector-set! record which-field (read))
             (get-record-loop (+ which-field 1) record (cdr fields)))))

;; count-db
;; Implement the count-db procedure. It should take no arguments, and it should return the number of records in the current database.

(define (count-db)
  (length (vector-ref (current-db) 2)))

;; list-db
;; Implement the list-db procedure. It should take no arguments, and it should print the current database in the format shown earlier.

(define (list-db)
  (let ((db (current-db)))
    (list-db-helper (db-fields db) (db-records db) 1)))

(define (list-db-helper fields records index)
  (if (null? records)
      "Listed"
      (begin (display "Record ")
             (display index)
             (newline)
             (list-record fields (car records) 0 (- (length fields) 1))
             (list-db-helper fields (cdr records) (+ 1 index)))))

(define (list-record fields record index end)
  (if (> index end)
      (newline)
      (begin (display (car fields))
             (display ": ")
             (display (vector-ref record index))
             (newline)
             (list-record (cdr fields) record (+ index 1) end))))

;; edit-record
;; Implement edit-record, which takes a number between one and the number of records in the current database as its argument. It should allow the user to interactively edit the given record of the current database, as shown earlier.

(define (edit-record index)
  (let ((db (current-db)))
    (let ((fields (db-fields db))
          (record (list-ref (db-records db) (- index 1))))
      (list-record fields record 0 (- (length fields) 1))
      (edit-record-helper fields record)
      (newline)
      'Edited)))

(define (edit-record-helper fields record)
  (display "Edit which field?")
  (let ((command (read)))
    (if (equal? #f command)
        'done
        (if (member command fields)
            (begin (edit-field fields command record)
                   (list-record fields record 
                                0 (- (length fields) 1))
                   (edit-record-helper fields record))
            (begin (display "No such filed in this data")
                   (newline)
                   (newline)
                   (edit-record-helper fields record))))))

(define (edit-field fields field record)
  (edit-field-helper (field-index field fields) field record))

(define (edit-field-helper index field record)
  (display "New value for ")
  (display field)
  (display "--> ")
  (let ((new-value (read)))
    (vector-set! record index new-value)))

(define (field-index field fields)
  (field-index-helper field fields 0))

(define (field-index-helper field fields index)
  (if (equal? field (car fields))
      index
      (field-index-helper field (cdr fields) (+ index 1))))

;;; Utilities

(define (ask question)
  (display question)
  (let ((answer (read)))
    (cond ((equal? (first answer) 'y) #t)
          ((equal? (first answer) 'n) #f)
          (else (show "Please type Y or N.")
                (ask question)))))

