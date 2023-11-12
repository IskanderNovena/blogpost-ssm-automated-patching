try {
  $_serverRole = "{{ServerRole}}" # This is an SSM variable reference
  $_fqdn = "$((Get-WmiObject Win32_ComputerSystem).DNSHostName).$((Get-WmiObject Win32_ComputerSystem).Domain)"
  Write-Output "[INF] Starting Components on $($_fqdn) with server role '$_serverRole'"

  switch ($_serverRole) {
    Web { 
      Write-Output "[INF] Setting Startup Type for web services where the current StartType is Manual to Automatic and starting them."

      Get-Service iisadmin | Where-Object StartType -eq "Manual" | Set-Service -StartupType Automatic -Status Running
      Get-Service w3svc | Where-Object StartType -eq "Manual" | Set-Service -StartupType Automatic -Status Running
    }
    Middleware {  
      Write-Output "[INF] Doing stuff to enable the middleware services to start."

      # Your code here
    }
    Database {  
      Write-Output "[INF] Setting Startup Type for all database services where the current StartType is Manual to Automatic and starting them."
      Get-Date -Format "yyyy-MM-dd HH:mm:ss"
      
      Get-Service *sql* | Where-Object StartType -eq "Manual" | Set-Service -StartupType Automatic -Status Running

      Write-Output "[INF] Making sure all database services are started before continuing."
      # When there are no services that match the name, the while loop will not be entered.
      while (Get-Service *sql* | Where-Object Status -ne Running) {
        Write-Output "[DEB] [$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] Not all database services have started yet. Waiting a little longer."
        Start-Sleep -Seconds 60
      }
    }
    Default { }
  }
}
catch {
  Write-Output "[ERR] Failed to start components!"
  Write-Error $Error[0] -ErrorAction Continue
  exit 1
}
