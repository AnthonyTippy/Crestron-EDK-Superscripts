
<#
.SYNOPSIS
  Asyncronously connects to devices and grabs Crestron device information such as model, serial number, mac address, and project file...etc
  script also discovers devices on control subnet of primary device and returns limited info

.DESCRIPTION
  Superscript will connect to up to 50 devices simultaneously to grab the associated device information from the device.


.PARAMETER <Parameter_Name>
    none

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - IP.txt text file containing IP addresses of devices (One per line)

.OUTPUTS
  C:\Superscript Results.csv

.NOTES
  Version:        2.0
  Author:         Anthony Tippy
  Creation Date:  11/29/21
  Purpose/Change: feature update, script cleanup

  Features added:
  -added cresnet support
  -added control subnet device discovery support
  -added error handling for if report is open when trying to run script

  .LIMITATIONS:
  Superscript currently not compatible with the following devices
  -DM Lite Devices
  -DM wall transmitters
  -UC-engine MTR's
  -Basically anything that can't be SSH'd into
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> Run Superscript--> script will output device info C:\Superscript Results.csv
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
                                                                                     
    
    v2.0                                               
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

#Delete old script report
Remove-Item "$home\Superscript Results.csv" -ErrorAction SilentlyContinue

 
#create a new object to hold the restults data
$DeviceResultsData =@()      

#Initilize the table
$DeviceResultsData | Out-GridView -Title "Device Status Results"

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


#clear whitespace from text file
$devs | Foreach {$_.TrimEnd()} | Foreach {$_.TrimStart()} | Set-Content (Join-Path $PSScriptRoot 'IP.txt')


