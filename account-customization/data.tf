data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_organizations_organization" "org_data" {}

data "local_file" "software_package_distributor" {
  filename = "${path.module}/add-software-package-distributor.tpl"
}

data "local_file" "distribute_software_package" {
  filename = "${path.module}/software-package-distributor.tpl"
}

data "archive_file" "package_archieve_file" {
  type        = "zip"
  source_dir  = "${path.module}/package"
  output_path = "${path.module}/${var.package_name}"
}


data "aws_iam_policy_document" "package_bucket_policy" {
  statement {
    sid = "AWSBucketPermissionsCheck"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.package_bucket.arn,
      "${aws_s3_bucket.package_bucket.arn}/*"
    ]
    condition {
      test = "StringEquals"
      values = [
        data.aws_organizations_organization.org_data.id
      ]
      variable = "aws:PrincipalOrgID"
    }
  }
}