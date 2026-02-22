# Sentinel ポリシーセット設定
# enforcement_level:
#   hard-mandatory = 誰であっても上書き不可（デプロイを完全にブロック）
#   soft-mandatory = 管理者が上書き可能
#   advisory       = 警告のみ（ブロックしない）

policy "enforce-s3-encryption" {
  source            = "./enforce-s3-encryption.sentinel"
  enforcement_level = "hard-mandatory"
}

policy "require-public-access-block" {
  source            = "./require-public-access-block.sentinel"
  enforcement_level = "hard-mandatory"
}
