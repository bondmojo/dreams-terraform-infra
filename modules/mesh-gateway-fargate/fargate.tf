resource "aws_security_group" "ecs_lb" {
  name   = "${var.name}-sg-lb"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["10.0.0.0/16"]
  }

  egress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "ecs_tasks" {
  name   = "${var.name}-vgateway-sg-task"
  vpc_id = var.vpc_id

  ingress {
    protocol         = "-1"
    from_port        = 0
    to_port          = 0
    cidr_blocks      = ["10.0.0.0/16"]
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
  family                   = "${var.name}-vgateway-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task-execution-arn
  task_role_arn            = var.task-arn
  container_definitions = jsonencode([{
    name      = "app"
    image     = "840364872350.dkr.ecr.ap-southeast-1.amazonaws.com/aws-appmesh-envoy:v1.16.1.1-prod"
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = 9901
      hostPort      = 9901
    },{
      protocol      = "tcp"
      containerPort = var.container_port
      hostPort      = var.container_port
    }]
    healthCheck = {
      command     = ["CMD-SHELL", "curl -s http://localhost:9901/server_info | grep state | grep -q LIVE"]
      interval    = 5
      retries     = 3
      timeout     = 2
      startPeriod = 0
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
    environment = [{
      name  = "APPMESH_VIRTUAL_NODE_NAME"
      value = "mesh/${var.mesh-name}/virtualGateway/${var.name}-gateway"
    },{
      name = "ENABLE_ENVOY_STATS_TAGS"
      value = "1"
    },{
      name = "ENABLE_ENVOY_DOG_STATSD"
      value = "1"
    },{
      name = "STATSD_PORT"
      value = "8125"
    },{
      name = "ENABLE_ENVOY_XRAY_TRACING"
      value = "1"
    }]
    mountPoints = []
    volumesFrom = []
  },
    {
      image: "amazon/aws-xray-daemon",
      essential: false,
      name: "xray",
      user = "1337"
      portMappings: [
        {
          hostPort: 2000,
          protocol: "udp",
          containerPort: 2000
        }
      ],
      healthCheck: {
        retries: 3,
        command: [
          "CMD-SHELL",
          "timeout 1 /bin/bash -c \"</dev/udp/localhost/2000\""
        ],
        timeout: 2,
        interval: 5,
        startPeriod: 10
      }
    },
    {
      name      = "log_driver"
      image     = "906394416424.dkr.ecr.us-east-2.amazonaws.com/aws-for-fluent-bit:latest"
      essential = false
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          config-file-type        = "file"
          config-file-value       = "/fluent-bit/configs/parse-json.conf"
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
  name                               = "${var.name}-vgateway-service"
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
    target_group_arn = aws_lb_target_group.main.id
    container_name   = "app"
    container_port   = var.container_port
    }

  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  depends_on = [aws_lb.main]
}

resource "aws_service_discovery_service" "main" {
  name = "gateway"

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 300
      type = "A"
    }
  }

  health_check_custom_config {
    failure_threshold = 5
  }

}

resource "aws_lb" "main" {
  name                             = "${var.name}-lb"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = "true"

  # launch lbs in public or private subnets based on "internal" variable
  internal        = true
  subnets         = var.subnets
}

resource "aws_lb_target_group" "main" {
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    protocol = "TCP"
    port     = var.container_port
    enabled  = true
    interval = 30
  }
}

resource "aws_lb_listener" "tcp" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.main.id
    type             = "forward"
  }
}
