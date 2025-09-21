# CourtVote

CourtVote is a blockchain-based jury selection system ensuring fair and impartial legal proceedings. Built on the Stacks blockchain using Clarity smart contracts, it provides a transparent and decentralized approach to jury management and voting for legal cases.

## Features

- **Juror Registration**: Citizens can register as potential jurors with reputation tracking
- **Case Management**: Administrators can create and manage legal cases
- **Fair Jury Selection**: Automated jury selection from eligible registered jurors
- **Secure Voting**: Anonymous and tamper-proof voting system for jury members
- **Transparent Tallying**: Real-time vote counting with immutable results
- **Reputation System**: Track juror participation and maintain reputation scores
- **Multi-Phase Process**: Structured workflow from case creation to verdict finalization

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity
- **Clarity Version**: 2
- **Epoch**: 2.5
- **Maximum Jury Size**: 12 jurors per case
- **Supported Verdicts**: Guilty, Not Guilty, Hung Jury

## Project Structure

```
CourtVote/
├── README.md
└── CourtVote_contract/
    ├── contracts/
    │   └── CourtVote.clar          # Main smart contract
    ├── tests/
    │   └── CourtVote.test.ts       # Test suite
    ├── settings/
    │   ├── Devnet.toml
    │   ├── Testnet.toml
    │   └── Mainnet.toml
    ├── Clarinet.toml               # Project configuration
    ├── package.json
    ├── tsconfig.json
    └── vitest.config.js
```

## Installation

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (version 16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd CourtVote
```

2. Navigate to the contract directory:
```bash
cd CourtVote_contract
```

3. Install dependencies:
```bash
npm install
```

4. Check contract syntax:
```bash
clarinet check
```

## Usage Examples

### Running Tests

Execute the test suite to verify contract functionality:

```bash
npm test
```

For detailed test reporting with coverage:
```bash
npm run test:report
```

For continuous testing during development:
```bash
npm run test:watch
```

### Contract Interaction

#### Register as a Juror

```clarity
(contract-call? .CourtVote register-juror)
```

#### Create a Case (Admin Only)

```clarity
(contract-call? .CourtVote create-case
  "Criminal Case #2024-001"
  "State vs. Defendant regarding charges of fraud"
  u12)
```

#### Select Jury for a Case

```clarity
(contract-call? .CourtVote select-jury u1)
```

#### Submit a Vote (Jurors Only)

```clarity
(contract-call? .CourtVote submit-vote u1 "not-guilty")
```

#### Finalize Case Verdict

```clarity
(contract-call? .CourtVote finalize-case u1)
```

## Contract Functions Documentation

### Public Functions

#### `register-juror()`
Registers the caller as an eligible juror in the system.
- **Returns**: `(ok true)` on success, error code on failure
- **Access**: Public

#### `create-case(title, description, jury-size)`
Creates a new legal case (admin only).
- **Parameters**:
  - `title`: Case title (max 100 characters)
  - `description`: Case description (max 500 characters)
  - `jury-size`: Number of jurors needed
- **Returns**: Case ID on success
- **Access**: Admin only

#### `select-jury(case-id)`
Selects jury members for a specific case (admin only).
- **Parameters**: `case-id` - The case identifier
- **Returns**: List of selected juror principals
- **Access**: Admin only

#### `start-voting(case-id)`
Initiates the voting phase for a case (admin only).
- **Parameters**: `case-id` - The case identifier
- **Returns**: `(ok true)` on success
- **Access**: Admin only

#### `submit-vote(case-id, vote)`
Allows jury members to submit their verdict.
- **Parameters**:
  - `case-id` - The case identifier
  - `vote` - Either "guilty" or "not-guilty"
- **Returns**: `(ok true)` on success
- **Access**: Selected jurors only

#### `finalize-case(case-id)`
Finalizes the case with the jury's verdict (admin only).
- **Parameters**: `case-id` - The case identifier
- **Returns**: Final verdict string
- **Access**: Admin only

### Read-Only Functions

#### `get-juror(juror)`
Retrieves information about a registered juror.

#### `get-case(case-id)`
Retrieves detailed information about a specific case.

#### `get-case-jury(case-id)`
Returns the list of jurors assigned to a case.

#### `get-case-tally(case-id)`
Returns the current vote tally for a case.

#### `get-case-counter()`
Returns the total number of cases created.

#### `is-registered-juror(juror)`
Checks if a principal is a registered juror.

## Case Workflow

1. **Case Creation**: Admin creates a new case with title, description, and jury size
2. **Jury Selection**: Admin selects eligible jurors from the registered pool
3. **Voting Phase**: Admin starts the voting phase, allowing jurors to submit votes
4. **Vote Submission**: Each selected juror submits a "guilty" or "not-guilty" vote
5. **Finalization**: Once all votes are collected, admin finalizes the case with the verdict

## Deployment Guide

### Local Development (Devnet)

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy the contract:
```clarity
::deploy_contracts
```

### Testnet Deployment

1. Configure your testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deployments generate --devnet
clarinet deployments apply --devnet
```

### Mainnet Deployment

1. Configure your mainnet settings in `settings/Mainnet.toml`
2. Ensure thorough testing on testnet
3. Deploy to mainnet:
```bash
clarinet deployments generate --mainnet
clarinet deployments apply --mainnet
```

## Security Notes

### Important Considerations

- **Admin Access**: The contract has an admin role with significant privileges (case creation, jury selection, voting initiation)
- **Jury Selection**: Current implementation uses a simplified jury selection mechanism that should be enhanced for production use
- **Vote Privacy**: While votes are recorded on-chain, the voting process maintains pseudonymity through wallet addresses
- **Immutable Records**: All case data and votes are permanently recorded on the blockchain
- **Smart Contract Auditing**: Recommend thorough security audit before mainnet deployment

### Error Codes

- `u100`: Unauthorized access
- `u101`: Already registered as juror
- `u102`: Not registered as juror
- `u103`: Case not found
- `u104`: Jury already selected
- `u105`: Not a juror for this case
- `u106`: Already voted
- `u107`: Case not in active state
- `u108`: Insufficient eligible jurors
- `u109`: Invalid verdict submitted

### Best Practices

- Always verify contract state before performing actions
- Implement proper access controls in frontend applications
- Monitor contract events for case progress tracking
- Backup important case data off-chain for redundancy
- Implement time-based restrictions for voting phases in production

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the ISC License.