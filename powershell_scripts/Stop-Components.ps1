function Check-MiddlewareServicesState {
  [CmdletBinding()]
  Param()

  # Your code to check if middleware services have stopped goed here.
  # Make sure to return a boolean.
  return $true
}

try {
  $_serverRole = "{{ServerRole}}" # This is an SSM variable reference
  $_fqdn = "$((Get-WmiObject Win32_ComputerSystem).DNSHostName).$((Get-WmiObject Win32_ComputerSystem).Domain)"
  Write-Output "[INF] Stopping Components on $($_fqdn) with server role '$_serverRole'"

  switch ($_serverRole) {
    Web { 
      Write-Output "[INF] Setting Startup Type for web services to Manual and stopping them."

      Get-Service iisadmin | Where-Object StartType -eq "Automatic" | Set-Service -StartupType Manual -Status Stopped
      Get-Service w3svc | Where-Object StartType -eq "Automatic" | Set-Service -StartupType Manual -Status Stopped
    }
    Middleware {  
      Write-Output "[INF] Doing stuff to stop middleware services."

      # Your code here
 
      Write-Output "[INF] Making sure all middleware services are stopped before continuing."
      $_middlewareServicesStopped = Check-MiddlewareServicesState
      while ($_middlewareServicesStopped -ne $true) {
        Write-Output "[DEB] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Not all middleware services have stopped yet. Waiting a little longer."
        Start-Sleep -Seconds 60
        $_middlewareServicesStopped = Check-MiddlewareServicesState
      }
      Write-Output "[INF] All middleware services have stopped. Continuing."
    }
    Database {  
      Write-Output "[INF] Setting Startup Type for all database services where the current StartType is Automatic to Manual and stopping them."

      Get-Service *sql* | Where-Object StartType -eq "Automatic" | Set-Service -StartupType Manual -Status Stopped
    }
    Default { }
  }
}
catch {
  Write-Output "[ERR] Failed to stop components!"
  Write-Error $Error[0] -ErrorAction Continue
  exit 1
}
