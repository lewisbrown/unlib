#lang scheme/base

(require "enumeration.ss"
         "test-base.ss")

; Helpers ----------------------------------------

(define-enum vehicle
  (car boat plane))

(define-enum option
  ([a 1 "item 1"]
   [b 2 "item 2"]
   [c 3 "item 3"]))

; Tests ------------------------------------------

(define enumeration-tests
  (test-suite "enumeration.ss"
    
    (test-case "vehicle"
      (check-pred enum? vehicle)
      (check-equal? (enum-values vehicle) '(car boat plane))
      (check-equal? (enum-pretty-values vehicle) '("car" "boat" "plane"))
      (check-equal? (enum->string vehicle) "car, boat, plane")
      (check-equal? (enum->pretty-string vehicle) "car, boat, plane")
      (check-equal? (vehicle car) 'car)
      (check-equal? (vehicle boat) 'boat)
      (check-equal? (vehicle plane) 'plane)
      (check-equal? (enum-list vehicle boat plane) '(boat plane))
      (check-true (enum-value? vehicle 'car))
      (check-true (enum-value? vehicle 'boat))
      (check-true (enum-value? vehicle 'plane))
      (check-false (enum-value? vehicle 'lemon)))
    
    (test-case "option"
      (check-pred enum? option)
      (check-equal? (enum-values option) '(1 2 3))
      (check-equal? (enum-pretty-values option) '("item 1" "item 2" "item 3"))
      (check-equal? (enum->string option) "1, 2, 3")
      (check-equal? (enum->pretty-string option) "item 1, item 2, item 3")
      (check-equal? (option a) 1)
      (check-equal? (option b) 2)
      (check-equal? (option c) 3)
      (check-true (enum-value? option 1))
      (check-true (enum-value? option 2))
      (check-true (enum-value? option 3))
      (check-false (enum-value? option 'a))
      (check-false (enum-value? option 'b))
      (check-false (enum-value? option 'c)))
    
    (test-case "enum->[pretty-]string with separator specified"
      (check-equal? (enum->string vehicle ":") "car:boat:plane")
      (check-equal? (enum->pretty-string vehicle ":") "car:boat:plane"))))

; Provide statements -----------------------------

(provide enumeration-tests)