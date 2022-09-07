resource "aws_security_group" "ecs_tasks" {
  name   = "${var.short_name}-${var.name}-sg-task"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    protocol  = "tcp"
    from_port = var.container_port
    to_port   = var.container_port
    self      = true
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${var.short_name}-${var.name}-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = var.task-execution-arn
  task_role_arn            = var.task-arn
  container_definitions = jsonencode([{
    name      = "app"
    image     = var.image
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
    healthCheck = {
      command     = ["CMD-SHELL", "wget --spider http://localhost:8080/admin/health || exit 1"]
      interval    = 100
      retries     = 5
      timeout     = 5
      startPeriod = 100
    }
    logConfiguration = {
      logDriver = "awsfirelens"
      options = {
        "tls.verify" = "off"
        "net.keepalive" = "off"
        Format = "json"
        "Header Authorization Bearer" = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJhY2Nlc3MiOltdLCJhdWQiOiJsb2dpcS1jbGllbnRzIiwianRpIjoiMTc4MWMzZGYtZjYzOC00YTRhLTgzZDktOTc2NjBmNTE4ZDNjIiwiaWF0IjoxNjMxMzQwMjY4LCJpc3MiOiJsb2dpcS1jb2ZmZWUtc2VydmVyIiwibmJmIjoxNjMxMzQwMjY4LCJzdWIiOiJmbGFzaC1hZG1pbkBmb28uY29tIiwiVWlkIjoxLCJyb2xlIjoiYWRtaW4ifQ.azOzCXiBGY5PKvRVKTX07yCBrxxDP8zbEbPMTbVrYMs51zEI2VHIXDWrt3sYz92XORZtDCEgfHZaOJV9IYPucyJbOfgUbqPpowKBISaeIjqegqLfulIOj-eSnEiria0JY4jZwJBLfuXgUOlEIPGi1kAndkpVffbxIB4X3rHuGOZsACLtWIOSOJ8wR0OTDT-LVim2FtLFUFtc1TPZdTfhpX-QFHxnCWO1cmrCNz78bJ9JOA-tlWVwd6otgUE2kXZedXRPzLYVAclE88JMecXrCkqM8LDNIVwB1P3IG2XKOyve_6aKG6tqvvXgSHLl1DaQy9wC_OB0ij6RpAFapSK2Vw"
        Port = "443"
        Host = "gj.logiq.ai"
        Name = "forward"
        compress = "gzip"
        tls = "on"
        URI = "/v1/json_batch"
        Match = "*"
        Name = "http"
      }
    }
    cpu         = 0
    environment = var.env_variables
    secrets = [
      {
        valueFrom = "arn:aws:ssm:${var.region}:${var.account_number}:parameter/CODE_COMMIT_ACCESSKEY"
        name      = "CODE_COMMIT_ACCESSKEY"
      },
      {
        valueFrom = "arn:aws:ssm:${var.region}:${var.account_number}:parameter/CODE_COMMIT_SECRETKEY"
        name      = "CODE_COMMIT_SECRETKEY"
      }
    ]
    mountPoints = []
    volumesFrom = []
    },
    {
      name      = "log_driver"
      image     = "906394416424.dkr.ecr.us-east-2.amazonaws.com/aws-for-fluent-bit:latest"
      essential = false
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          config-file-type  = "file"
          config-file-value = "/fluent-bit/configs/parse-json.conf"
        }
      }
      cpu          = 0
      environment  = []
      mountPoints  = []
      volumesFrom  = []
      portMappings = []
      user         = "0"
    }])
}

resource "aws_ecs_service" "main" {
  name                               = "${var.name}-service"
  cluster                            = var.cluster_id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"
  platform_version                   = "1.4.0"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.subnets
    assign_public_ip = true
  }


  load_balancer {
    target_group_arn = var.lb_target_group_id
    container_name   = "app"
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
