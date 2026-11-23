# pq-devnet-0 spec

:::info
:mega: pq-devnet-0 launch date: 23.11.2026
:::

:::info
:checkered_flag: **Scope.** First multi-client devnet of the **PQ** fork: validators and builders sign with leanXMSS instead of BLS, and attestations are aggregated with leanVM STARK proofs. The PQ fork is active **at genesis** on top of Gloas (Fulu, Gloas and PQ at epoch 0, Heze off), so there is no BLS to XMSS transition and no EIP-8483 registration flow in this devnet. Genesis validators get their XMSS public keys and VRF roots from the genesis tool.
Every client runs the **same leanVM revision** for signer, prover, verifier and sidecar. A proof made with another revision does not verify.
:::

## Pinned versions

Everything below is fixed for pq-devnet-0. A change to any of them is a coordinated restart.

| Component | Pin |
|-----------|-----|
| Consensus spec | [`ethereum/consensus-specs@2f43bc0f`](https://github.com/ethereum/consensus-specs/tree/2f43bc0f989f47af81df390a90bc1f78e2436323/specs/_features/pq) (`pq` branch, "Hash the VRF tree with Keccak-256") |
| leanVM (signer, prover, verifier, sidecar) | bindings **v0.15.0**, [`leanEthereum/leanVM@c5ee9d23`](https://github.com/leanEthereum/leanVM/tree/c5ee9d239e42d0bc8113eb4aee3e2cae5faf1764). Replaces `283686575c4e`. One version throughout, no backports |
| Genesis / key derivation | [`ethpandaops/eth-beacon-genesis@ff42fce0`](https://github.com/ethpandaops/eth-beacon-genesis/tree/ff42fce0ba5cbb351507af97d3583053df4cd165) |
| Genesis XMSS public keys and VRF roots | `.bin` and `.vrf` files of [`ethpandaops/ethereum-package@d4c9a8ac`](https://github.com/ethpandaops/ethereum-package/tree/d4c9a8ace9dd80ca4f9938885345f8f40a646fd0/static_files/xmss-keys) |
| Execution layer | Glamsterdam, `ethpandaops/geth:glamsterdam-devnet-8` |

Later commits on the consensus-specs `pq` branch (staggered aggregators, VRF secret commitments, `X_MAX_COMMITTEE_COUNT_PER_SLOT`, keccak256 for legacy key derivation) are **not** in pq-devnet-0.

## What the PQ fork changes

| Area | Change |
|------|--------|
| Signatures | leanXMSS replaces BLS for validators and builders. Each message type signs at an XMSS leaf derived from its slot (or target epoch for attestations), so a key never reuses a leaf |
| Aggregation | No native aggregation. A leanVM STARK proves many XMSS signatures at once (`AttestationProof`), and proofs are merged recursively |
| Aggregators | No self-selection. Each beacon committee has an aggregation committee sampled by effective balance (`AGGREGATORS_PER_COMMITTEE = 4`) |
| RANDAO | XMSS signatures are not unique, so the reveal is a `VRFProof`: the slot's secret plus its Merkle branch to the validator's registered VRF root |
| Sync committees | Removed, together with the light client protocol |
| Validator records | Carry the XMSS public key and VRF root in place of the BLS public key |

## Testing focus

- **Interop**: every pair of clients finalizes together on one leanVM revision, with blocks proposed and attestation proofs produced by each client.
- **Aggregation load**: committee proof and recursive merge times on validator hardware, missed aggregations, and proof sizes on gossip and in blocks.
- **Validator start-up**: building the XMSS trees takes minutes per key. Clients accept a precomputed cache (`--xmss-cache-url`, or the client's equivalent) and fall back to building the trees when it is unset, unreachable or refused.
- **Sidecar supervision**: the node keeps working, or recovers, when the leanVM sidecar restarts.
- **Sync and restart**: a node that was down syncs back and resumes its duties.

## Client readiness

| Client | Branch | leanVM | Image | Status |
|--------|--------|:------:|-------|:------:|
| Lighthouse | [`ethDreamer/lighthouse@pq-devnet-0`](https://github.com/ethDreamer/lighthouse/tree/pq-devnet-0) | v0.15.0 | `ethpandaops/lighthouse:pq-devnet-0` | :heavy_check_mark: |
| Teku | [`Consensys/teku@pq-devnet-0`](https://github.com/Consensys/teku/tree/pq-devnet-0) | v0.16.0 (proofs compatible with v0.15.0) | `ethpandaops/teku:pq-devnet-0` | :heavy_check_mark: |
| Prysm | [`OffchainLabs/prysm@pq-devnet-0`](https://github.com/OffchainLabs/prysm/tree/pq-devnet-0) | v0.15.0 sidecar | `ethpandaops/prysm-beacon-chain:pq-devnet-0`, sidecar not in the image yet | :hourglass: |
| Grandine | [`grandinetech/grandine@pq-devnet-0`](https://github.com/grandinetech/grandine/tree/pq-devnet-0) | v0.15.0 | `ethpandaops/grandine:pq-devnet-0`, not built yet | :hourglass: |
| ethlambda | [`lambdaclass/ethlambda@pq-devnet-0`](https://github.com/lambdaclass/ethlambda/tree/pq-devnet-0) | v0.15.0 | `ghcr.io/lambdaclass/ethlambda:pq-devnet-0` | :heavy_check_mark: |
| Silver | [`gattaca-com/pq-silver@pq-devnet-0`](https://github.com/gattaca-com/pq-silver/tree/pq-devnet-0) | v0.15.0 sidecar | `ethpandaops/silver:pq-devnet-0`, not built yet | :hourglass: |
| Nimbus | [`status-im/nimbus-eth2@pq-devnet-0`](https://github.com/status-im/nimbus-eth2/tree/pq-devnet-0) | `283686575c4e`, needs the bump to v0.15.0 | `ethpandaops/nimbus-eth2:pq-devnet-0` | :x: |
| Lodestar | [`ChainSafe/lodestar@pq-devnet-0`](https://github.com/ChainSafe/lodestar/tree/pq-devnet-0) | v0.15.0, compiled into the node | `ethpandaops/lodestar:pq-devnet-0` | :heavy_check_mark: |

Interop seen so far: Lighthouse + Teku finalizing in Kurtosis (minimal preset), and ethlambda reporting interop with Lighthouse, Teku and Prysm in local devnets.

## Validator keys

Validator XMSS keys are derived from the BLS keys of the default mnemonic, the same way in every client and in the genesis tool.

The XMSS caches of the first 10,000 keys are precomputed:

- URL: https://pub-9ca7c570d1d646ab9412620dce6f55d2.r2.dev/b9dec4e1daa17dfe.xmss
- Layout: raw leanVM v0.15.0 `cache_to_bytes` output with no framing, 14,696 bytes per key: top tree (4,096), bottom tree 0 for attestations (5,300), bottom tree 24576 for slot duties (5,300).
- Mapping: record `i` is key index `i` of the default mnemonic, in the order of the `.bin` public key file. Request bytes `i*14696` to `(i+1)*14696-1` to fetch a single key.
- Loading: `from_cache_bytes(seed, public_key, bytes)` checks the bytes against the public key, so the file does not need to be trusted.

### Specs & Tests

**Consensus Layer**

- [ ] [`pq` branch at 2f43bc0f](https://github.com/ethereum/consensus-specs/tree/2f43bc0f989f47af81df390a90bc1f78e2436323/specs/_features/pq) :hourglass:

**Execution Layer**

- [x] No execution layer changes, Glamsterdam as in glamsterdam-devnet-8 :heavy_check_mark:

### Open PRs

Not in scope for pq-devnet-0 (PQ is active at genesis), tracked for the transition devnets:

**EIPs**

- [PR-12609 - Add EIP: Post-Quantum Material Registration](https://github.com/ethereum/EIPs/pull/12609) Open :exclamation:

**Consensus Specs**

- [PR-5809 - Add PQ registration requests (EIP-8483)](https://github.com/ethereum/consensus-specs/pull/5809) Open :exclamation:

## Local testing

Uses the `pq` branch of ethereum-package ([PR-1523](https://github.com/ethpandaops/ethereum-package/pull/1523)):

```shell
kurtosis run github.com/ethpandaops/ethereum-package@pq --args-file https://raw.githubusercontent.com/ethpandaops/ethereum-package/pq/.github/tests/cl-pq.yaml --image-download always
```

The package passes each client its PQ flags on its own (sidecar wrapper, key derivation, VRF state URL, XMSS cache URL), with the published files of the default mnemonic as defaults.

That args file is [`.github/tests/cl-pq.yaml`](https://github.com/ethpandaops/ethereum-package/blob/pq/.github/tests/cl-pq.yaml) on the `pq` branch, with every consensus client:

```yaml
participants:
  - cl_type: lighthouse
    cl_image: ethpandaops/lighthouse:pq-devnet-0
    supernode: true
  - cl_type: teku
    cl_image: ethpandaops/teku:pq-devnet-0
    supernode: true
  - cl_type: prysm
    cl_image: ethpandaops/prysm-beacon-chain:pq-devnet-0
    vc_image: ethpandaops/prysm-validator:pq-devnet-0
  - cl_type: lodestar
    cl_image: ethpandaops/lodestar:pq-devnet-0
  - cl_type: nimbus
    cl_image: ethpandaops/nimbus-eth2:pq-devnet-0
  - cl_type: grandine
    cl_image: ethpandaops/grandine:pq-devnet-0
  - cl_type: ethlambda
    cl_image: ethpandaops/ethlambda:pq-devnet-0
  - cl_type: silver
    cl_image: ethpandaops/silver:pq-devnet-0
    vc_type: lighthouse
    vc_image: ethpandaops/lighthouse:pq-devnet-0

network_params:
  preset: mainnet
  gloas_fork_epoch: 0
  pq_fork_epoch: 0
  genesis_delay: 120

additional_services:
  - dora
```

Silver only supports the mainnet preset and has no validator client of its own, so it runs with a Lighthouse one. For the minimal preset, drop Silver and use the `-minimal` image tags of Prysm, Nimbus and Grandine.
