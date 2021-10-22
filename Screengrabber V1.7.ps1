
<#
.SYNOPSIS
  Script will grab screenshots of Crestron touch panels (TSW series)

.DESCRIPTION
  Script connects to each touchpanel on the IP.txt file and issues the screenshot command.  Screenshot is named according to the hostname of the panel.
  Screenshot is then extracted from the panel to the C:\Desktop\Screenshots folder.  Script is capable of running on up to X devices simultaneously.

.PARAMETER <Parameter_Name>
    none

.INPUTS
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - IP.txt text file containing IP addresses of devices (One per line)

.OUTPUTS
  C:\Desktop\Screenshots

.NOTES
  Version:        1.7
  Author:         Anthony Tippy
  Creation Date:  05/06/2021
  Purpose/Change: Feature Update.  Adds "poke" to panels before grab.  Converts file from .bmp to .png for easier handling
  
.EXAMPLE
  Modify username/password variables --> enter IP addresses into IP.txt file --> screenshot should be saved to C:\Desktop\Screenshots folder
#>

write-host @"  



███████╗ ██████╗██████╗ ███████╗███████╗███╗   ██╗     ██████╗ ██████╗  █████╗ ██████╗ ██████╗ ███████╗██████╗ 
██╔════╝██╔════╝██╔══██╗██╔════╝██╔════╝████╗  ██║    ██╔════╝ ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔══██╗
███████╗██║     ██████╔╝█████╗  █████╗  ██╔██╗ ██║    ██║  ███╗██████╔╝███████║██████╔╝██████╔╝█████╗  ██████╔╝
╚════██║██║     ██╔══██╗██╔══╝  ██╔══╝  ██║╚██╗██║    ██║   ██║██╔══██╗██╔══██║██╔══██╗██╔══██╗██╔══╝  ██╔══██╗
███████║╚██████╗██║  ██║███████╗███████╗██║ ╚████║    ╚██████╔╝██║  ██║██║  ██║██████╔╝██████╔╝███████╗██║  ██║
╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═══╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                                               
           
           v1.7
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
#Delete old Screenshot Folder
Remove-Item "$home\Desktop\Screenshots" -Recurse -ErrorAction SilentlyContinue

#Create Screenshot folder
New-Item -Path "$home\Desktop\" -Name "Screenshots" -ItemType "directory" -ErrorAction SilentlyContinue


#Import PSCRESTRON MODULE
Import-Module PSCrestron

$local = " "
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
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {



#####ENTER CREDENTIALS HERE!####

$username = 'ENTERUSERNAMEHERE'
$password = 'ENTERPASSWORDHERE'

################################



    try {
        $d = $_
        $DeviceResultItem = New-Object PSObject

        #New Crestron Session
        $session = Open-CrestronSession -Device $d -secure 
        #Read-Host -Prompt “Crestron Session Connected Press Enter to exit`n"
        
        #fake touch screen to wake system
        $faketouch = Invoke-CrestronSession $session "faketouch 10 10 10"

        #Hostname Extraction
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value

        #Invoke-CrestronSession $session "sntp sync"

        Write-Host -f Green "`n`n`n[Default Password]  Grabbing Screenshot for:" $d "==>" $deviceHostname
        $shotname = $d+"-"+$deviceHostname
        #write-host $shotname

        #Screenshot command
        $screenshot= Invoke-CrestronSession $session "screenshot $shotname"

        $Remotefile = ('logs\' + $shotname + '.bmp')

        Get-FTPFile -Device $d -RemoteFile $Remotefile -localPath "$home\Desktop\Screenshots" -secure -erroraction Continue 

        #Convert from .bmp to .png for easier file uploading
        rename-item "$home\Desktop\Screenshots\$shotname.bmp" -NewName "$home\Desktop\Screenshots\$shotname.png"

        #Cleanup -Remove Screenshot from device
        $cleanup = Remove-FTPFile -device $d -RemoteFile $Remotefile -secure -erroraction Continue

        #Close Crestron Session
        Close-CrestronSession $session
        } 

    catch {#"$_ Default Password Couldn't connect - Trying Custom Password"
        try {

        $DeviceResultItem = New-Object PSObject

        #New Crestron Session
        $session = Open-CrestronSession -Device $d -secure -Username $username -Password $password

        #fake touch screen to wake system
        $faketouch = Invoke-CrestronSession $session "faketouch 10 10 10"

        #Hostname Extraction
        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value

        #Invoke-CrestronSession $session "sntp sync"

        Write-Host -f Green "`n`n`n[Custom Password]  Grabbing Screenshot for:" $d "==>" $deviceHostname
        
        $shotname = $d+"-"+$deviceHostname
        #write-host $shotname

        #Screenshot command
        $screenshot= Invoke-CrestronSession $session "screenshot $shotname"
        #write-host $screenshot

        $Remotefile = ('logs\' + $shotname + '.bmp')
        #write-host $Remotefile

        #Grab Screenshot via FTP
        $ftpgrab = Get-FTPFile -Device $d -RemoteFile $Remotefile -localPath "$home\Desktop\Screenshots" -Username $username -Password $password -secure -erroraction Inquire 
        #write-host $ftpgrab

        #Convert from .bmp to .png for easier file uploading
        rename-item "$home\Desktop\Screenshots\$shotname.bmp" -NewName "$home\Desktop\Screenshots\$shotname.png"

        #Cleanup -Remove Screenshot from device
        $cleanup = Remove-FTPFile -device $d -RemoteFile $Remotefile  -Username $username -Password $password  -secure -erroraction Inquire 
        #write-host $cleanup

        #Close Crestron Session
        Close-CrestronSession $session
        } 

        Catch {
            Write-Host -f Red "`n`n`nError Connecting to " $d
            write-host " "
            #$d | export-csv -Path ".\Desktop\Failed Screengrabber IP.csv" -NoTypeInformation -Append 
            new-item -path "$home\Desktop\Screenshots" -Name "$d.bmp" -ItemType "file"
            $d | out-file -FilePath "$home\Desktop\Screenshots\Errors.txt" -Append
            Continue 
               }
    }
} -throttlelimit 40 -ShowProgress

invoke-item "$home\Desktop\Screenshots"

#Total time of script
$stopwatch

write-host -f Cyan "`n`nScreenshots saved to C:\Desktop\Screenshots"
invoke-item "$home\Desktop\Screenshots"


Read-Host -Prompt “Press Enter to exit”
