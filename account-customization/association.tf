resource "aws_ssm_association" "example" {
  name             = "AddSoftwarePackageToDistributor"
  document_version = "$DEFAULT"
  parameters = {
    "targetAccounts"      = var.target_Accounts
    "targetRegions"       = var.target_Regions
    "action"              = var.action
    "installationType"    = "In-place update"
    "name"                = var.association_name
    "AutomationAssumeRole" = aws_iam_role.systemsmanager_execution_role.arn
    "bucketName"          = aws_s3_bucket.package_bucket.id
    "bucketPrefix"        = "/"
  }

  dynamic "targets" {
    for_each = var.association_targets
    content {
      key    = targets.value.key
      values = targets.value.values
    }
  }

  automation_target_parameter_name = "instanceId"
}
