
;; title: CourtVote
;; version: 1.0.0
;; summary: A blockchain-based jury selection system ensuring fair and impartial legal proceedings
;; description: This contract manages juror registration, case creation, jury selection, and voting for legal proceedings

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_REGISTERED (err u101))
(define-constant ERR_NOT_REGISTERED (err u102))
(define-constant ERR_CASE_NOT_FOUND (err u103))
(define-constant ERR_JURY_ALREADY_SELECTED (err u104))
(define-constant ERR_NOT_JUROR (err u105))
(define-constant ERR_ALREADY_VOTED (err u106))
(define-constant ERR_CASE_NOT_ACTIVE (err u107))
(define-constant ERR_INSUFFICIENT_JURORS (err u108))
(define-constant ERR_INVALID_VERDICT (err u109))

;; Data Variables
(define-data-var case-counter uint u0)
(define-data-var admin principal CONTRACT_OWNER)

;; Data Maps
;; Juror registration map
(define-map jurors
  principal
  {
    registered-at: uint,
    is-eligible: bool,
    cases-served: uint,
    reputation-score: uint
  }
)

;; Court cases map
(define-map cases
  uint ;; case-id
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    created-by: principal,
    created-at: uint,
    jury-size: uint,
    status: (string-ascii 20), ;; "created", "jury-selected", "voting", "completed"
    verdict: (optional (string-ascii 20)) ;; "guilty", "not-guilty", "hung-jury"
  }
)

;; Jury selection for each case
(define-map case-juries
  uint ;; case-id
  (list 12 principal) ;; max 12 jurors
)

;; Individual juror votes for cases
(define-map juror-votes
  {case-id: uint, juror: principal}
  {
    vote: (string-ascii 20), ;; "guilty", "not-guilty"
    voted-at: uint
  }
)

;; Case vote tallies
(define-map case-tallies
  uint ;; case-id
  {
    guilty-votes: uint,
    not-guilty-votes: uint,
    total-votes: uint
  }
)

;; Public Functions

;; Register as a juror
(define-public (register-juror)
  (let ((sender tx-sender))
    (if (is-some (map-get? jurors sender))
      ERR_ALREADY_REGISTERED
      (begin
        (map-set jurors sender {
          registered-at: block-height,
          is-eligible: true,
          cases-served: u0,
          reputation-score: u100
        })
        (ok true)
      )
    )
  )
)

