########################################################################################
#                                    NODE DEFINITIONS
#
# Define your fleet as a list of node entries. Each entry supports:
#
#   Required:
#     - name            : Node type (e.g., "lighthouse-geth-super", "bootnode")
#     - count           : Number of instances
#     - cloud           : "digitalocean" or "hetzner"
#
#   Optional:
#     - validator_start : First validator index (default: 0)
#     - validator_end   : Last validator index (default: 0)
#     - size            : Instance size override (provider-specific)
#     - region          : Region override (digitalocean) or location (hetzner)
#     - supernode       : Force supernode=true/false (auto-detected from name)
#     - builder_start   : First builder index (buildoor nodes only). Exposes a
#                         builder_index=N server tag and inventory var per instance.
#
# Examples:
#   { name = "bootnode", count = 1, cloud = "digitalocean" }
#   { name = "lighthouse-geth-super", count = 2, cloud = "hetzner", validator_start = 0, validator_end = 200 }
#   { name = "mev-relay", count = 1, cloud = "hetzner", size = "ccx53" }
#
########################################################################################

variable "nodes" {
  description = "List of node definitions for the devnet"
  default = [
    { name = "bootnode", count = 1, cloud = "digitalocean" },
    { name = "lighthouse-geth", count = 3, cloud = "digitalocean", validator_start = 0, validator_end = 1500 },
    { name = "teku-geth", count = 3, cloud = "digitalocean", validator_start = 1500, validator_end = 3000 },
    { name = "prysm-geth", count = 3, cloud = "digitalocean", validator_start = 3000, validator_end = 4500 },
    { name = "lodestar-geth", count = 3, cloud = "digitalocean", validator_start = 4500, validator_end = 6000 },
    { name = "grandine-geth", count = 2, cloud = "digitalocean", validator_start = 6000, validator_end = 7000 },
    { name = "nimbus-geth", count = 2, cloud = "digitalocean", validator_start = 7000, validator_end = 8000 },
    { name = "ethlambda-geth", count = 2, cloud = "digitalocean", validator_start = 8000, validator_end = 9000 },
    { name = "silver-geth", count = 2, cloud = "digitalocean", validator_start = 9000, validator_end = 10000 },
    { name = "lighthouse-geth-observe", count = 1, cloud = "digitalocean", supernode = true },
    { name = "prysm-geth-observe", count = 1, cloud = "digitalocean", supernode = true },
  ]

  validation {
    condition = alltrue([
      for n in var.nodes :
      try(n.validator_start, 0) >= 0 && try(n.validator_start, 0) <= try(n.validator_end, 0)
    ])
    error_message = "Each node must satisfy 0 <= validator_start <= validator_end. Omit both fields (or set both to 0) for nodes without validators."
  }

  validation {
    condition = alltrue(flatten([
      for i, a in var.nodes : [
        for j, b in var.nodes :
        i >= j ||
        try(a.validator_end, 0) == 0 ||
        try(b.validator_end, 0) == 0 ||
        try(a.validator_end, 0) <= try(b.validator_start, 0) ||
        try(b.validator_end, 0) <= try(a.validator_start, 0)
      ]
    ]))
    error_message = "Validator ranges overlap between nodes. Each [validator_start, validator_end) interval must be disjoint from every other node's interval."
  }
}

