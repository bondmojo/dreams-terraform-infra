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
    dependsOn = [{
      containerName = "envoy",
      condition     = "HEALTHY"
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
      dependsOn = [{
        containerName = "envoy",
        condition     = "HEALTHY"
      }]
      cpu          = 0
      environment  = []
      mountPoints  = []
      volumesFrom  = []
      portMappings = []
      user         = "0"
    },
    {
      image: "amazon/aws-xray-daemon",
      essential: false,
      name: "xray",
      user = "1337"
      portMappings : [
        {
          hostPort : 2000,
          protocol : "udp",
          containerPort : 2000
        }
      ],
      healthCheck : {
        retries : 3,
        command : [
          "CMD-SHELL",
          "timeout 1 /bin/bash -c \"</dev/udp/localhost/2000\""
        ],
        timeout : 2,
        interval : 5,
        startPeriod : 10
      }
    },
    {
      name      = "envoy"
      image     = "840364872350.dkr.ecr.ap-southeast-1.amazonaws.com/aws-appmesh-envoy:v1.16.1.1-prod"
      essential = false
      portMappings = [{
        protocol      = "tcp"
        containerPort = 9901
        hostPort      = 9901
        },
        {
          protocol      = "tcp"
          containerPort = 15000
          hostPort      = 15000
        },
        {
          protocol      = "tcp"
          containerPort = 15001
          hostPort      = 15001
        }
      ]
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
          Port = "24224"
          Host = "a34185698b2bf4ba9aae257122ddb7d5-40708826.ap-southeast-1.elb.amazonaws.com"
          Name = "forward"
        }
      }
      user = "1337"
      cpu  = 0
      environment = [{
        name  = "APPMESH_VIRTUAL_NODE_NAME"
        value = "mesh/${var.mesh-name}/virtualNode/${var.name}-vnode"
        }, {
        name  = "ENABLE_ENVOY_XRAY_TRACING"
        value = "1"
      }]
      mountPoints = []
      volumesFrom = []
  }])

  proxy_configuration {
    type           = "APPMESH"
    container_name = "envoy"
    properties = {
      AppPorts         = "8080"
      EgressIgnoredIPs = "169.254.170.2,169.254.169.254"
      IgnoredUID       = "1337"
      ProxyEgressPort  = 15001
      ProxyIngressPort = 15000
    }
  }
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

  service_registries {
    registry_arn = aws_service_discovery_service.main.arn
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

resource "aws_service_discovery_service" "main" {
  name = var.name

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 300
      type = "A"
    }
  }

}
