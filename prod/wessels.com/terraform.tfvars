/**
 * AWS Provider
 * -------------------------------------------------------------------------------------------------------------------
 */
aws_region = "us-east-1"
aws_profile = "prod-wessels-nz"

/**
 * Platform Domain
 * -------------------------------------------------------------------------------------------------------------------
 */
environment = "prod/wessels.nz"
platform_domain_name = "wessels.nz"
email_domain_verification_cname_name = "zb14701019"
email_domain_verification_cname_value = "zmverify.zoho.com"
email_mx_records = ["10 mx.zoho.com", "20 mx2.zoho.com"]

platform_domain_certificate_arn = "arn:aws:acm:us-east-1:621434728682:certificate/2ec02fde-8e38-4970-84d0-bcadf1f726ca"

/**
 * Platform API
 * -------------------------------------------------------------------------------------------------------------------
 */
platform_api_state_name = "prod"
platform_api_state_description = "production"
