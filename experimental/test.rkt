#lang racket/base
(require racket/match
         racket/class
         mode-lambda
         mode-lambda/static
         mode-lambda/text/static
         mode-lambda/text/runtime
         mode-lambda/color
         mode-lambda/backend/gl
         racket/draw
         racket/gui/base
         pict
         pict/flash)

;;;
;;; SIZES
;;;

(define W 400)
(define H 400)
(define W/2 (/ W 2.))
(define H/2 (/ H 2.))

;;;
;;; BITMAPS
;;;

;(define gray-p
;  (colorize (filled-rectangle W H) "gray"))
;(define fish-p
;  (standard-fish  100 50))
;(define lantern-p
;  (jack-o-lantern 100))
;(define flash-p

;;;; SPRITES
;;;;



(define db (make-sprite-db))


;
;(add-sprite!/value db 'gray    gray-p)
;(add-sprite!/value db 'fish    fish-p)
;(add-sprite!/value db 'lantern lantern-p)
;(add-sprite!/value db 'flash   flash-p)

(add-sprite!/file db 'test   "test.png")


(define cdb (compile-sprite-db db))

;(module+ test
;  (require racket/runtime-path)
;  (define-runtime-path jens "jens")
;  (save-csd! cdb jens #:debug? #t))
;
;(define gray-idx    (sprite-idx cdb 'gray))
;(define fish-idx    (sprite-idx cdb 'fish))
;(define lantern-idx (sprite-idx cdb 'lantern))
;(define flash-idx   (sprite-idx cdb 'flash))

(define test-idx   (sprite-idx cdb 'test))

;;;
;;; LAYERS
;;;

(define bugl (layer W/2 H/2))    ; gray:       layer 0 ; too see bugs in GL
(define bgl  (layer W/2 H/2))    ; background: layer 1
(define ml   (layer W/2 H/2))    ; middle:     layer 2
(define fgl  (layer W/2 H/2 #:wrap-x? #t))    ; foreground: layer 3
(define lc   (vector bugl bgl ml fgl)) ; layer config

;;;
;;; SPRITES
;;;

;(define gray-sprite    (sprite W/2  H/2  gray-idx    #:layer 0)) ; bug layer
;(define fish-sprite    (sprite 200. 200. fish-idx    #:layer 1)) ; background
;(define lantern-sprite (sprite 250. 200. lantern-idx #:layer 2)) ; middle
;(define flash-sprite   (sprite 160. 200. flash-idx   #:layer 3)) ; foreground


;(define test-sprite   (sprite 0.0 0.0 test-idx   #:layer 3)) ; foreground


;;;
;;; RUNTIME
;;;

(define rendering-states->draw (stage-draw/dc cdb W H (vector-length lc)))

;(define static (list gray-sprite
;                     fish-sprite
;                     lantern-sprite
;                     test-sprite))

;(define static (list test-sprite))


(define test-x 0.0)
(define test-y 0.0)

(define (paint-canvas c dc)
  ;(display test-sprite)
  (set! test-x (- test-x 10.0))
  ;(set! test-y (- test-y 0.1))


  ;; move layer camera

  
  ;(define fgl  (layer W/2 H/2 #:wrap-x? #t)) ;foreground: layer 3
  
  
  (define test-sprite (sprite test-x test-y test-idx #:layer 3))
  
  ;(define dynamic (list flash-sprite))
  (define dynamic (list test-sprite))
  ;(define draw (rendering-states->draw lc static dynamic))
  (define draw (rendering-states->draw lc '() dynamic))
  (match/values (send c get-scaled-client-size)
    [(w h) (draw w h dc)]))

;(module+ main
(define glc (new gl-config%))
(send glc set-legacy? #f)
(define f (new frame% [label "Test"] [width W] [height H]))
(define c
  (new canvas%
       [parent f]
       [min-width W]
       [min-height H]
       [gl-config glc]
       [style '(no-autoclear gl)]
       [paint-callback paint-canvas]))

(send f show #t);)


(define timer (new timer%
                   [notify-callback (lambda() (send f refresh))] [interval #f]))

(send timer start 100)





