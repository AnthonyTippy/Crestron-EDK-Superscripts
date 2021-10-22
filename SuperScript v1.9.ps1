#Set-ExecutionPolicy remotesigned -force
<#
.SYNOPSIS
  Asyncronously connects to devices and grabs Crestron device information such as model, serial number, mac address, and project file...etc

.DESCRIPTION
  Superscript will connect to up to 30 devices simultaneously to grab the associated device information from the device.


.PARAMETER <Parameter_Name>
    none

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - IP.txt text file containing IP addresses of devices (One per line)

.OUTPUTS
  C:\Desktop\Superscript Results.csv

.NOTES
  Version:        1.9
  Author:         Anthony Tippy
  Creation Date:  10/21/2021
  Purpose/Change: feature update
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> Run Superscript--> script will output device info "$home\Superscript Results.csv"
#>


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
#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

if (Get-Module -ListAvailable -Name PSCrestron) {
} 
else {
    Write-Host "PSCrestron Module Not Installed. Please Install PSCrestron Module and Try Again!"
    exit
}


#Import PSCRESTRON MODULE
Import-Module PSCrestron

#Delete Old Report
Remove-Item  "$home\Superscript Results.csv"  -ErrorAction SilentlyContinue
 
#create a new object to hold the restults data
$DeviceResultsData =@()      

#Initilize the table
$DeviceResultsData | Out-GridView -Title "Device Status Results"

