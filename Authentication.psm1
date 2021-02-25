# ---------------------------------------------------------
# Authentication Module
# ---------------------------------------------------------

# minimum required version
#Requires -Version 3
Set-StrictMode -Version Latest

# ---------------------------------------------------------
function Set-Authentication
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Turns authentication on for the specified device.

	.DESCRIPTION

	    The Set-Authentication cmdlet will turn authentication on for the
        specified device. There are two sets of usernames and passwords. One set
        is requried to log into the unit and the second, prefixed with Auth is used
        to set the authentication username and password. A boolean is returned
        where True indicates success.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER AuthUsername

        Specifies the username to set for authentication.
	
    .PARAMETER AuthPassword

        Specifies the password to set for authentication.

    .PARAMETER Username

        The username to use for a secure connection.
	
    .PARAMETER Password

        The password to use for a secure connection.

	.PARAMETER Port

        An optional parameter that specifies the port to use. Defaults to the standard port
        for the protocol.

	.EXAMPLE

        Set-Authentication -Device 'CP3-MyUnit' -AuthUsername 'admin' -AuthPassword 'Pa$$w0rd'
		
        This command turns authentication on using the supplied username and password. The initial
        login uses the default credentials.

	.NOTES

		Author: Mike Gallo
	#>    

	[CmdletBinding()]
    param
    (
		[Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [string]$Device,

		[Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        $AuthUsername,

		[Parameter(Mandatory=$false)]
        [AllowEmptyString()]
        $AuthPassword,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Username,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Password,

        [parameter(Mandatory=$false)]
        [string]$PasswordLength,

        [parameter(Mandatory=$false)]
        [string]$LockOutTime,

        [parameter(Mandatory=$false)]
        [string]$TimeServer,

		[parameter(Mandatory=$false)]
		[int]$Port
    )

    try
    {
        # local variables
        [bool]$ret = $false
        [string]$x = ''

        # open a session
        Write-Verbose 'Opening a session...'
        $s = Open-CrestronSession -Device $Device -Secure:$true `
            -Username $Username -Password $Password -Port $Port

        # turn on authentication
        Write-Verbose 'Checking authentication...'
        $x = Invoke-CrestronSession $s 'AUTHENTICATION'
        if ($x -match 'authentication: *off')
        {
            Write-Verbose 'Enabling authentication...'
            $x = Invoke-CrestronSession $s 'AUTHENTICATION ON' -Prompt ':'
            if ($x -match 'create a local administrator account')
            {
                if ($x -match 'username')
                {
                    Write-Verbose 'Entering username...'
                    $x = Invoke-CrestronSession $s $AuthUsername -Prompt ':'
                    if ($x -match 'password')
                    {
                        Write-Verbose 'Entering password...'
                        $x = Invoke-CrestronSession $s $AuthPassword -Prompt ':'
                        Write-Verbose 'Verifying password...'
                        $x = Invoke-CrestronSession $s $AuthPassword
                        Close-CrestronSession $s
                        $x = Invoke-CrestronCommand 'SETPASSWORDRULE -LENGTH:'$PasswordLength
                        Write-Verbose 'Setting password minimum length...'
                        $x = Invoke-CrestronCommand 'SETLOCKOUTTIME '$LockOutTime
                        Write-Verbose 'Setting lockout time...'
                        $x = Invoke-CrestronCommand 'SNTP SERVER:'$TimeServer
                        Write-Verbose 'Setting NTP server...'
                        $ret = $true
                        if ($x -match 'reboot to')
                        {
                            Write-Verbose 'Rebooting the device...'
                            $x = Reset-CrestronDevice -Device $Device -NoWait -Secure:$true `
                                -Username $Username -Password $Password -Port $Port
                            $ret = Reset-CrestronDevice -Device $Device -WaitOnly -Secure:$true `
                                -Username $AuthUsername -Password $AuthPassword -Port $Port
                        }
                    }
                }
            }
            elseif ($x -match "enter your administrator's credentials")
            {
                if ($x -match 'username')
                {
                    Write-Verbose 'Entering username...'
                    $x = Invoke-CrestronSession $s $AuthUsername -Prompt ':'
                    if ($x -match 'password')
                    {
                        Write-Verbose 'Entering password...'
                        $x = Invoke-CrestronSession $s $AuthPassword
                        Close-CrestronSession $s
                        Remove-Variable s -Force -ErrorAction SilentlyContinue
                        $ret = $true
                        if ($x -match 'reboot to')
                        {
                            Write-Verbose 'Rebooting the device...'
                            $x = Reset-CrestronDevice -Device $Device -NoWait -Secure:$true `
                                -Username $Username -Password $Password -Port $Port
                            $ret = Reset-CrestronDevice -Device $Device -WaitOnly -Secure:$true `
                                -Username $AuthUsername -Password $AuthPassword -Port $Port
                        }
                    }
                }
            }
        }
        else
            {$x = 'Authentication is already on.'}
    }
    catch
    {
        $x = $_.Exception.GetBaseException().Message
    }
    finally
    {
        # close any opened sessions
        if (Test-Path variable:\s)
            {Close-CrestronSession $s -ErrorAction SilentlyContinue}

        # return result
        if (-not $ret) {Write-Warning $x}
        $ret
    }
}

# ---------------------------------------------------------
function Clear-Authentication
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Turns authentication off for the specified device.

	.DESCRIPTION

	    The Set-Authentication cmdlet will turn authentication off for the
        specified device. When turning off authentication, options are provided
        to control the final state of CTP, FTP, and SSL. A boolean is returned
        where True indicates success.
		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.
			
    .PARAMETER EnableFTP
    
        Optional switch to restart the FTP server after authentication is turned off.
                
    .PARAMETER EnableCTP
    
        Optional switch to restart the CTP console after authentication is turned off.
                
    .PARAMETER DisableSSL
    
        Optional switch to disable SSL after authentication is turned off.
                
    .PARAMETER Username

        The username to use for a secure connection.
	
    .PARAMETER Password

        The password to use for a secure connection.

	.PARAMETER Port

        An optional parameter that specifies the port to use. Defaults to the standard port
        for the protocol.

	.EXAMPLE

		Set-Authentication -Device 'CP3-MyUnit' -Username 'admin' -Password 'Pa$$w0rd' -State Off -DisableSSL

        This command turns both authentication and SSL off.

	.NOTES

		Author: Mike Gallo
	#>    

	[CmdletBinding()]
    param
    (
		[Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [string]$Device,

        [Parameter()]
        [switch]$EnableFTP,

        [Parameter()]
        [switch]$EnableCTP,

        [Parameter()]
        [switch]$DisableSSL,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Username,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Password,

		[parameter(Mandatory=$false)]
		[int]$Port
    )

    try
    {
        # local variables
        [bool]$ret = $false
        [string]$x = ''

        # turn authentication off
        Write-Verbose 'Checking authentication...'
        $x = Invoke-CrestronCommand -Device $Device -Command 'AUTHENTICATION' `
            -Secure:$true -Username $Username -Password $Password -Port $Port
        if ($x -match 'authentication: *on')
        {
            Write-Verbose 'Disabling authentication...'
            $cmd = @('AUTHENTICATION OFF')
            if ($DisableSSL) {$cmd += 'SSL OFF'}
            if ($EnableCTP) {$cmd += 'CTPCONSOLE ENABLE'}
            $x = $cmd | Invoke-CrestronCommand -Device $Device -Timeout 10 `
                -Secure:$true -Username $Username -Password $Password -Port $Port
            if ($x -match 'reboot')
            {
                Write-Verbose 'Rebooting the device...'
                $ret = Reset-CrestronDevice -Device $Device -Secure:$true `
                    -Username 'crestron' -Password '' -Port $Port
            }
            if ($ret -and $EnableFTP)
            {
                Write-Verbose 'Enabling FTP...'
                $x = Invoke-CrestronCommand -Device $Device -Command 'FTPSERVER ON' `
                    -Secure:$true -Username 'crestron' -Password '' -Port $Port
            }
        }
        else
            {$x = 'Authentication is already off.'}
    }
    catch
    {
        $x = $_.Exception.GetBaseException().Message
    }
    finally
    {
        # return result
        if (-not $ret) {Write-Warning $x}
        $ret
    }
}

# ---------------------------------------------------------
function Update-Authentication
# ---------------------------------------------------------
{
    <#
	.SYNOPSIS

	    Updates password for the specified device.

	.DESCRIPTION

		
	.PARAMETER Device

	    Specifies the IP address or hostname of the device.

    .PARAMETER Username

        The username to use for a secure connection.
	
    .PARAMETER OldPassword

        The old password to use for a secure connection.

    .PARAMETER NewPassword

        The new password to use for a secure connection.

	.PARAMETER Port

        An optional parameter that specifies the port to use. Defaults to the standard port
        for the protocol.

	.EXAMPLE

        Set-Authentication -Device 'CP3-MyUnit' -AuthUsername 'admin' -AuthPassword 'Pa$$w0rd'
		
        This command turns authentication on using the supplied username and password. The initial
        login uses the default credentials.

	.NOTES

		Author: Mike Gallo
	#>    

	[CmdletBinding()]
    param
    (
		[Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [string]$Device,


		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Username,

		[parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $OldPassword,

        [parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $NewPassword,

		[parameter(Mandatory=$false)]
		[int]$Port
    )

    try
    {
        # local variables
        [bool]$ret = $false
        [string]$x = ''

        Write-Verbose 'Opening a session...'
        $s = Open-CrestronSession -Device $Device -Secure:$true `
            -Username $Username -Password $OldPassword -Port $Port
        # change password
        Write-Verbose 'Changing password...'
        $x = Invoke-CrestronSession $s 'UPDATEPASSWORD'
        if ($x -match 'CurrentPassword: ')
        {
            $x = Invoke-CrestronSession $s $OldPassword -Prompt ':'
            $x = Invoke-CrestronSession $s $NewPassword -Prompt ':'
            $x = Invoke-CrestronSession $s $NewPassword
            Close-CrestronSession $s
        }
        catch
        {
            $x = $_.Exception.GetBaseException().Message
        }
        finally
        {
            # close any opened sessions
            if (Test-Path variable:\s)
                {Close-CrestronSession $s -ErrorAction SilentlyContinue}

            # return result
            if (-not $ret) {Write-Warning $x}
            $ret
        }
    }
}

# export control
Export-ModuleMember -Function *-Authentication
