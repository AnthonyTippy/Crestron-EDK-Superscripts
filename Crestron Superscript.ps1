### Crestron SuperScript V1.1   
###Script will call IP addresses from list and gather device information as well as program and DHCP state data

write-host @"  



 ██████╗██████╗ ███████╗███████╗████████╗██████╗  ██████╗ ███╗   ██╗                 
██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║                 
██║     ██████╔╝█████╗  ███████╗   ██║   ██████╔╝██║   ██║██╔██╗ ██║                 
██║     ██╔══██╗██╔══╝  ╚════██║   ██║   ██╔══██╗██║   ██║██║╚██╗██║                 
╚██████╗██║  ██║███████╗███████║   ██║   ██║  ██║╚██████╔╝██║ ╚████║                 
 ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝                 
                                                                                     
███████╗██╗   ██╗██████╗ ███████╗██████╗ ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗
██╔════╝██║   ██║██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝
███████╗██║   ██║██████╔╝█████╗  ██████╔╝███████╗██║     ██████╔╝██║██████╔╝   ██║   
╚════██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   
███████║╚██████╔╝██║     ███████╗██║  ██║███████║╚██████╗██║  ██║██║██║        ██║   
╚══════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
                                                                                     
                                                        

    Written By: Anthony Tippy



                                                                                                                                                           
"@

# make sure the PSCrestron Cmdlets are loaded into PowerShell
Import-Module PSCrestron

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#Reset Count
$count = 0

# set username and password
$cUsername = "ENTER USERNAME HERE"
$cPassword = "ENTER PASSWORD HERE"

# declare an object to hold the results table
$ResultsTable =@()

# discover devices on the network
#$deviceList = Get-AutoDiscovery 

#load IP from TXT list
$deviceList = Get-Content (Join-Path $PSScriptRoot 'IP.txt')

