package supplychain

deny[msg] {
  not input.signature_verified
  msg := "SBOM must be signed with Cosign"
}
