# Data-sources
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  patching = {
    # CRON notation, see https://docs.aws.amazon.com/systems-manager/latest/userguide/reference-cron-and-rate-expressions.html#reference-cron-and-rate-expressions-maintenance-window
    cron_patching_monday    = "cron(0 30 0 ? * MON *)"
    cron_patching_wednesday = "cron(0 30 0 ? * WED *)"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = "Automated Patching with SSM"
      ManagedBy = "Terraform"
    }
  }
}
