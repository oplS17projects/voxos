#lang racket/base
(require racket/match
         racket/fixnum
         racket/class
         (prefix-in pict: pict)
         (prefix-in image: 2htdp/image)
         lux
         lux/chaos/gui
         lux/chaos/gui/val
         lux/chaos/gui/key
         mode-lambda
         mode-lambda/static
         mode-lambda/backend/gl)

; resolutions
(define pWidth 720)
(define pHeight 240)
; sprites
(define sprite-db (make-sprite-db))
(add-sprite!/file sprite-db 'test   "test.png")
(define compiled-db (compile-sprite-db sprite-db))
(save-csd! compiled-db "test" #:debug? #t)
(define test-idx   (sprite-idx compiled-db 'test))
(define test-sprite (sprite 360.0 120.0 test-idx #:layer 0))
; draw stuff
(define rendering-states->draw (stage-draw/dc compiled-db pWidth pHeight 1))
(define move-x 0.0)

(define MODES
  (list (pict:arrowhead 30 0)
        (image:add-line
         (image:rectangle 100 100 "solid" "darkolivegreen")
         25 25 75 75
         (image:make-pen "goldenrod" 30 "solid" "round" "round"))))

(struct demo (g/v mode)
  #:methods gen:word

  [(define (word-output w)
     (match-define (demo g/v mode-n) w)

     (define bg-layer
       (layer (- 360. move-x) 120. #:hw (* 1/2 360.) #:hh 120.))

     (define dynamic (list test-sprite))

     (define lc2  (vector bg-layer))

     (rendering-states->draw lc2 '() dynamic))

   (define (word-event w e)
     (match-define (demo g/v mode-n) w)

     ;(define closed? #f)

     (cond
       [(eq? e 'close) #f]
      
       [(and (key-event? e) (not (eq? 'release (send e get-key-code))))
        (demo g/v (fxmodulo (fx+ 1 mode-n) (length MODES)))]

       [else (demo g/v mode-n)]))
   
   (define (word-tick w)
     (set! move-x (add1 move-x))
     w)])

(module+ main
  (call-with-chaos
   (make-gui #:mode 'gl-core
             #:width pWidth
             #:height pHeight)
   (λ () (fiat-lux (demo (make-gui/val) 0)))))