#clear whitespace from text file
(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt')) | Foreach {$_.TrimEnd()} | Foreach {$_.TrimStart()} | Set-Content (Join-Path $PSScriptRoot 'IP.txt')

# import device file
try
	{
    $devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
	Write-Host ' '
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device IP.txt is in same directory as script!!!'
	}


#Version
Invoke-RunspaceJob -InputObject $devs -ScriptBlock{
$DeviceResultItem = New-Object PSObject

########### Credentials ###########

$username = 'ENTERUSERNAMEHERE'
$password = 'ENTERPASSWORDHERE'

###################################

    try {
        $d = $_ 
        $session = Open-CrestronSession -Device $d -Secure -ErrorAction Continue
        $authmethod = "SSH Default"

        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-Host -f green "[Default Password] Working on => $deviceHostname  - " $d "`n`n`n" 

        #ver
        $VERResponce = Invoke-CrestronSession $session "ver"
        $deviceModel =  [regex]::Match($VERResponce, "\w([^[]+)").value
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value

        #free ram
        $ramfree = invoke-crestronsession $session "ramfree"
        $ramfree = [regex]::Match($ramfree, "(\d\d(.*) percent)").value 

        #progcom
        $progcomResponce = Invoke-CrestronSession $session "progcom"
        $programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 

        #est
        $estResponce = Invoke-CrestronSession $session "est"

        #get dns info
        $dnsservers = Invoke-CrestronSession $session "listdns"
        $dns = Select-String "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -input $dnsservers -AllMatches | Foreach {$_.matches}  | Select-Object -Property Value -ExpandProperty Value | Out-String 


        #Processor Uptime
        $uptime = Invoke-CrestronSession $session "uptime"
        $uptimereg =   [regex]::Match($uptime, "(\d+\sdays?)").value

        #dhcp
        $dDHCP = Invoke-CrestronSession $session "dhcp"
        $dDHCP =   [regex]::Match($dDHCP, "([^Device \d Current DHCP State:\s])(.*)").value
        
        #cresnet devices
        $cresnet = Invoke-CrestronSession $session "reportcresnet"
        
        #ctp port
        $ctp = Invoke-CrestronSession $session "ctpport"

        #devicetime
        $devicetime = Invoke-CrestronSession $session "time"
        $devicetime = [regex]::Match($devicetime , '(\d\d:\d\d:\d\d \d\d-\d\d-\d\d\d\d)').value

        #sntp enabled
        $sntp = Invoke-CrestronSession $session "sntp"

        #timezone
        $timezone = Invoke-CrestronSession $session "timezone"

        $FTP = Invoke-CrestronSession $session "FTPServer"

        #who report
        $who = Invoke-CrestronSession $session "who"
        $who = Select-String "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -input $who -AllMatches | Foreach {$_.matches}  | Select-Object -Property Value -ExpandProperty Value | Out-String 
        $who = $who.Substring(13)

        #Find all instances of "Ethernet Adapter in the estResponce"
        $ethernetAdapterRegex = [regex]"Ethernet A|adapter "

        #Determine if the Ethernet adapter has more than one

            if ($ethernetAdapterRegex.Matches($estResponce).Count -gt1) {
                #Find where the first instance is, string index values
                $matchesIndexArray = $ethernetAdapterRegex.Matches($estResponce).Index
                #isolate the first instance
                $firstEthInstance = $estResponce.Substring($matchesIndexArray[0],($matchesIndexArray[1] - $matchesIndexArray[0]))
                $processedestResponce = $firstEthInstance
            }
            else {
                #Begin Operating Directly
                $processedestResponce = $estResponce
            }

        #split processed estResponce into an array for each line ready for processing
        $estResponceArray = $processedestResponce.Split([Environment]::NewLine)

            #process each line
            foreach ($item in $estResponceArray) {
            
            if ($item -match 'MAC Address'){
                #parse just the mac address
                $deviceMAC = [regex]::Match($item ,  '([0-9A-Fa-f]{2}[:.]){5}([0-9A-Fa-f]{2})').value
            }
            elseif ($item -match 'IP Address') {
                #parse just the IP address
                $deviceIP = [regex]::Match($item , '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').value
            }
            elseif ($item -match 'Subnet Mask') {
                #parse just the Subnet Mask
                $deviceSM = [regex]::Match($item , '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').value
            }
            elseif ($item -match 'Default Gateway') {
                #parse just the Default Gateway
                $deviceDG = [regex]::Match($item , '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').value
            }
        }
        $Results = "$_,$deviceHostname,$deviceModel,$deviceSerial,$deviceVer,$dDHCP"

#Build Table
$time = (get-date)
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value "$programFileName "
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Ram Usage" -MemberType NoteProperty -Value "$ramfree "
# Table Coulumn 7 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $deviceVer
# Table Coulumn 8 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $deviceIP
# Table Coulumn 9 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value $deviceMAC
# Table Coulumn 10 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value $deviceSM
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value $deviceDG
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "DNS Servers" -MemberType NoteProperty -Value $dns
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value $uptimereg
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Current Device Time" -MemberType NoteProperty -Value $devicetime
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "SNTP Service" -MemberType NoteProperty -Value $sntp
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Timezone" -MemberType NoteProperty -Value $timezone
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value $dDHCP
# Table Coulumn 12 - Cresnet devices
$DeviceResultItem | Add-Member -Name "Cresnet Devices" -MemberType NoteProperty -Value $cresnet
# Table Coulumn 12 - CTP Port
$DeviceResultItem | Add-Member -Name "CTP Port" -MemberType NoteProperty -Value $ctp
# Table Coulumn 12 - WHO Report
$DeviceResultItem | Add-Member -Name "Other Connected Devices" -MemberType NoteProperty -Value $who
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value $authmethod
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "FTP" -MemberType NoteProperty -Value $FTP



#Add line to the report
$DeviceResultsData = $DeviceResultItem

$DeviceResultsData | export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append 

Close-CrestronSession $session

    }
    catch {
        
        try{


        $session = Open-CrestronSession -Device $d -Secure -username $username -password $password -ErrorAction Continue
        $authmethod = "Custom Password"

        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-host -f Green "[Custom Password] Working on => $deviceHostname  - "$d "`n`n`n" 
        write-output " "
        
        #ver
        $VERResponce = Invoke-CrestronSession $session "ver" 
        $deviceModel =  [regex]::Match($VERResponce, "\w([^[]+)").value  
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value
        
        #free ram
        $ramfree = invoke-crestronsession $session "ramfree"
        $ramfree = [regex]::Match($ramfree, "(\d\d(.*) percent)").value 

        #progcom
        $progcomResponce = Invoke-CrestronSession $session "progcom"
        $programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 

        #est
        $estResponce = Invoke-CrestronSession $session "est"

        #get dns info
        $dnsservers = Invoke-CrestronSession $session "listdns"
        $dns = Select-String "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -input $dnsservers -AllMatches | Foreach {$_.matches}  | Select-Object -Property Value -ExpandProperty Value | Out-String 

        #Processor Uptime
        $uptime = Invoke-CrestronSession $session "uptime"
        $uptimereg =   [regex]::Match($uptime, "(\d+\sdays?)").value

        #dhcp
        $dDHCP = Invoke-CrestronSession $session "dhcp"
        $dDHCP =   [regex]::Match($dDHCP, "([^Device \d Current DHCP State:\s])(.*)").value
        
        #cresnet devices
        $cresnet = Invoke-CrestronSession $session "reportcresnet" 
        
        #ctp port
        $ctp = Invoke-CrestronSession $session "ctpport"

        #devicetime
        $devicetime = Invoke-CrestronSession $session "time"
        $devicetime = [regex]::Match($devicetime , '(\d\d:\d\d:\d\d \d\d-\d\d-\d\d\d\d)').value

        #sntp enabled
        $sntp = Invoke-CrestronSession $session "sntp"

        #timezone
        $timezone = Invoke-CrestronSession $session "timezone"

        #ftp enabled?
        $FTP = Invoke-CrestronSession $session "FTPServer"

        #who report
        $who = Invoke-CrestronSession $session "who"
        $who = Select-String "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" -input $who -AllMatches | Foreach {$_.matches}  | Select-Object -Property Value -ExpandProperty Value | Out-String 
        $who = $who.Substring(13) 

        #Find all instances of "Ethernet Adapter in the estResponce"
        $ethernetAdapterRegex = [regex]"Ethernet A|adapter "

        #Determine if the Ethernet adapter has more than one
            if ($ethernetAdapterRegex.Matches($estResponce).Count -gt1) {
                #Find where the first instance is, string index values
                $matchesIndexArray = $ethernetAdapterRegex.Matches($estResponce).Index
                #isolate the first instance
                $firstEthInstance = $estResponce.Substring($matchesIndexArray[0],($matchesIndexArray[1] - $matchesIndexArray[0]))
                $processedestResponce = $firstEthInstance
            }
            else {
                #Begin Operating Directly
                $processedestResponce = $estResponce
            }

        #split processed estResponce into an array for each line ready for processing
        $estResponceArray = $processedestResponce.Split([Environment]::NewLine)

            #process each line
            foreach ($item in $estResponceArray) {
            
            if ($item -match 'MAC Address'){
                #parse just the mac address
                $deviceMAC = [regex]::Match($item ,  '([0-9A-Fa-f]{2}[:.]){5}([0-9A-Fa-f]{2})').value
            }
            elseif ($item -match 'IP Address') {
                #parse just the IP address
                $deviceIP = [regex]::Match($item , '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').value
            }
            elseif ($item -match 'Subnet Mask') {
                #parse just the Subnet Mask
                $deviceSM = [regex]::Match($item , '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').value
            }
            elseif ($item -match 'Default Gateway') {
                #parse just the Default Gateway
                $deviceDG = [regex]::Match($item , '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').value
            }
        }
        $Results = "$_,$deviceHostname,$deviceModel,$deviceSerial,$deviceVer,$dDHCP"

$time = (get-date)
#Build Table
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value "$programFileName "
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Ram Usage" -MemberType NoteProperty -Value "$ramfree "
# Table Coulumn 7 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $deviceVer
# Table Coulumn 8 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $deviceIP
# Table Coulumn 9 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value $deviceMAC
# Table Coulumn 10 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value $deviceSM
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value $deviceDG
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "DNS Servers" -MemberType NoteProperty -Value $dns
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value $uptimereg
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Current Device Time" -MemberType NoteProperty -Value $devicetime
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "SNTP Service" -MemberType NoteProperty -Value $sntp
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Timezone" -MemberType NoteProperty -Value $timezone
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value $dDHCP
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Cresnet Devices" -MemberType NoteProperty -Value $cresnet
# Table Coulumn 12 - CTP Port
$DeviceResultItem | Add-Member -Name "CTP Port" -MemberType NoteProperty -Value $ctp
# Table Coulumn 12 - WHO Report
$DeviceResultItem | Add-Member -Name "Other Connected Devices" -MemberType NoteProperty -Value $who
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value $authmethod
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "FTP" -MemberType NoteProperty -Value $FTP


#Add line to the report
$DeviceResultsData = $DeviceResultItem

$DeviceResultsData | export-csv -Path  "$home\Superscript Results.csv"  -NoTypeInformation -Append 

Close-CrestronSession $session

        }

        catch {write-host -f red "$d : Error Connecting!`n`n`n" 
            
            $time = (get-date)
            #Build Table
            # Table Coulumn 1 - Time
            $DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
            # Table Coulumn 12 - hostname
            $DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value " "
            # Table Coulumn 1 - model
            $DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value " "
            # Table Coulumn 3 - serial
            $DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value " "
            # Table Coulumn 6 - Program Name
            $DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value " "
            # Table Coulumn 6 - Program Name
            $DeviceResultItem | Add-Member -Name "Ram Usage" -MemberType NoteProperty -Value " "
            # Table Coulumn 7 - version
            $DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value " "
            # Table Coulumn 8 - ip
            $DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $d
            # Table Coulumn 9 - mac
            $DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value " "
            # Table Coulumn 10 - subnet mask
            $DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value " "
            # Table Coulumn 11 - default gateway
            $DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value " "
            # Table Coulumn 11 - default gateway
            $DeviceResultItem | Add-Member -Name "DNS Servers" -MemberType NoteProperty -Value " "
            # Table Coulumn 13 - uptime
            $DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "
            # Table Coulumn 13 - uptime
            $DeviceResultItem | Add-Member -Name "Current Device Time" -MemberType NoteProperty -Value " "
            # Table Coulumn 13 - uptime
            $DeviceResultItem | Add-Member -Name "SNTP Service" -MemberType NoteProperty -Value " "
            # Table Coulumn 13 - uptime
            $DeviceResultItem | Add-Member -Name "Timezone" -MemberType NoteProperty -Value " "
            # Table Coulumn 14 - DHCP Status
            $DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "
            # Table Coulumn 12 - hostname
            $DeviceResultItem | Add-Member -Name "Cresnet Devices" -MemberType NoteProperty -Value " "
            # Table Coulumn 12 - CTP Port
            $DeviceResultItem | Add-Member -Name "CTP Port" -MemberType NoteProperty -Value " "
            # Table Coulumn 12 - CTP Port
            $DeviceResultItem | Add-Member -Name "Other Connected Devices" -MemberType NoteProperty -Value " "
            # Table Coulumn 15 - Auth Method
            $DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "Error Connecting"
            # Table Coulumn 15 - Auth Method
            $DeviceResultItem | Add-Member -Name "FTP" -MemberType NoteProperty -Value " "



            #Add line to the report
            $DeviceResultsData = $DeviceResultItem

            
            $DeviceResultsData | export-csv -Path   "$home\Superscript Results.csv"  -NoTypeInformation -Append 
           
            
            }
            }

}-ThrottleLimit 30 -ShowProgress 

Write-host -f Cyan "`n`nResults can be found at $home\Superscript Results.csv" 

#import-csv  "$home\Superscript Results.csv"  | Out-gridview
import-csv  "$home\Superscript Results.csv" | export-csv  "$home\Superscript Results Log.csv" -Append 

invoke-item   "$home\Superscript Results.csv"

#Total time of script
$stopwatch


Read-Host -Prompt “Press Enter to exit”
