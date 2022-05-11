resource "aws_appmesh_virtual_service" "main" {
  name      = var.hostname
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
  name      = "${var.name}-vn"
  mesh_name = var.mesh_id

  spec {
    listener {
      port_mapping {
        port     = var.host_port
        protocol = "tcp"
      }
    }

    service_discovery {
      dns {
        hostname = var.hostname
      }
    }
  }
}
