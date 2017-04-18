#lang racket/base
(require racket/match
         racket/class
         mode-lambda
         mode-lambda/static
         mode-lambda/backend/gl
         racket/gui/base)
; resolutions
(define pWidth 720)
(define pHeight 240)
(define W/2 (/ pWidth 1.0))
(define H/2 (/ pHeight 1.0))
; sprites
(define sprite-db (make-sprite-db))
(add-sprite!/file sprite-db 'test   "test.png")
(define compiled-db (compile-sprite-db sprite-db))
(define test-idx   (sprite-idx compiled-db 'test))
(define test-sprite (sprite 0.0 0.0 test-idx #:layer 0))
; draw stuff
(define rendering-states->draw (stage-draw/dc compiled-db pWidth pHeight 1))
(define move-x 720.0)
; main drawing function
(define (paint-canvas c dc)
  (set! move-x (- move-x 3.0))
  ; move layer stuff
  (define bg-layer (layer move-x 240. #:wrap-x? #t #:wrap-y? #t ))
  (define dynamic (list test-sprite))
  (define lc2  (vector bg-layer))
  ; draw
  (define draw (rendering-states->draw lc2 '() dynamic))
  
  (match/values (send c get-scaled-client-size)
                [(pWidth pHeight) (draw pWidth pHeight dc)]))
; gl stuff
(define glc (new gl-config%))
(send glc set-legacy? #f)
; frame
(define f (new frame% [label "Test"] [width pWidth] [height pHeight]))
; canvas
(define c (new canvas% [parent f] [min-width pWidth]
               [min-height pHeight] [gl-config glc]
               [style '(no-autoclear gl)] [paint-callback paint-canvas]))
; display frame
(send f show #t)
; looper
(define timer (new timer% [notify-callback (lambda() (send f refresh))]
                   [interval #f]))
(send timer start 100)
