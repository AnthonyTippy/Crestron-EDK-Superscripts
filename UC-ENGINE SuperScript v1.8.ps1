
<#
.SYNOPSIS
  Asyncronously connects to UC-Engine and grabs windows Get-ComputerInfo details as well as connected devices, information about the touchpanel connected, and other various device info.

.DESCRIPTION
  Script will connect to up to 30 devices simultaneously to grab the associated device information from the device.


.PARAMETER <Parameter_Name>
    none

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - $cusername = 'ENTER YOUR USERNAME'  #Crestron Device Username (Touchpanel)
  - $cpassword = 'ENTER PASSWORD' #Crestron Device Password (Touchpanel)
  - IP.txt text file containing IP addresses of devices (One per line)

. REQUIREMENTS
    -Run script as admin
    -Each UC-Engine MUST have PSRemoting enabled (To enable: Run Powershell as administrator ON UC ENGINE ==> Issue the command "Enable-PSRemoting -SkipNetworkProfileCheck")
    -PSCrestron module must be installed (Crestron EDK)
    -IP.txt file for IP's

.OUTPUTS
  C:\MTR  Results.csv

.NOTES
  Version:        1.8
  Author:         Anthony Tippy
  Creation Date:  08/04/21
  Purpose/Change: Initial script development
  
.EXAMPLE
  Modify BOTH SETS of username/password variables (Line 97) --> enter UC-ENGINE IP addresses into IP.txt file --> Run Script--> script will output device info to C:\MTR  Results.csv
#>


write-host @"  



  _    _  _____      ______ _   _  _____ _____ _   _ ______ 
 | |  | |/ ____|    |  ____| \ | |/ ____|_   _| \ | |  ____|
 | |  | | |   ______| |__  |  \| | |  __  | | |  \| | |__   
 | |  | | |  |______|  __| | . ` | | |_ | | | | . ` |  __|  
 | |__| | |____     | |____| |\  | |__| |_| |_| |\  | |____ 
  \____/ \_____|    |______|_| \_|\_____|_____|_| \_|______|
  / ____|                     / ____|         (_)     | |   
 | (___  _   _ _ __   ___ _ _| (___   ___ _ __ _ _ __ | |_  
  \___ \| | | | '_ \ / _ \ '__\___ \ / __| '__| | '_ \| __| 
  ____) | |_| | |_) |  __/ |  ____) | (__| |  | | |_) | |_  
 |_____/ \__,_| .__/ \___|_| |_____/ \___|_|  |_| .__/ \__| 
              | |                               | |         
              |_|                               |_|         

                                                               
                                                                                   
    v1.8                                                 
    Written By: Anthony Tippy

    NOTE: THIS SCRIPT MUST BE RUN AS ADMINISTRATOR OR IT WILL NOT WORK!!!"

                                                                                                                                                           
"@


#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

if (Get-Module -ListAvailable -Name PSCrestron) {
} 
else {
    Write-Host "PSCrestron Module Not Installed. Please Install PSCrestron Module and Try Again!"
    exit
}


#Remove Old Output Doc
Remove-Item -Path "$home\MTR Results.csv" -ErrorAction SilentlyContinue -Force
Remove-Item -Path "$home\Autodiscovery Results.csv" -ErrorAction SilentlyContinue -Force


#load IP from TXT list
$devs =  @(Get-Content (Join-Path $PSScriptRoot 'IP.txt'))


