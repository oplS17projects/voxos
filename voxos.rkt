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

; music
(define power-core                (rs-read "./sound/power-core.wav"       ))
; weapons
(define main-weapon               (rs-read "./sound/main-weapon.wav"      ))
(define missile-weapon            (rs-read "./sound/missile-weapon.wav"   ))
(define wave-weapon               (rs-read "./sound/wave-weapon.wav"      ))
(define beam-weapon               (rs-read "./sound/beam-weapon.wav"      ))
; power-ups
(define main-power-up             (rs-read "./sound/main-power-up.wav"    ))
(define missile-power-up          (rs-read "./sound/missile-power-up.wav" ))
(define wave-power-up             (rs-read "./sound/wave-power-up.wav"    ))
(define beam-power-up             (rs-read "./sound/beam-power-up.wav"    ))
(define shield-power-up           (rs-read "./sound/shield-power-up.wav"  ))
; shield kill
(define shield-enemy-kill         (rs-read "./sound/shield-enemy-kill.wav"))
; explosions
(define player-explosion          (rs-read "./sound/player-explosion.wav" ))
(define enemy-explosion           (rs-read "./sound/enemy-explosion.wav"  ))
(define small-explosion           (rs-read "./sound/small-explosion.wav"  ))
(define medium-explosion          (rs-read "./sound/medium-explosion.wav" ))

; resolution
(define canvas-size-x          640)
(define canvas-size-y          480)

; create sprite database
(define sprite-db (make-sprite-db))

