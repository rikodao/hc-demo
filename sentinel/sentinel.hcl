policy "enforce-s3-encryption" {
  source            = "./enforce-s3-encryption.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "require-public-access-block" {
  source            = "./require-public-access-block.sentinel"
  enforcement_level = "hard-mandatory"
}
