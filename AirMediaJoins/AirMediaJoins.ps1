# ---------------------------------------------------------
# AirMedia Join Interface Script
#
# Copyright (C) 2019 to the present, Crestron Electronics, Inc.
# All rights reserved.
# No part of this software may be reproduced in any form, machine
# or natural, without the express written consent of Crestron Electronics.
# ---------------------------------------------------------

# minimum required version
#Requires -Version 4
Set-StrictMode -Version Latest

# import the module
Import-Module PSCrestron

# script folder
if ($PSScriptRoot)
    {$here = $PSScriptRoot}
else
    {$here = $PWD}

# private members
Set-Variable -Name session -Value $null -Scope Global

# ---------------------------------------------------------
function Set-LoginCode
# ---------------------------------------------------------
{
	[CmdLetBinding()]
    param
    (
		[Parameter(Mandatory=$true)]
        [ValidateSet('Disabled','Random','Fixed')]
        [string]$LoginMode,

		[Parameter(Mandatory=$false)]
        [ValidateRange(0,9999)]
        [int]$LoginCode,

        [Parameter()]
        [switch]$DisplayCode
    )

    try
    {
        # set the mode
        switch ($LoginMode)
        {
            'Disabled' {$v = 0}
            'Random'   {$v = 1}
            'Fixed'    {$v = 2}
        }
        $x = Invoke-CrestronSession $session "SETANALOGJOIN 9 3 $v"
        if ($x -match 'error')
            {throw 'Failed to set login mode.'}

        # set the code
        if ($LoginMode -eq 'Fixed')
        {
            $x = Invoke-CrestronSession $session "SETANALOGJOIN 9 4 $LoginCode"
            if ($x -match 'error')
                {throw 'Failed to set login code.'}
        }

        # set the display
        if ($DisplayCode) {$v = 51} else {$v = 52}
        $x = Invoke-CrestronSession $session "SETDIGITALJOIN 9 2 $v 1"
        if ($x -match 'error')
            {throw 'Failed to set display parameter.'}
    }
    catch
        {throw}
}

# ---------------------------------------------------------
# sample usage
# ---------------------------------------------------------

$session = Open-CrestronSession -Device '172.30.148.35' -Secure -Username 'admin' -Password 'admin'
Set-LoginCode -LoginMode Fixed -LoginCode 1234 -DisplayCode
Close-CrestronSession -Handle $session

# SIG # Begin signature block
# MIIXugYJKoZIhvcNAQcCoIIXqzCCF6cCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQ7+AdNwUgtu44wrPsB+tyaOr
# qUqgghLgMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUHJXsFqIcFG4Ve/q8TJDMJJkqbmwwDQYJ
# KoZIhvcNAQEBBQAEggEARQAA5eISuaueqV9EnFCgLTg9EnR/limIyBPt5OC7reEm
# mHFGqCb6lZDsJ3t+A1DLyqADdCBYQ7mCP1aT7HsulbDWyjwvuLuLi5GwUEKCmgay
# OZUcWDsBkajmq6hYGpa4eHsLJ8YioRpI/NNfHRx1em+HgBBjYyeaTjCWz1Vl6Tdg
# Hk4d+jWvJjUP3py1ScCnW586WqonpUrvJ8mXdYEnk3tzKHMvKliZPZncdx/EUD51
# zpf0Mu88Tr1NrNrfp6GwAw/DfuUXFCAL7/j6aL8WSusjtro9VOqCK9cUOx0m5klU
# +WyK9obSijwqKHjQ4i1fdYGd0Ca/AYD6zfHEBY9yD6GCAgswggIHBgkqhkiG9w0B
# CQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRl
# YyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBT
# ZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQMAkGBSsOAwIaBQCgXTAY
# BgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3DQEJBTEPFw0xOTA4MjYx
# NzU2MTZaMCMGCSqGSIb3DQEJBDEWBBSW95Pp0qlzkte7iz1DYGLQICrh2DANBgkq
# hkiG9w0BAQEFAASCAQCE9osst3kYnit379CyJ/wOPcrMPvKFA0Am0sgkV12wEzP0
# WAoEXVsYpvfSTWJf7epGDnGftbOI39itJieM1LDrmCBntiCgooKQmz0o/CEmQ7jn
# 0yiEZiLGEMLeDDr4PYBk1Kadts5+ra8P76W5tXEAsou38sYpCNY7HX9TVnaZWRKw
# S37gXX+HweVC+v0ZSYv6948qF5M4d6lgqXOsvLnhxtsV43i7NsShlW+4+jPwVjCw
# tNbQzJnm94RhtCtxRs3OnubHv28iuE4cyBITJHyYCaQ31Jb1Kwc2ihjGZac51MWL
# wV8osr590opuYbNX+8URVB+IiUbpJHKc9OaEZMbE
# SIG # End signature block
