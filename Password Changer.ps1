
<#
.SYNOPSIS
    Connects to Crestron Devices in IP.txt of local script directory via SSH.  Changes already set password to new password (AUTH ALREADY ENABLED) 

.DESCRIPTION
  Connects to Crestron Devices in IP.txt of local script directory via SSH.  If default password is set, script will set password to user specified password (Line 104)
  Script reports results out to root directory with whether the password was changed[New], previously set, or error connecting


.PARAMETER <Parameter_Name>
    none

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - IP.txt text file containing IP addresses of devices (One per line)

.OUTPUTS
  C:\Desktop\Superscript Results.csv

.NOTES
  Version:        1.0
  Author:         Anthony Tippy
  Creation Date:  11/29/2021
  Purpose/Change: initial dev
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> script--> script will output device info $home\Password Change Results.csv"
#>




write-host -f cyan @"  




██████╗  █████╗ ███████╗███████╗██╗    ██╗ ██████╗ ██████╗ ██████╗ 
██╔══██╗██╔══██╗██╔════╝██╔════╝██║    ██║██╔═══██╗██╔══██╗██╔══██╗
██████╔╝███████║███████╗███████╗██║ █╗ ██║██║   ██║██████╔╝██║  ██║
██╔═══╝ ██╔══██║╚════██║╚════██║██║███╗██║██║   ██║██╔══██╗██║  ██║
██║     ██║  ██║███████║███████║╚███╔███╔╝╚██████╔╝██║  ██║██████╔╝
╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝ ╚══╝╚══╝  ╚═════╝ ╚═╝  ╚═╝╚═════╝ 
                                                                   
██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗██████╗          
██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝██╔══██╗         
██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  ██████╔╝         
██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  ██╔══██╗         
╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗██║  ██║         
 ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝         
                                                                   

                                                                                     
                                                        
    Written By: Anthony Tippy



                                                                                                                                                           
"@


# import libraries
Import-Module PSCrestron

$passchanged = " "

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()


#create a new object to hold the restults data
$DeviceResultsData =@()      

#Initilize the table
$DeviceResultsData | Out-GridView -Title "Device Status Results"

#clear out device error count
$devicerror = " " 

#Delete Old Results from previous script run
remove-item -Path  "$home\Password Update Results.csv" -ErrorAction SilentlyContinue 


# import device file
try
	{
	$devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
    write-host " "
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device list.txt is in same directory as script!!!'
	}



# loop for each device
foreach ($d in $devs){


#### ENTER CREDENTIALS HERE #####


$username = "EXISTING USERNAME"
$password = "EXISTING PASSWORD"

$newpassword = "NEW PASSWORD TO BE SET"

                          
#### ENTER CREDENTIALS HERE #####


    try {
        #Clear Connect Error
        
        $Errors = " "
        $AuthMethod = " "

        #New Data Object
        $DeviceResultItem = New-Object PSObject
        
	    Write-Host -f green "`n`nConnecting to : $d"
        
        try{
        #Connect to Device via SSH with old password
        $session = Open-CrestronSession -Device $d -Secure -Username $username -Password $password 

        #Grab device hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-host -f green "Working on => $deviceHostname`n`n`n`n"
        }
        catch{"$d : Error Opening Crestron Session"
        $deviceHostname = " "
        $ConnectError = "Error Opening Crestron Session,"
        $Errors += $ConnectError 
        Stop}

        try{
        #Set Username/Password 
        Invoke-CrestronSession $session 'UPDATEPassword'

        #Enter Current Password
        Invoke-CrestronSession $session "$password"

        #Enter Updated Pass x2
        Invoke-CrestronSession $session "$newpassword"
        Invoke-CrestronSession $session "$newpassword"

        #Reboot Device to confirm changes
        Invoke-CrestronSession $session 'reboot'
        #Close-CrestronSession $session

        Write-host -f Green "$deviceHostname : Password Successfully Changed`n`n`n`n"
        $AuthMethod = 'Password [New]'
        }
        catch{"$d - $hostname : Error Changing Password`n"
        $AuthMethod = 'Password Change Fail'
        $ConnectError = "Error Changing password,"
        $Errors += $ConnectError 
        stop}
        }

    catch {
        Write-host -f red "$d : Unable to Connect!`n"
        }

#Current Date/Time
$time = (get-date)

#Build Table
# Table Coulumn 1 - Time
$DeviceResultItem | Add-Member -Name "Time" -MemberType NoteProperty -Value $time
# Table Coulumn 2 - IP Address
$DeviceResultItem | Add-Member -Name "IP Address" -MemberType NoteProperty -Value $d
# Table Coulumn 3 - Hostname
$DeviceResultItem | Add-Member -Name "Hostname" -MemberType NoteProperty -Value $deviceHostname
# Table Coulumn 4 - Authentication
$DeviceResultItem | Add-Member -Name "Authentication" -MemberType NoteProperty -Value $AuthMethod
# Table Coulumn 5 - Error
$DeviceResultItem | Add-Member -Name "Error" -MemberType NoteProperty -Value $Errors

#Add line to the report
$DeviceResultsData += $DeviceResultItem

} 

#OutGrid Preview of Results
$DeviceResultsData | Out-GridView -Title "Password Update Results"

#Append results to Password Change Results Document + Log 
$DeviceResultsData | Export-Csv -Path "$home\Password Update Results.csv" -NoTypeInformation -append
$DeviceResultsData | Export-Csv -Path "$home\Password Update Results Log.csv" -NoTypeInformation -append


#Open Password Change Results CSV
Invoke-Item -Path "$home\Password Update Results.csv"


#Total time of script
$stopwatch
