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
(add-sprite!/file sprite-db 'enemy          "../enemy.png")
(add-sprite!/file sprite-db 'static-bg      "../static-bg.png")
(add-sprite!/file sprite-db 'primary-bg     "../primary-bg.png")
(add-sprite!/file sprite-db 'secondary-bg   "../secondary-bg.png")
(add-sprite!/file sprite-db 'primary-weapon "../main-projectile.png")

;(add-sprite!/file sprite-db '              "../.png")

(define compiled-db    (compile-sprite-db sprite-db))
;(save-csd! compiled-db "voxos-sprite-db" #:debug? #t)
;(define compiled-db (load-csd "voxos-sprite-db"))

(define player-index         (sprite-idx compiled-db 'player))
(define enemy-index          (sprite-idx compiled-db 'enemy))
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
(define player-speed 3)
(define projectile-speed 10)
(define enemy-speed -5)
(define tick-counter 0)
(define enemy-frequency 20)
(define alpha 1.0)

; screen edge collision boxes
(define border-boxes '((330 0 20 480)
                       (-330 0 20 480)
                       (0 250 640 20)
                       (0 -250 640 20)))

(define player-box   '(-275.0 0.0 64 32))
(define beam-box     '())
(define bullet-boxes '())
(define enemy-boxes  '())

; player control input
(define is-up-input    #false)
(define is-down-input  #false)
(define is-left-input  #false)
(define is-right-input #false)
(define is-fired-input #false)

; static sprites dont move
(define static-bg-sprite (sprite 0.0 0.0 static-bg-index #:layer 0))
(define static-sprites   (list static-bg-sprite))

; primary draw function
(define rendering-states->draw (stage-draw/dc compiled-db 
                                              canvas-size-x
                                              canvas-size-y
                                              (vector-length layer-config)))

(struct demo ()
  #:methods gen:word

  [(define (word-output w)
     (match-define (demo) w)

     (define primary-bg-sprite
       (sprite 0.0 0.0 primary-bg-index #:layer 1))
     (define secondary-bg-sprite
       (sprite 0.0 0.0 secondary-bg-index #:layer 2))
     ;(define -bg-sprite
     ;  (sprite canvas-size-x canvas-size-y -bg-index #:layer ))

     (define player-sprite (sprite (car player-box)
                                   (cadr player-box)
                                   player-index #:layer 3))
     
     ; list of all sprites to be drawn
     (define dynamic-sprites (list primary-bg-sprite
                                   secondary-bg-sprite
                                   player-sprite))

     ; adds new bullets to dynamic sprites
     (set! dynamic-sprites (append dynamic-sprites
                                   (make-sprites bullet-boxes
                                                 primary-weapon-index)))
     ; adds enemies to dynamic sprites
     (set! dynamic-sprites (append dynamic-sprites
                                   (make-sprites enemy-boxes
                                                 enemy-index)))
     
     (rendering-states->draw layer-config static-sprites dynamic-sprites))

   (define (word-event w e)
     (match-define (demo) w)

     (cond
       ; closes window
       [(eq? e 'close) #f]

       ; display diagnostics - bullet info
       [(and (key-event? e) (eq? (send e get-key-code) 'escape))
        ;(display (length enemy-boxes))]
        (display tick-counter)]

       ; WASD keys - controls player position and speed
       [(and (key-event? e) (eq? (send e get-key-code) #\w))
        (set! is-up-input #true)]

       [(and (key-event? e) (eq? (send e get-key-release-code) #\w))
        (set! is-up-input #false)]

       [(and (key-event? e) (eq? (send e get-key-code) #\a))
        (set! is-left-input #true)]

       [(and (key-event? e) (eq? (send e get-key-release-code) #\a))
        (set! is-left-input #false)]

       [(and (key-event? e) (eq? (send e get-key-code) #\s))
        (set! is-down-input #true)]

       [(and (key-event? e) (eq? (send e get-key-release-code) #\s))
        (set! is-down-input #false)]

       [(and (key-event? e) (eq? (send e get-key-code) #\d))
        (set! is-right-input #true)]

       [(and (key-event? e) (eq? (send e get-key-release-code) #\d))
        (set! is-right-input #false)]
       
       
       ; SPACE key - fires primary weapon
       [(and (key-event? e) (eq? (send e get-key-code) #\space))
        (if (not is-fired-input)
            (fire-projectile)
            '())
        (set! is-fired-input #true)]
       
       [(and (key-event? e) (eq? (send e get-key-release-code) #\space))
       (set! is-fired-input #false)])

       (demo))

   ; frame animation system
   (define (word-tick w)
     ; remove off-screen projectiles from list
     (set! bullet-boxes (filter (lambda (e) (< (car e) 340)) bullet-boxes))
     ; adjusts positions of bullet-boxes
     (set! bullet-boxes (move-boxes bullet-boxes projectile-speed))


     
     

     ; enemy freq var
     ; tick counter
     ; counter reaches freq gen enemy, then reset counter     
     (cond
       ((>= tick-counter enemy-frequency)
        (set! tick-counter 0)
        (set! enemy-frequency 0)
        ; generate enemies
        (set! enemy-boxes (cons (list 340.0
                                      (- (random 480) 240.0)
                                      32
                                      32)
                                enemy-boxes))
        (set! enemy-frequency (+ (random 60) 15))
        (display "\n enemy frequency ")
        (display enemy-frequency))
        ;(display tick-counter))
       (else
        (set! tick-counter (+ tick-counter 1))
        (display "\n tick counter ")
        (display tick-counter)))


     
     ; removes off-screen enemies
     (set! enemy-boxes (filter (lambda (e) (> (car e) -340)) enemy-boxes))
     ; adjusts positions of enemy-boxes
     (set! enemy-boxes (move-boxes enemy-boxes enemy-speed))

     ; player model animation
     (if is-right-input
         (begin
           (move-player-right)
           (if (border-collision)
               (move-player-left)
               '()))
         '())

     (if is-left-input
         (begin
           (move-player-left)
           (if (border-collision)
               (move-player-right)
               '()))
         '())

     (if is-up-input
         (begin
           (move-player-up)
           (if (border-collision)
               (move-player-down)
               '()))
         '())

     (if is-down-input
         (begin
           (move-player-down)
           (if (border-collision)
               (move-player-up)
               '()))
         '())

     
     
     w)])

; move hit boxes of sprites by adjusting their x-values in the list
(define (move-boxes boxes speed)
  (cond
    ((null? boxes) '())
    (else

     (cons (list (+ (car (car boxes)) speed) ; x
                 (cadr   (car boxes))        ; y
                 (caddr  (car boxes))        ; width
                 (cadddr (car boxes)))       ; height
           (move-boxes (cdr boxes) speed)))))

; creates a list of sprites
(define (make-sprites boxes sprite-index)
  (cond
    ((null? boxes) '())
    (else          
     (cons (sprite (car (car boxes))
                   (cadr (car boxes))
                   sprite-index
                   #:a alpha
                   #:layer 3)
           (make-sprites (cdr boxes) sprite-index)))))

; adds projectiles to bullet-boxes list
(define (fire-projectile)
  (set! bullet-boxes (cons (list (+ (car player-box) 25)
                                 (cadr player-box)
                                 8
                                 8)
                           bullet-boxes)))


; player movement
(define (move-player-right)
  (set! player-box (cons (+ (car player-box) player-speed) (cdr player-box))))

(define (move-player-left)
  (set! player-box (cons (- (car player-box) player-speed) (cdr player-box))))

(define (move-player-up)
  (set! player-box (cons (car player-box)
                         (cons (- (cadr player-box) player-speed)
                               (cddr player-box)))))

(define (move-player-down)
  (set! player-box (cons (car player-box)
                         (cons (+ (cadr player-box) player-speed)
                               (cddr player-box)))))

; collision detection using hit boxes
(define (border-collision)
  (box-to-list-collision player-box border-boxes))

(define (box-to-list-collision box boxes)
  (cond
    ((null? boxes) #false)
    ((box-to-box-collision box (car boxes)) #true)
    (else (box-to-list-collision box (cdr boxes)))))

(define (box-to-box-collision box1 box2)
  (define box1-x (car box1))
  (define box1-y (cadr box1))
  (define box2-x (car box2))
  (define box2-y (cadr box2))
  (define sum-radii-x (/ (+ (caddr box1) (caddr box2)) 2))
  (define sum-radii-y (/ (+ (cadddr box1) (cadddr box2)) 2))
  (define distance-x (abs (- box1-x box2-x)))
  (define distance-y (abs (- box1-y box2-y)))

  (if (and (< distance-x sum-radii-x) (< distance-y sum-radii-y))
      #true ;; collision detected
      #false))

(module+ main
  (call-with-chaos
   (make-gui #:mode 'gl-core
             #:width canvas-size-x
             #:height canvas-size-y)
   (λ () (fiat-lux (demo)))))
