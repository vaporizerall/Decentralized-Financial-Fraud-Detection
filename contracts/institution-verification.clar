;; Institution Verification Contract
;; Validates and stores financial entities

(define-data-var admin principal tx-sender)

;; Institution status: 0 = pending, 1 = verified, 2 = rejected
(define-map institutions
  { institution-id: (string-ascii 64) }
  {
    name: (string-ascii 256),
    registration-number: (string-ascii 64),
    status: uint,
    verification-date: uint,
    verified-by: principal
  }
)

(define-read-only (get-institution (institution-id (string-ascii 64)))
  (map-get? institutions { institution-id: institution-id })
)

(define-read-only (is-institution-verified (institution-id (string-ascii 64)))
  (let ((institution (get-institution institution-id)))
    (if (is-some institution)
      (is-eq (get status (unwrap-panic institution)) u1)
      false
    )
  )
)

(define-public (register-institution
    (institution-id (string-ascii 64))
    (name (string-ascii 256))
    (registration-number (string-ascii 64)))
  (begin
    (asserts! (is-none (get-institution institution-id)) (err u1)) ;; Institution ID already exists
    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        registration-number: registration-number,
        status: u0, ;; pending
        verification-date: u0,
        verified-by: tx-sender
      }
    )
    (ok true)
  )
)

(define-public (verify-institution (institution-id (string-ascii 64)) (approve bool))
  (let ((institution (get-institution institution-id)))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only admin can verify
      (asserts! (is-some institution) (err u404)) ;; Institution not found
      (asserts! (is-eq (get status (unwrap-panic institution)) u0) (err u2)) ;; Not in pending status

      (map-set institutions
        { institution-id: institution-id }
        {
          name: (get name (unwrap-panic institution)),
          registration-number: (get registration-number (unwrap-panic institution)),
          status: (if approve u1 u2), ;; 1 = verified, 2 = rejected
          verification-date: block-height,
          verified-by: tx-sender
        }
      )
      (ok true)
    )
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403)) ;; Only current admin can change admin
    (var-set admin new-admin)
    (ok true)
  )
)
