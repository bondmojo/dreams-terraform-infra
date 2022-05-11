resource "aws_appmesh_virtual_gateway" "main" {
  name      = "${var.name}-gateway"
  mesh_name = var.mesh_id

  spec {
    listener {
      port_mapping {
        port     = 8080
        protocol = "http"
      }
    }
  }
}
