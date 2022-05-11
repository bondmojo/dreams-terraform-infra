output "cluster-id" {
  value = aws_ecs_cluster.main.id
}
output "task-execution-arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}
output "task-arn" {
  value = aws_iam_role.ecs_task_role.arn
}
