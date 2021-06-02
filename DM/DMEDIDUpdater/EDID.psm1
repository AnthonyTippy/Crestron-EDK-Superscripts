# ---------------------------------------------------------
# EDID Script
#
# Requested by: A. Patel
# Requested on: 2018-03-16
# Written by:   M. Gallo
#
# Copyright (C) 2018 to the present, Crestron Electronics, Inc.
# All rights reserved.
# No part of this software may be reproduced in any form, machine
# or natural, without the express written consent of Crestron Electronics.
# ---------------------------------------------------------

# minimum required version
#Requires -Version 4
Set-StrictMode -Version Latest

# import the library
Import-Module PSCrestron

# ---------------------------------------------------------
function Get-EdidInfo
# ---------------------------------------------------------
{
    param
    (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$InputObject
    )

    # get user info
    $user = Get-UserAccess -Secure:$InputObject.Secure -Username $InputObject.Username -Password $InputObject.Password -Port $InputObject.Port

    # get the info
    if ($InputObject.slot -and $InputObject.slot -gt 0)
    {
        # use the cards command
        if ($InputObject.Slot -match '\.')
        {
            $sp = $InputObject.Slot -split '\.'
            $x = @(("RCON SLOT $($sp[0]) EDIDINPUT $($sp[1])" |
                Invoke-CrestronCommand -Device $InputObject.Device -Timeout 60 -Secure:$user.Secure `
                    -Username $user.Username -Password $user.Password -Port $user.CTPPort) -split "`r")
        }
        else
        {
            $x = @(("EDIDINPUT $($InputObject.Slot)" |
                Invoke-CrestronCommand -Device $InputObject.Device -Timeout 60 -Secure:$user.Secure `
                    -Username $user.Username -Password $user.Password -Port $user.CTPPort) -split "`r")
        }
        if (-not ($x | Select-String -SimpleMatch 'MetaData' -Quiet))
            {throw 'Failed to obtain EDID info.'}
    }
    else
    {
        # try both possible commands
        $x = "EDIDHDMIINPUT $($InputObject.Input - 1)" |
            Invoke-CrestronCommand -Device $InputObject.Device -Secure:$user.Secure `
                -Username $user.Username -Password $user.Password -Port $user.CTPPort
        if (-not ($x | Select-String -SimpleMatch 'MetaData' -Quiet))
        {
            $x = "EDIDANALOGINPUT 0" |
                Invoke-CrestronCommand -Device $InputObject.Device -Secure:$user.Secure `
                    -Username $user.Username -Password $user.Password -Port $user.CTPPort
        }
        if (-not ($x | Select-String -SimpleMatch 'MetaData' -Quiet))
            {throw 'Failed to obtain EDID info.'}
    }

    # convert to a collection of lines
    $x = $x -split "`r"

    # extract the video info
    $patt = '(?<=Supported resolutions: )\d+'
    $vr = $x | Select-String -Pattern $patt -Context ([regex]::Match($x,$patt).Value)

    # extract the audio info
    $patt = '(?<=Supported audio formats: )\d+'
    $ar = $x | Select-String -Pattern $patt -Context ([regex]::Match($x,$patt).Value)

    # extract the guid
    $gr = $x | Select-String -Pattern 'Guid:' -Context 0,2
    $guid = [regex]::Matches($gr,'(?<=0x)[0-9a-f]{2}').Value -join ''

    # extract the error codes
    $ecodes = [regex]::Matches($x,'(?<=ErrCode\[\d\]:0x)[0-9a-f]{1,2}').Value

    # return an object
    $cobj = [PSCustomObject]@{Device = $InputObject.Device; Slot = $InputObject.Slot; 
        Port = $InputObject.Port; Input = $InputObject.Input; Video = $null;
        Audio = $null; Guid = $guid; Errors=$ecodes}
    if ($vr.Context) {$cobj.Video = $vr.Context.PostContext}
    if ($ar.Context) {$cobj.Audio = $ar.Context.PostContext}
    $cobj
}

# ---------------------------------------------------------
function Convert-EdidToSerial
# ---------------------------------------------------------
{
    param
    (
		[parameter(Mandatory=$true)]
        [string]$Path,

		[parameter(Mandatory=$true)]
        [string]$Slot,

		[parameter(Mandatory=$true)]
        [string]$Join,

        [parameter(Mandatory=$false)]
        [ValidateSet('Ignore','Allow','Adapt')]
        [string]$MismatchedEDID = 'Adapt'
    )

    # check the file
    if (-not (Test-Path $Path))
        {throw 'Failed to find file.'}
    if ((Get-Item $Path).Extension -notmatch '\.cedid')
        {throw 'Only CEDID files are supported.'}

    # load the file
    [xml]$xml = Get-Content $Path

    # convert slot to hex
    if ($Slot -eq '0')
        {$shex = '0'}
    else
        {$shex = ($Slot -split '\.' | %{'0x{0:X2}' -f [int]$_}) -join '.'}

    # length
    $len = 336
    $b = [BitConverter]::GetBytes([int16]$len)

    # edid
    $b += [Convert]::FromBase64String($xml.edid.data)

    # metadata version
    $b += [byte]1

    # error mask
    $b += [BitConverter]::GetBytes([int64]0)

    # mismatched edid
    switch ($MismatchedEDID)
    {
        'Ignore' {$b += [byte]0}
        'Allow' {$b += [byte]1}
        'Adapt' {$b += [byte]2}
    }

    # guid
    $guid = $xml.edid.id -replace '-',''
    for ($i = 1;$i -lt 32;$i = $i + 2)
        {$b += [Convert]::ToByte($guid.Substring($i,2),16)}

    # display name
    $b += [byte[]][char[]](($xml.edid.name).PadRight(50,' '))

    # extension
    $b += [byte]0

    # checksum
    $b += $b | ForEach-Object -Begin {[int32]$sum = 0} -Process {$sum += $_} `
        -End {[byte]((($sum -band 0xFF) -bxor 0xFF) + 1)}

    # convert to serial join format
    $joins = @()
    for ($i = 0;$i -lt 28;$i++)
    {
        $s = (($b[($i * 12)..($i * 12 + 11)] | %{'\x{0:X2}' -f $_}) -join '')
        switch ($i)
        {
            0 {$joins += "joinsetserial !Last $shex $Join $s"}
            27 {$joins += "joinsetserial !First $shex $Join $s"}
            default {$joins += "joinsetserial !First !Last $shex $Join $s"}
        }

    }
    $joins
}

# ---------------------------------------------------------
function Send-EdidFile
# ---------------------------------------------------------
{
    param
    (
		[Parameter(Mandatory=$true)]
		[string]$Device,

		[Parameter(Mandatory=$true)]
        [string]$Path,

		[Parameter(Mandatory=$true)]
        [string]$Slot,

		[Parameter(Mandatory=$true)]
        [string]$Join,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Ignore','Allow','Adapt')]
        [string]$MismatchedEDID = 'Adapt',

		[Parameter()]
		[switch]$Secure,

		[Parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Username,

		[Parameter(Mandatory=$false)]
        [AllowNull()]
        [AllowEmptyString()]
        $Password,

		[Parameter(Mandatory=$false)]
		[int]$Port
    )

    # get user info
    $user = Get-UserAccess -Secure:$Secure -Username $Username -Password $Password -Port $Port

    # check the file
    if (-not (Test-Path $Path))
        {throw 'Failed to find file.'}
    if ((Get-Item $Path).Extension -notmatch '\.cedid')
        {throw 'Only CEDID files are supported.'}

    # turn off join monitoring
    'joinmonitorslot stop all' |
        Invoke-CrestronCommand -Device $Device -Secure:$user.Secure `
            -Username $user.Username -Password $user.Password -Port $user.CTPPort |
        Out-Null

    # convert to serial and send
    Convert-EdidToSerial -Path $Path -Slot $Slot -Join $join -MismatchedEDID $MismatchedEDID |
        Invoke-CrestronCommand -Device $Device -Secure:$user.Secure `
            -Username $user.Username -Password $user.Password -Port $user.CTPPort |
        Out-Null

    # save it to nvram
    'joinsetdigital 33 0 1' |
        Invoke-CrestronCommand -Device $Device -Secure:$user.Secure `
            -Username $user.Username -Password $user.Password -Port $user.CTPPort |
        Out-Null
}

# ---------------------------------------------------------
function Send-EdidInfo
# ---------------------------------------------------------
{
    param
    (
		[Parameter(Mandatory=$true)]
        [Alias('Workbook')]
		[string]$Path
    )

    try
    {
        # import the user spreadsheet
        Write-Verbose 'Importing the worksheet...'
        $devs = Import-Excel -Workbook $Path -Worksheet 'Devices' | Where-Object Device

        # return collection
        $robj = @()

        # iterate the rows
        foreach ($r in $devs)
        {
            # check the inputs
            if ($r.Slot -eq $null) {$r.Slot = 0}
            if ($r.Port -eq $null) {$r.Port = 0}
            if ($r.Input -lt 1 -or $r.Input -gt 3) {throw 'Input out of range.'}

            # verbose message
            Write-Verbose ('Updating Device:{0} Slot:{1} Port:{2} Input:{3}...' -f $r.Device,$r.Slot,$r.Port,$r.Input)

            # return object
            $cobj = [PSCustomObject]@{Device = $r.Device; File = $r.File;
                Slot = [string]$r.Slot; Port = [int]$r.Port; Input = [int]$r.Input;
                Mode = $r.Mode; Guid = $null; Pass = $false;
                ErrorBytes = $null; ErrorMessage = $null}

            # process the edid
            try
            {
                # send the edid
                Send-EdidFile -Device $r.Device -Path $r.File -Slot $r.Slot `
                    -Join ($r.Input * 10 + 31) -MismatchedEDID $r.Mode -Port $r.Port `
                    -Secure:$r.Secure -Username $r.Username -Password $r.Password

                # add a delay for transmitters going offline
                if ($r.Port) {Start-Sleep -Seconds 60}

                # get the result
                $x = Get-EdidInfo -InputObject $r
                $gin = ([xml](Get-Content $r.File)).edid.id `
                    -replace '-','' -replace '\{','' -replace '\}',''
                $cobj.ErrorBytes = $x.Errors
                $cobj.Guid = $x.Guid

                # check the results
                if ($cobj.ErrorBytes[0] -band 1)
                    {throw 'EDID Fatal Error'}
                elseif ($cobj.ErrorBytes[0] -band 2)
                    {throw 'EDID Warning'}
                elseif ($cobj.ErrorBytes[0] -band 4)
                    {throw 'EDID Rejected'}
                elseif ($cobj.ErrorBytes[0] -band 8)
                    {$cobj.Pass = $true; $cobj.ErrorMessage = 'EDID Modified'}
                elseif ($cobj.Guid -ne $gin)
                    {throw 'EDID GUID Compare Failed'}
                else
                    {$cobj.Pass = $true}
            }
            catch
            {
                # save the error
                $cobj.Pass = $false
                $cobj.ErrorMessage = $_.Exception.GetBaseException().Message
            }

            # convert error bytes to a string
            $cobj.ErrorBytes = $cobj.ErrorBytes -join ','

            # add it to the collection
            $robj += $cobj
        }
    }
    catch
        {throw}
    finally
        {$robj}
}

# export control
Export-ModuleMember -Function Send-EdidInfo

# SIG # Begin signature block
# MIIXugYJKoZIhvcNAQcCoIIXqzCCF6cCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcQBh+PsCCaIcvjMQi4ZrGjf4
# GKugghLgMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggTmMIIDzqADAgECAhBdt+RaTI9wKusQcBnxuet1MA0GCSqGSIb3DQEBCwUAMH8x
# CzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEfMB0G
# A1UECxMWU3ltYW50ZWMgVHJ1c3QgTmV0d29yazEwMC4GA1UEAxMnU3ltYW50ZWMg
# Q2xhc3MgMyBTSEEyNTYgQ29kZSBTaWduaW5nIENBMB4XDTE3MDIyNzAwMDAwMFoX
# DTIwMDQxNzIzNTk1OVowfjELMAkGA1UEBhMCVVMxEzARBgNVBAgMCk5ldyBKZXJz
# ZXkxEjAQBgNVBAcMCVJvY2tsZWlnaDEiMCAGA1UECgwZQ3Jlc3Ryb24gRWxlY3Ry
# b25pY3MsIEluYzEiMCAGA1UEAwwZQ3Jlc3Ryb24gRWxlY3Ryb25pY3MsIEluYzCC
# ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALw7YZFDCEXJumY8yxf3wBge
# UOhK9ucGK0pWbZ9orOFUaARc9Q5CC2LTF0XCjq58euJmY44q4ADvXu7Eab0pzraa
# L9JfReNJkXIRHc9QoNOGt0TGF0tFU67g6rNLorZ9A+P00HeE/0QvBIy2KPsbqD34
# hnkate9PQcB+nVaiL+tebaVIS7WfAwr4JeICiQdFIQFm2cfd4usgJuVRVZ3lWcRq
# YULOl5HI1OHp32vrFLsA8n1ne1zCWPURDMzkNRywuXyiLKjk6tcXsQuqW6fXW4pC
# Fmwe43i5eXg/ngXxCyeFDspnnKJS8zeK8jeO0JPR7rk15e1ZldeF8eEMsjXmA38C
# AwEAAaOCAV0wggFZMAkGA1UdEwQCMAAwDgYDVR0PAQH/BAQDAgeAMCsGA1UdHwQk
# MCIwIKAeoByGGmh0dHA6Ly9zdi5zeW1jYi5jb20vc3YuY3JsMGEGA1UdIARaMFgw
# VgYGZ4EMAQQBMEwwIwYIKwYBBQUHAgEWF2h0dHBzOi8vZC5zeW1jYi5jb20vY3Bz
# MCUGCCsGAQUFBwICMBkMF2h0dHBzOi8vZC5zeW1jYi5jb20vcnBhMBMGA1UdJQQM
# MAoGCCsGAQUFBwMDMFcGCCsGAQUFBwEBBEswSTAfBggrBgEFBQcwAYYTaHR0cDov
# L3N2LnN5bWNkLmNvbTAmBggrBgEFBQcwAoYaaHR0cDovL3N2LnN5bWNiLmNvbS9z
# di5jcnQwHwYDVR0jBBgwFoAUljtT8Hkzl699g+8uK8zKt4YecmYwHQYDVR0OBBYE
# FDJwh/7uG0PfinUOdDcypiN7o2+eMA0GCSqGSIb3DQEBCwUAA4IBAQA2rdGTYtYz
# pI35eO6lyKJC6FKLS89Dh6OiPSMdRuKVU+uVFe9DPxeDV3mKFpUXwmu5MKZihMg0
# WB8027sgKuQ2jneVePxAxg3fpW+DZGOOF3FawSbCJ5e5kNe1jnNXlOUlw53hlDuR
# PDEGvS/ZMMGs9A6+Jcx6R31h1FMBqRdjZIbE6nrqb46NzEQy109U0ZI8tdUyKyeT
# Vi9xGod/Zr6ZK17ewtWnjSt/Zm9hTg44VdJjXeEGh0w48tl1UTuozkg4jXzbcjQU
# WnjUuM5QTolgAP9dojMQfwMGZW7Zv6NOCuSgGaTLpb77rlKG3uHPyvoFyIt8/kXV
# Ba3zctOXlC9/MIIFWTCCBEGgAwIBAgIQPXjX+XZJYLJhffTwHsqGKjANBgkqhkiG
# 9w0BAQsFADCByjELMAkGA1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMu
# MR8wHQYDVQQLExZWZXJpU2lnbiBUcnVzdCBOZXR3b3JrMTowOAYDVQQLEzEoYykg
# MjAwNiBWZXJpU2lnbiwgSW5jLiAtIEZvciBhdXRob3JpemVkIHVzZSBvbmx5MUUw
# QwYDVQQDEzxWZXJpU2lnbiBDbGFzcyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmlj
# YXRpb24gQXV0aG9yaXR5IC0gRzUwHhcNMTMxMjEwMDAwMDAwWhcNMjMxMjA5MjM1
# OTU5WjB/MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5
# bWFudGVjIENsYXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZI
# hvcNAQEBBQADggEPADCCAQoCggEBAJeDHgAWryyx0gjE12iTUWAecfbiR7TbWE0j
# Ymq0v1obUfejDRh3aLvYNqsvIVDanvPnXydOC8KXyAlwk6naXA1OpA2RoLTsFM6R
# clQuzqPbROlSGz9BPMpK5KrA6DmrU8wh0MzPf5vmwsxYaoIV7j02zxzFlwckjvF7
# vjEtPW7ctZlCn0thlV8ccO4XfduL5WGJeMdoG68ReBqYrsRVR1PZszLWoQ5GQMWX
# korRU6eZW4U1V9Pqk2JhIArHMHckEU1ig7a6e2iCMe5lyt/51Y2yNdyMK29qclxg
# hJzyDJRewFZSAEjM0/ilfd4v1xPkOKiE1Ua4E4bCG53qWjjdm9sCAwEAAaOCAYMw
# ggF/MC8GCCsGAQUFBwEBBCMwITAfBggrBgEFBQcwAYYTaHR0cDovL3MyLnN5bWNi
# LmNvbTASBgNVHRMBAf8ECDAGAQH/AgEAMGwGA1UdIARlMGMwYQYLYIZIAYb4RQEH
# FwMwUjAmBggrBgEFBQcCARYaaHR0cDovL3d3dy5zeW1hdXRoLmNvbS9jcHMwKAYI
# KwYBBQUHAgIwHBoaaHR0cDovL3d3dy5zeW1hdXRoLmNvbS9ycGEwMAYDVR0fBCkw
# JzAloCOgIYYfaHR0cDovL3MxLnN5bWNiLmNvbS9wY2EzLWc1LmNybDAdBgNVHSUE
# FjAUBggrBgEFBQcDAgYIKwYBBQUHAwMwDgYDVR0PAQH/BAQDAgEGMCkGA1UdEQQi
# MCCkHjAcMRowGAYDVQQDExFTeW1hbnRlY1BLSS0xLTU2NzAdBgNVHQ4EFgQUljtT
# 8Hkzl699g+8uK8zKt4YecmYwHwYDVR0jBBgwFoAUf9Nlp8Ld7LvwMAnzQzn6Aq8z
# MTMwDQYJKoZIhvcNAQELBQADggEBABOFGh5pqTf3oL2kr34dYVP+nYxeDKZ1HngX
# I9397BoDVTn7cZXHZVqnjjDSRFph23Bv2iEFwi5zuknx0ZP+XcnNXgPgiZ4/dB7X
# 9ziLqdbPuzUvM1ioklbRyE07guZ5hBb8KLCxR/Mdoj7uh9mmf6RWpT+thC4p3ny8
# qKqjPQQB6rqTog5QIikXTIfkOhFf1qQliZsFay+0yQFMJ3sLrBkFIqBgFT/ayftN
# TI/7cmd3/SeUx7o1DohJ/o39KK9KEr0Ns5cF3kQMFfo2KwPcwVAB8aERXRTl4r0n
# S1S+K4ReD6bDdAUK75fDiSKxH3fzvc1D1PFMqT+1i4SvZPLQFCExggREMIIEQAIB
# ATCBkzB/MQswCQYDVQQGEwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRp
# b24xHzAdBgNVBAsTFlN5bWFudGVjIFRydXN0IE5ldHdvcmsxMDAuBgNVBAMTJ1N5
# bWFudGVjIENsYXNzIDMgU0hBMjU2IENvZGUgU2lnbmluZyBDQQIQXbfkWkyPcCrr
# EHAZ8bnrdTAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUyuAmtmwVxw4JcHxx7Y18QAZ3mt0wDQYJ
# KoZIhvcNAQEBBQAEggEAMA+4EFJVpmSt5vRJdHlkJHXIS879lDmR5kKXKTUvI3KE
# eYRn1sUAklFE9MRbWL4bwUtRIisxvb+8stRO5QNKR+X2Mk6gynanYI0SGQhVrUV1
# hP5ZVmXNSi93jwUxSniEaUc6WjOxNVYE/romWUjYNij6fELXuopiIq1Ftj/5307f
# mDiUDxELylSW8GK+weS/T/PPPI3pPSH0ryIsx0TyE+G0FJesXdo41TgPa+d59BTK
# LOqbcL5mt4Vd3J765v6SvC0nnVC/cGPulEzhuBbU63h7ScobACBGPkEh3U+rIFpx
# g3Jd0nC9It9ksIiUeMxNmT+A2EDuR7/1MSdD+oWqXKGCAgswggIHBgkqhkiG9w0B
# CQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRl
# YyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBT
# ZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xOTExMjUx
# MzMxMTJaMCMGCSqGSIb3DQEJBDEWBBROccphcjtZCNjJ0LiIN6BE/IvkIzANBgkq
# hkiG9w0BAQEFAASCAQCMYzHDlStjqcw6EsD/ZFur+NuwCOkuNIgvF7GNr1S/Ez50
# gbfVfJTvKRUoa1sCTzDKtGUoHWnFMju7WIHjE8h91Zb2Wdmz16Yft88KQrQ9Q9Ih
# VxeNfA88cpjLd+a5dqXsOKzBmpWGGHnc/e0TjSXhrpbf6XmrvCLXjJcRmLanypL1
# Ub00UCh9FtDzwenS3xOFyxBkOF+wQWSa9SiIIwAYl+S1n0oXPqpFfp/zAMptR0US
# 7tVif5SZEys79HGo9GX3+kFOOM7IJ6IpKGrdL9z7ZmkjTAr8do2SIoX6yua1afTf
# kwoUVQBGrEFDc9DELVu0pzJ7fMEtge7FpsbL0TSa
# SIG # End signature block
