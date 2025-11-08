output "load_balancer_dns" {
  description = "The DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "route53_record" {
  description = "The Route 53 record pointing to the ALB."
  value       = aws_route53_record.www.name
}

output "rds_endpoint" {
  description = "The endpoint of the RDS database."
  value       = aws_db_instance.main.endpoint
}

output "rds_password" {
  description = "The generated password for the RDS database."
  value       = random_string.db_password.result
  sensitive   = true
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket."
  value       = aws_s3_bucket.main.id
}