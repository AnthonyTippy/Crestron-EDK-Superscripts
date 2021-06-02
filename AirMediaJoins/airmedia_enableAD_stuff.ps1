# minimum required version
#Requires -Version 5
Set-StrictMode -Version Latest

# import the library
Import-Module PSCrestron

# get a list of devices
# this can be by AutoDiscovery, Excel, or a text file
$devs = Get-AutoDiscovery -Pattern 'AM-200'

# execute the list in parallel
# notes :
#   no error checking
#   no processing of the results
#   adjust throttle limit based on network and PC load
#   assumes same credentials for all devices
$devs | Invoke-RunspaceJob -ThrottleLimit 8 -ScriptBlock {
        Invoke-CrestronCommand -Device $_.IP -Command 'ver' `
            -Secure -Username 'admin' -Password 'admin'
    }
	
	
	
	
$devs = Get-Content -Path (Join-Path $PSScriptRoot 'devices.txt')








<#This script will run command on the devices
Before executing:
1. Define devices in: devices.txt
#>

Write-Host "Job started:", (Get-Date) -ForegroundColor Yellow

# import libraries
Write-Host 'Importing libraries' -ForegroundColor DarkYellow
Import-Module PSCrestron

# import file
try
{
$devs = @(Get-Content -Path (Join-Path $PSScriptRoot\ScriptInput 'devices.txt'))
Write-Host 'Obtaining list of devices' -ForegroundColor DarkYellow
}
catch
{
Write-Host 'Error Obtaining list of devices' -ForegroundColor Red
}

foreach ($d in $devs)
{
Write-host "$d" -ForegroundColor DarkYellow
}

# define variables

# Prompt user for variables
$command = Read-Host "Enter command to send to devices (If needs confirmation use this format: command , Y)"
$command -split','
$username = Read-Host "Enter the username (leave blank for unsecured)"
$password = Read-Host "Enter password (leave blank for unsecured)"
$port = Read-Host "Enter port number (22 for SSH, 41795 for CTP)"


# ask for confirmation

$confirmation = Read-Host "Do you want to send command: $command to these devices (y or n)"

# loop for each device

if ($confirmation -eq 'y')
{
switch ($port)
{
22
{
# loop for each device to obtain information
foreach ($d in $devs)
{
Write-Host 'Sending command: '$command' to:' $d -ForegroundColor green
Invoke-CrestronCommand -Device $d -Command $command -Password "$password" -Port $port -Secure -Username $username -ErrorAction SilentlyContinue
}
}



41795
{
# loop for each device to obtain information
foreach ($d in $devs)
{
Write-Host 'Sending command: '$command' to:' $d -ForegroundColor green
Invoke-CrestronCommand -Device $d -Command $command -ErrorAction SilentlyContinue
}
}
}
}
else
{
}



Write-Host "Job completed:", (Get-Date) -ForegroundColor Yellow



