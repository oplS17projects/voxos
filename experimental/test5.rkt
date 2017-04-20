#lang racket/base
(require racket/match
         racket/class
         lux
         lux/chaos/gui
         lux/chaos/gui/key
         mode-lambda
         mode-lambda/static
         mode-lambda/backend/gl)

; resolution
(define canvas-size-x 640)
(define canvas-size-y 480)

; sprites and layers
(define sprite-db (make-sprite-db))
(add-sprite!/file sprite-db 'player         "../player.png")
(add-sprite!/file sprite-db 'static-bg      "../static-bg.png")
(add-sprite!/file sprite-db 'primary-bg     "../primary-bg.png")
(add-sprite!/file sprite-db 'secondary-bg   "../secondary-bg.png")
(add-sprite!/file sprite-db 'primary-weapon "../primary-weapon.png")
;(add-sprite!/file sprite-db '              "../.png")

(define compiled-db    (compile-sprite-db sprite-db))
(save-csd! compiled-db "voxos-sprite-db" #:debug? #t)
;(load-csd "voxos-sprite-db")

(define player-index         (sprite-idx compiled-db 'player))
(define static-bg-index      (sprite-idx compiled-db 'static-bg))
(define primary-bg-index     (sprite-idx compiled-db 'primary-bg))
(define secondary-bg-index   (sprite-idx compiled-db 'secondary-bg))
(define primary-weapon-index (sprite-idx compiled-db 'primary-weapon))
;(define -index  (sprite-idx compiled-db '))

(define static-bg-layer
  (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))
(define primary-bg-layer
  (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))
(define secondary-bg-layer
  (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))
(define action-layer
  (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))
;(define -layer
;  (layer (* 1.0 canvas-size-x) (* 1.0 canvas-size-y)))

(define layer-config
  (vector static-bg-layer primary-bg-layer secondary-bg-layer action-layer))


; state variables
(define move-x 0.0)
(define move-y 0.0)
(define player-position-x 0.0)
(define player-position-y 0.0)
(define player-speed 5)


; draw
(define rendering-states->draw (stage-draw/dc compiled-db 
                                              canvas-size-x
                                              canvas-size-y
                                              (vector-length layer-config)))

(struct demo ()
  #:methods gen:word

  [(define (word-output w)
     (match-define (demo) w)

     (define static-bg-sprite
       (sprite canvas-size-x canvas-size-y static-bg-index #:layer 0))
     (define primary-bg-sprite
       (sprite canvas-size-x canvas-size-y primary-bg-index #:layer 1))
     (define secondary-bg-sprite
       (sprite canvas-size-x canvas-size-y secondary-bg-index #:layer 2))
     ;(define -bg-sprite
     ;  (sprite canvas-size-x canvas-size-y -bg-index #:layer ))

     
     (define player-sprite
       (sprite player-position-x player-position-y player-index #:layer 3))
     (define primary-weapon-sprite
       (sprite canvas-size-x canvas-size-y primary-weapon-index #:layer 3))

     (define static-sprites  (list static-bg-sprite))
     (define dynamic-sprites (list primary-bg-sprite
                                   secondary-bg-sprite
                                   player-sprite
                                   primary-weapon-sprite))

     (rendering-states->draw layer-config static-sprites dynamic-sprites))

   (define (word-event w e)
     (match-define (demo) w)

     (cond
       ; closes window
       [(eq? e 'close) #f]

       ; WASD keys - controls player position and speed
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

       ; SPACE key - fires primary weapon
       [(and (key-event? e) (eq? (send e get-key-code) #\space))
        (set! player-position-x (+ player-position-x player-speed))
        (demo)]
       
       [(and (key-event? e) (eq? (send e get-key-release-code) #\space))
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