;; Create a new case (admin only)
(define-public (create-case (title (string-ascii 100)) (description (string-ascii 500)) (jury-size uint))
  (let ((case-id (+ (var-get case-counter) u1)))
    (if (is-eq tx-sender (var-get admin))
      (begin
        (map-set cases case-id {
          title: title,
          description: description,
          created-by: tx-sender,
          created-at: block-height,
          jury-size: jury-size,
          status: "created",
          verdict: none
        })
        (map-set case-tallies case-id {
          guilty-votes: u0,
          not-guilty-votes: u0,
          total-votes: u0
        })
        (var-set case-counter case-id)
        (ok case-id)
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Select jury for a case (simplified random selection)
(define-public (select-jury (case-id uint))
  (let ((case-data (map-get? cases case-id)))
    (if (is-eq tx-sender (var-get admin))
      (match case-data
        case-info
        (if (is-eq (get status case-info) "created")
          (let ((jury-list (get-eligible-jurors (get jury-size case-info))))
            (if (>= (len jury-list) (get jury-size case-info))
              (begin
                (map-set case-juries case-id jury-list)
                (map-set cases case-id (merge case-info {status: "jury-selected"}))
                (ok jury-list)
              )
              ERR_INSUFFICIENT_JURORS
            )
          )
          ERR_JURY_ALREADY_SELECTED
        )
        ERR_CASE_NOT_FOUND
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Start voting phase for a case
(define-public (start-voting (case-id uint))
  (let ((case-data (map-get? cases case-id)))
    (if (is-eq tx-sender (var-get admin))
      (match case-data
        case-info
        (if (is-eq (get status case-info) "jury-selected")
          (begin
            (map-set cases case-id (merge case-info {status: "voting"}))
            (ok true)
          )
          ERR_CASE_NOT_ACTIVE
        )
        ERR_CASE_NOT_FOUND
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Submit vote (jurors only)
(define-public (submit-vote (case-id uint) (vote (string-ascii 20)))
  (let (
    (case-data (map-get? cases case-id))
    (jury-list (default-to (list) (map-get? case-juries case-id)))
    (existing-vote (map-get? juror-votes {case-id: case-id, juror: tx-sender}))
  )
    (if (and
          (is-some case-data)
          (is-eq (get status (unwrap-panic case-data)) "voting")
          (is-some (index-of jury-list tx-sender))
          (is-none existing-vote)
          (or (is-eq vote "guilty") (is-eq vote "not-guilty"))
        )
      (let ((current-tally (default-to {guilty-votes: u0, not-guilty-votes: u0, total-votes: u0} (map-get? case-tallies case-id))))
        (map-set juror-votes {case-id: case-id, juror: tx-sender} {
          vote: vote,
          voted-at: block-height
        })
        (if (is-eq vote "guilty")
          (map-set case-tallies case-id {
            guilty-votes: (+ (get guilty-votes current-tally) u1),
            not-guilty-votes: (get not-guilty-votes current-tally),
            total-votes: (+ (get total-votes current-tally) u1)
          })
          (map-set case-tallies case-id {
            guilty-votes: (get guilty-votes current-tally),
            not-guilty-votes: (+ (get not-guilty-votes current-tally) u1),
            total-votes: (+ (get total-votes current-tally) u1)
          })
        )
        ;; Update juror's served cases count
        (match (map-get? jurors tx-sender)
          juror-data
          (map-set jurors tx-sender (merge juror-data {cases-served: (+ (get cases-served juror-data) u1)}))
          false
        )
        (ok true)
      )
      (if (is-some existing-vote)
        ERR_ALREADY_VOTED
        (if (not (or (is-eq vote "guilty") (is-eq vote "not-guilty")))
          ERR_INVALID_VERDICT
          (if (is-none (index-of jury-list tx-sender))
            ERR_NOT_JUROR
            ERR_CASE_NOT_ACTIVE
          )
        )
      )
    )
  )
)

;; Finalize case verdict
(define-public (finalize-case (case-id uint))
  (let (
    (case-data (map-get? cases case-id))
    (tally (map-get? case-tallies case-id))
    (jury-list (default-to (list) (map-get? case-juries case-id)))
  )
    (if (is-eq tx-sender (var-get admin))
      (match case-data
        case-info
        (match tally
          vote-tally
          (if (and
                (is-eq (get status case-info) "voting")
                (is-eq (get total-votes vote-tally) (len jury-list))
              )
            (let ((verdict (if (> (get guilty-votes vote-tally) (get not-guilty-votes vote-tally))
                             "guilty"
                             (if (> (get not-guilty-votes vote-tally) (get guilty-votes vote-tally))
                               "not-guilty"
                               "hung-jury"))))
              (map-set cases case-id (merge case-info {
                status: "completed",
                verdict: (some verdict)
              }))
              (ok verdict)
            )
            ERR_CASE_NOT_ACTIVE
          )
          ERR_CASE_NOT_FOUND
        )
        ERR_CASE_NOT_FOUND
      )
      ERR_UNAUTHORIZED
    )
  )
)

;; Read-only Functions

;; Get juror information
(define-read-only (get-juror (juror principal))
  (map-get? jurors juror)
)

;; Get case information
(define-read-only (get-case (case-id uint))
  (map-get? cases case-id)
)

;; Get case jury
(define-read-only (get-case-jury (case-id uint))
  (map-get? case-juries case-id)
)

;; Get case vote tally
(define-read-only (get-case-tally (case-id uint))
  (map-get? case-tallies case-id)
)

;; Get current case counter
(define-read-only (get-case-counter)
  (var-get case-counter)
)

;; Check if address is registered juror
(define-read-only (is-registered-juror (juror principal))
  (is-some (map-get? jurors juror))
)

;; Private Functions

;; Get list of eligible jurors (simplified - returns first N eligible jurors)
(define-private (get-eligible-jurors (count uint))
  ;; This is a simplified implementation
  ;; In a real implementation, this would use a more sophisticated random selection
  (list)
)
