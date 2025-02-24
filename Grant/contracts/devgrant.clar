;; Decentralized Development Grant (DDG)
;; A framework for transparent, milestone-based project funding with community oversight

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant MIN_CONTRIBUTION_AMOUNT u200)
(define-constant VOTING_DURATION u1440) ;; ~15 days in blocks (assuming 10 min/block)
(define-constant SUCCESS_THRESHOLD u670) ;; 67.0% represented as 670/1000
(define-constant MAX_GRANT_SIZE u5000000000) ;; Maximum amount allowed for projects
(define-constant MIN_PROJECT_NAME_LENGTH u8)
(define-constant MIN_PROJECT_DETAILS_LENGTH u20)

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVALID_PROJECT (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_INSUFFICIENT_CONTRIBUTION (err u103))
(define-constant ERR_VOTING_CLOSED (err u104))
(define-constant ERR_MILESTONE_INVALID (err u105))
(define-constant ERR_PROJECT_REJECTED (err u106))
(define-constant ERR_INVALID_FUNDING (err u107))
(define-constant ERR_INVALID_MILESTONE_COUNT (err u108))
(define-constant ERR_INVALID_PROJECT_NAME (err u109))
(define-constant ERR_INVALID_PROJECT_DETAILS (err u110))

;; Data Maps and Variables
(define-map Projects
    { project-id: uint }
    {
        creator: principal,
        name: (string-ascii 100),
        details: (string-ascii 500),
        total-funding: uint,
        milestone-count: uint,
        current-milestone: uint,
        start-block: uint,
        end-block: uint,
        status: (string-ascii 20),
        total-support-for: uint,
        total-support-against: uint,
        total-voting-weight: uint
    }
)

(define-map Milestones
    { project-id: uint, milestone-id: uint }
    {
        funding: uint,
        details: (string-ascii 200),
        status: (string-ascii 20),
        delivery-evidence: (optional (string-ascii 200))
    }
)

(define-map CommunityVotes
    { project-id: uint, voter: principal }
    {
        amount: uint,
        support: bool,
        contributed-amount: uint
    }
)

(define-map ContributorStakes
    { user: principal }
    { total-contributed: uint }
)

(define-data-var project-counter uint u0)

;; Private functions
(define-private (is-contract-owner)
    (is-eq tx-sender CONTRACT_OWNER)
)

(define-private (calculate-voting-weight (contribution-amount uint))
    contribution-amount
)

(define-private (is-valid-project-id (project-id uint))
    (<= project-id (var-get project-counter))
)

(define-private (is-valid-milestone-id (milestone-id uint) (milestone-count uint))
    (< milestone-id milestone-count)
)

(define-private (is-valid-funding (amount uint))
    (and (> amount u0) (<= amount MAX_GRANT_SIZE))
)

(define-private (is-valid-name (name (string-ascii 100)))
    (>= (len name) MIN_PROJECT_NAME_LENGTH)
)

(define-private (is-valid-details (details (string-ascii 500)))
    (>= (len details) MIN_PROJECT_DETAILS_LENGTH)
)

(define-private (validate-and-process-support (support-direction bool) (voting-weight uint) (project-data (tuple (total-support-for uint) (total-support-against uint) (total-voting-weight uint))))
    (let (
        (safe-support (validate-support-bool support-direction))
        (current-support-for (get total-support-for project-data))
        (current-support-against (get total-support-against project-data))
        (current-total-weight (get total-voting-weight project-data))
    )
        {
            total-support-for: (if safe-support 
                (+ current-support-for voting-weight)
                current-support-for
            ),
            total-support-against: (if safe-support
                current-support-against
                (+ current-support-against voting-weight)
            ),
            total-voting-weight: (+ current-total-weight voting-weight)
        }
    )
)

(define-private (validate-support-bool (support-direction bool))
    (if support-direction
        true
        false
    )
)

(define-private (safe-merge-project-votes (project-map {
        creator: principal,
        name: (string-ascii 100),
        details: (string-ascii 500),
        total-funding: uint,
        milestone-count: uint,
        current-milestone: uint,
        start-block: uint,
        end-block: uint,
        status: (string-ascii 20),
        total-support-for: uint,
        total-support-against: uint,
        total-voting-weight: uint
    }) 
    (support-updates {
        total-support-for: uint,
        total-support-against: uint,
        total-voting-weight: uint
    }))
    (merge project-map
        {
            total-support-for: (get total-support-for support-updates),
            total-support-against: (get total-support-against support-updates),
            total-voting-weight: (get total-voting-weight support-updates)
        }
    )
)

;; Public functions
(define-public (submit-project (name (string-ascii 100)) 
                              (details (string-ascii 500)) 
                              (total-funding uint)
                              (milestone-count uint))
    (begin
        (asserts! (is-valid-name name) ERR_INVALID_PROJECT_NAME)
        (asserts! (is-valid-details details) ERR_INVALID_PROJECT_DETAILS)
        (asserts! (is-valid-funding total-funding) ERR_INVALID_FUNDING)
        (asserts! (and (> milestone-count u0) (<= milestone-count u10)) ERR_INVALID_MILESTONE_COUNT)
        
        (let ((project-id (+ (var-get project-counter) u1)))
            (map-set Projects
                { project-id: project-id }
                {
                    creator: tx-sender,
                    name: name,
                    details: details,
                    total-funding: total-funding,
                    milestone-count: milestone-count,
                    current-milestone: u0,
                    start-block: block-height,
                    end-block: (+ block-height VOTING_DURATION),
                    status: "ACTIVE",
                    total-support-for: u0,
                    total-support-against: u0,
                    total-voting-weight: u0
                }
            )
            (var-set project-counter project-id)
            (ok project-id)
        )
    )
)

