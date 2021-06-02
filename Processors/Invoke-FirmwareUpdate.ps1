Import-Module PSCrestron

function Invoke-FirmwareUpdate {
    <#
	.SYNOPSIS

	    Downloads a firmware PUF from an FTP server then uploads and updates to devices.

	.DESCRIPTION

        The Invoke-FirmwareUpdate cmdlet allows the user to download a firmware PUF from
        an FTP server then upload it to a list of devices from a CSV file then update those
        same devices.
		
	.PARAMETER FtpServer

        Specifies the IP address or hostname of the FTP server.
        
    .PARAMETER FirmwareLocation

        Specifies the location of the firmware PUF on the FTP server.
			
    .PARAMETER Username

        The username to use for the ftp server if it's required.
	
    .PARAMETER Password

        The password to use for the ftp server if it's required.

    .PARAMETER DeviceList

	    Specifies the directory and name for the CSV with the list of devices in the format IP,Port,Procname.
        
	.EXAMPLE

		Invoke-FirmwareUpdate -FtpServer 'ftp.crestron.com' -FirmwareLocation '/firmware/tsw-xx60/tsw-xx60_3.000.0014.001.puf' -Username 'XXXXXXXX' -Password 'XXXXXX' -DeviceList './DeviceList.csv'
		
	.NOTES

		Author: Jay
	#>    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [supportswildcards()]
        [string]$FtpServer,

        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
        [supportswildcards()]
        [string]$FirmwareLocation,

        [Parameter(Mandatory=$false,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
        [supportswildcards()]
        [string]$Username,

        [Parameter(Mandatory=$false,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
        [supportswildcards()]
        [string]$Password,

        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)]
        [AllowNull()]
        [supportswildcards()]
        [string]$DeviceList
    )
    
####Bring in CSV file
Import-Csv -Path $deviceList | ForEach-Object {[PSCustomObject]@{'IP' = $_.IP; 'Port' = $_.Port; 'Procname' = $_.Procname}}

####Firmware files will be stored in local Downloads Directory
$LocalDir = 'C:\Users\$([Environment]::UserName)\Downloads'

####Download firmare from FTP location
Get-FTPFile -Device $FtpServer -RemoteFile $FirmwareLocation -Username $Username -Password $Password -LocalPath $LocalDir


####Send firmware to Device
Update-PUF -Device $IP -Port $Port -Path $LocalDir -ShowProgress

}