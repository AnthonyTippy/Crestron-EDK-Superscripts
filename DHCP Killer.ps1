<# This Script connects to devices from an IP list and grabs the IP information, 
then sets the device to static ip address, disables DHCP, and then reboots to confirm changes#>

write-host @"                        


    ____  __  ____________     __ __ _ ____         
   / __ \/ / / / ____/ __ \   / //_/(_) / /__  _____
  / / / / /_/ / /   / /_/ /  / ,<  / / / / _ \/ ___/
 / /_/ / __  / /___/ ____/  / /| |/ / / /  __/ /    
/_____/_/ /_/\____/_/      /_/ |_/_/_/_/\___/_/     
              
              
                                                    
    Based on script from: Brandon Meiklejohn 
    Stolen by: Anthony Tippy 


"@

# import libraries
Import-Module PSCrestron

#User Provided Device Info
$dns1 = "8.8.8.8"  #Enter DNS of your choice
$dns2 = "8.8.4.4"  #Enter DNS of your choice

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#create a new object to hold the restults data
$DeviceResultsData =@()      

#Initilize the table
$DeviceResultsData | Out-GridView -Title "Device Status Results"

# import device file
try
	{
	$devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
	}
catch
	{
	Write-Host 'Error Obtaining list of devices'
	}

# loop for each device
foreach ($d in $devs)
  {
    try {
       
        $DeviceResultItem = New-Object PSObject
        write-host " "
	    Write-Host 'Running commands for:' $d
        
        $session = Open-CrestronSession -Device $d -secure #-username "admin" -password "Toyota123$"
       
        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-Output "Working on => $d | $deviceHostname"

        #ver
        $VERResponce = Invoke-CrestronSession $session "ver"
        $deviceModel =  [regex]::Match($VERResponce, "^([^\s]+)").value
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value

        #progcom
        $progcomResponce = Invoke-CrestronSession $session "progcom"
        $programFileName =   [regex]::Match($progcomResponce, "([^Program File:\s])(.*?)(\.smw)").value
        
        #est
        $estResponce = Invoke-CrestronSession $session "est"

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

#Change IP Address
write-host 'Setting Static IP Address'
$setIP = Invoke-CrestronSession $session "ipa 0 $deviceIP"
#write-host "-Static IP Address Set"


#set Subnet Mask
write-host 'Setting subnet mask'
$setmask = Invoke-CrestronSession $session "ipm 0 $deviceSM"
#write-host "-Subnet Mask Set"

#set gateway
write-host 'Setting gateway'
$setgateway = Invoke-CrestronSession $session "defroute 0 $deviceDG"
#write-host "-Gateway Set"

#set DNS
write-host 'Setting DNS'
$setdns = Invoke-CrestronSession $session "adddns $dns1"
#write-host "-Success:New DNS value set: $dns1"

$setdns = Invoke-CrestronSession $session "adddns $dns2"
#write-host "-Success:New DNS value set: $dns2"

#Disable DHCP
write-host 'Disabling DHCP'
$disabledhcp = Invoke-CrestronSession $session "dhcp 0 off"
#write-host "-DHCP Disabled"

#Reboot Device
write-host 'SUCCESS - Rebooting Device =>' $deviceIP $deviceHostname
$reboot = Invoke-CrestronSession $session "reboot"
#write-host $reboot


#Build Table
# Table Coulumn 1 - hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname
# Table Coulumn 2 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 4 - version
$DeviceResultItem | Add-Member -Name "Version" -MemberType NoteProperty -Value $deviceVer
# Table Coulumn 5 - mac
$DeviceResultItem | Add-Member -Name "MAC Address" -MemberType NoteProperty -Value $deviceMAC
# Table Coulumn 6 - ip
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $deviceIP
# Table Coulumn 7 - subnet mask
$DeviceResultItem | Add-Member -Name "Subnet Mask" -MemberType NoteProperty -Value $deviceSM
# Table Coulumn 8 - default gateway
$DeviceResultItem | Add-Member -Name "Default Gateway" -MemberType NoteProperty -Value $deviceDG
# Table Coulumn 9 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value $programFileName
 
#Add line to the report
$DeviceResultsData += $DeviceResultItem

Close-CrestronSession $session

    } catch {
        Write-Host "Error Connecting to " $d
        Continue 
    }
  }
$DeviceResultsData | Out-GridView -Title "Device Status Results"
$DeviceResultsData | export-csv -Path (Join-Path $PSScriptRoot "DHCP Change.csv")

#Total time of script
$stopwatch
