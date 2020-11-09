1### Crestron Toyota SuperScript V1.0  
###Script will call IP addresses from list and try to upgrade firmware version bas

# make sure the PSCrestron Cmdlets are loaded into PowerShell
Import-Module PSCrestron

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

# set username and password
$cUsername = "USERNAME"
$cPassword = "PASSWORD"

# declare an object to hold the results table
$ResultsTable =@()

# discover devices on the network
#$deviceList = Get-AutoDiscovery 

#load IP from TXT list
$deviceList = Get-Content (Join-Path $PSScriptRoot 'IP.txt')

#Firmware file location
$FW = (Join-Path $PSScriptRoot 'tsw-xx60_2.009.0122.001.puf')
$fname = 'tsw-xx60_2.009.0122.00.puf' #firmware file name

# for each device in the devicelist
foreach ($dev in $deviceList)
{ 
try {   
    # try to query the device a few different ways:
    # try ssh with username/password, then ssh no username, then ssh admin admin, then CTP
    # set $cMethod so we will know what worked later on in the script
        write-host $dev 'Trying SSH Password'
        write-host " " 
        $dVersionInfo = Get-VersionInfo -Device $dev -Secure -Username $cUsername -Password $cPassword  #normal ssh
        $cMethod = "SSH PW"

        if($dVersionInfo.ErrorMessage.Contains("Permission denied (password)"))   #wrong password, try the defaults
        {   write-host $dev 'Trying SSH default password'
            $dVersionInfo = Get-VersionInfo -Device $dev -Secure   #authentication not setup 
            $cMethod = "SSH Default"

            if($dVersionInfo.ErrorMessage.Contains("Permission denied (password)"))   #try admin admin
            {   write-host $dev 'Trying SSH admin admin'
                $dVersionInfo = Get-VersionInfo -Device $dev -Secure -Username "admin" -Password "admin" 
                $cMethod = "SSH admin"
            } 

        }
        
        if($dVersionInfo.ErrorMessage.Contains("Failed to find port 22 open"))   #device doesn't support ssh, try CTP
        {   write-host $dev 'Trying CTP defaults'
            $dVersionInfo = Get-VersionInfo -Device $dev -Username "admin" -Password "admin" -erroraction 'silentlycontinue'
            $cMethod = "CTP"
        }

        if($dVersionInfo.ErrorMessage.Contains("Failed to find port 41795 open"))   #device doesn't support ssh, try CTP
        {   write-host $dev 'Could not Connect'
            $cMethod = "ERROR"
        }
        }
catch{
$dVersionInfo.ErrorMessage.Contains("Failed to find port 41794 open")}

    #if control system category, query for CPU load
        If ($dVersionInfo.Device.Contains("10"))
            {

            #connect appropriately based on what we learned above
            if($cMethod.Contains("SSH PW"))
                {write-host '-Attempting Firmware Update: ' $FW
                $consoleSession = Send-CrestronFirmware -Device $dev -LocalFile $fw -Secure -username $cUsername -Password $cPassword -erroraction 'silentlycontinue'
                write-host '-Firmware uploaded to device'
                write-host '-Intiating PUF ALL Firmware update'
                $update = Invoke-CrestronCommand -Device $dev -Command 'PUF' -Secure -username $cUsername -Password $cPassword -ErrorAction SilentlyContinue
                write-host $update
                }
            elseif($cMethod.Contains("SSH Default"))
                {
                write-host '-Attempting Firmware Update: ' $FW
                $consoleSession = Send-CrestronFirmware -Device $dev -LocalFile $fw -Secure -erroraction 'silentlycontinue'
                write-host '-Firmware uploaded to device'
                Start-Sleep -s 5
                write-host '-Intiating PUF ALL Firmware update'
                $update = Invoke-CrestronCommand -Device $dev -Command 'PUF' -Secure -ErrorAction SilentlyContinue
                write-host $update
                }
            elseif($cMethod.Contains("SSH admin"))
                {write-host '-Attempting Firmware Update: ' $FW
                $consoleSession = Send-CrestronFirmware -Device $dev -LocalFile $fw -Secure -Username "admin" -Password "admin" -erroraction 'silentlycontinue'
                write-host '-Firmware uploaded to device'
                write-host '-Intiating PUF ALL Firmware update'
                $update = Invoke-CrestronCommand -Device $dev -Command 'PUF' -Secure -Username "admin" -Password "admin" -ErrorAction SilentlyContinue
                write-host $update
                }
           elseif($cMethod.Contains("MTR CTP"))
                {write-host '-Attempting Firmware Update: ' $FW
                $consoleSession = Send-CrestronFirmware -Device $dev -LocalFile $fw -Secure -Username "admin" -Password "sfb" -erroraction 'silentlycontinue'
                write-host '-Firmware uploaded to device'
                write-host '-Intiating PUF ALL Firmware update'
                $update = Invoke-CrestronCommand -Device $dev -Command 'PUF' -Secure -Username "admin" -Password "sfb" -ErrorAction SilentlyContinue
                write-host $update
                }
           elseif($cMethod.Contains("ERROR"))
                {write-host '-Attempting Firmware Update: ' $FW
                $consoleSession = write-host "ERROR SKIPPED"
                }
            else
                {write-host '-Attempting Firmware Update: ' $FW
                $consoleSession = Send-CrestronFirmware -Device $dev -LocalFile $fw -erroraction 'silentlycontinue'
                write-host '-Firmware uploaded to device'
                write-host '-Intiating PUF ALL Firmware update'
                $update = Invoke-CrestronCommand -Device $dev -Command 'PUF' -ErrorAction SilentlyContinue
                write-host $update
                }
            if($cMethod.contains("ERROR")){ }
            
            #Error Handling - If ErrorMessage clears out Program and DHCP info to prevent false info
            if ($dVersionInfo.ErrorMessage.Contains(" ")){
            $dDHCP = " "
            #$cMethod = "Error"
            $dCPULoad =" "}

            #Add program Results
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Firmware Upgrade" -NotePropertyValue $consoleSession -erroraction 'silentlycontinue'

            #Add Connection Method Log
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Auth Method" -NotePropertyValue $cMethod -erroraction 'silentlycontinue'
            } 

    # not reporting back as a control system
        ELSE
            {
            $dCPULoad = 'N/A'
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Program" -NotePropertyValue $dCPULoad -erroraction 'silentlycontinue'
            }
    

    # Add entry to the table
    #-----------------------
        $ResultsTable += $dVersionInfo

}

# Return the results
#-------------------
$Error | Out-File (Join-Path $PSScriptRoot 'Firmware ERROR LOG.txt')
$ResultsTable | Out-GridView
$ResultsTable | Select-Object -Property "Device", "Hostname", "Prompt", "Serial", "MACAddress", "VersionOS", "Category", "Set Static IP", "Firmware Upgrade", "Auth Method", "ErrorMessage" | Export-Csv -Path $PSScriptRoot\"Firmware Upgrade Results.csv" -NoTypeInformation

#Total time of script
$stopwatch