(define-public (add-milestone (project-id uint) 
                            (milestone-id uint)
                            (funding uint)
                            (details (string-ascii 200)))
    (begin
        (asserts! (is-valid-details details) ERR_INVALID_PROJECT_DETAILS)
        (let ((project (unwrap! (map-get? Projects {project-id: project-id}) ERR_INVALID_PROJECT)))
            (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT)
            (asserts! (is-valid-funding funding) ERR_INVALID_FUNDING)
            (asserts! (is-valid-milestone-id milestone-id (get milestone-count project)) ERR_MILESTONE_INVALID)
            (asserts! (is-eq (get creator project) tx-sender) ERR_UNAUTHORIZED)
            
            (map-set Milestones
                { project-id: project-id, milestone-id: milestone-id }
                {
                    funding: funding,
                    details: details,
                    status: "PENDING",
                    delivery-evidence: none
                }
            )
            (ok true)
        )
    )
)

(define-public (vote-on-project (project-id uint) (vote-for bool) (contribution-amount uint))
    (let (
        (project (unwrap! (map-get? Projects {project-id: project-id}) ERR_INVALID_PROJECT))
        (current-block block-height)
        (voting-weight (calculate-voting-weight contribution-amount))
        (safe-support (validate-support-bool vote-for))
    )
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT)
        (asserts! (>= contribution-amount MIN_CONTRIBUTION_AMOUNT) ERR_INSUFFICIENT_CONTRIBUTION)
        (asserts! (<= current-block (get end-block project)) ERR_VOTING_CLOSED)
        (asserts! (is-none (map-get? CommunityVotes {project-id: project-id, voter: tx-sender})) ERR_ALREADY_VOTED)
        
        (try! (stx-transfer? contribution-amount tx-sender (as-contract tx-sender)))
        
        ;; Record vote with validated boolean
        (map-set CommunityVotes
            {project-id: project-id, voter: tx-sender}
            {
                amount: contribution-amount,
                support: safe-support,
                contributed-amount: contribution-amount
            }
        )
        
        ;; Process support and update project
        (let (
            (updated-support (validate-and-process-support 
                safe-support
                voting-weight
                {
                    total-support-for: (get total-support-for project),
                    total-support-against: (get total-support-against project),
                    total-voting-weight: (get total-voting-weight project)
                }
            ))
        )
            (map-set Projects
                {project-id: project-id}
                (safe-merge-project-votes project updated-support)
            )
            (ok true)
        )
    )
)

(define-public (submit-milestone-evidence 
    (project-id uint)
    (milestone-id uint)
    (evidence (string-ascii 200)))
    
    (let (
        (project (unwrap! (map-get? Projects {project-id: project-id}) ERR_INVALID_PROJECT))
        (milestone (unwrap! (map-get? Milestones {project-id: project-id, milestone-id: milestone-id}) ERR_MILESTONE_INVALID))
    )
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT)
        (asserts! (is-valid-milestone-id milestone-id (get milestone-count project)) ERR_MILESTONE_INVALID)
        (asserts! (is-eq (get creator project) tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-eq milestone-id (get current-milestone project)) ERR_MILESTONE_INVALID)
        
        (map-set Milestones
            {project-id: project-id, milestone-id: milestone-id}
            (merge milestone
                {
                    status: "PENDING_REVIEW",
                    delivery-evidence: (some evidence)
                }
            )
        )
        (ok true)
    )
)

(define-public (approve-milestone (project-id uint) (milestone-id uint))
    (let (
        (project (unwrap! (map-get? Projects {project-id: project-id}) ERR_INVALID_PROJECT))
        (milestone (unwrap! (map-get? Milestones {project-id: project-id, milestone-id: milestone-id}) ERR_MILESTONE_INVALID))
    )
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT)
        (asserts! (is-valid-milestone-id milestone-id (get milestone-count project)) ERR_MILESTONE_INVALID)
        (asserts! (is-contract-owner) ERR_UNAUTHORIZED)
        
        ;; Transfer milestone funding to creator
        (try! (as-contract (stx-transfer? (get funding milestone) tx-sender (get creator project))))
        
        ;; Update milestone status
        (map-set Milestones
            {project-id: project-id, milestone-id: milestone-id}
            (merge milestone {status: "COMPLETED"})
        )
        
        ;; Update project current milestone
        (map-set Projects
            {project-id: project-id}
            (merge project
                {
                    current-milestone: (+ milestone-id u1),
                    status: (if (>= (+ milestone-id u1) (get milestone-count project))
                        "COMPLETED"
                        "ACTIVE"
                    )
                }
            )
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-project (project-id uint))
    (map-get? Projects {project-id: project-id})
)

(define-read-only (get-milestone (project-id uint) (milestone-id uint))
    (map-get? Milestones {project-id: project-id, milestone-id: milestone-id})
)

(define-read-only (get-vote (project-id uint) (voter principal))
    (map-get? CommunityVotes {project-id: project-id, voter: voter})
)

(define-read-only (get-project-result (project-id uint))
    (let ((project (unwrap! (map-get? Projects {project-id: project-id}) ERR_INVALID_PROJECT)))
        (asserts! (is-valid-project-id project-id) ERR_INVALID_PROJECT)
        (if (>= block-height (get end-block project))
            (let (
                (total-votes (get total-voting-weight project))
                (votes-for (get total-support-for project))
            )
                (if (and
                    (> total-votes u0)
                    (>= (* votes-for u1000) (* total-votes SUCCESS_THRESHOLD))
                )
                    (ok "APPROVED")
                    (ok "REJECTED")
                )
            )
            (ok "VOTING_ACTIVE")
        )
    )
)