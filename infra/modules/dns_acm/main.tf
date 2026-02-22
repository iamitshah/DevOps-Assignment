variable "root_domain" { type = string }
variable "frontend_domain" { type = string }
variable "api_domain" { type = string }

data "aws_route53_zone" "zone" {
  name         = var.root_domain
  private_zone = false
}

# API cert in ap-south-1
resource "aws_acm_certificate" "api" {
  domain_name       = var.api_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "api_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "api" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for r in aws_route53_record.api_validation : r.fqdn]
}

# CloudFront cert must be in us-east-1
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "frontend" {
  provider          = aws.use1
  domain_name       = var.frontend_domain
  validation_method = "DNS"
}

resource "aws_route53_record" "frontend_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options :
    dvo.domain_name => {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  }
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.use1
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for r in aws_route53_record.frontend_validation : r.fqdn]
}

output "zone_id" { value = data.aws_route53_zone.zone.zone_id }
output "api_cert_arn" { value = aws_acm_certificate_validation.api.certificate_arn }
output "frontend_cert_arn" { value = aws_acm_certificate_validation.frontend.certificate_arn }
