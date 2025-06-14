output "bootstrap_bucket_name" {
  description = "Name of the created S3 bucket for bootstrap configuration"
  value       = aws_s3_bucket.bootstrap_bucket.id
}
