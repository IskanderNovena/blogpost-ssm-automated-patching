# Maintenance Windows
resource "aws_ssm_maintenance_window" "install_window_monday" {
  enabled  = true
  name     = "patch-window-monday"
  schedule = local.patching.cron_patching_monday
  duration = 4
  cutoff   = 2
}

resource "aws_ssm_maintenance_window_task" "task_install_patches_monday" {
  window_id = aws_ssm_maintenance_window.install_window_monday.id
  name      = "install-patches-monday"
  task_type = "AUTOMATION"
  task_arn  = aws_ssm_document.patching_automation.name
  priority  = 5

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "PatchWindow"
        values = ["Monday"]
      }
    }
  }
}

resource "aws_ssm_maintenance_window" "install_window_wednesday" {
  enabled  = true
  name     = "patch-window-wednesday"
  schedule = local.patching.cron_patching_wednesday
  duration = 4
  cutoff   = 2
}

resource "aws_ssm_maintenance_window_task" "task_install_patches_wednesday" {
  window_id = aws_ssm_maintenance_window.install_window_wednesday.id
  name      = "install-patches-wednesday"
  task_type = "AUTOMATION"
  task_arn  = aws_ssm_document.patching_automation.name
  priority  = 5

  task_invocation_parameters {
    automation_parameters {
      document_version = "$LATEST"

      parameter {
        name   = "PatchWindow"
        values = ["Wednesday"]
      }
    }
  }
}
