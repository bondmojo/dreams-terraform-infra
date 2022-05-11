resource "aws_appmesh_virtual_service" "main" {
  name      = "${var.name}.${var.namespace}"
  mesh_name = var.mesh_id

  spec {
    provider {
      virtual_node {
        virtual_node_name = aws_appmesh_virtual_node.main.name
      }
    }
  }
}

resource "aws_appmesh_virtual_node" "main" {
  name      = "${var.name}-vnode"
  mesh_name = var.mesh_id

  dynamic "spec" {
    for_each = ["value"]
    content {
      dynamic "backend"{
        for_each = var.backends
        content {
          virtual_service {
            virtual_service_name = backend.value
          }
        }
      }
      listener {
        port_mapping {
          port     = 8080
          protocol = "http"
        }

        health_check {
          protocol            = "http"
          path                = var.health_check_path
          healthy_threshold   = 3
          unhealthy_threshold = 3
          timeout_millis      = 5000
          interval_millis     = 30000
        }
      }

      service_discovery {
        dns {
          hostname = "${var.name}.${var.namespace}"
        }
      }
    }
  }
}

resource "aws_appmesh_gateway_route" "main" {
  name                 = "${var.name}-gateway-route"
  mesh_name            = var.mesh_id
  virtual_gateway_name = var.gateway-name

  spec {
    http_route {
      action {
        target {
          virtual_service {
            virtual_service_name = aws_appmesh_virtual_service.main.name
          }
        }
      }

      match {
        prefix = "/${var.name}"
      }
    }
  }
}
