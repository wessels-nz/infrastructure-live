/**
 * AWS Provider
 * -------------------------------------------------------------------------------------------------------------------
 */
variable "aws_region" {
  type = "string"
  description = "The AWS region."
}
variable "aws_profile" {
  type = "string"
  description = "The AWS CLI profile."
}

/**
 * Platform Domain
 * -------------------------------------------------------------------------------------------------------------------
 */
variable "environment" {
  type = "string"
  description = "The environment name (prod/domain.com)."
}
variable "platform_domain_name" {
  type = "string"
  description = "The fully qualified platform domain name. (domain.com.)"
}
variable "email_domain_verification_cname_name" {
  type = "string"
  description = "The name of the CNAME record used by the email provider to verify the domain ownership."
}
variable "email_domain_verification_cname_value" {
  type = "string"
  description = "The value of the CNAME record used by the email provider to verify the domain ownership."
}
variable "email_mx_records" {
  type = "list"
  description = "The values of the MX record used to point to the email provider."
  default = []
}

/**
 * Platform API
 * -------------------------------------------------------------------------------------------------------------------
 */
variable "platform_api_state_name" {
  type = "string"
  description = "The Stage Name for the Platform API Deployment."
}
variable "platform_api_state_description" {
  type = "string"
  description = "The Stage Description for the Platform API Deployment."
}
