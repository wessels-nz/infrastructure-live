/**
 * Remote state configuration.
 * -------------------------------------------------------------------------------------------------------------------
 */
terraform {
  required_version = "0.9.5"
  backend "s3" {
    bucket = "wessels.nz.terraform"
    key = "prod.wessels.nz.tfstate"
    region = "us-east-1"
    profile = "prod-wessels-nz"
    lock_table = "prod-wessels-nz-tflock"
  }
}

/**
 * AWS Provider.
 * -------------------------------------------------------------------------------------------------------------------
 */
provider "aws" {
  region = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

/**
 * IAM
 * -------------------------------------------------------------------------------------------------------------------
 */

/**
 * IAM Role to enable APIGateway logging to CloudWatch.
 */
resource "aws_iam_role" "platform_api_gateway_account" {
  name = "platform_api_gateway_account"
  assume_role_policy = "${file("${path.module}/IAM/CloudWatch/APIGateway/AssumeRolePolicy.json")}"
}

/**
 * IAM Role Policy to enable APIGateway logging to CloudWatch.
 */
resource "aws_iam_role_policy" "platform_api_gateway_account" {
  name = "platform_api_gateway_account"
  role = "${aws_iam_role.platform_api_gateway_account.id}"
  policy = "${file("${path.module}/IAM/CloudWatch/APIGateway/InlinePolicy.json")}"
}

/**
 * IAM Role for the Platform Website Lambda Function.
 */
resource "aws_iam_role" "platform_api_website_lambda" {
  name = "platform_api_website_lambda"
  assume_role_policy = "${file("${path.module}/IAM/Lambda/PlatformAPIWebsite/AssumeRolePolicy.json")}"
}

/**
 * IAM Role Policy for the Platform Website Lambda Function.
 */
resource "aws_iam_role_policy" "platform_api_website_lambda" {
  name = "platform_api_website_lambda"
  role = "${aws_iam_role.platform_api_website_lambda.id}"
  policy = "${file("${path.module}/IAM/Lambda/PlatformAPIWebsite/InlinePolicy.json")}"
}

/**
 * API Gateway
 * -------------------------------------------------------------------------------------------------------------------
 */

/**
 * Enable APIGateway logging to CloudWatch.
 */
resource "aws_api_gateway_account" "platform_api" {
  cloudwatch_role_arn = "${aws_iam_role.platform_api_gateway_account.arn}"
}

/**
 * Modules
 * -------------------------------------------------------------------------------------------------------------------
 */

/**
 * Create the Platform Domain.
 */
module "platform_domain" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//platform-domain"
  environment = "${var.environment}"
  platform_domain_name = "${var.platform_domain_name}"
  email_domain_verification_cname_name = "${var.email_domain_verification_cname_name}"
  email_domain_verification_cname_value = "${var.email_domain_verification_cname_value}"
  email_mx_records = "${var.email_mx_records}"
  cloudfront_distribution_domain_name = "${module.platform_api.cloudfront_distribution_domain_name}"
  cloudfront_distribution_hosted_zone_id = "${module.platform_api.cloudfront_distribution_hosted_zone_id}"
}

/**
 * Create the Platform API.
 */
module "platform_api" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//platform-api"
  region = "${var.aws_region}"
  stage_name = "${var.platform_api_state_name}"
  stage_description = "${var.platform_domain_name}"
  website_lambda_filename = "${path.module}/Lambda/PlatformApiWebsite/bundle.zip"
  website_lambda_role_arn = "${aws_iam_role.platform_api_website_lambda.arn}"
  domain_name = "${var.platform_domain_name}"
  domain_certificate_arn = "${var.platform_domain_certificate_arn}"
}
