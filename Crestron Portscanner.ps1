

<#
.SYNOPSIS
  Asyncronously scans devices in IP.txt file across multiple ports. 

.DESCRIPTION
  Script will connect to up to 30 devices simultaneously scan for various open ports



.INPUTS
  - IP.txt text file containing IP addresses of devices (One per line)

. REQUIREMENTS
    -PSCrestron module must be installed (Crestron EDK)
    -IP.txt file for IP's

.OUTPUTS
  C:\PortScan Results.csv

.NOTES
  Version:        1.0
  Author:         Anthony Tippy
  Creation Date:  08/04/21
  Purpose/Change: Initial script development
  
.EXAMPLE
  Enter IP's to scan into IP.txt file in root script directory --> Run script --> Script will scan each device for common ports as well as Crestron specific ports
#>

write-host @"  



   ______               __  _____                                 
  / ____/_______  _____/ /_/ ___/_________ _____  ____  ___  _____
 / /   / ___/ _ \/ ___/ __/\__ \/ ___/ __ `/ __ \/ __ \/ _ \/ ___/
/ /___/ /  /  __(__  ) /_ ___/ / /__/ /_/ / / / / / / /  __/ /    
\____/_/   \___/____/\__//____/\___/\__,_/_/ /_/_/ /_/\___/_/     
                                                                  

                                                                                                               
           Written By: Anthony Tippy                                                                                                        

"@


#Crestron PortScanner
import-module pscrestron

Remove-Item -Path ("$home\PortScan Results.csv") -Force -erroraction silentlycontinue

try
	{
    $devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
	Write-Host ' '
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device IP.txt is in same directory as script!!!'
	}


Invoke-RunspaceJob -InputObject $devs -ScriptBlock {
    $d = $_
    Write-host -f green "scanning $d`n"
    #$portscan = Test-crestronport -device $d -port (20, 21, 22, 23, 25, 80, 443,143, 3389,53, 67,68, 110, 41794, 41795, 41796,41796,123, 161, 49500, 5985,5986) -showprogress
    $portscan = Test-crestronport -device $d -port (21, 22, 23, 25, 80, 443, 41794, 41795, 41797) -showprogress
    $portscan | Export-CSV -Path "$home\PortScan Results.csv" -NoTypeInformation -Append
} -ThrottleLimit 50

import-csv "$home\PortScan Results.csv" | out-gridview -Title "Open Ports"

$portscan | Out-GridView
