resource "aws_appmesh_mesh" "main" {
  name = "${var.name}-mesh"

  //TODO: Remove this after the Logiq push issue is sorted
  spec {
    egress_filter {
      type = "ALLOW_ALL"
    }
  }
}
