output "lb-url" {
  value = aws_lb.main.dns_name
}

output "lb-arn" {
  value = aws_lb.main.arn
}
