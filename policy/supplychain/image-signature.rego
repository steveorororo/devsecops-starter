package supplychain

deny[msg] {
  not data.supplychain.image_verified
  msg := "Image must be verified by Cosign"
}

