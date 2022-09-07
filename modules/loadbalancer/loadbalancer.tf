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
