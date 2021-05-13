
<#
.SYNOPSIS
  Script will connect to crestron devices from ip list and find other devices that they can beacon out to.

.DESCRIPTION
  CrestFinder IP Scanner intiates device discovery for each device in the IP.txt device list.  Script will gather info about Crestron devices.
  If no adjacent devices are found outside of host Crestron device, script will gather host device info and add it to list. When all device info has been gathered,
  script removes any possible duplicate IP addresses and exports to C:\Desktop\CrestFinder Results SORTED.csv.

.PARAMETER <Parameter_Name>
  None

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - IP.txt text file containing IP addresses of devices (One per line)

.OUTPUTS
  Results can be found at C:\Desktop\CrestFinder Results SORTED.csv

.NOTES
  Version:        1.6
  Author:         Anthony Tippy
  Creation Date:  05/13/2021
  Purpose/Change: Updates
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> Run Script--> script will output found and sorted devices to  C:\Desktop\CrestFinder Results SORTED.csv
#>


###Crestron Device Discovery Script
###Script will call IP addresses from list and gather device information via autodiscovery 
write-host @"  



 ██████╗██████╗ ███████╗███████╗████████╗███████╗██╗███╗   ██╗██████╗ ███████╗██████╗ 
██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██║████╗  ██║██╔══██╗██╔════╝██╔══██╗
██║     ██████╔╝█████╗  ███████╗   ██║   █████╗  ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝
██║     ██╔══██╗██╔══╝  ╚════██║   ██║   ██╔══╝  ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
╚██████╗██║  ██║███████╗███████║   ██║   ██║     ██║██║ ╚████║██████╔╝███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                      
    v1.6
    Written By: Anthony Tippy


                                                                                                                                                           
"@
#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

if (Get-Module -ListAvailable -Name PSCrestron) {
} 
else {
    Write-Host "PSCrestron Module Not Installed. Please Install PSCrestron Module and Try Again!"
    exit
}

# make sure the PSCrestron Cmdlets are loaded into PowerShell
Import-Module PSCrestron

#Delete old fILES
Remove-Item "$home\Desktop\CrestFinder Results.csv" -ErrorAction SilentlyContinue
Remove-Item "$home\Desktop\CrestFinder Results SORTED.csv" -ErrorAction SilentlyContinue


#load IP from TXT list
$devs = @(Get-Content (Join-Path $PSScriptRoot 'IP.txt'))

#Run Autodiscovery in parallel processes
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {

        #Credentials
        $username = 'USERNAME HERE'
        $password = 'PASSWORD HERE'
    try {
        $d = $_

        $DeviceResultItem = New-Object PSObject

        Write-host -f Green "[AutoDiscovery Default Password] Working on => $d `n" 

        $DeviceResultItem = Read-AutoDiscovery $d  -secure -ErrorAction "SilentlyContinue" | Select-Object -Property Device, IP, Hostname, Description
         
        $DeviceResultItem | export-csv -Path "$home\Desktop\CrestFinder Results.csv" -NoTypeInformation -Append

        if (([string]::IsNullOrEmpty($DeviceResultItem)))
            {write-host -f yellow "$d - Initial Discovery Did Not Find Any Other Devices --> Grabbing Device Info`n"
            $result = Get-AutoDiscovery -endpoint $d | Select-Object -Property Device, IP, Hostname, Description | Export-Csv -Path "$home\Desktop\CrestFinder Results.csv" -NoTypeInformation -append
            write-host $result}
        }
    Catch {
        Try{

        Write-host -f Green "[AutoDiscovery Custom Password] Working on => $d `n" 

        $DeviceResultItem = Read-AutoDiscovery $d -secure -username $username -password $password -ErrorAction "SilentlyContinue" | Select-Object -Property Device, IP, Hostname, Description

        $DeviceResultItem | export-csv -Path "$home\Desktop\CrestFinder Results.csv" -NoTypeInformation -Append

        if (([string]::IsNullOrEmpty($DeviceResultItem)))
            {write-host -f yellow "$d - Initial Discovery Did Not Find Any Other Devices --> Grabbing Device Info`n"
            $result = Get-AutoDiscovery -endpoint $d | Select-Object -Property Device, IP, Hostname, Description | Export-Csv -Path "$home\Desktop\CrestFinder Results.csv" -NoTypeInformation -append
            write-host $result}
        }

        Catch{
        write-host -f Red "$d Unable to connect`n`n"
        #$d | export-csv -Path (".\Desktop\CrestFinder Results.csv") -NoTypeInformation -Append
        }

        }

 } -throttlelimit 30 -ShowProgress
 

 #Remove Duplicate Entries
Import-Csv "$home\Desktop\CrestFinder Results.csv" | sort IP –Unique | export-csv "$home\Desktop\CrestFinder Results SORTED.csv" -NoTypeInformation -Force

#Delete Unneeded Duplicate Raw Output File
Remove-Item "$home\Desktop\CrestFinder Results.csv" -ErrorAction SilentlyContinue

import-csv "$home\Desktop\CrestFinder Results SORTED.csv" | out-gridview -Title "Total Discovered Devices"

Write-host -f Cyan "`n`nResults can be found at C:\Desktop\CrestFinder Results SORTED.csv"

#Total time of script
$stopwatch

Read-Host -Prompt “Press Enter to exit”
