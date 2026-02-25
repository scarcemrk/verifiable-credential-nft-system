# Verifiable Credential NFT Protocol (Security-First Reference Implementation)
![CI](https://github.com/scarcemrk/verifiable-credential-nft-system/actions/workflows/test.yml/badge.svg?branch=master)
![Coverage](https://img.shields.io/badge/Test%20Coverage-97.03%25-brightgreen)
![Solidity](https://img.shields.io/badge/Solidity-0.8.34-blue)

## Overview

This repository contains a security-first, upgradeable Verifiable Credential NFT protocol implemented in Solidity `0.8.34` using Foundry and OpenZeppelin upgradeable contracts (UUPS pattern).

The system provides an on-chain credential primitive designed for:

* Audit attestations
* Security verification badges
* Professional certifications
* Non-transferable identity-bound credentials

This repository is infrastructure, not a consumer product. It is intended to serve as a protocol-grade reference implementation for security-conscious credential issuance.

---

## Design Goals

The protocol is designed around the following principles:

1. **Security-first architecture**
   Explicit role boundaries and minimal surface area.

2. **Upgrade-safe storage layout**
   Dedicated storage contracts and append-only storage discipline.

3. **Explicit trust assumptions**
   Administrative authority is clearly defined and documented.

4. **Non-transferable credentials**
   Credentials represent attestations, not tradable assets.

5. **Auditability and clarity**
   Contracts are structured to be readable and testable.

6. **Composable ERC721 interface**
   ERC721 is used for ecosystem compatibility, while transferability is intentionally disabled.

---

## System Architecture

The system consists of two primary contracts:

### 1. IssuerRegistry (UUPS Upgradeable)

* Maintains authorized issuers.
* Controlled by a protocol admin.
* Governs who is permitted to mint credentials.
* Upgrade authorization restricted to protocol admin.

### 2. CredentialNFT (UUPS Upgradeable, Non-Transferable ERC721)

* Mints credentials to holders.
* Stores credential hash (`bytes32`).
* Stores original issuer address.
* Supports issuer-based revocation.
* Supports emergency admin revocation.
* Enforces non-transferability via `_update` override.

### Deployment Model

Both contracts are deployed behind `ERC1967Proxy` using the UUPS upgrade pattern.

Storage layout is separated into:

* `IssuerRegistryStorage`
* `CredentialNFTStorage`

Each storage contract includes a fixed-size storage gap to preserve upgrade safety.

---

## Roles & Permissions

### Protocol Admin

* Initializes contracts.
* Adds and removes issuers.
* Authorizes contract upgrades.
* Performs emergency credential revocation.

### Authorized Issuer

* Mints credentials.
* Revokes credentials it originally issued.

### Holder

* Owns credential token.
* Cannot transfer or burn credential.
* Credential validity determined by revocation status.

---

## System Invariants

The following invariants are expected to hold:

* Credential tokens are non-transferable.
* Revocation is irreversible.
* Only the original issuer can revoke a credential (except emergency admin).
* Storage layout is append-only.
* Upgrade authority is restricted to protocol admin.
* Removing an issuer does not retroactively invalidate issued credentials.

These invariants should be preserved across all upgrades.

---

## Non-Transferability Design

Credentials are implemented as ERC721 tokens for composability and tooling compatibility.

Transfer and burn operations are prevented by overriding `_update` and reverting if the token already exists.

This enforces a bound credential model where:

* Ownership represents issuance
* Mobility is intentionally restricted
* Credentials function as attestations rather than assets

---

## Revocation Model

Two revocation mechanisms exist:

### Issuer Revocation

* Only the original issuer may revoke.
* Revocation marks credential invalid.
* Token is not burned.

### Emergency Revocation

* Protocol admin may revoke any credential.
* Intended for security incidents or issuer compromise.

Revocation does not alter ownership, only validity state.

---

## Upgradeability Model

The system uses the UUPS upgrade pattern:

* Implementation contracts are deployed separately.
* Proxies delegate calls via `ERC1967Proxy`.
* `_authorizeUpgrade` restricts upgrades to protocol admin.

### Upgrade Discipline

* Storage must remain append-only.
* No variable reordering.
* No type changes.
* No deletions.

Upgrade governance is centralized in MVP and must be hardened for production use.

---

## Trust Assumptions

This protocol currently assumes:

* Protocol admin is trusted to manage issuer permissions and upgrades.
* Issuers are trusted to issue and revoke credentials honestly.
* Off-chain credential data integrity is external to the contract.
* Emergency revocation is used responsibly.

Administrative key management is critical.

---

## Threat Model Summary

Primary risks include:

1. Admin key compromise
   → Enables malicious upgrades or revocations.

2. Issuer key compromise
   → Enables unauthorized credential minting.

3. Faulty upgrade implementation
   → May break invariants or corrupt storage.

4. Off-chain data misuse
   → On-chain only stores hashes; validation must occur externally.

Mitigations include:

* Multisig admin
* Upgrade timelocks
* Operational monitoring
* Strict upgrade review procedures

---

## Non-Goals (v1)

This protocol does not attempt to provide:

* Decentralized governance
* Immutable deployment guarantees
* Off-chain credential validation logic
* Identity verification mechanisms
* Marketplace functionality

It is intentionally minimal.

---

## Deployment

Build:

```bash
forge build
```

Deployment sequence:

1. Deploy `IssuerRegistry` implementation.
2. Deploy `ERC1967Proxy` and initialize with admin.
3. Deploy `CredentialNFT` implementation.
4. Deploy `ERC1967Proxy` and initialize with:

   * name
   * symbol
   * issuer registry address
   * admin

Use Foundry scripts for reproducible deployment.

---

## Testing

Run full test suite:

```bash
forge test
```

Tests cover:

* Initialization safety
* Issuer authorization
* Minting logic
* Revocation logic
* Emergency revoke
* Non-transferability
* Upgrade safety
* Storage persistence across upgrades

---

## Upgrade Process

1. Deploy new implementation.
2. Call `upgradeToAndCall` from proxy.
3. Ensure caller is protocol admin.
4. Verify invariants post-upgrade.
5. Confirm storage compatibility.

Upgrades should be audited prior to execution.

---

## Roadmap

### MVP (Current)

* Centralized admin
* UUPS upgradeability
* Non-transferable credential model
* Issuer registry

### Hardening

* Multisig-controlled upgrades
* Upgrade timelocks
* Operational monitoring

### Governance Evolution

* Decentralized issuer governance
* Upgrade approval mechanisms
* Optional immutable deployment mode

---

## License

MIT
