# Save this script as Aberakadebera.ps1 and run with elevated privileges (if possible).

# Output file
$outputFile = "Aberakadebera_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-Log {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $message"
    Write-Output $logMessage | Out-File -Append -FilePath $outputFile
    Write-Host $logMessage
}

function Handle-Error {
    param (
        [string]$operation,
        [System.Management.Automation.ErrorRecord]$error
    )
    Write-Log "Error during $operation - $($error.Exception.Message)"
}

Write-Log "===== Aberakadebera for Windows Started ====="

# Basic System Information
try {
    Write-Log "Gathering system information..."
    Write-Log "Hostname: $(hostname)"
    Write-Log "Operating System: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)"
    Write-Log "OS Architecture: $(if($([System.Environment]::Is64BitOperatingSystem)) { '64-bit' } else { '32-bit' })"
    Write-Log "OS Build: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber)"
    Write-Log "System Manufacturer: $(Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty Manufacturer)"
    Write-Log "System Model: $(Get-CimInstance Win32_ComputerSystem | Select-Object -ExpandProperty Model)"
} catch {
    Handle-Error -operation "Basic System Information" -error $_
}

# Network Information
try {
    Write-Log "Gathering network information..."
    Get-NetIPAddress | ForEach-Object {
        Write-Log "IP Address: $($_.IPAddress), InterfaceAlias: $($_.InterfaceAlias), AddressFamily: $($_.AddressFamily)"
    }
    Get-NetTCPConnection | ForEach-Object {
        Write-Log "Local Address: $($_.LocalAddress):$($_.LocalPort) -> Remote Address: $($_.RemoteAddress):$($_.RemotePort), State: $($_.State)"
    }
} catch {
    Handle-Error -operation "Network Information" -error $_
}

# User Information
try {
    Write-Log "Enumerating users..."
    Get-LocalUser | ForEach-Object {
        Write-Log "User: $($_.Name), Enabled: $($_.Enabled), LastLogon: $($_.LastLogon)"
    }
} catch {
    Handle-Error -operation "User Information" -error $_
}

# Group Information
try {
    Write-Log "Enumerating groups..."
    Get-LocalGroup | ForEach-Object {
        Write-Log "Group: $($_.Name)"
    }
} catch {
    Handle-Error -operation "Group Information" -error $_
}

# Services
try {
    Write-Log "Gathering service information..."
    Get-Service | Where-Object {$_.Status -eq "Running"} | ForEach-Object {
        Write-Log "Service: $($_.DisplayName), Name: $($_.Name), Status: $($_.Status)"
    }
} catch {
    Handle-Error -operation "Service Information" -error $_
}

# Installed Applications
try {
    Write-Log "Enumerating installed applications..."
    Get-CimInstance Win32_Product | ForEach-Object {
        Write-Log "App: $($_.Name), Version: $($_.Version)"
    }
} catch {
    Handle-Error -operation "Installed Applications" -error $_
}

# Open Shares
try {
    Write-Log "Enumerating shared folders..."
    Get-SmbShare | ForEach-Object {
        Write-Log "Share: $($_.Name), Path: $($_.Path), Description: $($_.Description)"
    }
} catch {
    Handle-Error -operation "Shared Folders" -error $_
}

# Firewall Configuration
try {
    Write-Log "Checking firewall rules..."
    Get-NetFirewallRule -Enabled True | ForEach-Object {
        Write-Log "Rule: $($_.DisplayName), Action: $($_.Action), Direction: $($_.Direction)"
    }
} catch {
    Handle-Error -operation "Firewall Configuration" -error $_
}

# Security Policies
try {
    Write-Log "Retrieving security policies..."
    secedit /export /cfg "$env:temp\secpol.cfg" > $null
    $securityConfig = Get-Content "$env:temp\secpol.cfg"
    Write-Log $securityConfig
    Remove-Item "$env:temp\secpol.cfg" -Force
} catch {
    Handle-Error -operation "Security Policies" -error $_
}

# Scheduled Tasks
try {
    Write-Log "Enumerating scheduled tasks..."
    Get-ScheduledTask | ForEach-Object {
        Write-Log "Task: $($_.TaskName), State: $($_.State), LastRunTime: $($_.LastRunTime)"
    }
} catch {
    Handle-Error -operation "Scheduled Tasks" -error $_
}

# Local Password Policies
try {
    Write-Log "Retrieving password policies..."
    $policies = net accounts
    Write-Log $policies
} catch {
    Handle-Error -operation "Password Policies" -error $_
}

Write-Log "===== Aberakadebera for Windows Completed ====="
Write-Log "Report saved to: $outputFile"
