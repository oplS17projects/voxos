# Voxos - 2d side-scrolling shooter game

## William Bobos
### April 30, 2017

# Overview

Voxos is a 2D side scrolling game developed in Racket. It uses the Lux, Mode-Lambda, and Rsound libraries.

It was a fun way to explore a real world project using Racket.

The code uses a number of techniques learned from class.
The techniques used include: recursion, filter, and some state modification.

**Authorship note:** ALL of the code, artwork, and sound effects described here was written by myself.


![Voxos:](https://raw.githubusercontent.com/oplS17projects/voxos/master/voxos-screen-1.png)


# Libraries Used
The code uses three libraries:

```
(require rsound)
(require mode-lambda)
(require lux)
```

* The ```lux``` library provides the ability to create interactive programs

* The ```mode-lambda``` library is used to create high performance 2D graphics

* The ```rsound``` library is used to read, write, and play sounds

![Voxos:](https://raw.githubusercontent.com/oplS17projects/voxos/master/voxos-screen-2.png)

# Key Code Excerpts

Here are some core code samples that exemplify the techniques learned in class.

The examples are shown below, and they are individually numbered.

## 1. Initialization - using a Global Object

The following code creates a global object, ```compiled-db```
that is heavily used to draw sprites to the screen:


```

; compile sprite database
(define compiled-db
  (compile-sprite-db sprite-db))

; saves compiled database - outputs sprite atlas
(save-csd! compiled-db
  "voxos-sprite-db" #:debug? #t)

; loads compiled database
(define compiled-db
  (load-csd "voxos-sprite-db"))

```

Sprites are drawn to the screen using Mode-Lambda calls. The sprites are
referenced using an index from the ```compiled-db```:

Here are some sprite indexes:

```

; misc
(define player-index              (sprite-idx compiled-db 'player        ))
(define earth-index               (sprite-idx compiled-db 'earth         ))
(define dead-earth-index          (sprite-idx compiled-db 'dead-earth    ))
(define shield-index              (sprite-idx compiled-db 'shield        ))
; enemies
(define basic-index               (sprite-idx compiled-db 'basic         ))
(define droid-index               (sprite-idx compiled-db 'droid         ))
(define bomber-index              (sprite-idx compiled-db 'bomber        ))
(define fighter-index             (sprite-idx compiled-db 'fighter       ))
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
(define shield-power-up-index   (sprite-idx compiled-db 'shield-power-up ))

```

## 2. Filter - removal of off-screen elements

There are elements that needed removal once they moved off-screen:

* Player projectiles
* Enemy projectiles
* Enemies
* Power-ups

There are three main calls utilizing ```filter``` that accomplish these tasks.

```

; removes off-screen player-bullets, enemy-bullets, powerups

; removes player projectiles
(set! bullet-boxes
  (filter (lambda (e) (< (car e) 340))  bullet-boxes))

; removes enemy projectiles
(set! enemy-bullet-boxes
  (filter (lambda (e) (> (car e) -340)) enemy-bullet-boxes))


; removes power-ups
(set! power-up-boxes
  (filter (lambda (e) (> (car e) -340)) power-up-boxes))

```

The lambda procedure examines the x-axis location of each element.


## 3. State Modification - utilized in the Lux Word object

During each tick of abstract time, a ```word``` object is returned.

The ```word-tick``` occurs during every tick of time, and returns a ```word```
object during every tick.

State modification using ```set!``` to accomplish many tasks as the game runs.

* animating player projectiles:

```

; moves player projectiles
(set! bullet-boxes
  (move-boxes
    bullet-boxes projectile-speed))

```

* animating explosions:

```

; animates explosions
(set! explosion-boxes
  (move-explosion-boxes
    explosion-boxes))

```

* animating enemy projectiles:

```

; moves enemy projectiles
(set! enemy-bullet-boxes
  (move-boxes
    enemy-bullet-boxes enemy-bullet-speed))

```


## 4. Recursion - accomplishes nearly all major tasks

Recursion is the most heavily used technique in Voxos. Recursion is
used to draw sprites, detect collision detection, create animation,
and much more.

Here are three major examples of recursion:

* Sprite Drawing

The sprite creation function ```make-sprites```
handles the majority of sprite drawing:

```

; sprite creation
(define (make-sprites boxes)
  (cond
    ((null? boxes) '())
    (else
     (cons (sprite (car    (car boxes))       ; x location
                   (cadr   (car boxes))       ; y location
                   (cadddr (cdr (car boxes))) ; sprite-name
                   #:layer 3)
           (make-sprites (cdr boxes))))))

```

```make-sprites``` uses recursion to process the list of sprites to be drawn.

* Collision Detection

The function ```box-to-list-collision``` handles collision detection:

```

(define (box-to-list-collision box boxes)
  (cond
    ((null? boxes) #false)
    ((box-to-box-collision box (car boxes)) #true)
    (else (box-to-list-collision box (cdr boxes)))))

```

```box-to-list-collision``` uses recursion for collision detection between
a single element against a list of multiple elements. An example may
be detecting collision between the player and multiple projectiles.

* Firing Projectiles

The function ```enemy-projectile-removal``` handles destroyed enemies:

```

; removes killed enemy / projectiles
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

```

```enemy-projectile-removal``` uses recursion to remove a
destroyed enemy, the associated projectile, updates the score, and queues an
explosion animation.


![Voxos:](https://raw.githubusercontent.com/oplS17projects/voxos/master/voxos-screen-3.png)


# Responsibilities

## William Bobos @wbobos

- EVERYTHING
- all environment interaction
- all player movement
- all player interaction
- all collision detection
- all artwork - backgrounds, player, enemies, effects
- all sound effects - sound effects, sound processing
- all music - music, music processing, streaming objects


![Voxos:](https://raw.githubusercontent.com/oplS17projects/voxos/master/voxos-screen-4.png)

