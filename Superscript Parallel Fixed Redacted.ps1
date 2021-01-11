### Crestron Parallel SuperScript V1.4
###Script will call IP addresses from list and gather device information as well as program and DHCP state data
#YOU MUST FILL OUT THE PROPER USERNAME/PASSWORD BEFORE RUNNING

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
                                                                                     
    V1.4                                                    
    Written By: Anthony Tippy



                                                                                                                                                           
"@
#Create IP.txt File if not there
New-Item -Path . -Name "IP.txt" -ItemType "file" -ErrorAction SilentlyContinue

#Credentials
$username = 'USERNAME HERE'
$password = 'PASSWORD HERE'

#Import PSCRESTRON MODULE
Import-Module PSCrestron


#create a new object to hold the restults data
$DeviceResultsData =@()      

#Initilize the table
$DeviceResultsData | Out-GridView -Title "Device Status Results"

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

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
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {
$DeviceResultItem = New-Object PSObject
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
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value $programFileName
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

$DeviceResultsData | export-csv -Path (".\desktop\Superscript Results.csv") -NoTypeInformation -Append

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
        Write-host -f Green "[Toyota Password] Working on => $deviceHostname" $d "`n`n`n" 
        write-output " "
        
        #ver
        $VERResponce = Invoke-CrestronSession $session "ver" 
        $deviceModel =  [regex]::Match($VERResponce, "\w([^[]+)").value  #$deviceModel =  [regex]::Match($VERResponce, "^([^\s]+)").value
        $deviceTSID = [regex]::Match($VERResponce, "(?<=#)[0-9a-fA-F]{8}").value
        $deviceSerial = Convert-TsidToSerial -TSID $deviceTSID
        $deviceVer = [regex]::Match($VERResponce, "(?<=\[v)[0-9\.]+").value
        write-host $VERResponce
        

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
# Table Coulumn 1 - model
$DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value $deviceModel
# Table Coulumn 3 - serial
$DeviceResultItem | Add-Member -Name "Serial Number" -MemberType NoteProperty -Value $deviceSerial
# Table Coulumn 6 - Program Name
$DeviceResultItem | Add-Member -Name "Program File Name" -MemberType NoteProperty -Value $programFileName
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


#$DeviceResultsData | Out-File -FILEPATH ("C:\Users\461194\Desktop\Crestron PS scripts\Paralell Superscript.txt") -Append
$DeviceResultsData | export-csv -Path (".\desktop\Superscript Results.csv") -NoTypeInformation -Append

Close-CrestronSession $session
        }

        catch {write-host -f red "$d : Error Connecting!`n`n`n" 
        
            #Build Table
            # Table Coulumn 1 - model
            $DeviceResultItem | Add-Member -Name "Model" -MemberType NoteProperty -Value " "#$deviceModel
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

            #$DeviceResultsData | Out-File -FILEPATH ("C:\Users\461194\Desktop\Crestron PS scripts\Paralell Superscript.txt") -Append
            $DeviceResultsData | export-csv -Path (".\desktop\Superscript Results.csv") -NoTypeInformation -Append
            }
            }

}-ThrottleLimit 30  -ShowProgress #-TIMEOUT 1 

#Total time of script
$stopwatch


Read-Host -Prompt “Press Enter to exit”