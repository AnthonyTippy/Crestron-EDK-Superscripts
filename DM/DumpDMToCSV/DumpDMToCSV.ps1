# ---------------------------------------------------------
# DumpDMToCSV Script
#
# Copyright (C) 2017 to the present, Crestron Electronics, Inc.
# All rights reserved.
# No part of this software may be reproduced in any form, machine
# or natural, without the express written consent of Crestron Electronics.
# ---------------------------------------------------------

# minimum required version
#Requires -Version 3
Set-StrictMode -Version Latest

# import the library
Import-Module PSCrestron

# get the device list
$here = $PSScriptRoot
$devs = Get-Content -Path (Join-Path $here 'devices.txt') |
    Where-Object {$_ -match '^\w'}

# iterate the devices
$groups = $devs | Invoke-RunspaceJob -ShowProgress -SharedVariables here -ScriptBlock {

    # dot source the worker script
    . (Join-Path $here 'DumpDMIPConfig.ps1')

    # iterate the ports and group by device
    Get-DumpDMIPConfig -Device $_ | Where-Object {[int]$_.Port -gt 0} |
    Invoke-RunspaceJob -ScriptBlock {
        $v = Get-VersionInfo $_.ExternalIP -Port $_.Port
        $_ | Add-Member -NotePropertyName 'Hostname' -NotePropertyValue $v.Hostname
        $_ | Add-Member -NotePropertyName 'Prompt' -NotePropertyValue $v.Prompt
        $_ | Add-Member -NotePropertyName 'MACAddress' -NotePropertyValue $v.MACAddress
        $_ | Add-Member -NotePropertyName 'TSID' -NotePropertyValue $v.TSID
        $_ | Add-Member -NotePropertyName 'Serial' -NotePropertyValue $v.Serial
        $_ | Add-Member -NotePropertyName 'ErrorMessage' -NotePropertyValue $v.ErrorMessage
        $_
    }} | Group-Object ExternalIP

# output to csv files
$groups | %{$_.Group | Export-Csv -Path (Join-Path $here "$($_.Name).csv") -NoTypeInformation}