#Version
Invoke-RunspaceJob -InputObject $devs -ScriptBlock{
$DeviceResultItem = New-Object PSObject

########### Credentials ###########

$username = 'USERNAME'
$password = 'PASSWORD'

###################################

    try {
        $d = $_ 

        
        #Open Crestron Connection
        $session = Open-CrestronSession -Device $d -Secure -ErrorAction Continue
        $authmethod = "SSH Default"

        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-Host -f green "[Default Password] Working on => $deviceHostname" $d "`n`n`n" 

        #version info
        $VERResponce = Invoke-CrestronSession $session "ver"
        $deviceModel =  [regex]::Match($VERResponce, "\w([^[]+)").value
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value

        #progcom
        $progcomResponce = Invoke-CrestronSession $session "progcom"
        $programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 

        #systemname
        $systename = [regex]::Match($progcomResponce, "(?<=System\sName:\s\s)(.*)").value 


        #Get IP info
        $estResponce = Invoke-CrestronSession $session "est"

        #Processor Uptime
        $uptime = Invoke-CrestronSession $session "uptime"
        $uptimereg =   [regex]::Match($uptime, "(\d+\sdays?)").value

        #dhcp
        $dDHCP = Invoke-CrestronSession $session "dhcp"
        $dDHCP =   [regex]::Match($dDHCP, "([^Device \d Current DHCP State:\s])(.*)").value

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
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value $systename
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value "$programFileName "
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
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value $uptimereg
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value $dDHCP
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value $authmethod


#Add line to the report
$DeviceResultsData = $DeviceResultItem

#Export info out to report
$DeviceResultsData | export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append 


#Close session connection
Close-CrestronSession $session



try{
#Autodiscovery scan of Control subnet devices
$Autodiscovery = Read-AutoDiscovery -Device $d -Secure | Where-Object "Interface" -EQ "CS" 


$count = $Autodiscovery.Count
if ($count -eq "0"){
write-host -f cyan "`n0 control subnet devices found in $d - $deviceHostname"}
else{
Write-host -f cyan "`n$count control subnet devices found in $d - $deviceHostname"

$count = $count - "1"
$numbers.clear
$numbers = "0".."$count"

#For each device in autodiscovery array results, parse out specific device info
foreach ($num in $numbers){
$DeviceResultItem = New-Object PSObject

$IP = $Autodiscovery.Get($num).IP
#$IP

$Hostname = $Autodiscovery.Get($num).Hostname
#$Hostname

$Description = $Autodiscovery.Get($num).Description

$model = [regex]::Match($Description, ".*(?=[[])").value
#$model = [regex]::Match($Description, "([^[]*)").value
#$model

write-host "- $num : $model"

$firmware = [regex]::Match($Description, "(?<=v).*(?=[(])").value
#$firmware

$tsid = [regex]::Match($Description, "(?<=#).*(?=])").value
#$tsid

try{
$serial = Convert-TsidToSerial -TSID $tsid 
}
catch{$serial =" "}



#Build Table
$time = (get-date)
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $model
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $serial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value " "
# Table Coulumn 7 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $firmware
# Table Coulumn 8 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $IP
# Table Coulumn 9 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value " "
# Table Coulumn 10 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value " "
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value " "
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $Hostname
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "CS Device - $deviceHostname"

#Add line to the report
$DeviceResultsData = $DeviceResultItem

#export report data to csv
$DeviceResultsData |  export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append 

}
}
}
catch{write-host -f RED "$d - $hostname Control Subnet Autodiscovery ERROR!"}

#Crestron Cresnet Processing
try{
#Cresnet Info
$cresnet = Get-CresnetInfo -Device $d -Secure

Clear-Variable $count

$count = ($cresnet | Measure-Object).Count
if ($count -eq "0"){
write-host -f cyan "`n0 cresnet devices found in $d - $deviceHostname"}
else{
Write-host -f cyan "`n$count cresnet devices found in $d - $deviceHostname"
$count = $count - "1"
#clear-variable $numbers
#clear-variable $num
$numbers = "0".."$count"

#For each device in autodiscovery array results, parse out specific device info
foreach ($num in $numbers){
$DeviceResultItem = New-Object PSObject

try{
#Model
$Cresnetmodel= $cresnet.Get($num).Device
}
catch {$Cresnetmodel = $cresnet.Device}

write-host "- $num : $Cresnetmodel"


#ip address
#$IP = $d

try{
#firmware version
$cresnetversion = $cresnet.Get($num).Version}
catch{$cresnetversion = $cresnet.Version}

try{
#Cresnet ID
$cresnetID = $cresnet.Get($num).CresnetID}
catch{$cresnetID = $cresnet.CresnetID}

try{
#cresnet serial number
$cresnetserial = $cresnet.Get($num).Serial}
catch{$cresnetserial = $cresnet.Serial}


#Build Table
$time = (get-date)
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $Cresnetmodel
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $cresnetserial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value " "
# Table Coulumn 7 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $cresnetversion
# Table Coulumn 8 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value " "
# Table Coulumn 9 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value " "
# Table Coulumn 10 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value " "
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value " "
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value " "
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "Cresnet Device - $deviceHostname"

#Add line to the report
$DeviceResultsData = $DeviceResultItem

#export data to csv
$DeviceResultsData |  export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append

}
}
}
catch{write-host -f RED "$d - $hostname CRESNET ERROR!"}

    }
    catch {
        
        try{
        
        #open crestron session to device with password
        $session = Open-CrestronSession -Device $d -Secure -username $username -password $password -ErrorAction Continue
        $authmethod = "Custom Password"

        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-host -f Green "[Custom Password] Working on => $deviceHostname" $d "`n`n`n" 
        write-output " "
        
        #ver
        $VERResponce = Invoke-CrestronSession $session "ver" 
        $deviceModel =  [regex]::Match($VERResponce, "\w([^[]+)").value  #$deviceModel =  [regex]::Match($VERResponce, "^([^\s]+)").value
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value
        
        #progcom
        $progcomResponce = Invoke-CrestronSession $session "progcom"
        $programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 

        #systemname
        $systename = [regex]::Match($progcomResponce, "(?<=System\sName:\s\s)(.*)").value 

        #est
        $estResponce = Invoke-CrestronSession $session "est"

        #Processor Uptime
        $uptime = Invoke-CrestronSession $session "uptime"
        $uptimereg =   [regex]::Match($uptime, "(\d+\sdays?)").value

        #dhcp
        $dDHCP = Invoke-CrestronSession $session "dhcp"
        $dDHCP =   [regex]::Match($dDHCP, "([^Device \d Current DHCP State:\s])(.*)").value

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
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value $systename
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value "$programFileName "
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
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value $uptimereg
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value $dDHCP
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value $authmethod


#Add line to the report
$DeviceResultsData = $DeviceResultItem

#export data out to csv file
$DeviceResultsData | export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append 

#close crestron session connection
Close-CrestronSession $session

try{
#autodiscover control subnet devices on primary device
$Autodiscovery = Read-AutoDiscovery -Device $d -Secure -username $username  -Password $password | Where-Object "Interface" -EQ "CS" 


$count = $Autodiscovery.Count
if ($count -eq "0"){
write-host -f cyan "`n0 control subnet devices found in $d - $deviceHostname"}
else{
Write-host -f cyan "`n$count control subnet devices found in $d - $deviceHostname"
$count = $count - "1"
$numbers.clear
$numbers = "0".."$count"

#For each device in autodiscovery array results, parse out specific device info
foreach ($num in $numbers){
$DeviceResultItem = New-Object PSObject

$IP = $Autodiscovery.Get($num).IP
#$IP

$Hostname = $Autodiscovery.Get($num).Hostname
#$Hostname

$Description = $Autodiscovery.Get($num).Description 


$model = [regex]::Match($Description, ".*(?=[[])").value
#$model = [regex]::Match($Description, "([^[]*)").value
#$model

write-host "- $num : $model"

$firmware = [regex]::Match($Description, "(?<=v).*(?=[(])").value
#$firmware

$tsid = [regex]::Match($Description, "(?<=#).*(?=])").value
#$tsid

try{
#try to convert serial, if no work skip
$serial = Convert-TsidToSerial -TSID $tsid 
}
catch{$serial =" "}


#Build Table
$time = (get-date)
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $model
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $serial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value " "
# Table Coulumn 7 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $firmware
# Table Coulumn 8 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $IP
# Table Coulumn 9 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value " "
# Table Coulumn 10 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value " "
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value " "
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $Hostname
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "CS Device - $deviceHostname"

#Add line to the report
$DeviceResultsData = $DeviceResultItem

#export data to csv
$DeviceResultsData |  export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append

}
}
}
catch{write-host -f RED "$d - $hostname Control Subnet Autodiscovery ERROR!"}


#Crestron Cresnet Processing
try{
#Cresnet Info
$cresnet = Get-CresnetInfo -Device $d -Secure -Username $username -Password $password

Clear-Variable $count

$count = ($cresnet | Measure-Object).Count
if ($count -eq "0"){
write-host -f cyan "`n0 cresnet devices found in $d - $deviceHostname"}
else{
Write-host -f cyan "`n$count cresnet devices found in $d - $deviceHostname"
$count = $count - "1"
#clear-variable $numbers
#clear-variable $num
$numbers = "0".."$count"

#For each device in autodiscovery array results, parse out specific device info
foreach ($num in $numbers){
$DeviceResultItem = New-Object PSObject

try{
#Model
$Cresnetmodel= $cresnet.Get($num).Device
}
catch {$Cresnetmodel = $cresnet.Device}

write-host "- $num : $Cresnetmodel"


#ip address
#$IP = $d

try{
#firmware version
$cresnetversion = $cresnet.Get($num).Version}
catch{$cresnetversion = $cresnet.Version}

try{
#Cresnet ID
$cresnetID = $cresnet.Get($num).CresnetID}
catch{$cresnetID = $cresnet.CresnetID}

try{
#cresnet serial number
$cresnetserial = $cresnet.Get($num).Serial}
catch{$cresnetserial = $cresnet.Serial}


#Build Table
$time = (get-date)
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $Cresnetmodel
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $cresnetserial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value " "
# Table Coulumn 7 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $cresnetversion
# Table Coulumn 8 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value " "
# Table Coulumn 9 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value " "
# Table Coulumn 10 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value " "
# Table Coulumn 11 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value " "
# Table Coulumn 12 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value " "
# Table Coulumn 13 - uptime
$DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "
# Table Coulumn 14 - DHCP Status
$DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "
# Table Coulumn 15 - Auth Method
$DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "Cresnet Device - $deviceHostname"

#Add line to the report
$DeviceResultsData = $DeviceResultItem

#export data to csv
$DeviceResultsData |  export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append

}
}
}
catch{write-host -f RED "$d - $hostname CRESNET ERROR!"}

        }

        catch {write-host -f red "$d : Error Connecting!`n`n`n" 
            
            $time = (get-date)
            #Build Table
            # Table Coulumn 1 - Time
            $DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time 
            # Table Coulumn 1 - model
            $DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value " "#$deviceModel
            # Table Coulumn 2 space
            $DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "#$systemname
            # Table Coulumn 3 - serial
            $DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value " "#$deviceSerial
            # Table Coulumn 6 - Program Name
            $DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value " "#$programFileName
            # Table Coulumn 7 - version
            $DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value " "#$deviceVer
            # Table Coulumn 8 - ip
            $DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $d
            # Table Coulumn 9 - mac
            $DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value " "#$deviceMAC
            # Table Coulumn 10 - subnet mask
            $DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value " "#$deviceSM
            # Table Coulumn 11 - default gateway
            $DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value " "#$deviceDG
            # Table Coulumn 12 - hostname
            $DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value " "#$deviceHostname
            # Table Coulumn 13 - uptime
            $DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "#$uptimereg
            # Table Coulumn 14 - DHCP Status
            $DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "#$dDHCP
            # Table Coulumn 15 - Auth Method
            $DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "Error Connecting"


            #Add line to the report
            $DeviceResultsData = $DeviceResultItem

            #export data to csv file
            $DeviceResultsData | export-csv -Path "$home\Superscript Results.csv" -NoTypeInformation -Append 
            
            
            }
            }

}-ThrottleLimit 50 -ShowProgress 

Write-host -f Cyan "`n`nResults can be found at $home\Superscript Results.csv"

#import initial report , add collection to persistent log file 
import-csv "$home\Superscript Results.csv" | export-csv -Path "$home\Superscript Results Log.csv" -NoTypeInformation -Append  -erroraction SilentlyContinue

#grid view option
#import-csv "$home\Superscript Results.csv" | out-gridview 

#open report file generated
Invoke-item "$home\Superscript Results.csv" -erroraction SilentlyContinue

#Total time of script
$stopwatch


Read-Host -Prompt “Press Enter to exit”
