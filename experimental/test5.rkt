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
(define canvas-size-x 640)
(define canvas-size-y 480)

; sprites and layers
(define sprite-db     (make-sprite-db))
(add-sprite!/file sprite-db 'player   "../player.png")
(define compiled-db   (compile-sprite-db sprite-db))
(save-csd! compiled-db "voxos-sprite-db" #:debug? #t)
(define player-index  (sprite-idx compiled-db 'player))
(define bg-layer (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))
(define action-layer (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))
(define layer-config  (vector bg-layer action-layer))


;(define static) -static list of sprites


; state variables
(define move-x 0.0)
(define player-position-x 0.0)
(define player-position-y 0.0)
(define player-speed 5)

; draw
(define rendering-states->draw
  (stage-draw/dc compiled-db canvas-size-x canvas-size-y 2))

(struct demo ()
  #:methods gen:word

  [(define (word-output w)
     (match-define (demo) w)

     (define player-sprite
       (sprite player-position-x player-position-y player-index #:layer 1))
     
     (define dynamic (list player-sprite))

     (rendering-states->draw layer-config '() dynamic))

   (define (word-event w e)
     (match-define (demo) w)

     (cond
       [(eq? e 'close) #f]
      
       ;[(and (key-event? e) (not (eq? 'release (send e get-key-code))))
        ;(set! player-position-x (+ move-x 1))
        ;(demo)]

       [(and (key-event? e)
             (eq? (send e get-key-code) #\w)
             (eq? (send e get-key-code) #\d))
        (set! player-position-y (- player-position-y player-speed))
        (set! player-position-x (+ player-position-x player-speed)) 
        (demo)]

       
       [(and (key-event? e) (eq? (send e get-key-code) #\w))
        (set! player-position-y (- player-position-y player-speed))
        (demo)]

       [(and (key-event? e) (eq? (send e get-key-code) #\a))
        (set! player-position-x (- player-position-x player-speed))
        (demo)]

       [(and (key-event? e) (eq? (send e get-key-code) #\s))
        (set! player-position-y (+ player-position-y player-speed))
        (demo)]

       [(and (key-event? e) (eq? (send e get-key-code) #\d))
        (set! player-position-x (+ player-position-x player-speed))
        (demo)]

       [else (demo)]))
   
   (define (word-tick w)
     (set! move-x (add1 move-x))
     w)])

(module+ main
  (call-with-chaos
   (make-gui #:mode 'gl-core
             #:width canvas-size-x
             #:height canvas-size-y)
   (λ () (fiat-lux (demo)))))