# for each device in the devicelist
foreach ($dev in $deviceList)
{ 
try {   
    # try to query the device a few different ways:
    # try ssh with username/password, then ssh no username, then ssh admin admin, then CTP
    # set $cMethod so we will know what worked later on in the script
        write-host $dev 'Trying SSH default password'
        write-host " " 
        $dVersionInfo = Get-VersionInfo -Device $dev -Secure  #default ssh
        $cMethod = "SSH Default"

        if($dVersionInfo.ErrorMessage.Contains("Permission denied (password)"))   #wrong password, try the defaults
        {   write-host $dev 'Trying SSH Custom Password'
            $dVersionInfo = Get-VersionInfo -Device $dev -Secure -Username $cUsername -Password $cPassword  #ssh with non-standard Password
            $cMethod = "SSH PW"

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

        <#if($dVersionInfo.ErrorMessage.Contains("Failed to find port 41795 open."))   #device doesn't support ssh, try CTP
        {   write-host $dev 'Trying CTP MTR password'
            $dVersionInfo = Get-VersionInfo -Device $dev -Username "admin" -Password "sfb" -erroraction 'silentlycontinue'
            $cMethod = "MTR CTP"
            Write-Host $dVersionInfo
        }#>

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
                {
                $consoleSession = Open-CrestronSession -Device $dev -Secure -username $cUsername -Password $cPassword -erroraction 'silentlycontinue'
                }
            elseif($cMethod.Contains("SSH Default"))
                {

                $consoleSession = Open-CrestronSession -Device $dev -Secure -erroraction 'silentlycontinue'
                }
            elseif($cMethod.Contains("SSH admin"))
                {
                $consoleSession = Open-CrestronSession -Device $dev -Secure -Username "admin" -Password "admin" -erroraction 'silentlycontinue'
                }
           elseif($cMethod.Contains("MTR CTP"))
                {
                $consoleSession = Open-CrestronSession -Device $dev -Secure -Username "admin" -Password "MTRPASSWORD" -erroraction 'silentlycontinue'
                }
           elseif($cMethod.Contains("ERROR"))
                {
                $consoleSession = write-host "ERROR SKIPPED"
                }
            <#else
                {
                $consoleSession = Open-CrestronSession -Device $dev -erroraction 'silentlycontinue'
                }#>
            if($cMethod.contains("ERROR")){ }

            else{
                #Run Crestron Device Commands PROGCOMMENTS
                write-host '-Connected - Running PROGCOMMENTS'
                $dCPULoad = Invoke-CrestronSession -Handle $consoleSession -Command 'progcomments' -ErrorAction SilentlyContinue
                #Parse out just program file info
                $dCPULoad =   [regex]::Match($dCPULoad, "([^Program File:\s])(.*?)(\.smw)").value

                #Run Crestron Command DHCP
                write-host '-Connected - Running DHCP'
                $dDHCP = Invoke-CrestronSession -Handle $consoleSession -Command 'DHCP' -ErrorAction SilentlyContinue
                $dDHCP =   [regex]::Match($dDHCP, "([^Device \d Current DHCP State:\s])(.*)").value

                #Run Crestron Command IPCONFIG
                write-host '-Connected - Running IPCONFIG'
                $dIPCONFIG = Invoke-CrestronSession -Handle $consoleSession -Command 'ipconfig' -ErrorAction SilentlyContinue
                
                #Run Crestron Command ipmask
                write-host '-Connected - Getting Subnet Mask'
                $dIPMASK = Invoke-CrestronSession -Handle $consoleSession -Command 'ipmask' -ErrorAction SilentlyContinue

                #Run Crestron Command LISTDNS
                write-host '-Connected - Getting DNS'
                $dDNS = Invoke-CrestronSession -Handle $consoleSession -Command 'listdns' -ErrorAction SilentlyContinue
                
                #Close Crestron Session to device
                Close-CrestronSession -Handle $consoleSession -erroraction 'silentlycontinue'

                #Error Handling - If no error's add to record message
                if ($dVersionInfo.ErrorMessage.Contains(""))
                    {write-host '-SUCCESS - Added to Record'
                    write ' '}
                    }

            #Error Handling - If ErrorMessage clears out Program and DHCP info to prevent false info
            if ($dVersionInfo.ErrorMessage.Contains(" ")){
            $dDHCP = " "
            #$cMethod = "Error"
            $dCPULoad =" "}

            #Update Counter for each device
            $count = $count + 1

            #Add program Results
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Program" -NotePropertyValue $dCPULoad -erroraction 'silentlycontinue'

            #Add DHCP Check Results
            Add-Member -InputObject $dVersionInfo -NotePropertyName "DHCP Status" -NotePropertyValue $dDHCP -erroraction 'silentlycontinue'

            #Add Connection Method Log
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Auth Method" -NotePropertyValue $cMethod -erroraction 'silentlycontinue'
            
            #Add IPCONFIG
            Add-Member -InputObject $dVersionInfo -NotePropertyName "IPCONFIG" -NotePropertyValue $dIPCONFIG -erroraction 'silentlycontinue'
                        
            #Add IPmask
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Subnet Mask" -NotePropertyValue $dIPMASK -erroraction 'silentlycontinue'

            #Add DNS info
            Add-Member -InputObject $dVersionInfo -NotePropertyName "DNS" -NotePropertyValue $dDNS -erroraction 'silentlycontinue'
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
$Error | Out-File (Join-Path $PSScriptRoot 'SuperScript ERROR LOG.txt')
$ResultsTable | Out-GridView
$ResultsTable | Select-Object -Property "Device", "Hostname", "Prompt", "Serial", "MACAddress", "VersionOS", "Category", "Build" , "DHCP Status", "Auth Method", "ErrorMessage", "Program", "IPCONFIG","Subnet Mask", "DNS" | Export-Csv -Path $PSScriptRoot\"SuperScript Results.csv" -NoTypeInformation

#Report Count of Devices
write-host 'Total Devices Queried: ' $count

#Total time of script
$stopwatch

#Read-Host -Prompt “Press Enter to exit”
