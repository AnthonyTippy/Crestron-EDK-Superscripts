
<#
.SYNOPSIS
  Asyncronously connects to devices and grabs Crestron device information such as model, serial number, mac address, and project file...etc

.DESCRIPTION
  Superscript will connect to up to 30 devices simultaneously to grab the associated device information from the device.  Now Supports DM devices as well as MTR UC-Engine's 


.PARAMETER <Parameter_Name>
    none

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'

  Default MTR PASSWORD is auto filled
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - IP.txt text file containing IP addresses of devices (One per line)

.OUTPUTS
  C:\Desktop\Superscript Results.csv

.NOTES
  Version:        1.1
  Author:         Anthony Tippy
  Creation Date:  05/12/2021
  Purpose/Change: Initial script development
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> Run Superscript--> script will output device info C:\Desktop\Superscript Results.csv
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
                                                                                     
    v1.2                                                    
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

Remove-Item "$home\Desktop\Superscript Results.csv" -ErrorAction SilentlyContinue
Remove-Item "$home\Desktop\Errors.txt" -ErrorAction SilentlyContinue

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


#Superscript processing
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {
$DeviceResultItem = New-Object PSObject

########### Credentials ###########

$username = 'USERNAME HERE'
$password = 'PASSWORD HERE'

###################################

    try {
        $d = $_ 
        $session = Open-CrestronSession -Device $d -Secure -ErrorAction Continue
        $authmethod = "SSH Default"

        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-Host -f green "[Default Password] Working on => $deviceHostname" $d "`n`n`n" 

        #ver
        $VERResponce = Invoke-CrestronSession $session "ver"
        $deviceModel =  [regex]::Match($VERResponce, "\w([^[]+)").value
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value

        #progcom
        $progcomResponce = Invoke-CrestronSession $session "progcom"
        $programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 

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

#Build Table
$time = (get-date)
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 2 space
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
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

$DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append 

Close-CrestronSession $session

    }
    catch {
        #Write-host -F Yellow "$d : Non-default password"
        try{


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
$DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
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

$DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append 

Close-CrestronSession $session

        }

        catch {#write-host -f red "$d : Error Connecting!`n`n`n"
            $d | out-file -FilePath "$home\Desktop\Errors.txt" -append

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
            
            }
            }

}-ShowProgress -TIMEOUT 5 -ErrorAction SilentlyContinue


# import device file
try
	{
	$devs =@(Get-Content -Path "$home\Desktop\Errors.txt") 
    write-host " "
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device list.txt is in same directory as script!!!'
	}


#Port Test to differentiate between MTR and OTHER
$porttest = Invoke-RunspaceJob -InputObject $devs -ScriptBlock {
$d=$_
Test-crestronport -device $d -port 49500
}

$portopen = $porttest | Where-Object -Property "CanConnect" -EQ "True" |Select-Object Device | select -ExpandProperty Device

$portclosed = $porttest | Where-Object -Property "CanConnect" -NE "True" |Select-Object Device  | select -ExpandProperty Device

#Write-host -f green "Attempting MTR device connections"

#MTR Processing
Invoke-RunspaceJob -InputObject $portopen -ScriptBlock {

Set-Item wsman:\localhost\Client\TrustedHosts -value "$_" -Force -ErrorAction Stop
#Write-host -f Green "`nConnecting to: $_`n"

$DeviceResultItem = New-Object PSObject

$Username = 'admin'#default MTR PASSWORD
$Password = 'sfb' #default MTR PASSWORD
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,pass


#Get-Computer-Info Command
$computer = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
    Get-ComputerInfo  |Select-object -property PSComputerName, CsDNSHostName, WindowsVersion, BiosSeralNumber, CsModel,OsVersion, OsBuildNumber, OsLocalDateTime, OsLastBootUpTime, OsUptime  -ErrorAction Continue 
}

Write-Host -f Green "[MTR Password] Working on => $_`n`n`n"