Invoke-RunspaceJob -InputObject $devs -ScriptBlock {

Clear-Variable -include -name $autodiscovery,$row, $deviceHostname, $serial,$serialpost,$Crestronfirmware, $GraphicsFile, $computer , $process, $devices, $devicesraw, $touchpanel, $cprocessor, $programFileName, $sleepsettings,  $sleepout, $Data

$Data = @()

Set-Item wsman:\localhost\Client\TrustedHosts -value "$_" -Concatenate -Force -ErrorAction Stop
Write-host -f Green "`nConnecting to: $_`n"

$Data = New-object PSObject

#MTR Credentials  
$Username = 'MTR USERNAME'
$Password = 'MTR PASSWORD'

#Crestron Device Credentials
$cusername = "USERNAME"
$cpassword = "PASSWORD"

$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$pass

$time = (get-date)
# Table Coulumn 1 - Time
$Data | Add-Member -Name "Time" -MemberType NoteProperty -Value $time

$autodiscovery = get-autodiscovery -EndPoint "$_" -erroraction SilentlyContinue


$autodiscovery | export-csv -Path "$home\Autodiscovery Results.csv" -NoTypeInformation -Append -erroraction SilentlyContinue


$IMPORT = import-csv -Path "$home\Autodiscovery Results.csv" | sort IP, Hostname -Unique
$row = $IMPORT | Where IP -eq "$_"
#write-host $row

#Hostname Autodiscovery
$deviceHostname = $row.Hostname

#Serial Number
$serial = [regex]::Match($row.Description, "(?<=#)[0-9a-fA-F]{8}").value 
$serialpost = Convert-TsidToSerial -TSID "$serial" 
#write-host "$_ Serial Number: $serialpost"

#Crestron Firmware
$Crestronfirmware = [regex]::Match($row.Description, "(?<=\[v)[0-9\.]+").value


# Add Row to table
$Data | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $_
# Add Row to table
$Data | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname

# Add Row to table
$Data | Add-Member -Name "Crestron Firmware Version" -MemberType NoteProperty -Value $Crestronfirmware
# Add Row to table
$Data | Add-Member -Name "Crestron Serial Number" -MemberType NoteProperty -Value $serialpost


#Get-Computer-Info Command
$computer = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
    Get-ComputerInfo | Select-object -property PSComputerName, CsDNSHostName, WindowsVersion, BiosSeralNumber, BiosBIOSVersion, CsModel,OsVersion, OsBuildNumber, OsLocalDateTime, OsLastBootUpTime, OsUptime  -ErrorAction Continue 
}

#Computer Info Reporting
# Add Row to table
$Data | Add-Member -Name "Model" -MemberType NoteProperty -Value $computer.CsModel
# Add Row to table
$Data | Add-Member -Name "Windows Version" -MemberType NoteProperty -Value $computer.WindowsVersion
# Add Row to table
$Data | Add-Member -Name "Windows Version Full" -MemberType NoteProperty -Value $computer.OsVersion
# Add Row to table
$Data | Add-Member -Name "BIOS Version" -MemberType NoteProperty -Value $computer.BiosBIOSVersion
# Add Row to table
$Data | Add-Member -Name "OS Build Number" -MemberType NoteProperty -Value $computer.OsBuildNumber
# Add Row to table
$Data | Add-Member -Name "Last Boot Time" -MemberType NoteProperty -Value $computer.OsLastBootUpTime
# Add Row to table
$Data | Add-Member -Name "Device Time" -MemberType NoteProperty -Value $computer.OsLocalDateTime
# Add Row to table
$Data | Add-Member -Name "Uptime" -MemberType NoteProperty -Value $computer.OsUptime


#Graphics File
$GraphicsFile =  Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
    dir "C:\Program Files\Crestron\CCS400\User\Display" *.vtx| select BaseName -ErrorAction Continue 
}
$GraphicsFile = $GraphicsFile | Select-Object -Property Basename -ExpandProperty BaseName

# Add Row to table
$Data | Add-Member -Name "Graphics File" -MemberType NoteProperty -Value $GraphicsFile



#List MTR Process
$process = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
    get-process DesktopAPIService |select-object -property Name, ProductVersion, CPU -ErrorAction Continue 
}

#Process Reporting
# Add Row to table
$Data | Add-Member -Name "MTR App Version" -MemberType NoteProperty -Value $process.ProductVersion
# Add Row to table
$Data | Add-Member -Name "MTR APP CPU Usage" -MemberType NoteProperty -Value $process.CPU




$devices = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
#gwmi -Class Win32_PnPEntity
gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Image"} | Select-Object -Property Name 
gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Media"} | Select-Object -Property Name
gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "Monitor"} | Select-Object -Property Name
gwmi -Class Win32_PnPEntity | where {$_.PNPClass -eq "AudioEndpoint"} | Select-Object -Property Name
}
$devicesraw = $devices | Select-Object -Property Name -ExpandProperty Name | out-string

#Attached Devices
# Add Row to table
$Data | Add-Member -Name "Attached Devices" -MemberType NoteProperty -Value $devicesraw

$touchpanel = " "
#TouchPanel Information
$touchpanel = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
Get-NetTCPConnection -State Established |
Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State,
                       @{name='Process';expression={(Get-Process -Id $_.OwningProcess).Name}} | where -Property Process -eq "VMKServer"
}
$paneladdress = $touchpanel.RemoteAddress

#Touch Panel Info  Add Row to table
$Data | Add-Member -Name "MTR Touch Panel IP" -MemberType NoteProperty -Value $touchpanel.RemoteAddress

#Touch Panel Info # Add Row to table
#$Data | Add-Member -Name "MTR Touch Panel IP" -MemberType NoteProperty -Value $touchpanel.RemoteAddress

