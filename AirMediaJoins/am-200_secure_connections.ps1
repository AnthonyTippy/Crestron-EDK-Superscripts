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
    Get-Content -Path 'd:\Crestron Scripts\devices.txt'
    help Get-Content -Full