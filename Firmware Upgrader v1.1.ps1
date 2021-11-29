write-host @"  


Firmware Update v1.5
                                                                                     
                                                        
    Written By: Anthony Tippy

                                                                                                                                                           
"@

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#Import PSCRESTRON MODULE
Import-Module PSCrestron


$local = $PSScriptRoot

$update = @()
#create a new object to hold the restults data
$DeviceResultsData =@()      

#Initilize the table
$DeviceResultsData | Out-GridView -Title "Device Status Results"



#import filtereddevice file
try
	{
    $devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
	Write-Host ' '
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device IP.txt is in same directory as script!!!'
	}


#delete old data export file
remove-item -Path "$home\Firmware Update.csv" -erroraction silentlycontinue 

#Runspace Script Block
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {

###### Credentials #######

$username = 'USERNAME'
$password = 'PASSWORD'

##########################

#Firmware File Path Location (Can work with remote server as well)
$FW= "C:\\tsw-xx60_3.000.0038.001.puf"


    try {
        $d = $_
        
        #Load Firmware to Device
        Write-Host -f green "Updating $d firmware.  Do not Reboot!`n"

        #Firmware Update Process
        $update = Update-PUF -Device $d -Path $FW  -secure
        
        write-output $update
        $update | Export-Csv -Path "$home\Firmware Update.csv" -NoTypeInformation -append
        $update | Export-Csv -Path "$home\Firmware Update Log.csv" -NoTypeInformation -append
        
        }
    catch {
        $d = $_

        #Load Firmware to Device
        Write-Host -f green "Updating $d firmware [CUSTOM PASSWORD].  Do not Reboot!`n"

        #Firmware Update Process
        $update = Update-PUF -Device $d -Path $FW -username $username -password $password -secure
        
        write-output $update
        $update | Export-Csv -Path "$home\Firmware Update.csv" -NoTypeInformation -append
        $update | Export-Csv -Path "$home\Firmware Update Log.csv" -NoTypeInformation -append
    }

}-throttlelimit 30 -ShowProgress 

import-csv "$home\Firmware Update.csv" | out-gridview


#Total time of script
$stopwatch


Read-Host -Prompt “Press Enter to exit”

