terraform {
  backend "s3" {
    # 1) BUCKET NAME from bootstrap output `bootstrap_bucket_name`
    #    (random suffix — paste the EXACT value here)
    bucket = "cloudnest-dev-bucket-bootstrap-a06da03b"

    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloudnest-dev-dynamodb-table"
    encrypt        = true

    # 2) KMS ARN from bootstrap output `bootstrap_kms_key_arn` (OPTIONAL).
    #    Encrypts the state object with your CMK. The GitHub Actions role must
    #    have kms:Encrypt/Decrypt on this key. Remove the line to use default SSE.
    # kms_key_id = "arn:aws:kms:us-east-1:<acct>:key/<id>"
  }
}