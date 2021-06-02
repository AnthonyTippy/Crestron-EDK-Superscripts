# ---------------------------------------------------------
# Touchpanel Control Script
#
# Copyright (C) 2020 to the present, Crestron Electronics, Inc.
# All rights reserved.
# No part of this software may be reproduced in any form, machine
# or natural, without the express written consent of Crestron Electronics.
# ---------------------------------------------------------

# minimum required version
#Requires -Version 5
Set-StrictMode -Version Latest

# script folder
if ($PSScriptRoot)
    {$here = $PSScriptRoot}
else
    {$here = $PWD}
    
# import the modules
Import-Module PSCrestron

# trust all certificates
Add-Type @" 
    using System.Net; 
    using System.Security.Cryptography.X509Certificates; 
    public class TrustAllCertsPolicy : ICertificatePolicy { 
        public bool CheckValidationResult( 
            ServicePoint srvPoint, X509Certificate certificate, 
            WebRequest request, int certificateProblem) { 
            return true; 
        } 
    } 
"@
[Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::Expect100Continue = $false

# ---------------------------------------------------------
function Open-TSXSession
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Opens a web session to a TSX panel.

	.DESCRIPTION

	    The Open-TSXSession cmdlet creates a web session to an TSX device
        and returns a WebRequestSession object which must be used in any
        subsequent calls that get or post web requests.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Username

        The username to use for a secure connection.
	
    .PARAMETER Password

        The password to use for a secure connection.
        
	.EXAMPLE

		$session = Open-TSXSession -Device 'TSX-BLDG1' -Username 'admin' -Password 'pa$$w0rd'
		
	.NOTES

		Author: Jay
	#>    

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]$Device,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Username,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Password
    )

    try
    {
        # secure and unsecure urls
        $url = "http://$Device/userlogin.html"
        $urls = "https://$Device/userlogin.html"

        # create an intial session
        $res = Invoke-WebRequest -Uri $url -SessionVariable session -Method Post
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $url."}

        # add the credentials
        $form = $res.Forms[0]
        $form.Fields['login'] = $Username
        $form.Fields['passwd'] = $Password

        # open a secure session
        $res = Invoke-WebRequest -Uri $urls -WebSession $session -Method Post -Body $form.Fields
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $urls."}
        $cookies = $session.Cookies.GetCookies($urls)

        # return the session
        $session
    }
    catch
    {
        throw
    }
}

# ---------------------------------------------------------
function Get-TSXAppVersion
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Gets the application version.

	.DESCRIPTION

	    The Get-TSXAppVersion cmdlet retrieves the current application version.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Session

        The web session obtained from the call to Open-TSXSession.
	
	.EXAMPLE

		$ver = Get-TSXAppVersion -Device 'TSX-BLDG1' -Session $session
		
	.NOTES

		Author: Jay
	#>    

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]$Device,

		[Parameter(Mandatory=$true)]
		[Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )

    try
    {
        # get the info
        $urls = "https://$Device/Device/SystemVersions/Components"
        $res = Invoke-WebRequest -Uri $urls -WebSession $Session -Method Get
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $urls."}

        # extract the info
        $dev = $res.Content | ConvertFrom-Json
        foreach ($c in $dev.Device.SystemsVersions.Components)
            {foreach ($n in $c.Name)
                {$n.Version}}
    }
    catch
    {
        throw
    }
}

# ---------------------------------------------------------
function Update-App
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Updates the running application.

	.DESCRIPTION

	    The Update-App cmdlet updates the running application.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Session

        The web session obtained from the call to Open-TSXSession.
	
	.EXAMPLE

		Update-App -Device 'TSX-BLDG1' -Session $session
		
	.NOTES

		Author: Jay
	#>    

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]$Device,

		[Parameter(Mandatory=$true)]
		[Microsoft.PowerShell.Commands.WebRequestSession]$Session
    )

    try
    {
        # send the update
        $json = '{"Device":{"ThirdPartyApplications":{"ApplicationUpdateCheckNow":true}}}'
        $res = Invoke-WebRequest -Uri "https://$Device/Device" -WebSession $Session
            -Method Post -Body ($json) -ContentType "application/json"
		
		#get update status
		$json2 = '{"Device":{"ThirdPartyApplications":{"ApplicationUpdateStatus"}}}'
		$res2 = Invoke-WebRequest -Uri "https://$Device/Device" -WebSession $Session
			-Method Get -Body ($json) -ContentType "application/json"
	}
    catch
    {
        throw
    }
}