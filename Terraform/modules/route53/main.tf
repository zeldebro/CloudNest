# =========================================================
# Route53 PRIVATE hosted zone - cloudnest.internal
# Private = it has a vpc{} block, so it ONLY resolves inside the linked VPC.
# Records pointing at the controller-created ALB are best managed by
# ExternalDNS (the ALB DNS name isn't known at Terraform plan time).
# =========================================================
resource "aws_route53_zone" "private" {
  name = var.zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  # Avoid destroy errors if ExternalDNS adds records into this zone
  force_destroy = true

  tags = {
    Name = "${var.project}-${var.environment}-${var.zone_name}"
  }
}

