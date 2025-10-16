output "bucket_name" {
  value = aws_s3_bucket.assignment_bucket.bucket
}

output "kms_key_id" {
  value = aws_kms_key.s3_key.key_id
}
