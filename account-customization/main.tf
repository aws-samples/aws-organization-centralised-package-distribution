data "aws_iam_policy_document" "administration_assume_role_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = [
      "resource-groups:ListGroupResources",
      "tag:GetResources",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2messages:GetEndpoint",
      "ec2messages:FailMessage",
      "ec2messages:AcknowledgeMessage",
      "ec2messages:SendReply",
      "ec2messages:GetMessages",
      "organizations:ListAccountsForParent",
      "organizations:ListOrganizationalUnitsForParent",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/SystemsManager-AutomationExecutionRole",
    ]
  }
  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/SystemsManager-AutomationAdministrationRole",
    ]
  }
}

resource "aws_iam_role" "systemsmanager_execution_role" {
  name = "SystemsManager-AutomationAdministrationRole"
  path = "/"
  inline_policy {
    name   = "automation-administration-policy"
    policy = data.aws_iam_policy_document.this.json
  }
  assume_role_policy = data.aws_iam_policy_document.administration_assume_role_policy_document.json
}

resource "aws_ssm_document" "software_package_distributor" {
  name            = "AddSoftwarePackageToDistributor"
  document_format = "JSON"
  document_type   = "Automation"
  content         = data.local_file.software_package_distributor.content
}

resource "aws_ssm_document" "distribute_software_package" {
  name            = "DistributeSoftwarePackage"
  document_format = "JSON"
  document_type   = "Automation"
  content         = data.local_file.distribute_software_package.content
}

resource "aws_s3_object" "pacakge_object" {
  bucket = aws_s3_bucket.package_bucket.id
  key    = var.package_name
  source = "${path.module}/${var.package_name}"
  etag   = data.archive_file.package_archieve_file.output_sha
}

resource "local_file" "pacakge_manifest_file" {
  content  = templatefile("${path.module}/distribution-manifest.json",{
    calculated_sha = data.archive_file.package_archieve_file.output_sha
    package_name=var.package_name,
    package_version=var.package_version
  })
  filename = "${path.module}/manifest.json"
}

resource "aws_s3_object" "pacakge_manifest_object" {
  bucket = aws_s3_bucket.package_bucket.id
  key    = "manifest.json"
  source = "${path.module}/manifest.json"
  etag   = local_file.pacakge_manifest_file.content_base64sha512
}

resource "aws_s3_bucket" "package_bucket" {
  bucket = var.package_bucket_name
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.package_bucket.id
  policy = data.aws_iam_policy_document.package_bucket_policy.json
}