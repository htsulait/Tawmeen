# Tamween Chain

A blockchain-based supply chain transparency platform for Qatar’s **Tamween** food subsidy program.

Tamween Chain improves **traceability, recall management, and consumer trust** by recording key supply-chain events on-chain and anchoring off-chain batch data for auditability.

---

## Overview

Tamween Chain was designed to address a practical problem in regulated food distribution: when consumers and stakeholders cannot easily verify the origin, status, or safety of subsidized food products, rumors and uncertainty spread quickly. In a system as sensitive as Tamween, that can reduce public trust and make product recalls harder to manage.

This project uses smart contracts to create a tamper-evident record of product batches, lifecycle updates, and change notices. Consumers, retailers, suppliers, and regulators each interact with the system in different ways, while the Ministry of Commerce & Industry (MOCI) acts as the primary regulator/operator.

---

## Problem Statement

Tamween products move through multiple actors before reaching consumers. Without a trustworthy and transparent system:

- consumers may not know whether a batch is safe or recalled
- regulators may struggle to track changes quickly
- retailers may lack reliable recall visibility
- public confidence can be damaged by misinformation

Tamween Chain helps solve this by making batch history and recall status easier to verify.

---

## Key Features

- **Batch Registration**
  - Register product batches with metadata references and content hashes

- **Lifecycle Tracking**
  - Track batches through states such as:
    - Registered
    - In Transit
    - In Storage
    - For Sale
    - Sold
    - Recalled
    - Expired

- **Recall Management**
  - Regulators or operators can mark unsafe batches as recalled

- **Change Notice Workflow**
  - Submit, approve, reject, supersede, and close notices related to batch updates

- **Merkle Anchoring**
  - Store Merkle roots on-chain for integrity verification of off-chain batch data

- **Role-Based Access Control**
  - Restrict sensitive operations to authorized actors such as owner, operator, regulator, supplier, or retailer

- **Consumer Verification**
  - Consumers can verify whether a batch is valid, safe, or recalled through the frontend or QR-based flow

---

## Smart Contract Architecture

The system is built around three core contracts:

### `BatchRegistry.sol`

Responsible for:

- creating batches
- storing metadata references
- tracking lifecycle state transitions
- handling recalls
- preventing invalid state changes

### `ChangeNotice.sol`

Responsible for:

- managing notice workflows
- handling approvals and rejections
- linking authorized updates to regulated processes
- connecting batch changes to Merkle proof validation

### `MerkleAnchor.sol`

Responsible for:

- storing approved Merkle roots for batches
- verifying whether off-chain data matches the anchored root
- supporting tamper-evident document integrity

---

## Roles in the System

- **MOCI / Owner / Regulator**
  - Oversees the system, manages permissions, and approves sensitive actions

- **Operator**
  - Executes core administrative batch actions

- **Supplier**
  - Submits product and shipment-related information

- **Retailer**
  - Updates downstream status and interacts with recall flows

- **Auditor**
  - Reviews records for compliance and authenticity

- **Consumer**
  - Checks product safety and traceability status

---

## Tech Stack

- **Solidity**
- **Foundry**
- **Sepolia Testnet**
- **Next.js**
- **MetaMask**
- **Anvil**

---

## Getting Started

### Prerequisites

Make sure you have installed:

- Foundry
- Git
- A wallet private key for testnet deployment
- A Sepolia RPC endpoint

### Installation

```bash
git clone https://github.com/your-username/tamween-chain.git
cd tamween-chain
forge install
```
### Build

```bash
forge build
```

### Run Tests

```bash
forge test -vv
```

### Generate Gas Snapshot

```bash
forge snapshot
```

### Local Development

Start a local Anvil node:
```bash
anvil
```

Then deploy locally
```bash
forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```
### Deploy to Sepolia

Set your environment variables:
```bash
export PRIVATE_KEY=your_private_key
export SEPOLIA_RPC_URL=your_rpc_url
export ETHERSCAN_API_KEY=your_api_key
```
Deploy:

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

---
## Testing Focus

This project includes testing for:

- authorized vs unauthorized access  
- valid and invalid batch creation  
- lifecycle progression rules  
- recall behavior  
- Merkle root submission and verification  
- change notice approval and rejection flows  
- negative tests using revert expectations  

Example Foundry helper:

```bash
vm.expectRevert();
```

---

## Security Considerations

The project follows several secure development practices:

- Role-based access control  
- Checks-Effects-Interactions mindset  
- Input validation  
- Terminal state protection  
- Hash-based integrity checks  
- Off-chain / on-chain separation for sensitive or bulky data  

Important notes:

- on-chain integrity does not automatically guarantee off-chain input truthfulness  
- permissioned actors must still be trusted and managed carefully  
- key compromise remains an operational risk  

---

## Gas and Audit Readiness

For beta and audit work, the project can include:

- gas snapshots for hotspot identification  
- before and after gas optimization comparisons  
- Slither-based static analysis summaries  
- accepted-risk notes for documented trade-offs  
- repeatable, idempotent deployment scripts  
- basic UI polish for loading, empty, and error states  

---

## Project Goal

The goal of Tamween Chain is not just to store data on a blockchain.  

It is to create a practical trust layer for a regulated food supply system where transparency, accountability, and auditability matter.  

---

## Future Improvements

- improved frontend QR scanning  
- better dashboards for regulators and retailers  
- expanded Slither-based security review  
- gas optimization of hotspot functions  
- reproducible deployment artifacts and runbooks  
- more polished UI states for loading, empty, and error cases  

---

## Academic Note

This repository represents a prototype or MVP built for coursework and demonstration purposes.  

It is intended to show the feasibility of blockchain-assisted traceability for Tamween, not to serve as a production-ready government system without further review, testing, and policy integration.  

---

## License

This project is for academic and educational use unless otherwise specified.
