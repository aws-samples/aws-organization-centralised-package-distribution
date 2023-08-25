variable "package_bucket_name" {
  type        = string
  description = "Name of S3 bucekt which contains pacakge distribution file"
  default     = "centralized-distribution-pacakge"
}

variable "package_name" {
  type        = string
  description = "Name fo the package distribution"
  default     = "aws-cli.zip"
}

variable "package_version" {
  type = string
  default = "1.0"
  description = "Pacakge version of installer"
}

variable "target_Accounts" {
  type    = list(string)
  default = []
}

variable "target_Regions" {
  type    = list(string)
  default = []
}

variable "action" {
  type    = string
  default = ""
}

variable "association_targets" {
  type = list(object({
    key    = string
    values = list(string)
  }))
  default = [
    {
      key    = "tag:Name"
      values = ["ssm"]
    }
  ]
}

variable "association_name" {
  type    = string
  default = "test_AddSoftwarePackageToDistributor"
}