#Get-Computer-Info Command
$ipconfig = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
Get-WmiObject -Class "win32_networkadapterconfiguration" | where -Property Description -EQ "Intel(R) Ethernet Connection (2) I219-LM"
}


$info = Get-AutoDiscovery -EndPoint $_ 
 
$version  = $info.Description
$model = [regex]::Match($info.Description, "\w([^[]+) ").value
$version = [regex]::Match($info.Description, "(?<=v)(.*)(?=,)").value
$tsid = [regex]::Match($info.Description, "(?<=#)(.*)(?=])").value
$serial = Convert-TsidToSerial -TSID $tsid
$subnet = [regex]::Match($ipconfig.IPSubnet, "(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})").value

        $time = (get-date)
        #Build Table
        # Table Coulumn 1 - Time
        $DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
        # Table Coulumn 1 - model
        $DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $model
        # Table Coulumn 2 space
        $DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value " "
        # Table Coulumn 3 - serial
        $DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $serial
        # Table Coulumn 6 - Program Name
        $DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value $computer.OsVersion
        # Table Coulumn 7 - version
        $DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $version
        # Table Coulumn 8 - ip
        $DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $_
        # Table Coulumn 9 - mac
        $DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value $ipconfig.MACAddress
        # Table Coulumn 10 - subnet mask
        $DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value $subnet
        # Table Coulumn 11 - default gateway
        $DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value $ipconfig.DefaultIPGateway
        # Table Coulumn 12 - hostname
        $DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $info.Hostname
        # Table Coulumn 13 - uptime
        $DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value $computer.OsUptime
        # Table Coulumn 14 - DHCP Status
        $DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "
        # Table Coulumn 15 - Auth Method
        $DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "MTR Password"

        #Add line to the report
        $DeviceResultsData = $DeviceResultItem
        $DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append 



} -throttlelimit 1 -ShowProgress -TIMEOUT 5  -ErrorAction Continue 



