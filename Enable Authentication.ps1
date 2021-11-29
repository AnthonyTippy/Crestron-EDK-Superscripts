
<#
.SYNOPSIS
    Connects to Crestron Devices in IP.txt of local script directory via SSH.  If default password is set, script will set password to user specified password. 

.DESCRIPTION
  Connects to Crestron Devices in IP.txt of local script directory via SSH.  If default password is set, script will set password to user specified password (Line 96)
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
  Creation Date:  11/29/201
  Purpose/Change: initial dev
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> script--> script will output device info $home\Password Change Results.csv"
#>




write-host -f cyan @"  




Enable Authentication
(Set password from default auth)       
                                                                   

                                                                                     
                                                        
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
remove-item -Path  "$home\Password Change Results.csv" -ErrorAction SilentlyContinue 


# import device file
try
	{
	$devs =  @(Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
    write-host " "
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device list.txt is in same directory as script!!!'
	}



# loop for each device
foreach ($d in $devs){



####  Credentials  ####

$username = "USERNAME"
$password = "PASSWORD"

####  Credentials  ####




    try {
        #Clear Connect Error
        $ConnectError = " " 

        #New Data Object
        $DeviceResultItem = New-Object PSObject
        
	    Write-Host -f green 'Running commands for:' $d

        #Connect to Device via SSH Default pass/no pass
        $session = Open-CrestronSession -Device $d -Secure -ErrorAction SilentlyContinue

        #hostname
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value
        Write-Output -f green "Working on => $deviceHostname`n`n`n`n"

        #Set Username/Password 
        Invoke-CrestronSession $session 'AUTH ON'
        Invoke-CrestronSession $session "$username"
        Invoke-CrestronSession $session "$password"
        Invoke-CrestronSession $session "$password"

        #Reboot Device to confirm changes
        Invoke-CrestronSession $session 'reboot'
        Close-CrestronSession $session
        
        Write-host -f Green "$deviceHostname : Password Successfully Changed`n`n`n`n"
        $AuthMethod = 'Custom Password [New]'
        }

    catch {
        Write-host -f yellow "`n-Default Password Unsuccessful`n"
        
	    #Test for Custom Password
        Try {
            #Connect to Device via SSH with credentials provided
            $session = Open-CrestronSession -Device $d -Secure -username $username -password $password -ErrorAction Continue
        
            #Get device hostname hostname
            $hostnameResponce = Invoke-CrestronSession $session "hostname"
            $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value

            Write-host -f Green "$deviceHostname ($d) - Password is already set`n`n`n`n"

            Close-CrestronSession $session
            $AuthMethod = 'Custom Password'
            }

        #Catch for error connecting after default/Custom password
        catch {
            $deviceHostname =" "
            $ConnectError = "Connection Attempts Unsuccessful"
            Write-Host -f Red "`n $d - Default & Custom Password Attempts Unsuccessful: Could NOT Connect!`n`n`n`n"
            $AuthMethod = 'Unknown Password/Error'
            }

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
$DeviceResultItem | Add-Member -Name "Error" -MemberType NoteProperty -Value $ConnectError

#Add line to the report
$DeviceResultsData += $DeviceResultItem

} 

#OutGrid Preview of Results
$DeviceResultsData | Out-GridView -Title "Password Change Results"

#Append results to Password Change Results Document + Log 
$DeviceResultsData | Export-Csv -Path "$home\Password Change Results.csv" -NoTypeInformation -append
$DeviceResultsData | Export-Csv -Path "$home\Password Change Results Log.csv" -NoTypeInformation -append


#Open Password Change Results CSV
Invoke-Item -Path "$home\Password Change Results.csv"


#Total time of script
$stopwatch
