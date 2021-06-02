# ---------------------------------------------------------
# AirMedia Control Script
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
$DialogEventsCustomCode = @"
namespace DialogEvents
{
    public class OnViewportQueryAck
    {
        public void RegisterEvent(Crestron.Toolbox.VptCOMServer.Interop.VptSession2 session)
        {
            session.OnViewportQuery += OnViewportQueryCallback;
        }

        private void OnViewportQueryCallback(int nTransactionID, [System.Runtime.InteropServices.ComAliasName("Crestron.Toolbox.VptCOMServer.Interop.EVptQueryType")] Crestron.Toolbox.VptCOMServer.Interop.EVptQueryType lQueryType, string pszwQueryPrompt, ref string ppszwResponse, int nUserPassBack)
        {
            if(lQueryType == Crestron.Toolbox.VptCOMServer.Interop.EVptQueryType.EVptQueryType_GeneralNotificationServer)
                ppszwResponse = Crestron.Toolbox.VptCOMServer.Interop.EVptQueryResponseCategory.EVptQueryResponseCategory_ConfirmOk.ToString();

            if(lQueryType == Crestron.Toolbox.VptCOMServer.Interop.EVptQueryType.EVptQueryType_GeneralNotificationYesNoCancel)
                ppszwResponse = "n";

            if(lQueryType == Crestron.Toolbox.VptCOMServer.Interop.EVptQueryType.EVptQueryType_SendDefaultIPTable)
                ppszwResponse = "y";
        }
    }
}
"@
$referencedAssemblies = @(
'mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
$TBInterop
)

Add-Type $DialogEventsCustomCode -ReferencedAssemblies $referencedAssemblies -Language CSharp

[Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy 
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::Expect100Continue = $false

# ---------------------------------------------------------
function Open-AMSession
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Opens a web session to a AM panel.

	.DESCRIPTION

	    The Open-AMSession cmdlet creates a web session to an AM device
        and returns a WebRequestSession object which must be used in any
        subsequent calls that get or post web requests.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Username

        The username to use for a secure connection.
	
    .PARAMETER Password

        The password to use for a secure connection.
        
	.EXAMPLE

		$session = Open-AMSession -Device 'AM-BLDG1' -Username 'admin' -Password 'pa$$w0rd'
		
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
        [securestring]$Password
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
function Get-AMSSID
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Gets the SSID.

	.DESCRIPTION

	    The Get-AMSSID cmdlet retrieves the WIFI SSID from the AirMedia device.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Session

        The web session obtained from the call to Open-AMSession.
	
	.EXAMPLE

		$ver = Get-AMSSID -Device 'AM-BLDG1' -Session $session
		
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
        $urls = "https://$Device/Device/AirMedia/ConnectionDisplayOptions/WifiSsidCustomString"
        $res = Invoke-WebRequest -Uri $urls -WebSession $Session -Method Get
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $urls."}

        # extract the ssid
        $dev = $res.Content | ConvertFrom-Json
        $dev.Device.AirMedia.ConnectionDisplayOptions.WifiSsidCustomString
    }
    catch
    {
        throw
    }
}

# ---------------------------------------------------------
function Get-AMWifiKey
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Gets the WIFI key.

	.DESCRIPTION

	    The Get-AMWifiKey cmdlet retrieves the WIFI key from the AirMedia device.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Session

        The web session obtained from the call to Open-AMSession.
	
	.EXAMPLE

		$ver = Get-AMWifiKey -Device 'AM-BLDG1' -Session $session
		
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
        $urls = "https://$Device/Device/AirMedia/ConnectionDisplayOptions/WifiKeyCustomString"
        $res = Invoke-WebRequest -Uri $urls -WebSession $Session -Method Get
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $urls."}

        # extract the ssid
        $dev = $res.Content | ConvertFrom-Json
        $dev.Device.AirMedia.ConnectionDisplayOptions.WifikeyCustomString
    }
    catch
    {
        throw
    }
}
# ---------------------------------------------------------
function Set-AMSSID
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Set WIFI SSID.

	.DESCRIPTION

	   Sets the WIFI SSID for the AM device.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Session

        The web session obtained from the call to Open-TSXSession.
	
	.EXAMPLE

		 -Device 'AM-BLDG1' -Session $session
		
	.NOTES

		Author: Jay
	#>    

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]$Device,

		[Parameter(Mandatory=$true)]
		[Microsoft.PowerShell.Commands.WebRequestSession]$Session,
		
		[Parameter(Mandatory=$true)]
		[string]$SSID
    )

    try
    {
        # send the update
        $json = '{"Device":{"ConnectionDisplayOptions":{"WifiSsidCustomString":$SSID}}}'
        $res = Invoke-WebRequest -Uri "https://$Device/Device" -WebSession $Session
            -Method Post -Body ($json) -ContentType "application/json"
	}
    catch
    {
        throw
    }
}
# ---------------------------------------------------------
function Set-AMWifiKey
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Set WIFI key.

	.DESCRIPTION

	   Sets the WIFI key for the AM device.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER Session

        The web session obtained from the call to Open-AMSession.
	
	.EXAMPLE

		 -Device 'AM-BLDG1' -Session $session
		
	.NOTES

		Author: Jay
	#>    

	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		[string]$Device,

		[Parameter(Mandatory=$true)]
		[Microsoft.PowerShell.Commands.WebRequestSession]$Session,
		
		[Parameter(Mandatory=$true)]
		[string]$key
    )

    try
    {
        # send the update
        $json = '{"Device":{"ConnectionDisplayOptions":{"WifiKeyCustomString":$key}}}'
        $res = Invoke-WebRequest -Uri "https://$Device/Device" -WebSession $Session
            -Method Post -Body ($json) -ContentType "application/json"
	}
    catch
    {
        throw
    }
}