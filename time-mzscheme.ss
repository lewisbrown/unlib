#lang mzscheme

(require mzlib/etc
         mzlib/kw
         srfi/19
         "base.ss")

; Constants --------------------------------------

; integer
(define min-zone-offset
  (* 12 60 60 -1))

; integer
(define max-zone-offset 
  (* 12 60 60))

; Date and time constructors ---------------------

;  date
;  [#:nanosecond  (U integer #f)]
;  [#:second      (U integer #f)]
;  [#:minute      (U integer #f)]
;  [#:hour        (U integer #f)]
;  [#:day         (U integer #f)]
;  [#:month       (U integer #f)]
;  [#:year        (U integer #f)]
;  [#:zone-offset (U integer #f)]
; ->
;  srfi:date
(define/kw (copy-date date #:key
                      [nanosecond  #f] 
                      [second      #f]
                      [minute      #f]
                      [hour        #f]
                      [day         #f]
                      [month       #f]
                      [year        #f]
                      [zone-offset #f])
  (make-date (or nanosecond  (date-nanosecond date))
             (or second      (date-second date))
             (or minute      (date-minute date))
             (or hour        (date-hour date))
             (or day         (date-day date))
             (or month       (date-month date))
             (or year        (date-year date))
             (or zone-offset (date-zone-offset date))))

; (U time-tai time-utc) -> date
(define (time->date time)
  (if (time-tai? time)
      (time-tai->date time)
      (time-utc->date time)))

; Date and time predicates -----------------------

; any -> boolean
(define (time-tai? datum)
  (and (time? datum)
       (eq? (time-type datum) time-tai)))

; any -> boolean
(define (time-utc? datum)
  (and (time? datum)
       (eq? (time-type datum) time-utc)))

; any -> boolean
(define (time-duration? datum)
  (and (time? datum)
       (eq? (time-type datum) time-duration)))

; srfi:date -> boolean
(define (date-valid? date)
  (let ([nanosecond (date-nanosecond date)]
        [second     (date-second date)]
        [minute     (date-minute date)]
        [hour       (date-hour date)]
        [day        (date-day date)]
        [month      (date-month date)]
        [year       (date-year date)]
        [tz         (date-zone-offset date)])
    ; Check month first to prevent days-in-month 
    ; raising an exception if it is invalid:
    (and (>= month 1)            (<= month 12)
         (>= day 1)              (<= day (days-in-month month year))
         (>= hour 0)             (< hour 24)
         (>= minute 0)           (< minute 60)
         (>= second 0)           (< second 60)
         (>= nanosecond 0)       (< nanosecond 1000000000)
         (>= tz min-zone-offset) (< tz max-zone-offset))))

; Date and time accessors ------------------------

; date -> (U 'mon 'tue 'wed 'thu 'fri 'sat 'sun)
(define (date-day-of-the-week date)
  (string->symbol (string-downcase (date->string date "~a"))))

; date -> boolean
(define (date-week-day? date)
  (and (memq (date-day-of-the-week date) '(mon tue wed thu fri)) #t))

; Other utilities --------------------------------

; integer -> boolean
(define (leap-year? year)
  (if (zero? (remainder year 4))
      (if (zero? (remainder year 100))
          (if (zero? (remainder year 400))
              #t
              #f)
          #t)
      #f))

; integer [integer] -> integer
(define days-in-month
  (opt-lambda (month [year 2001]) ; non-leap-year by default
    (case month
      [(9 4 6 11) 30]
      [(2) (if (leap-year? year) 29 28)]
      [(1 3 5 7 8 9 10 12) 31]
      [else (raise-exn exn:fail:contract
              (format "Month out of range: ~a" month))])))

; integer [integer] -> string
;
; Takes an integer seconds value (like the value returned by current-seconds) and,
; optionally, a second argument representing the current seconds, and returns a string like:
;
;   n second(s) ago
;   n minute(s) ago
;   n hour(s) ago
;   n day(s) ago
(define seconds->ago-string 
  (opt-lambda (then [now (current-seconds)])
    ; (integer string -> string)
    (define (make-answer number unit)
      (if (= number 1)
          (if (equal? unit "day")
              "yesterday"
              (format "~a ~a ago" number unit))
          (format "~a ~as ago" number unit)))
    ; integer
    (define difference (- now then))
    (when (< difference 0)
      (raise-exn exn:fail:contract
        (format "Expected first argument to be less than second, received ~a ~a." then now)))
    (cond [(< difference 60)    (make-answer difference "second")]
          [(< difference 3600)  (make-answer (floor (/ difference 60)) "minute")]
          [(< difference 86400) (make-answer (floor (/ difference 3600)) "hour")]
          [else                 (make-answer (floor (/ difference 86400)) "day")])))

; (U time-tai time-utc) [(U time-tai time-utc)] -> string
; 
; Takes a time-tai or time-utc (and, optionally, another argument of the same type representing
; the current time) and returns a string like:
;
;   n second(s) ago
;   n minute(s) ago
;   n hour(s) ago
;   n day(s) ago
(define time->ago-string
  (case-lambda
    [(then)
     (let ([now (if (time-tai? then)
                    (current-time time-tai)
                    (current-time time-utc))])
       (seconds->ago-string (time-second then) (time-second now)))]
    [(then now)
     (if (eq? (time-type then) (time-type now))
         (seconds->ago-string (time-second then) (time-second now))
         (raise-exn exn:fail:contract
           (format "Arguments have different time types: ~a ~a" then now)))]))

; -> integer
(define (current-time-zone-offset)
  (date-zone-offset (time-tai->date (current-time time-tai))))

; -> integer
(define (current-year)
  (date-year (time-tai->date (current-time time-tai))))

; Provide statements --------------------------- 

; contract
(define time/c
  (or/c time-tai? time-utc?))

; contract
(define month/c 
  (flat-named-contract 
   "month/c"
   (lambda (x)
     (and (integer? x)
          (>= x 1)
          (<= x 12)))))

; contract
(define day-of-the-week/c
  (flat-named-contract
   "day-of-the-week/c"
   (lambda (x)
     (and (memq x '(mon tue wed thu fri sat sun)) #t))))

(provide copy-date)

(provide/contract
 [time->date               (-> time/c date?)]
 [time-tai?                procedure?]
 [time-utc?                procedure?]
 [time-duration?           procedure?]
 [date-valid?              (-> date? boolean?)]
 [date-day-of-the-week     (-> date? day-of-the-week/c)]
 [date-week-day?           (-> date? boolean?)]
 [leap-year?               (-> integer? boolean?)]
 [days-in-month            (->* (month/c) (integer?) integer?)]
 [seconds->ago-string      (->* (integer?) (integer?) string?)]
 [time->ago-string         (->* (time/c) (time/c) string?)]
 [current-time-zone-offset (-> integer?)]
 [current-year             (-> integer?)])