; add sprites to database
(add-sprite!/file sprite-db  'player           "./sprites/player.png"          )
(add-sprite!/file sprite-db  'earth            "./sprites/earth.png"           )
(add-sprite!/file sprite-db  'shield           "./sprites/shield.png"          )
; enemies
(add-sprite!/file sprite-db  'basic            "./sprites/basic.png"           )
(add-sprite!/file sprite-db  'droid            "./sprites/droid.png"           )
(add-sprite!/file sprite-db  'fighter          "./sprites/fighter.png"         )
(add-sprite!/file sprite-db  'bomber           "./sprites/bomber.png"          )
; backgrounds
(add-sprite!/file sprite-db  'static-bg        "./sprites/static-bg.png"       )
(add-sprite!/file sprite-db  'main-bg          "./sprites/main-bg.png"         )
(add-sprite!/file sprite-db  'secondary-bg     "./sprites/secondary-bg.png"    )
; weapons
(add-sprite!/file sprite-db  'main-weapon      "./sprites/main-weapon.png"     )
(add-sprite!/file sprite-db  'missile-weapon   "./sprites/missile-weapon.png"  )
(add-sprite!/file sprite-db  'wave-weapon      "./sprites/wave-weapon.png"     )
(add-sprite!/file sprite-db  'beam-weapon      "./sprites/beam-weapon.png"     )
(add-sprite!/file sprite-db  'enemy-weapon     "./sprites/enemy-weapon.png"    )
; game-over screen
(add-sprite!/file sprite-db  'game-over        "./sprites/game-over.png"       )
; explosion frames
(add-sprite!/file sprite-db  'explosion-1      "./sprites/explosion-1.png"     )
(add-sprite!/file sprite-db  'explosion-2      "./sprites/explosion-2.png"     )
(add-sprite!/file sprite-db  'explosion-3      "./sprites/explosion-3.png"     )
; power-ups
(add-sprite!/file sprite-db  'main-power-up    "./sprites/main-power-up.png"   )
(add-sprite!/file sprite-db  'wave-power-up    "./sprites/wave-power-up.png"   )
(add-sprite!/file sprite-db  'beam-power-up    "./sprites/beam-power-up.png"   )
(add-sprite!/file sprite-db  'shield-power-up  "./sprites/shield-power-up.png" )
(add-sprite!/file sprite-db  'missile-power-up "./sprites/missile-power-up.png")

; compile sprite database
(define compiled-db               (compile-sprite-db sprite-db))
;(save-csd! compiled-db           "voxos-sprite-db" #:debug? #t)
;(define compiled-db              (load-csd "voxos-sprite-db"))

; sprite index
(define player-index              (sprite-idx compiled-db 'player        ))
(define earth-index               (sprite-idx compiled-db 'earth         ))
(define shield-index              (sprite-idx compiled-db 'shield        ))
; enemies
(define basic-index               (sprite-idx compiled-db 'basic         ))
(define droid-index               (sprite-idx compiled-db 'droid         ))
(define elite-index               (sprite-idx compiled-db 'elite         ))
(define fighter-index             (sprite-idx compiled-db 'fighter       ))
; backgrounds
(define static-bg-index           (sprite-idx compiled-db 'static-bg     ))
(define main-bg-index             (sprite-idx compiled-db 'main-bg       ))
(define secondary-bg-index        (sprite-idx compiled-db 'secondary-bg  ))
; weapons
(define main-index                (sprite-idx compiled-db 'main-weapon   ))
(define missile-index             (sprite-idx compiled-db 'missile-weapon))
(define wave-index                (sprite-idx compiled-db 'wave-weapon   ))
(define beam-index                (sprite-idx compiled-db 'beam-weapon   ))
(define enemy-index               (sprite-idx compiled-db 'enemy-weapon  ))
; power-ups
(define main-power-up-index     (sprite-idx compiled-db 'main-power-up   ))
(define missile-power-up-index  (sprite-idx compiled-db 'missile-power-up))
(define wave-power-up-index     (sprite-idx compiled-db 'wave-power-up   ))
(define beam-power-up-index     (sprite-idx compiled-db 'beam-power-up   ))
; game over
(define game-over-index           (sprite-idx compiled-db 'game-over     ))
; explosion frames
(define explosion-1-index         (sprite-idx compiled-db 'explosion-1   ))
(define explosion-2-index         (sprite-idx compiled-db 'explosion-2   ))
(define explosion-3-index         (sprite-idx compiled-db 'explosion-3   ))

; layers - sprites are placed onto layers
(define static-bg-layer           ; static   bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))
(define main-bg-layer             ; parallax bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))
(define secondary-bg-layer        ; parallax bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))
(define action-layer              ; action   bg layer
       (layer (* 1.0 canvas-size-x)
            (* 1.0 canvas-size-y)))

; layer configuration
(define layer-config
  (vector static-bg-layer main-bg-layer secondary-bg-layer action-layer))

; state variables
(define is-player-alive      #true) ; player       state
(define is-main-weapon       #true) ; main         weapon
(define is-missile-weapon   #false) ; missile      weapon
(define is-wave-weapon      #false) ; wave         weapon
(define is-beam-weapon      #false) ; beam         weapon
(define shield-alpha           1.0) ; alpha        amount
(define random-enemy         'main) ; enemy        choice
(define tick-counter             0) ; tick         counter
(define shield-cap             125) ; max          shield
(define enemy-frequency         15) ; enemy        frequency
(define player-speed             3) ; player       speed
(define projectile-speed        10) ; bullet       speed
(define power-up-speed          -7) ; power-up     speed
(define enemy-bullet-speed      -5) ; enemy bullet speed
(define enemy-speed             -2) ; enemy        speed
(define shield-strength        100) ; shield       strength
(define player-score             0) ; player       score
(define shield-location       -300) ; shield       x-position

; screen edge collision boxes
(define border-boxes
                   '((330 0 20 480) ; right  screen edge hit box
                    (-330 0 20 480) ; left   screen edge hit box
                     (0 250 640 20) ; top    screen edge hit box
                  (0 -250 640 20))) ; bottom screen edge hit box
; misc hit boxes
(define player-box
               '(-250.0 0.0 64 32)) ; starting     position
(define bullet-boxes           '()) ; bullet       hit-boxes
(define enemy-bullet-boxes     '()) ; enemy bullet hit-boxes
(define enemy-boxes            '()) ; enemy        hit-boxes
(define explosion-boxes        '()) ; explosion    hit-boxes
(define power-up-boxes         '()) ; power-up     hit-boxes
(define power-up-list               ; power-up     list
  (list 'main
        'missile
        'wave
        'beam))
(define enemy-list                  ; enemy        list
  (list ''basic-index
        ''droid-index
        ''elite-index
        ''fighter-index))
(define number-list
  (list -5 -4 -3 -2 -1 0
        1  2  3  4  5))             ; number       list

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
      "Voxos:    SHIELD STRENGTH:  ~a%    -    SCORE: ~a"
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
     (define tile-main-bg-sprite      ; main bg      - tile sprite
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
     ; shield sprite
     (define shield-sprite      (sprite 0.0
                                        0.0
                                        #:a shield-alpha
                                        shield-index #:layer 3))
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
     (set! dynamic-sprites     (cons earth-sprite
                                      dynamic-sprites))
     ; draws shield
     (set! dynamic-sprites     (cons shield-sprite
                                      dynamic-sprites))
     ; draws power-ups
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-sprites power-up-boxes)))
     ; draws player bullets
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-sprites bullet-boxes)))
     ; draws enemy bullets
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-sprites enemy-bullet-boxes)))
     ; draws enemies
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-sprites enemy-boxes)))
     ; draws explosions
     (set! dynamic-sprites     (append dynamic-sprites
                                       (make-explosion-sprites
                                        explosion-boxes)))
     ; draws everything
     (rendering-states->draw layer-config
                             static-sprites
                             dynamic-sprites))
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ; WORD-EVENT
   ; captures key events
   (define (word-event w e)
     (match-define (demo) w)
     ; closes window / stops music
     (cond
       [(eq? e 'close)
        (stop) ; stops music
        #f]

       ; ESC key
       ; respawns and resets player / environment
       [(and (key-event? e) (eq? (send e get-key-code) 'escape))
        (set! is-player-alive    #true)
        (set! player-box         '(-250.0 0.0 64 32))
        (set! bullet-boxes       '())
        (set! enemy-boxes        '())
        (set! enemy-bullet-boxes '())
        (set! explosion-boxes    '())
        (set! power-up-boxes     '())
        (set! player-score         0)
        (set! shield-strength    100)]

       ; W A S D keys - controls player
       ; W / UP arrow key - up
       [(and (key-event? e) (eq? (send e get-key-code) #\w))
        (set! is-up-input #true)]     ; W pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\w))
        (set! is-up-input #false)]    ; W released
       [(and (key-event? e) (eq? (send e get-key-code) 'up))
        (set! is-up-input #true)]     ; UP pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'up))
        (set! is-up-input #false)]    ; UP released
       ; A / LEFT arrow key - left
       [(and (key-event? e) (eq? (send e get-key-code) #\a))
        (set! is-left-input #true)]   ; A pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\a))
        (set! is-left-input #false)]  ; A released
       [(and (key-event? e) (eq? (send e get-key-code) 'left))
        (set! is-left-input #true)]   ; LEFT pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'left))
        (set! is-left-input #false)]  ; LEFT released
       ; S / DOWN arrow key - down
       [(and (key-event? e) (eq? (send e get-key-code) #\s))
        (set! is-down-input #true)]   ; S pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\s))
        (set! is-down-input #false)]  ; S released
       [(and (key-event? e) (eq? (send e get-key-code) 'down))
        (set! is-down-input #true)]   ; DOWN pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'down))
        (set! is-down-input #false)]  ; DOWN released
       ; D / RIGHT arrow key - right
       [(and (key-event? e) (eq? (send e get-key-code) #\d))
        (set! is-right-input #true)]  ; D pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) #\d))
        (set! is-right-input #false)] ; D released
       [(and (key-event? e) (eq? (send e get-key-code) 'right))
        (set! is-right-input #true)]  ; RIGHT pressed
       [(and (key-event? e) (eq? (send e get-key-release-code) 'right))
        (set! is-right-input #false)] ; RIGHT released       
       ; SPACE - fires weapon
       [(and (key-event? e) (eq? (send e get-key-code) #\space))
        ; SPACE pressed        
        (cond
          ; main weapon
          ((and (not is-fired-input) is-main-weapon is-player-alive)
           (fire-projectile main-index 8 8)
           (play main-weapon))        ; play sound
          ; wave weapon
          ((and (not is-fired-input) is-wave-weapon is-player-alive)
           (fire-projectile wave-index 8 16)
           (play wave-weapon))        ; play sound
          ; missile weapon
          ((and (not is-fired-input) is-missile-weapon is-player-alive)
           (fire-projectile missile-index 16 8)
           (play missile-weapon))     ; play sound
          ; beam weapon
          ((and (not is-fired-input) is-beam-weapon is-player-alive)
           (fire-projectile beam-index 640 8)
           (play beam-weapon)))       ; play sound
        (set! is-fired-input #true)]
       ; SPACE released
       [(and (key-event? e) (eq? (send e get-key-release-code) #\space))
        (set! is-fired-input #false)]
       ; CTRL key - fires weapon
       [(and (key-event? e) (eq? (send e get-key-code) 'rcontrol))
        ; CTRL pressed        
        (cond
          ; main weapon
          ((and (not is-fired-input) is-main-weapon is-player-alive)
           (fire-projectile main-index 8 8)
           (play main-weapon))        ; play sound
          ; wave weapon
          ((and (not is-fired-input) is-wave-weapon is-player-alive)
           (fire-projectile wave-index 8 16)
           (play wave-weapon))        ; play sound
          ; missile weapon
          ((and (not is-fired-input) is-missile-weapon is-player-alive)
           (fire-projectile missile-index 16 8)
           (play missile-weapon))     ; play sound
          ; beam weapon
          ((and (not is-fired-input) is-beam-weapon is-player-alive)
           (fire-projectile beam-index 640 8)
           (play beam-weapon)))       ; play sound
        (set! is-fired-input #true)]
       ; CTRL released
       [(and (key-event? e) (eq? (send e get-key-release-code) 'rcontrol))
        (set! is-fired-input #false)])
     
     (demo))
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

     ; removes off-screen bullets - player / enemy
     (set! bullet-boxes
           (filter (lambda (e) (< (car e) 340))  bullet-boxes))
     (set! enemy-bullet-boxes
           (filter (lambda (e) (> (car e) -340)) enemy-bullet-boxes))
     
     ; moves bullet-boxes - player / enemy
     (set! bullet-boxes
           (move-boxes bullet-boxes projectile-speed))
     (set! enemy-bullet-boxes
           (move-boxes enemy-bullet-boxes enemy-bullet-speed))
     
     ; enemy frequency - utilizes a tick counter
     (cond
       ((>= tick-counter enemy-frequency)
        (set! tick-counter 0)

        ; randomly selects an enemy from a list of enemies
        (set! random-enemy
              (list-ref enemy-list (random (length enemy-list))))

        (display " random enemy is ")
        (display random-enemy)
        
        ; generate enemies
        (set! enemy-boxes (cons (list 340.0                  ; x location
                                      (- (random 448) 224.0) ; y location
                                      44                     ; hit-box width
                                      44                     ; hit-box height
                                      'basic-index)          ; enemy sprite
                                enemy-boxes))

        ; difficulty setting - enemy spawn frequency
        (set! enemy-frequency
              (+ (random (max 1 (- 100 (floor (/ player-score 70))))) 5)))
       (else
        (set! tick-counter (+ tick-counter 1))))


     ; create random power-ups
     (make-power-up-boxes)

     ; moves power-up-boxes
     (set! power-up-boxes (move-boxes power-up-boxes power-up-speed))

     ; create enemy bullets based on enemy boxes
     (make-enemy-bullets enemy-boxes)
     
     ; projectile and enemy collision detection
     (enemy-projectile-collision enemy-boxes bullet-boxes)

     ; original enemy count - used in calculating damage to shield
     (define temp-enemy-count (length enemy-boxes))

     ; handles shield / shield-killed enemies
     (set! enemy-boxes (shield-kill enemy-boxes))

     ; moves enemy-boxes
     (set! enemy-boxes (move-boxes enemy-boxes enemy-speed))

     ;(detect-player-enemies-bullets-collision)
     ; collision detection between player and enemies / enemy bullets
     (cond
       ((or (box-to-list-collision player-box enemy-boxes)
             (box-to-list-collision player-box enemy-bullet-boxes))
        (set! explosion-boxes (cons (list (car    player-box) ; x
                                          (cadr   player-box) ; y
                                          (caddr  player-box) ; hit-box width
                                          (cadddr player-box) ; hit-box height
                                          0)                  ; tick
                                    explosion-boxes))
        (play small-explosion)                                ; play sound
        (play player-explosion)                               ; play sound
        (set! is-player-alive #false)))

     ;(detect-player-power-up-collision)
     ; collision detection between player and power-ups
     (cond
       ; shield power-up
       ((and
         (equal? (player-power-ups-collision player-box power-up-boxes)
                 'shield-power-up-index)
         (< shield-strength shield-cap))
        (set! shield-strength (+ shield-strength 5))
        (play shield-power-up))
       ; main weapon power-up
       ((and
         (equal? (player-power-ups-collision player-box power-up-boxes)
                 'main-power-up-index))
        (set! is-main-weapon    #true)
        (set! is-missile-weapon #false)
        (set! is-wave-weapon    #false)
        (set! is-beam-weapon    #false)
        (play main-power-up))
       ; missile weapon power-up
       ((and
         (equal? (player-power-ups-collision player-box power-up-boxes)
                 'missile-power-up-index))
        (set! is-missile-weapon #true)
        (set! is-main-weapon    #false)
        (set! is-wave-weapon    #false)
        (set! is-beam-weapon    #false)
        (play missile-power-up))
       ; wave weapon power-up
       ((and
         (equal? (player-power-ups-collision player-box power-up-boxes)
                 'wave-power-up-index))
        (set! is-wave-weapon    #true)
        (set! is-main-weapon    #false)
        (set! is-missile-weapon #false)
        (set! is-beam-weapon    #false)
        (play wave-power-up))
       ; beam weapon power-up
       ((and
         (equal? (player-power-ups-collision player-box power-up-boxes)
                 'beam-power-up-index))
        (set! is-beam-weapon    #true)
        (set! is-main-weapon    #false)
        (set! is-missile-weapon #false)
        (set! is-wave-weapon    #false)
        (play beam-power-up)))

        ; set shield transparency depending on shield strength
        (cond
          ((< shield-strength 100)
           (set! shield-alpha (/ shield-alpha .01))))

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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; FUNCTIONS
; called by word-tick / word-event / word-output

; power-up creation
(define (make-power-up-boxes)
  (cond
    ((< (random 1000) 3)
     (set! power-up-boxes
           (cons (list 340.0                    ; x location
                       (- (random 448) 224.0)   ; y location
                       1                       ; hit-box width
                       44                       ; hit-box height
                       ''beam-power-up-index)    ; sprite name
                 power-up-boxes))
     (make-power-up-boxes))
    ; wave weapon
    ((< (random 1000) 5)
     (set! power-up-boxes
           (cons (list 340.0                    ; x location
                       (- (random 448) 224.0)   ; y location
                       2                       ; hit-box width
                       32                       ; hit-box height
                       ''wave-power-up-index)    ; sprite name
                 power-up-boxes))
     (make-power-up-boxes))
    ; missile weapon
    ((< (random 1000) 7)
     (set! power-up-boxes
           (cons (list 340.0                    ; x location
                       (- (random 448) 224.0)   ; y location
                       3                       ; hit-box width
                       32                       ; hit-box height
                       ''missile-power-up-index) ; sprite name
                 power-up-boxes))
     (make-power-up-boxes))
    ; main weapon
    ((< (random 1000) 10)
     (set! power-up-boxes
           (cons (list 340.0                    ; x location
                       (- (random 448) 224.0)   ; y location
                       4                       ; hit-box width
                       32                       ; hit-box height
                       ''main-power-up-index)    ; sprite name
                 power-up-boxes))
     (make-power-up-boxes))))

; sprite creation
(define (make-sprites boxes)
  (cond
    ((null? boxes) '())
    (else          
     (cons (sprite (car    (car boxes))       ; x location
                   (cadr   (car boxes))       ; y location
                   ;(cadddr (cdr (car boxes))) ; sprite-name
                   (list-ref (car boxes) 4))  ; sprite name
                   #:layer 3)
           (make-sprites (cdr boxes)))))

; enemy bullet creation
(define (make-enemy-bullets enemies)
  (cond
    ((null? enemies)
     '())
    ((< (random 1000) 7)
     (set! enemy-bullet-boxes
           (cons (list (car    (car enemies))        ; x location
                       (cadr   (car enemies))        ; y location
                       (caddr  (car enemies))        ; hit-box width
                       (cadddr (car enemies))        ; hit-box height
                       (cadddr (cdr (car enemies)))) ; sprite name
                 enemy-bullet-boxes))
     (make-enemy-bullets (cdr enemies)))
    (else (make-enemy-bullets (cdr enemies)))))

; handles shield / destroys enemies that hit shield
(define (shield-kill enemies)
  (cond
    ((null? enemies) '())
    ((and (> shield-strength 0) (< (car (car enemies)) -200))
     (set! explosion-boxes
           (cons (list (car    (car enemies))                    ; x
                       (cadr   (car enemies))                    ; y
                       (caddr  (car enemies))                    ; width
                       (cadddr (car enemies))                    ; height
                       1)                                        ; set tick
                 explosion-boxes))
     (play shield-enemy-kill)                                    ; play sound
     (set! shield-strength (- shield-strength 5))                ; update shield
     (set! enemy-boxes  (remove (car enemies) enemies))          ; remove enemy
     (shield-kill (cdr enemies)))
     ((and (<= shield-strength 0) (<= (car (car enemies)) -350)) ; cull enemies
      (remove (car enemies) enemies)
      (set! is-player-alive #false)
      (set! shield-strength 0)
      (shield-kill (cdr enemies)))
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
    ; animates y-axis of power-ups
    ((or (equal? (list-ref (car boxes) 4) 'shield-power-up)
         (equal? (list-ref (car boxes) 4) 'main-power-up)
         (equal? (list-ref (car boxes) 4) 'missile-power-up)
         (equal? (list-ref (car boxes) 4) 'wave-power-up)
         (equal? (list-ref (car boxes) 4) 'beam-power-up))
     (cons (list (+ (car (car boxes)) speed)                    ; x
                 (+ (cadr   (car boxes)) (random-element list)) ; random y
                 (caddr  (car boxes))                           ; width
                 (cadddr (car boxes)))                          ; height
           (move-boxes (cdr boxes) speed)))
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
                   #:layer 3)
           (make-explosion-sprites (cdr boxes))))))

; adds projectiles to bullet-boxes list
(define (fire-projectile bullet-type hit-box-x hit-box-y)
  (set! bullet-boxes (cons (list (+ (car player-box) 25) ; x position
                                 (cadr player-box)       ; y position
                                 hit-box-x               ; hit-box width
                                 hit-box-y               ; hit-box height
                                 bullet-type)            ; bullet type
                           bullet-boxes)))

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

; detect collision - (screen edges)
(define (border-collision)
  (box-to-list-collision player-box border-boxes))

; detect collision - player against power-ups
(define (player-power-ups-collision player power-ups)
  (cond
    ((null? power-ups) #false)
    ((box-to-box-collision player (car power-ups))
     (list-ref (car power-ups) 4)) ; collision - returns name of power-up
    (else (player-power-ups-collision player (cdr power-ups)))))

; detect collision - a single item against multiple items
(define (box-to-list-collision box boxes)
  (cond
    ((null? boxes) #false)
    ((box-to-box-collision box (car boxes)) #true)
    (else (box-to-list-collision box (cdr boxes)))))

; detect collision - two single items
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

; detect collision - enemy against projectiles
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

; loops audio - background music
(define (play-rsound-loop audio #:init-volume [init-volume 0.3])
  (define myStream (make-pstream #:buffer-time 0.2)) ; create pstream
  (pstream-set-volume! myStream init-volume)         ; set pstream volume
  (define totalFrames (rs-frames audio))             ; gets frame length
  (define (audioLoop)                                ; loops pstream function
    (pstream-play myStream audio)                    ; adds file to pstream
    ; callback function - calls itself when audio file ends using frame length
    (pstream-queue-callback myStream
                            audioLoop
                            (+ (pstream-current-frame myStream) totalFrames)))
  (thread audioLoop))                                ; puts function into thread

; allows random selection
(define (random-element list)
  (list-ref list (random (length list))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MAIN
; main program
(module+ main
  (play-rsound-loop power-core #:init-volume .3)     ; play background track
  (call-with-chaos
   (make-gui #:mode 'gl-core
             #:width canvas-size-x
             #:height canvas-size-y)
   (λ () (fiat-lux (demo)))))
