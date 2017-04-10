#lang racket
(require mode-lambda
         mode-lambda/static)


;;;  Resolution  ;;;

; The game resolution variables

(define width  640.0)
(define height 480.0)


;;;  Layers  ;;;

; These are the various layers that create the environment
; This is temporary, and additional layers may be needed

(define primary-bg-layer   (layer width height))    ; layer 0
(define secondary-bg-layer (layer width height))    ; layer 1
(define foreground-layer   (layer width height))    ; layer 2
(define layer-ordering     (vector primary-bg-layer ; layer order
                                   secondary-bg-layer
                                   foreground-layer))


;;;  Sprite Database  ;;;

; This creates the database that stores game sprites

(define sprite-database (make-sprite-db))


;;;  Bitmaps  ;;;

; These are the images used to create the sprites

;;  Player
(define player-image-path       "player.png")

;; Primary Background
(define primary-bg-image-path   "primary-bg.png")

;; Secondary Background
(define secondary-bg-image-path "secondary-bg.png")

;; Additional Backgrounds

;; Projectiles

;; Power Ups

;; Enemies

;; Level Boss


;;; Sprite Database  ;;;

; These add sprites to the sprite database

(add-sprite!/file sprite-database 'player       player-image-path)
(add-sprite!/file sprite-database 'primary-bg   primary-bg-image-path)
(add-sprite!/file sprite-database 'secondary-bg secondary-bg-image-path)


;;;  Compile Sprite Database

; This compiles the sprite database

(define compiled-sprite-database (compile-sprite-db sprite-database))


;;;  Sprite Index  ;;;

; These variables contain each sprite's associated index in the sprite database

;; Player
(define player-index       (sprite-idx compiled-sprite-database 'player))

;; Primary Background
(define primary-bg-index   (sprite-idx compiled-sprite-database 'primary-bg))

;; Additional Backgrounds
(define secondary-bg-index (sprite-idx compiled-sprite-database 'secondary-bg))

;; Projectiles

;; Power Ups

;; Enemies

;; Level Boss


;;;  Sprite Creation ;;;

; Creates an instance of a sprite from the sprite database on a layer

(define player-sprite       (sprite 0.0 0.0  player-index       #:layer 0))
(define primary-bg-sprite   (sprite 0.0 0.0 primary-bg-index    #:layer 1))
(define secondary-bg-sprite (sprite 0.0 0.0  secondary-bg-index #:layer 2))


;;;  Dynamic Sprite List  ;;;

; Creates list of dynamic sprites

(define dynamic-sprites (list player-sprite
                              primary-bg-sprite
                              secondary-bg-sprite))


;;;  Static Sprite List  ;;;

; To be determined

;(define static-sprites (list static-sprite
;                             static-sprite
;                             static-sprite))

;;; Write Database

; This writes the database to a file in the root voxos directory
; the debug flag allows the sprites to be output to an atlas .PNG
; sprites.PNG will contain all game sprites

(define voxos-path "./")
(save-csd! compiled-sprite-database voxos-path #:debug? #t)
