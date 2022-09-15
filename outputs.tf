output "alb_hostname" {
  value = "https://${aws_route53_record.dns_record.name}"
}