#DM DEVICE PROCESSING
Invoke-RunspaceJob -InputObject $portclosed -ScriptBlock {
$DeviceResultItem = New-Object PSObject
    try{
        $d = $_ 

        $DeviceResultItem = New-Object PSObject
        #Write-host  "`nAttempting connection to $d`n"
        Write-Host -f Green "[Default Password] Working on => DM Device: $d`n`n`n"

        $openpage = Invoke-WebRequest -Uri $d -TimeoutSec 5
        #write-host -F Green "--connected to $d`n"
        
        $model = [regex]::Match($openpage, "(?<=model=')(.*)(?=';ser)").value 
        $serial = [regex]::Match($openpage, "(?<=seriv=')(.*)(?=';firm)").value 
        $firmware = [regex]::Match($openpage, "(?<=firmv=')(.*)(?=';host)").value
        $ip = [regex]::Match($openpage, "(?<=ip=')(.*)(?=';sn)").value
        $hostname = [regex]::Match($openpage, "(?<=host=')(.*)(?=';ip_mode)").value 
        $sn = [regex]::Match($openpage, "(?<=sn=')(.*)(?=';gw)").value 
        $gw =[regex]::Match($openpage, "(?<=gw=')(.*)(?=';mac)").value 
        $mac = [regex]::Match($openpage, "(?<=mac=')(.*)(?=';cus)").value 
       
        $time = (get-date)
        #Build Table
        # Table Coulumn 1 - Time
        $DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
        # Table Coulumn 1 - model
        $DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $model
        # Table Coulumn 2 space
        $DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value $systemname
        # Table Coulumn 3 - serial
        $DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $serial
        # Table Coulumn 6 - Program Name
        $DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value $programFileName
        # Table Coulumn 7 - version
        $DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $firmware
        # Table Coulumn 8 - ip
        $DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $ip
        # Table Coulumn 9 - mac
        $DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value $mac
        # Table Coulumn 10 - subnet mask
        $DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value $sn
        # Table Coulumn 11 - default gateway
        $DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value $gw
        # Table Coulumn 12 - hostname
        $DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $hostname 
        # Table Coulumn 13 - uptime
        $DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "#$uptimereg
        # Table Coulumn 14 - DHCP Status
        $DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "#$dDHCP
        # Table Coulumn 15 - Auth Method
        $DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "DM Device Default Password"

        #Add line to the report
        $DeviceResultsData = $DeviceResultItem
        $DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append  
        }
    catch{
    try{
    Write-Host -f Green "[Custom Password] Working on => DM Device: $d`n`n`n"

    $Uri = "$d"
    
    $Headers = @{ Authorization = "Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password))) }
    
    Invoke-RestMethod -Uri $Uri -Headers $Headers -TimeoutSec 5
    write-host -F Green "`n--connected to $d"

        $model = [regex]::Match($openpage, "(?<=model=')(.*)(?=';ser)").value 
        $serial = [regex]::Match($openpage, "(?<=seriv=')(.*)(?=';firm)").value 
        $firmware = [regex]::Match($openpage, "(?<=firmv=')(.*)(?=';host)").value
        $ip = [regex]::Match($openpage, "(?<=ip=')(.*)(?=';sn)").value
        $hostname = [regex]::Match($openpage, "(?<=host=')(.*)(?=';ip_mode)").value 
        $sn = [regex]::Match($openpage, "(?<=sn=')(.*)(?=';gw)").value 
        $gw =[regex]::Match($openpage, "(?<=gw=')(.*)(?=';mac)").value 
        $mac = [regex]::Match($openpage, "(?<=mac=')(.*)(?=';cus)").value 
       

        $time = (get-date)
        #Build Table
        # Table Coulumn 1 - Time
        $DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
        # Table Coulumn 1 - model
        $DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $model
        # Table Coulumn 2 space
        $DeviceResultItem | Add-Member -Name "System Name" -MemberType NoteProperty -value $systemname
        # Table Coulumn 3 - serial
        $DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $serial
        # Table Coulumn 6 - Program Name
        $DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value $programFileName
        # Table Coulumn 7 - version
        $DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $firmware
        # Table Coulumn 8 - ip
        $DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $ip
        # Table Coulumn 9 - mac
        $DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value $mac
        # Table Coulumn 10 - subnet mask
        $DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value $sn
        # Table Coulumn 11 - default gateway
        $DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value $gw
        # Table Coulumn 12 - hostname
        $DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $hostname 
        # Table Coulumn 13 - uptime
        $DeviceResultItem | Add-Member -Name "Uptime" -MemberType NoteProperty -Value " "#$uptimereg
        # Table Coulumn 14 - DHCP Status
        $DeviceResultItem | Add-Member -Name "DHCP Status" -MemberType NoteProperty -Value " "#$dDHCP
        # Table Coulumn 15 - Auth Method
        $DeviceResultItem | Add-Member -Name "Auth Method" -MemberType NoteProperty -Value "DM Device Toyota Password"

        #Add line to the report
        $DeviceResultsData = $DeviceResultItem
        $DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append 
        }
        catch{ 
            Write-host -f red "$d : Error Connecting!"
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

            
            $DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append 
            }
    }

}-ShowProgress -TIMEOUT 5 -ErrorAction SilentlyContinue


#export data out
$DeviceResultsData | export-csv -Path "$home\Desktop\Superscript Results.csv" -NoTypeInformation -Append  

#DeleteErrorsFile
Remove-Item "$home\Desktop\Errors.txt" -ErrorAction SilentlyContinue

Write-host -f Cyan "`n`nResults can be found at C:\Desktop\Superscript Results.csv"

import-csv "$home\Desktop\Superscript Results.csv" | Out-gridview

#stopwatch timer
$stopwatch 


Read-Host -Prompt “Press Enter to exit”
