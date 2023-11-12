# SSM Documents
resource "aws_ssm_document" "patching_stop_components" {
  name          = "Patching-StopComponents"
  document_type = "Command"
  target_type   = "/AWS::EC2::Instance"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Patching Pre-install Stop Components Document"
    parameters = {
      ServerRole = {
        type        = "String"
        description = "Role of the server (Web, Middleware, Database, None)"
        default     = "None"
        allowedValues = [
          "Web",
          "Middleware",
          "Database",
          "None",
        ]
      }
    }
    mainSteps = [
      {
        action = "aws:runPowerShellScript"
        name   = "StopComponents"
        precondition = {
          StringEquals = [
            "platformType",
            "Windows"
          ]
        }
        inputs = {
          runCommand = split("\n", file("${path.cwd}/powershell_scripts/Stop-Components.ps1"))
        }
      }
    ]
  })
}

resource "aws_ssm_document" "patching_start_components" {
  name          = "Patching-StartComponents"
  document_type = "Command"
  target_type   = "/AWS::EC2::Instance"

  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Patching Post-install Start Components Document"
    parameters = {
      ServerRole = {
        type        = "String"
        description = "Role of the server (Web, Middleware, Database, None)"
        default     = "None"
        allowedValues = [
          "Web",
          "Middleware",
          "Database",
          "None",
        ]
      }
    }
    mainSteps = [
      {
        action = "aws:runPowerShellScript"
        name   = "StartComponents"
        precondition = {
          StringEquals = [
            "platformType",
            "Windows"
          ]
        }
        inputs = {
          runCommand = split("\n", file("${path.cwd}/powershell_scripts/Start-Components.ps1"))
        }
      }
    ]
  })
}

resource "aws_ssm_document" "patching_automation" {
  name            = "Patching-Automation"
  document_type   = "Automation"
  document_format = "YAML"

  content = <<EOT
description: |-
  # Patching Automation

  This script provides a staged patching experience. Services are stopped in a specific order on specific instances after which patching is run, and services are started again on servers in reverse order.
schemaVersion: '0.3'
parameters:
  PatchWindow:
    type: String
    allowedValues:
      - Monday
      - Wednesday
    description: Patch-window to run for. Determines which servers are affected.
mainSteps:
  - name: StopWebServerServices
    action: 'aws:runCommand'
    inputs:
      DocumentName: ${aws_ssm_document.patching_stop_components.name}
      Targets:
        - Key: 'tag:ServerRole'
          Values:
            - Web
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        ServerRole: Web
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Stop the services on the web servers
    nextStep: StopMiddlewareServices
    onFailure: 'step:StartWebServerServices'
  - name: StopMiddlewareServices
    action: 'aws:runCommand'
    inputs:
      DocumentName: ${aws_ssm_document.patching_stop_components.name}
      Targets:
        - Key: 'tag:ServerRole'
          Values:
            - Middleware
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        ServerRole: Middleware
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Stop the services on the middleware servers
    nextStep: StopDatabaseServices
    onFailure: 'step:StartMiddlewareServices'
  - name: StopDatabaseServices
    action: 'aws:runCommand'
    inputs:
      DocumentName: ${aws_ssm_document.patching_stop_components.name}
      Targets:
        - Key: 'tag:ServerRole'
          Values:
            - Database
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        ServerRole: Database
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Stop the services on the database servers
    nextStep: PatchServers
    onFailure: 'step:StartDatabaseServices'
  - name: PatchServers
    action: 'aws:runCommand'
    inputs:
      DocumentName: AWS-RunPatchBaseline
      Targets:
        # Uncomment the following lines to only patch specific server-roles
        # - Key: 'tag:ServerRole'
        #   Values:
        #     - Web
        #     - Middleware
        #     - Database
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        Operation: Install
        RebootOption: RebootIfNeeded
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Patch the servers
    nextStep: StartDatabaseServices
    onFailure: Abort
  - name: StartDatabaseServices
    action: 'aws:runCommand'
    inputs:
      DocumentName: ${aws_ssm_document.patching_start_components.name}
      Targets:
        - Key: 'tag:ServerRole'
          Values:
            - Database
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        ServerRole: Database
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Start the services on the database servers
    nextStep: StartMiddlewareServices
    onFailure: Abort
  - name: StartMiddlewareServices
    action: 'aws:runCommand'
    inputs:
      DocumentName: ${aws_ssm_document.patching_start_components.name}
      Targets:
        - Key: 'tag:ServerRole'
          Values:
            - Middleware
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        ServerRole: Middleware
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Start the services on the middleware servers
    nextStep: StartWebServerServices
    onFailure: Abort
  - name: StartWebServerServices
    action: 'aws:runCommand'
    inputs:
      DocumentName: ${aws_ssm_document.patching_start_components.name}
      Targets:
        - Key: 'tag:ServerRole'
          Values:
            - Web
        - Key: 'tag:PatchWindow'
          Values:
            - '{{PatchWindow}}'
      Parameters:
        ServerRole: Web
      CloudWatchOutputConfig:
        CloudWatchLogGroupName: ${aws_cloudwatch_log_group.automated_patching.name}
        CloudWatchOutputEnabled: true
    description: Start the services on the web servers
    isEnd: true
EOT
}
