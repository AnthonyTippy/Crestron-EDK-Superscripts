function Invoke-CertificateLoad {
    <#
	.SYNOPSIS

	    Uploads a certificate to a Crestron AirMedia device.

	.DESCRIPTION

	    The Invoke-CertificateLoad cmdlet uploads a password projected .pfx certificate to the webserver certificate store internally on Crestron AirMedia devices.
		
	.PARAMETER DeviceUsername

	    Specifies the username used to access the device.
			
	.PARAMETER DevicePassword

	    Specifies the password used to access the device.
	
	.PARAMETER CertPath

	    Specifies the path to the .pfx certificate that will be uploaded.
	
    .PARAMETER PrivKeyPass

        Specifies the password for the certificate file.
	
	.EXAMPLE

		Invoke-CertificateLoad -DeviceUsername <usename> -DevicePassword <password> -CertPath <path to password protected .pfx file> -PrivKeyPass <password for cert/private key>
		
	.NOTES

		Author: Jay Allbright

    #>    
    
    [CmdLetBinding()]
    param
    (
		[parameter(Mandatory=$true)]
        [string]$DeviceUsername,

		[parameter(Mandatory=$true)]
        [securestring]$DevicePassword,

        [parameter(Mandatory=$true)]
        [string]$CertPath,

        [parameter(Mandatory=$true)]
        [securestring]$PrivKeyPass
    )

    # import EDK module
    Import-Module PSCrestron

    Get-AutoDiscovery -ShowProgress -Pattern '^(am-200|am-300)' |
        Select-Object -ExpandProperty IP |
        Send-SFTPFile -Secure -Username $DeviceUsername -LocalFile $CertPath -RemoteFile "\User\Cert\serv_cert.der" -Password $DevicePassword |
        Invoke-CrestronCommand -Command "certificate add webserver $PrivKeyPass"


# instantiate the SSH library
Add-Type -Path (Join-Path $PSScriptRoot 'Renci.SshNet.dll')
}