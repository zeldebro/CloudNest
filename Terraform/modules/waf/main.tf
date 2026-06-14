# =========================================================
# WAFv2 Web ACL (REGIONAL - for ALB)
# Rules: CommonRuleSet + IpReputationList + rate limit 2000/5min
# Attach to the controller-created ALB via the Ingress annotation:
#   alb.ingress.kubernetes.io/wafv2-acl-arn = <this web_acl arn>
# =========================================================

# IP allowlist - put YOUR laptop/office IP here (CIDR, e.g. "1.2.3.4/32").
# Used by the priority-0 allow rule so your IP bypasses all the block rules.
resource "aws_wafv2_ip_set" "allowlist" {
  name               = "${var.project}-${var.environment}-allowlist"
  description        = "Trusted IPs that bypass WAF block rules"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.allowed_ips
}

resource "aws_wafv2_web_acl" "cloudnest" {
  name        = "${var.project}-${var.environment}-web-acl"
  description = "CloudNest WAF: common rules + IP reputation + rate limit"
  scope       = "REGIONAL" # REGIONAL = ALB/API GW; CLOUDFRONT only for CDN

  # We ALLOW by default and let the rules below BLOCK bad traffic
  default_action {
    allow {}
  }

  # --- Rule 0: ALLOWLIST - trusted IPs skip every rule below (terminating allow) ---
  # Only rendered when you actually provide allowed_ips.
  dynamic "rule" {
    for_each = length(var.allowed_ips) > 0 ? [1] : []
    content {
      name     = "IpAllowlist"
      priority = 0

      action {
        allow {}
      }

      statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.allowlist.arn
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "IpAllowlist"
        sampled_requests_enabled   = true
      }
    }
  }

  # --- Rule 1: AWS Managed Common Rule Set (OWASP-style protections) ---
  rule {
    name     = "CommonRuleSet"
    priority = 1

    # managed groups use override_action (none = keep the group's own actions)
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # --- Rule 2: Amazon IP Reputation List (blocks known-bad IPs) ---
  rule {
    name     = "IpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IpReputationList"
      sampled_requests_enabled   = true
    }
  }

  # --- Rule 3: Rate limit - 2000 requests / 5 min per IP (window is fixed at 5m) ---
  rule {
    name     = "RateLimit"
    priority = 3

    # our own rule uses action (not override_action) -> BLOCK over the limit
    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimit"
      sampled_requests_enabled   = true
    }
  }

  # ACL-level metrics (required)
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-web-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name = "${var.project}-${var.environment}-web-acl"
  }
}

