#lang racket/base
;;; gen-batch.rkt — generate many virgil-smith programs in one Racket process.
;;;
;;; Loading Xsmith and the spec costs ~2s; generating a program costs ~10ms.
;;; Running one process per program therefore wastes almost all of the time,
;;; so the campaign scripts use this driver to generate a whole batch.
;;;
;;; Usage:
;;;   racket gen-batch.rkt --seed S --count N --out-dir DIR [--max-depth D]
;;; writes DIR/prog_<seed>.v3 for each seed in [S, S+N).

(require racket/cmdline
         racket/runtime-path)

(define-runtime-path smith "virgil-smith.rkt")
(define virgil-generate (dynamic-require smith 'virgil-generate))

(define start 1)
(define count 1)
(define depth 5)
(define dir ".")

(command-line
 #:once-each
 [("--seed") s "first seed" (set! start (string->number s))]
 [("--count") c "number of programs" (set! count (string->number c))]
 [("--max-depth") d "maximum tree depth (default 5)" (set! depth (string->number d))]
 [("--out-dir") o "output directory" (set! dir o)])

(for ([i (in-range count)])
  (define seed (+ start i))
  (with-handlers ([exn:fail? (λ (e)
                               (eprintf "seed ~a: generation failed: ~a\n" seed (exn-message e)))])
    (virgil-generate #:seed seed
                     #:max-depth depth
                     #:output-file (format "~a/prog_~a.v3" dir seed))))