try { 
        $panelversion = Invoke-CrestronCommand -Device $paneladdress -Command "ver" -Secure
        $panelversion = [regex]::Match($panelversion, "(?<=\[v)[0-9\.]+").value
    }
catch{
        $panelversion =  Invoke-CrestronCommand -Device $paneladdress -Command "ver" -Secure -username $cusername -password $cpassword
        $panelversion = [regex]::Match($panelversion, "(?<=\[v)[0-9\.]+").value
    }

#Attached Devices
# Add Row to table
$Data | Add-Member -Name "Touchpanel Firmware" -MemberType NoteProperty -Value $panelversion

$cprocessor = " "
#Control Processor Information
$cprocessor = Invoke-Command -ComputerName $_ -Credential $Cred -ScriptBlock {
Get-NetTCPConnection -State Established |
Select-Object -Property LocalAddress, LocalPort, RemoteAddress, RemotePort, State,
                       @{name='Process';expression={(Get-Process -Id $_.OwningProcess).Name}} | where -Property Process -eq "UtsEngine" |where -Property RemotePort -eq "41794"
}
  
#Control Processor Info  Add Row to table
$Data | Add-Member -Name "Control Processor" -MemberType NoteProperty -Value $cprocessor.RemoteAddress

try{
#Control Processor Firmware
$processorfirmware = Invoke-CrestronCommand -Device $cprocessor.RemoteAddress -Command "ver" -secure
#write-host $processorfirmware 
$processorfirmware = [regex]::Match($processorfirmware, "(?<=\[v)[0-9\.]+").value
}
catch{ #write-host -f Red "$cprocessor.RemoteAddress :unable to connect to control processor via default pass"
#Control Processor Firmware
$processorfirmware = Invoke-CrestronCommand -Device $cprocessor.RemoteAddress -Command "ver" -username $cusername -password $cpassword -secure
#write-host $processorfirmware
$processorfirmware =   [regex]::Match($processorfirmware, "(?<=\[v)[0-9\.]+").value 
}

#Control Processor Info # Add Row to table
$Data | Add-Member -Name "Control Processor Firmware" -MemberType NoteProperty -Value $processorfirmware


#Get Control Processor File
$progcomResponce =""
$programFileName =""
try{
#Control Processor File
$progcomResponce = Invoke-CrestronCommand -Device $cprocessor.RemoteAddress -Command "progcom" -secure
$programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 
}
catch{ #write-host -f Red "$cprocessor.RemoteAddress :unable to connect to control processor via default pass"
#Control Processor File
$progcomResponce = Invoke-CrestronCommand -Device $cprocessor.RemoteAddress -Command "progcom" -username $cusername -password $cpassword -secure
$programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value 
}
#Control Processor Info # Add Row to table
$Data | Add-Member -Name "Processor Program File" -MemberType NoteProperty -Value $programFileName


$sleepsettings = ""
$sleepout = ""
$sleepsettings = Invoke-Command -ComputerName $computer.PSComputerName -Credential $Cred -ScriptBlock {

$scheme = (Get-WmiObject -Namespace Root\CIMV2\power -Class win32_powerplan  -Filter  isActive='true' ). ElementName

$settingindex = powercfg /query scheme_$scheme sub_sleep standbyidle | Where-Object {$_ -Like "*Setting Index*"}

                #For each power scheme (AC/DC) convert hexadecimal to 16-base decimal for seconds
                ForEach ($setting in $settingindex) {
                        
                    Write-Verbose "Getting ready to split and convert $setting" 
                    $power = $setting.split()[5]
                    $hex = $setting.split()[9]
                    $minutes = [Convert]::toint16("$hex",16) / 60
                   
                    If ($minutes -eq 0) {
                    Write-output "Sleep setting for $power is Never (0 minutes)" -Verbose
                    }
                    Else {
                    Write-output "Sleep setting for $power is $minutes minutes" -Verbose
                    }
                   
                }

} -Verbose
$sleepout = $sleepsettings |out-string


# Add Row to table
$Data | Add-Member -Name "Current Sleep Setting" -MemberType NoteProperty -Value $sleepout
 

#output data to csv export file
$Data | export-csv -Path "$home\MTR Results.csv" -NoTypeInformation -Append
} -ShowProgress 


#COLLECT RESULTS INTO GRID VIEW
import-csv -Path "$home\MTR Results.csv" |out-gridview
#Add results to long running log (not deleted upon run)
import-csv -Path "$home\MTR Results.csv" | Export-Csv  "$home\MTR Results Log.csv" -Append 


Write-Host "`nDone!"

#Total time of script
$stopwatch

Read-Host -Prompt “Press Enter to exit”

