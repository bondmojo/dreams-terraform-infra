output "lb_target_group_id" {
  value = aws_lb_target_group.main.id
}

output "lb_arn" {
  value = aws_lb.main.arn
}

output "lb_url" {
  value = aws_lb.main.dns_name
}
