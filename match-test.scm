; modified matcher with strict *+num+placeholder

; ********************************************************************************************** accept patten and sentence

; <-----> match
; <-----> accept pattern and sentence arguments
; <-----> create '() as initial known-values
; <-----> invoke match-using-known-values

(define (match pattern sent)
  (match-using-known-values pattern sent '()))

; ********************************************************************************************** general matching

; <-----> match-using-known-values
; <-----> accept pattern, sentence and known-values as arguments

; <-----> list five general categorises for matching:
; <-----> 1. pattern is empty
; <-----> 2. first pattern is special placeholder (* & ? !)
; <-----> 3. sentence is empty
; <-----> 4. one by one non-special word matching
; <-----> 5. else

; <-----> invoke:
; <-----> strict? (if pattern is not empty)
; <-----> match-strict (if first pattern is strict)
; <-----> special? (if first pattern is not strict)
; <-----> match-special (if first pattern is special)
; <-----> match-using-known-values (if check non-special word)

(define (match-using-known-values pattern sent known-values)
  (cond ((empty? pattern)
         (if (empty? sent) known-values 'failed))
        ((plus-num? (first pattern))
         (let ((placeholder (first pattern)))
           (match-plus-num (bf placeholder)
                           (bf pattern)
                           sent
                           known-values)))
        ((strict? (first pattern))
         (let ((placeholder (bf (first pattern))))
           (match-strict (get-num placeholder)
                         (but-num placeholder)
                         (bf pattern)
                         sent
                         known-values)))
        ((special? (first pattern))
         (let ((placeholder (first pattern)))
           (match-special (first placeholder)
                          (bf placeholder)
                          (bf pattern)
                          sent
                          known-values)))
        ((empty? sent) 'failed)
        ((equal? (first pattern) (first sent))
         (match-using-known-values (bf pattern) (bf sent) known-values))
        (else 'failed)))

; <----->plus-num?
(define (plus-num? wd)
  (equal? '+ (first wd)))

; <-----> strict?
(define (strict? wd)
  (and (> (count wd) 2)
       (equal? '* (first wd))
       (number? (first (bf wd)))))

; <-----> get-num
(define (get-num wd)
  (cond ((empty? wd) "")
        ((number? (first wd))
         (word (first wd) (get-num (bf wd))))
        (else (get-num (bf wd)))))

; <-----> but-num
(define (but-num wd)
  (cond ((empty? wd) "")
        ((not (number? (first wd)))
         (word (first wd) (but-num (bf wd))))
        (else (but-num (bf wd)))))

; <-----> special?
; <-----> accept wd as argument
(define (special? wd)
  (member? (first wd) '(* & ? !)))

; ********************************************************************************************** plus number pattern

; <-----> match-plus-num

(define (match-plus-num name pattern-rest sent known-values)
  (let ((old-value (lookup name known-values)))
    (if (not (equal? old-value 'no-value))
        (if (and (number? (first old-value))
                 (= (count old-value) 1))
            (already-known-match
              old-value pattern-rest sent known-values)
            'failed)
        (if (not (empty? sent))
            (mpn-helper name pattern-rest (first sent) (bf sent) known-values)
            'failed))))

; <-----> mpn-helper

(define (mpn-helper name pattern-rest sent-matched sent known-values)
  (if (number? (first sent-matched))
      (match-using-known-values pattern-rest
                                sent
                                (add name sent-matched known-values))
      'failed))

; ********************************************************************************************** strict pattern matching

; <-----> match-strict

(define (match-strict strict-howmany name pattern-rest sent known-values)
 (let ((old-value (lookup name known-values)))
   (if (not (equal? old-value 'no-value))
       (if (= (count old-value) strict-howmany)
           (already-known-match
             old-value pattern-rest sent known-values)
           'failed)
       (ms-helper strict-howmany name pattern-rest '() sent known-values))))

; <-----> ms-helper
(define (ms-helper strict-howmany name pattern-rest sent-matched sent known-values)
  (cond ((= strict-howmany 0) (match-using-known-values pattern-rest
                                                        sent
                                                        (add name sent-matched known-values)))
        ((empty? sent) 'failed)
        (else (ms-helper (- strict-howmany 1)
                         name
                         pattern-rest
                         (se sent-matched (first sent))
                         (bf sent)
                         known-values))))

; ********************************************************************************************** special pattern matching

; <-----> match-special
; <-----> accept howmany, name, pattern-rest, sent, and known-values as arguments

; <-----> list 2 categories and 4 sub-categories for matching special patterns
; <-----> 1. the same placeholder is already in the konwn-values
; <-----> 2. new place holders:
; <----->    1) ?
; <----->    2) !
; <----->    3) *
; <----->    4) &

; <-----> invoke lookup to let old-value get (lookup name known-values)
; <-----> invoke length-ok? when old-value is not 'no-value
; <-----> <-----> invoke already-known-match if length-ok? returns true
; <-----> <-----> and take old-value as value

; <-----> invoke longest-match when howmany equal to ?/!/*/&
; <-----> create:
; <----->   1. 0/1 as min
; <----->   2. #t/#f as max-one?

(define (match-special howmany name pattern-rest sent known-values)
  (let ((old-value (lookup name known-values)))
    (cond ((not (equal? old-value 'no-value))
           (if (length-ok? old-value howmany)
               (already-known-match
                 old-value pattern-rest sent known-values)
               'failed))
          ((equal? howmany '?)
           (longest-match name pattern-rest sent 0 #t known-values))
          ((equal? howmany '!)
           (longest-match name pattern-rest sent 1 #t known-values))
          ((equal? howmany '*)
           (longest-match name pattern-rest sent 0 #f known-values))
          ((equal? howmany '&)
           (longest-match name pattern-rest sent 1 #f known-values)))))


; <-----> length-ok?

(define (length-ok? value howmany)
  (cond ((empty? value) (member? howmany '(? *)))
        ((not (empty? (bf value))) (member? howmany '(* &)))
        (else #t)))

; <-----> already-known-match

(define (already-known-match value pattern-rest sent known-values)
  (let ((unmatched (chop-leading-substring value sent)))
    (if (not (equal? unmatched 'failed))
        (match-using-known-values pattern-rest unmatched known-values)
        'failed)))

; <-----> chop-leading-substring

(define (chop-leading-substring value sent)
  (cond ((empty? value) sent)
        ((empty? sent) 'failed)
        ((equal? (first value) (first sent))
         (chop-leading-substring (bf value) (bf sent)))
        (else 'failed)))

; <-----> longest-match
; <-----> accept name, pattern-rest, sent, min, max-one? and known-values as arguments

; <-----> list 2 categorises and 2 sub-categories:
; <----->   1. sentence is empty
; <----->   2. sentence is not empty
; <----->      1) max-one? is true
; <----->      2) max-one? is false

; <-----> invoke match-using-known-values when sent is empty and min=0
; <-----> invoke (add name '() known-values) to be known-values

; <-----> when max-one? is true, invoke lm-helper with
; <-----> (se (first sent)) as sent-matched
; <-----> (bf sent) as sent-unmatched

; <-----> when max-one? is false, invoke lm-helper with
; <-----> sent as sent-matched
; <-----> '() as sent-unmatched

(define (longest-match name pattern-rest sent min max-one? known-values)
  (cond ((empty? sent)
         (if (= min 0)
             (match-using-known-values pattern-rest
                                       sent
                                       (add name '() known-values))
             'failed))
        (max-one?
          (lm-helper name pattern-rest (se (first sent))
                     (bf sent) min known-values))
        (else (lm-helper name pattern-rest
                         sent '() min known-values))))

; <-----> lm-helper
; <-----> accept name, pattern-rest, sent-matched, sent-unmatched min and known-values as arguments

; <-----> if length of sent-matched is not less than min
; <-----> let tentative-result = (match-using-known-values pattern-rest sent-unmatched (add name sent-matched known-values))

; <-----> list 3 categories for matching:
; <----->   1. tentative-result is not failed
; <----->   2. sent-matched is empty
; <----->   3. tentative-result is failed but sent-matched is not empty

; <-----> invoke lm-helper with
; <-----> (bl sent-matched) as sent-matched
; <-----> (se (last sent-matched) sent-unmatched) as sent-unmatched

(define (lm-helper name pattern-rest
                   sent-matched sent-unmatched min known-values)
  (if (< (length sent-matched) min)
      'failed
      (let ((tentative-result (match-using-known-values
                                pattern-rest
                                sent-unmatched
                                (add name sent-matched known-values))))
        (cond ((not (equal? tentative-result 'failed)) tentative-result)
              ((empty? sent-matched) 'failed)
              (else (lm-helper name
                               pattern-rest
                               (bl sent-matched)
                               (se (last sent-matched) sent-unmatched)
                               min
                               known-values))))))

;;; Known values database abstract data type

(define (lookup name known-values)
  (cond ((empty? known-values) 'no-value)
        ((equal? (car (car known-values)) name)
         (get-value (bf known-values)))
        (else (lookup name (skip-value known-values)))))

(define (get-value stuff)
  (cdar stuff))

(define (skip-value stuff)
  (cdr stuff))

(define (add name value known-values)
  (if (empty? name)
      known-values
      (append known-values (list (list name value)))))

