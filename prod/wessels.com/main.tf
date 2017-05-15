/**
 * Remote state configuration.
 * -------------------------------------------------------------------------------------------------------------------
 */
terraform {
  required_version = "0.9.3"
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
 * IAM Role for the Platform GraphQL Lambda Function.
 */
resource "aws_iam_role" "platform_api_graphql_lambda" {
  name = "platform_api_graphql_lambda"
  assume_role_policy = "${file("${path.module}/IAM/Lambda/PlatformAPIGraphQL/AssumeRolePolicy.json")}"
}

/**
 * IAM Role Policy for the Platform GraphQL Lambda Function.
 */
resource "aws_iam_role_policy" "platform_api_graphql_lambda" {
  name = "platform_api_graphql_lambda"
  role = "${aws_iam_role.platform_api_graphql_lambda.id}"
  policy = "${file("${path.module}/IAM/Lambda/PlatformAPIGraphQL/InlinePolicy.json")}"
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
}

/**
 * Create the Platform API.
 */
module "platform_api" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//platform-api"
  stage_name = "${var.platform_api_state_name}"
  stage_description = "${null_resource.platform_api_deployment.triggers.stage_description}"
}

/**
 * Create the Website endpoint for the Platform API.
 */
module "platform_api_website" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//aws-serverless-express"
  region = "${var.aws_region}"
  filename = "${path.module}/Lambda/platform-api-website/bundle.zip"
  function_name = "platform-api-website"
  role_arn = "${aws_iam_role.platform_api_website_lambda.arn}"
  handler = "index.handler"
  runtime = "nodejs6.10"
  rest_api_id = "${module.platform_api.rest_api_id}"
  rest_api_parent_resource_id = "${module.platform_api.rest_api_root_resource_id}"
  create_child_resource = false
}

/**
 * Create the GraphQL endpoint for the Platform API.
 */
module "platform_api_graphql" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//aws-serverless-express"
  region = "${var.aws_region}"
  filename = "${path.module}/Lambda/platform-api-graphql/bundle.zip"
  function_name = "platform-api-graphql"
  role_arn = "${aws_iam_role.platform_api_graphql_lambda.arn}"
  handler = "index.handler"
  runtime = "nodejs6.10"
  rest_api_id = "${module.platform_api.rest_api_id}"
  rest_api_parent_resource_id = "${module.platform_api.rest_api_root_resource_id}"
  create_child_resource = true
  child_resource_path = "graphql"
}

/**
 * Create the S3 Bucket and Endpoint for the Platform Resources. TODO Files need to be copied manually at the moment.
 */
module "platform_bucket_website_resources" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//aws-s3-website"
  bucket_name = "wessels.nz"
}

/**
 * Create the CloudFront Distribution for the Platform Website.
 */
module "platform_distribution" {
  source = "git::git@github.com:wessels-nz/infrastructure-modules.git//platform-distribution"
  aliases = ["${var.platform_domain_name}"]
  root_origin_id = "platform_api_website"
  root_origin_domain_name = "${module.platform_api.deployment_invoke_url}"
  resource_origin_id = "platform_s3_website"
  resource_origin_domain_name = "${module.platform_bucket_website_resources.website_endpoint}"
  domain_certificate_arn = "${var.platform_domain_certificate_arn}"
}

/**
 * Dependency Helpers
 * -------------------------------------------------------------------------------------------------------------------
 */

/**
 * Dependency Helper to ensure that the API Deployment happens after all API Resources have been created.
 */
resource "null_resource" "platform_api_deployment" {
  triggers {
    stage_description = "${var.platform_api_state_description}"
  }
  depends_on = ["module.platform_api_website", "module.platform_api_graphql"]
}
