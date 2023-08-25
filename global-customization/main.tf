data "aws_iam_policy_document" "assume_role_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }

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
      "ec2messages:GetMessages"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:role/SystemsManager-AutomationExecutionRole",
    ]
  }
}

resource "aws_iam_role" "systemsmanager_execution_role" {
  name = "SystemsManager-AutomationExecutionRole"
  path = "/"
  inline_policy {
    name   = "cross-account-assume-role-policy"
    policy = data.aws_iam_policy_document.this.json
  }
  managed_policy_arns = ["arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonSSMAutomationRole"]
  assume_role_policy  = data.aws_iam_policy_document.assume_role_policy_document.json
}