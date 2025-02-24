# Decentralized Development Grant (DDG)

## Overview

The Decentralized Development Grant (DDG) is a smart contract framework designed to enable transparent, milestone-based project funding with community oversight. It allows creators to propose projects, receive community funding, and deliver milestones in a fully accountable manner.

Built on the Stacks blockchain, the DDG contract facilitates democratic decision-making around grant allocation while ensuring funds are only released as project milestones are achieved and verified.

## Key Features

- **Community-Driven Decision Making**: Projects require 67% community support to be approved
- **Milestone-Based Development**: Funding is split into separate milestones with individual deliverables
- **Transparent Fund Allocation**: All transactions and voting are recorded on-chain
- **Progressive Fund Release**: Funds are only released as milestones are completed
- **On-Chain Evidence**: Milestone completion requires submission of verifiable evidence

## Core Components

### Projects

Each project in the DDG system contains:

- **Creator**: The principal address of the project's creator
- **Details**: Project name and detailed description
- **Funding**: Total requested funding amount
- **Milestones**: Number of development milestones and current progress
- **Timeline**: Start and end blocks for the voting period
- **Status**: Current project status (ACTIVE, COMPLETED, etc.)
- **Voting Data**: Accumulated votes for and against

### Milestones

Each project is divided into milestones that contain:

- **Funding**: Amount allocated for this specific milestone
- **Details**: Description of deliverables for this milestone
- **Status**: Current milestone status (PENDING, PENDING_REVIEW, COMPLETED)
- **Evidence**: Optional link or hash to evidence of milestone completion

### Community Voting

Community members can participate by:

- Voting for or against projects
- Contributing funds (minimum 200 STX)
- The voting weight is proportional to the contribution amount

## Contract Constants

| Constant | Value | Description |
|----------|-------|-------------|
| MIN_CONTRIBUTION_AMOUNT | 200 STX | Minimum contribution required to vote |
| VOTING_DURATION | 1440 blocks | Approximately 15 days voting period |
| SUCCESS_THRESHOLD | 67% | Percentage of votes required for approval |
| MAX_GRANT_SIZE | 5,000,000,000 | Maximum funding a project can request |
| MIN_PROJECT_NAME_LENGTH | 8 | Minimum length for project names |
| MIN_PROJECT_DETAILS_LENGTH | 20 | Minimum length for project details |

## How It Works

### Project Creation and Funding Flow

1. **Project Submission**:
   - Creator calls `submit-project` with project details and milestone count
   - Project enters the voting period (15 days)

2. **Milestone Definition**:
   - Creator defines each milestone with `add-milestone`, specifying:
     - Milestone funding amount
     - Detailed deliverables

3. **Community Voting**:
   - Community members call `vote-on-project` with:
     - Their vote (for/against)
     - Their contribution amount (minimum 200 STX)
   - Voting weight is proportional to contribution

4. **Project Approval**:
   - After voting period ends, `get-project-result` determines outcome
   - Projects require 67% support to be approved
   - Rejected projects cannot access funds

5. **Milestone Development and Verification**:
   - For each milestone:
     - Creator develops and submits evidence with `submit-milestone-evidence`
     - Contract owner reviews and calls `approve-milestone` if satisfied
     - Milestone funds are released to creator
     - Project advances to next milestone

6. **Project Completion**:
   - When all milestones are completed, project status changes to "COMPLETED"

## Public Functions

### For Project Creators

- `submit-project(name, details, total-funding, milestone-count)`: Create a new project proposal
- `add-milestone(project-id, milestone-id, funding, details)`: Define a project milestone
- `submit-milestone-evidence(project-id, milestone-id, evidence)`: Submit proof of milestone completion

### For Community Members

- `vote-on-project(project-id, vote-for, contribution-amount)`: Vote and contribute to a project

### For Contract Owner

- `approve-milestone(project-id, milestone-id)`: Approve a milestone and release funds

### Read-Only Functions

- `get-project(project-id)`: Get all project details
- `get-milestone(project-id, milestone-id)`: Get specific milestone details
- `get-vote(project-id, voter)`: Get details of a specific vote
- `get-project-result(project-id)`: Get the final or current result of project voting

## Error Codes

| Code | Description |
|------|-------------|
| ERR_UNAUTHORIZED (100) | Access denied for this operation |
| ERR_INVALID_PROJECT (101) | Project doesn't exist or is invalid |
| ERR_ALREADY_VOTED (102) | User has already voted on this project |
| ERR_INSUFFICIENT_CONTRIBUTION (103) | Contribution amount is below minimum |
| ERR_VOTING_CLOSED (104) | Voting period has ended |
| ERR_MILESTONE_INVALID (105) | Invalid milestone ID |
| ERR_PROJECT_REJECTED (106) | Project didn't receive sufficient approval |
| ERR_INVALID_FUNDING (107) | Funding amount is invalid |
| ERR_INVALID_MILESTONE_COUNT (108) | Milestone count is invalid |
| ERR_INVALID_PROJECT_NAME (109) | Project name is too short |
| ERR_INVALID_PROJECT_DETAILS (110) | Project details are too short |

## Security Considerations

- Funds are held by the contract until milestone approval
- Only the project creator can submit evidence
- Only the contract owner can approve milestones and release funds
- All voting is final and cannot be changed
- Projects cannot be modified after submission
- Milestone approvals are irreversible

## Example Usage

### Submitting a Project

```clarity
(contract-call? .decentralized-development-grant submit-project 
    "Web3 Identity Framework" 
    "A decentralized identity solution with self-sovereign data control and cross-chain compatibility" 
    u5000000 
    u4)
```

### Adding a Milestone

```clarity
(contract-call? .decentralized-development-grant add-milestone 
    u1  ;; project-id
    u0  ;; first milestone (0-indexed)
    u1250000  ;; 25% of total funding
    "Complete API specification and framework architecture")
```

### Voting on a Project

```clarity
(contract-call? .decentralized-development-grant vote-on-project
    u1  ;; project-id
    true  ;; vote in favor
    u500  ;; contributing 500 STX
)
```

### Submitting Milestone Evidence

```clarity
(contract-call? .decentralized-development-grant submit-milestone-evidence
    u1  ;; project-id
    u0  ;; milestone-id
    "https://github.com/project/repo/milestone1-delivery")
```

## Best Practices for Project Creators

1. **Clear Milestones**: Define clear, measurable deliverables for each milestone
2. **Reasonable Funding**: Request appropriate funding relative to deliverables
3. **Community Engagement**: Engage with voters during the voting period
4. **Transparent Development**: Maintain open communication during development
5. **Thorough Evidence**: Provide comprehensive evidence of milestone completion

## Limitations

- Maximum of 10 milestones per project
- Project names limited to 100 ASCII characters
- Project details limited to 500 ASCII characters
- Milestone details limited to 200 ASCII characters
- Evidence links limited to 200 ASCII characters

## Integration with Frontend Applications

Frontend applications can interact with this contract using Stacks.js or similar libraries to:
- Display active projects for voting
- Show project details and voting progress
- Enable users to vote and contribute
- Allow creators to submit evidence
- Track milestone completion status