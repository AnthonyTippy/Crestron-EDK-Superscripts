#Import PSCRESTRON MODULE
Import-Module PSCrestron

#Count
$devicerror= 0
$counterror= 0

write-host " " 

$IP = Read-Host "Please Enter Device IP: "

$local = $PSScriptRoot


# import device file
try
	{
    $devs = (Get-Content -Path (Join-Path $PSScriptRoot 'IP.txt'))
	Write-Host ' '
	}
catch
	{
	Write-Host 'Error Obtaining list of devices. Make sure device IP.txt is in same directory as script!!!'
	}


foreach ($d in $devs)
  {
    try {
        
        $DeviceResultItem = New-Object PSObject
        
	    Write-Host 'Grabbing Screenshot for:' $d

        $session = Open-CrestronSession -Device $d -secure

        $hostnameResponce = Invoke-CrestronSession $session "hostname"
        $deviceHostname = [regex]::Match($hostnameResponce, "(?<=Host\sName:\s)[\w-]+").value

        Invoke-CrestronSession $session "screenshot $deviceHostname"
        
        Write-host " "

        $Remotefile = ('logs\' + $deviceHostname + '.bmp')
  
        Get-FTPFile -Device $d -RemoteFile $Remotefile -LocalPath $local -secure

        Close-CrestronSession $session

        Write-Host "Screenshot saved to: $local"
        Write-Host "Direct Link to Screenshot : ftp://crestron@$d/logs/$deviceHostname.bmp"
        write-host
        } 

    catch {
        Write-Host "Error Connecting to " $d
        write-host " "

        #$devicerror += "$d`n"
        $counterror=$counterror+1

        Continue 
    }
  }

write-host " "
write-host 'Devices with Errors: '$counterror
write-host " "
write-host $devicerror

Read-Host -Prompt “Press Enter to exit”

