#lang racket/base
(require racket/match
         racket/class
         lux
         lux/chaos/gui
         lux/chaos/gui/key
         mode-lambda
         mode-lambda/static
         mode-lambda/backend/gl
         rsound)

; define background music track
(define power-core                (rs-read "./sound/power-core.wav"))
(define main-weapon               (rs-read "./sound/main-weapon.wav"))
(define enemy-explosion           (rs-read "./sound/enemy-explosion.wav"))
(define player-explosion          (rs-read "./sound/player-explosion.wav"))
(define small-explosion           (rs-read "./sound/small-explosion.wav"))
(define medium-explosion          (rs-read "./sound/medium-explosion.wav"))
(define shield-enemy-kill         (rs-read "./sound/shield-enemy-kill.wav"))
; resolution
(define canvas-size-x          640) ; width
(define canvas-size-y          480) ; height

; create sprite database
(define sprite-db                 (make-sprite-db))

; add sprites to database
(add-sprite!/file sprite-db       'player         "./sprites/player.png")
(add-sprite!/file sprite-db       'earth          "./sprites/earth.png")
(add-sprite!/file sprite-db       'enemy          "./sprites/enemy.png")
(add-sprite!/file sprite-db       'static-bg      "./sprites/static-bg.png")
(add-sprite!/file sprite-db       'main-bg        "./sprites/main-bg.png")
(add-sprite!/file sprite-db       'secondary-bg   "./sprites/secondary-bg.png")
(add-sprite!/file sprite-db       'main-weapon    "./sprites/main-weapon.png")
(add-sprite!/file sprite-db       'enemy-weapon   "./sprites/enemy-weapon.png")
(add-sprite!/file sprite-db       'game-over      "./sprites/game-over.png")
(add-sprite!/file sprite-db       'explosion-1    "./sprites/explosion-1.png")
(add-sprite!/file sprite-db       'explosion-2    "./sprites/explosion-2.png")
(add-sprite!/file sprite-db       'explosion-3    "./sprites/explosion-3.png")

; compile sprite database
(define compiled-db               (compile-sprite-db sprite-db))
;(save-csd! compiled-db           "voxos-sprite-db" #:debug? #t)
;(define compiled-db              (load-csd "voxos-sprite-db"))

; sprite index
(define player-index              (sprite-idx compiled-db 'player))
(define earth-index               (sprite-idx compiled-db 'earth))
(define enemy-index               (sprite-idx compiled-db 'enemy))
(define static-bg-index           (sprite-idx compiled-db 'static-bg))
(define main-bg-index             (sprite-idx compiled-db 'main-bg))
(define secondary-bg-index        (sprite-idx compiled-db 'secondary-bg))
(define main-weapon-index         (sprite-idx compiled-db 'main-weapon))
(define enemy-weapon-index        (sprite-idx compiled-db 'enemy-weapon))
(define game-over-index           (sprite-idx compiled-db 'game-over))
(define explosion-1-index         (sprite-idx compiled-db 'explosion-1))
(define explosion-2-index         (sprite-idx compiled-db 'explosion-2))
(define explosion-3-index         (sprite-idx compiled-db 'explosion-3))

; game layers - sprites are placed onto layers
(define static-bg-layer             ; static bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))
(define main-bg-layer               ; parallax bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))
(define secondary-bg-layer          ; parallax bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))
(define action-layer                ; action layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))

; layer configuration
(define layer-config
  (vector static-bg-layer main-bg-layer secondary-bg-layer action-layer))

; state variables
(define is-player-alive      #true) ; player state
(define player-speed             3) ; player movement speed
(define projectile-speed        10) ; projectile movement speed
(define enemy-projectile-speed  -5) ; enemy projectile movement speed
(define enemy-speed             -2) ; enemy movement speed
(define tick-counter             0) ; tick counter
(define enemy-frequency         15) ; enemy creation frequency
(define alpha                  1.0) ; transparency amount
(define shield-strength        100) ; shield strength
(define player-score             0) ; player score
(define shield-location       -300) ; shield x-axis location

; screen edge collision boxes
(define border-boxes
                   '((330 0 20 480) ; right screen edge hit box
                    (-330 0 20 480) ; left screen edge hit box
                     (0 250 640 20) ; top screen edge hit box
                  (0 -250 640 20))) ; bottom screen edge hit box
; misc hit boxes
(define player-box
               '(-275.0 0.0 64 32)) ; starting position
(define beam-box               '()) ; laser weapon
(define bullet-boxes           '()) ; projectile hit-boxes
(define enemy-bullet-boxes     '()) ; enemy projectile hit-boxes
(define enemy-boxes            '()) ; enemy hit-boxes
(define explosion-boxes        '()) ; explosion hit-boxes

; player control input toggles
(define is-up-input         #false) ; up
(define is-down-input       #false) ; down
(define is-left-input       #false) ; left
(define is-right-input      #false) ; right
(define is-fired-input      #false) ; fire weapon

; parallax background movement
(define main-bg-x              0.0) ; main bg           - x position
(define main-bg-y              0.0) ; main bg           - y position
(define tile-main-bg-x       640.0) ; tile main bg      - x position
(define tile-main-bg-y         0.0) ; tile main bg      - y position
(define secondary-bg-x         0.0) ; secondary bg      - x position
(define secondary-bg-y         0.0) ; secondary bg      - y position
(define tile-secondary-bg-x  640.0) ; tile-secondary bg - x position
(define tile-secondary-bg-y    0.0) ; tile-secondary bg - y position
(define secondary-bg-speed    0.75) ; secondary bg      - movement speed
(define main-bg-speed          0.5) ; main bg           - movement speed

; static sprites - not animated
(define static-bg-sprite          (sprite 0.0 0.0 static-bg-index #:layer 0))
(define static-sprites            (list static-bg-sprite))

; main draw function
(define rendering-states->draw    (stage-draw/dc compiled-db 
                                                 canvas-size-x
                                                 canvas-size-y
                                                 (vector-length layer-config)))

(struct demo ()
  #:methods gen:word
  [

   (define (word-label s ft)
     (format
      "Voxos:    Shield Strength: ~a%    -    SCORE: ~a"
      shield-strength
      player-score))

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; WORD-OUTPUT
   ; draws environment
   (define (word-output w)
     (match-define (demo) w)

     ; uber parallax scrolling backgrounds
     ; main background
     (define main-bg-sprite           ; main bg
       (sprite main-bg-x
               main-bg-y
               main-bg-index
               #:layer 1))
     (define tile-main-bg-sprite      ; main bg - tile sprite
       (sprite tile-main-bg-x
               tile-main-bg-y
               main-bg-index
               #:layer 1))
     ; secondary background
     (define secondary-bg-sprite      ; secondary bg
       (sprite secondary-bg-x
               secondary-bg-y
               secondary-bg-index
               #:layer 2))
     (define tile-secondary-bg-sprite ; secondary bg - tile sprite
       (sprite tile-secondary-bg-x
               tile-secondary-bg-y
               secondary-bg-index
               #:layer 2))

     ; earth sprite
     (define earth-sprite      (sprite 0.0
                                       0.0
                                       earth-index #:layer 3))
     ; player sprite
     (define player-sprite     (sprite (car player-box)
                                       (cadr player-box)
                                       player-index #:layer 3))

     ; game-over sprite
     (define game-over-sprite  (sprite 0.0
                                       0.0
                                       game-over-index #:layer 2))


     ; list of all sprites to be drawn
     (define dynamic-sprites   (list main-bg-sprite
                                     tile-main-bg-sprite
                                     secondary-bg-sprite
                                     tile-secondary-bg-sprite))

     ; draws player if alive
     (cond
       (is-player-alive
         (set! dynamic-sprites (cons player-sprite
                                     dynamic-sprites)))
       (else
        (set! player-box      '(-275.0 500.0 64 32))  ; move player off-screen
        (set! dynamic-sprites  (cons game-over-sprite ; display game-over screen
                                     dynamic-sprites))))

     ; draws earth
     (set! dynamic-sprites (cons earth-sprite
                                 dynamic-sprites))
     
     ; adds new player bullets to dynamic sprites
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-sprites bullet-boxes
                                                     main-weapon-index)))

     ; adds new enemy bullets to dynamic sprites
     (set! dynamic-sprites     (append dynamic-sprites
                                   (make-sprites enemy-bullet-boxes
                                                 enemy-weapon-index)))
     ; adds enemies to dynamic sprites
     (set! dynamic-sprites     (append dynamic-sprites
                                   (make-sprites enemy-boxes
                                                 enemy-index)))

     ; adds explosions to dynamic sprites
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-explosion-sprites
                                        explosion-boxes)))
     ; draws everything
     (rendering-states->draw layer-config
                             static-sprites
                             dynamic-sprites))

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; WORD-EVENT
   ; captures key events
   (define (word-event w e)
     (match-define (demo) w)

     (cond
       ; closes window / stops music
       [(eq? e 'close)
        (stop) ; stops background music track
        #f]

       ; ESC key
       ; respawns and resets player
       [(and (key-event? e) (eq? (send e get-key-code) 'escape))
        (set! is-player-alive    #true)
        (set! player-box         '(-275.0 0.0 64 32))
        (set! bullet-boxes       '())
        (set! enemy-boxes        '())
        (set! enemy-bullet-boxes '())
        (set! explosion-boxes    '())
        (set! player-score         0)
        (set! shield-strength    100)]

       ; W A S D keys - controls player
       ; W / up arrow key - up
       [(and (key-event? e) (eq? (send e get-key-code) #\w))
        (set! is-up-input #true)]     ; W pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\w))
        (set! is-up-input #false)]    ; W released
       [(and (key-event? e) (eq? (send e get-key-code) 'up))
        (set! is-up-input #true)]     ; up pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'up))
        (set! is-up-input #false)]    ; up released

       ; A / left arrow key - left
       [(and (key-event? e) (eq? (send e get-key-code) #\a))
        (set! is-left-input #true)]   ; A pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\a))
        (set! is-left-input #false)]  ; A released
       [(and (key-event? e) (eq? (send e get-key-code) 'left))
        (set! is-left-input #true)]     ; left pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'left))
        (set! is-left-input #false)]    ; left released
       
       ; S / down arrow key - down
       [(and (key-event? e) (eq? (send e get-key-code) #\s))
        (set! is-down-input #true)]   ; S pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\s))
        (set! is-down-input #false)]  ; S released
       [(and (key-event? e) (eq? (send e get-key-code) 'down))
        (set! is-down-input #true)]     ; down pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'down))
        (set! is-down-input #false)]    ; down released

       ; D / right arrow key - right
       [(and (key-event? e) (eq? (send e get-key-code) #\d))
        (set! is-right-input #true)]  ; D pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\d))
        (set! is-right-input #false)] ; D released
       [(and (key-event? e) (eq? (send e get-key-code) 'right))
        (set! is-right-input #true)]     ; right pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'right))
        (set! is-right-input #false)]    ; right released       
       
       ; SPACE / CTRL key - fires main weapon
       [(and (key-event? e) (eq? (send e get-key-code) #\space))
        (if (and (not is-fired-input) is-player-alive)
            (fire-projectile)
            '())
        (set! is-fired-input #true)]   ; SPACE pressed
       
       [(and (key-event? e) (eq? (send e get-key-release-code) #\space))
        (set! is-fired-input #false)]

       [(and (key-event? e) (eq? (send e get-key-code) 'rcontrol))
        (if (and (not is-fired-input) is-player-alive)
            (fire-projectile)
            '())
        (set! is-fired-input #true)]   ; CTRL pressed
       
       [(and (key-event? e) (eq? (send e get-key-release-code) 'rcontrol))
        (set! is-fired-input #false)]) ; CTRL released
     
     (demo))

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; WORD-TICK
   ; tick based frame animation system
   (define (word-tick w)

     ; animates explosions-boxes
     (set! explosion-boxes
           (move-explosion-boxes explosion-boxes))
     
     ; move main background
     (cond
       ((<= main-bg-x -640)
        (set! main-bg-x 640.0))
       ((<= tile-main-bg-x -640)
        (set! tile-main-bg-x 640.0))
       (else
        (set! main-bg-x (- main-bg-x main-bg-speed))
        (set! tile-main-bg-x (- tile-main-bg-x main-bg-speed))))

     ; move secondary background
     (cond
       ((<= secondary-bg-x -640)
        (set! secondary-bg-x 640.0))
       ((<= tile-secondary-bg-x -640)
        (set! tile-secondary-bg-x 640.0))
       (else
        (set! secondary-bg-x (- secondary-bg-x secondary-bg-speed))
        (set! tile-secondary-bg-x (- tile-secondary-bg-x secondary-bg-speed))))

     ; removes ALL off-screen projectiles from list
     (set! bullet-boxes
           (filter (lambda (e) (< (car e) 340))  bullet-boxes))
     (set! enemy-bullet-boxes
           (filter (lambda (e) (> (car e) -340)) enemy-bullet-boxes))
     
     ; moves player bullet-boxes
     (set! bullet-boxes
           (move-boxes bullet-boxes projectile-speed))

     ; moves enemy bullet-boxes
     (set! enemy-bullet-boxes
           (move-boxes enemy-bullet-boxes enemy-projectile-speed))
     
     ; enemy frequency - utilizes a tick counter
     (cond
       ((>= tick-counter enemy-frequency)
        (set! tick-counter 0)
        ; generate enemies
        (set! enemy-boxes (cons (list 340.0
                                      (- (random 448) 224.0)
                                      32
                                      32)
                                enemy-boxes))
        (set! enemy-frequency
              (+ (random (max 1 (- 100 (floor (/ player-score 70))))) 5)))
       (else
        (set! tick-counter (+ tick-counter 1))))

     ; enemy projectile frequency
     (define (make-enemy-bullets enemies)
       (cond
         ((null? enemies)
          '())
         ((< (random 1000) 7)
          (set! enemy-bullet-boxes
                (cons (list (car (car enemies)) (cadr (car enemies)) 8 8)
                      enemy-bullet-boxes))
          (make-enemy-bullets (cdr enemies)))
         (else (make-enemy-bullets (cdr enemies)))))

     ; create enemy bullets based on enemy boxes
     (make-enemy-bullets enemy-boxes)
     
     ; projectile and enemy collision detection
     (enemy-projectile-collision enemy-boxes bullet-boxes)

     ; original enemy count - used in calculating damage to shield
     (define temp-enemy-count (length enemy-boxes))

     ; removes shield-killed enemies
     
     (set! enemy-boxes (shield-kill enemy-boxes))


     (display "\n")
     (display (length enemy-boxes))

     
     ; removes off-screen enemies
     ;(set! enemy-boxes (filter (lambda (e) (> (car e) -340)) enemy-boxes))

     ; updated enemy count - number of enemies that damaged shield
     ;(set! temp-enemy-count (- temp-enemy-count (length enemy-boxes)))

     ; update shield strength when hit by enemies
     ;(set! shield-strength (- shield-strength (* temp-enemy-count 5)))

     ; end game when earth is hit - shield strength is 0
;     (cond
;       ((< shield-strength 0)
;         (set! is-player-alive #false)
;         (set! shield-strength 0)))
     
     ; moves enemy-boxes
     (set! enemy-boxes (move-boxes enemy-boxes enemy-speed))

     ; collision detection between player and enemies / enemy bullets
     (cond
       ((or (box-to-list-collision player-box enemy-boxes)
             (box-to-list-collision player-box enemy-bullet-boxes))
        (set! explosion-boxes (cons (list (car    player-box) ; x
                                          (cadr   player-box) ; y
                                          (caddr  player-box) ; width
                                          (cadddr player-box) ; height
                                          0)                  ; tick
                                    explosion-boxes))
        (play small-explosion)                                ; play sound
        (play player-explosion)                               ; play sound
        (set! is-player-alive #false)))

     ; player model animation
     ; move right
     (if (and is-right-input is-player-alive)
         (begin
           (move-player-right)
           (if (border-collision)
               (move-player-left)
               '()))
         '())
     ; move left
     (if (and is-left-input is-player-alive)
         (begin
           (move-player-left)
           (if (border-collision)
               (move-player-right)
               '()))
         '())
     ; move up
     (if (and is-up-input is-player-alive)
         (begin
           (move-player-up)
           (if (border-collision)
               (move-player-down)
               '()))
         '())
     ; move down
     (if (and is-down-input is-player-alive)
         (begin
           (move-player-down)
           (if (border-collision)
               (move-player-up)
               '()))
         '())
     ; return word
     w)])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FUNCTIONS
; called by word-tick / word-event / word-output

; destroys enemies that hit shield
(define (shield-kill enemies)
  (cond
    ((null? enemies) '())
    ((and (> shield-strength 0) (< (car (car enemies)) -200))
     (set! explosion-boxes
           (cons (list (car    (car enemies))               ; x
                       (cadr   (car enemies))               ; y
                       (caddr  (car enemies))               ; width
                       (cadddr (car enemies))               ; height
                       1)                                   ; set tick
                 explosion-boxes))
     (play shield-enemy-kill)                               ; play sound
     (set! shield-strength (- shield-strength 5))           ; update shield
     (set! enemy-boxes  (remove (car enemies) enemies))     ; remove enemy
     (shield-kill (cdr enemies)))
     ((and (< shield-strength 0) (> (car (car enemies)) -340)) ; remove enemies
      (remove (car enemies) enemies)
      (set! is-player-alive #false)
      (set! shield-strength 0))
     (else
      (cons (car enemies)
            (shield-kill (cdr enemies))))))

; animates explosions by modifying tick parameter
(define (move-explosion-boxes explosions)
  (cond
    ((null? explosions)
     '())
    ((<= (cadddr (cdr (car explosions))) 15)            ; tick threshold
     (cons (list (car    (car explosions))              ; x
                 (cadr   (car explosions))              ; y
                 (caddr  (car explosions))              ; width
                 (cadddr (car explosions))              ; height
                 (+ (cadddr (cdr (car explosions))) 1)) ; update tick
           (move-explosion-boxes (cdr explosions))))
    (else
     (set! explosion-boxes (remove (car explosion-boxes) explosion-boxes))
     (move-explosion-boxes (cdr explosions)))))

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

; creates a list of animated explosion sprites
(define (make-explosion-sprites boxes)
  (cond
    ((null? boxes) '())
    (else          
     (cons (sprite (car (car boxes))
                   (cadr (car boxes))
                   ; determine which sprite to use based on the tick
                   ; parameter stored in the sub-list
                   (cond
                     ((<= (cadddr (cdr (car boxes))) 5)
                      explosion-1-index)     ; explosion frame 1
                     ((<= (cadddr (cdr (car boxes))) 10)
                      explosion-2-index)     ; explosion frame 2
                     (else
                      explosion-3-index))    ; explosion frame 3
                   ; end sprite index selection
                   #:a alpha
                   #:layer 3)
           (make-explosion-sprites (cdr boxes))))))

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
                           bullet-boxes))
  (play main-weapon)) ; play main-weapon sound

; player movement
; move right
(define (move-player-right)
  (set! player-box (cons (+ (car player-box) player-speed) (cdr player-box))))
; move left
(define (move-player-left)
  (set! player-box (cons (- (car player-box) player-speed) (cdr player-box))))
; move up
(define (move-player-up)
  (set! player-box (cons (car player-box)
                         (cons (- (cadr player-box) player-speed)
                               (cddr player-box)))))
; move down
(define (move-player-down)
  (set! player-box (cons (car player-box)
                         (cons (+ (cadr player-box) player-speed)
                               (cddr player-box)))))

; collision detection using border-boxes (screen edges)
(define (border-collision)
  (box-to-list-collision player-box border-boxes))

; detect collision between a single item against multiple items
(define (box-to-list-collision box boxes)
  (cond
    ((null? boxes) #false)
    ((box-to-box-collision box (car boxes)) #true)
    (else (box-to-list-collision box (cdr boxes)))))

; detect collision between two single items
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

; detect enemy collision against projectiles
(define (enemy-projectile-collision enemies projectiles)
  (cond
    ((null? enemies)
     '())
    (else (enemy-projectile-removal (car enemies) projectiles)
          (enemy-projectile-collision (cdr enemies) projectiles))))

; removes collided enemies / projectiles
(define (enemy-projectile-removal enemy projectiles)
  (cond
    ((null? projectiles)
     '())
    ((not (box-to-box-collision enemy (car projectiles)))
     (enemy-projectile-removal enemy (cdr projectiles)))
    (else
     ; collision detected between enemy and projectile
     ; remove bullet/enemy from list
     ; add explosion animation
     (set! explosion-boxes (cons (list (car    enemy) ; x
                                       (cadr   enemy) ; y
                                       (caddr  enemy) ; width
                                       (cadddr enemy) ; height
                                       0)             ; tick
                                 explosion-boxes))
     (play enemy-explosion)                                      ; play sound
     (set! player-score (+ player-score 100))                    ; update score
     (set! enemy-boxes  (remove enemy enemy-boxes))              ; remove enemy
     (set! bullet-boxes (remove (car projectiles) bullet-boxes)) ; remove bullet
     (enemy-projectile-removal enemy (cdr projectiles)))))

; background music looping function
(define (play-rsound-loop audio #:init-volume [init-volume 0.3])
  (define myStream (make-pstream #:buffer-time 0.2)) ; create pstream

  (pstream-set-volume! myStream init-volume)         ; set pstream volume
  
  (define totalFrames (rs-frames audio))             ; gets frame length

  (define (audioLoop)                                ; loops pstream function
    (pstream-play myStream audio)                    ; adds file to pstream

    ; callback function
    ; this calls itself once the audio file ends by using the frame length
    (pstream-queue-callback myStream
                            audioLoop
                            (+ (pstream-current-frame myStream) totalFrames)))

  (thread audioLoop))                                ; puts function into thread

; main
(module+ main
  (play-rsound-loop power-core #:init-volume .3)     ; play background track
  (call-with-chaos
   (make-gui #:mode 'gl-core
             #:width canvas-size-x
             #:height canvas-size-y)
   (λ () (fiat-lux (demo)))))
