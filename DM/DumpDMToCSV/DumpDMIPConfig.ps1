# ---------------------------------------------------------
# DumpDMIPConfig Script
#
# Copyright (C) 2017 to the present, Crestron Electronics, Inc.
# All rights reserved.
# No part of this software may be reproduced in any form, machine
# or natural, without the express written consent of Crestron Electronics.
# ---------------------------------------------------------

# minimum required version
#Requires -Version 3
Set-StrictMode -Version Latest

# ---------------------------------------------------------
function Get-DumpDMIPConfig
# ---------------------------------------------------------
{
	[CmdLetBinding()]
    param
    (
		[parameter(Mandatory=$true)]
        [string]$Device
    )

    # regex pattern
    $patt = [regex]'(?<Slot>[\d\.]+) *\|(?<Device>[\w- ]+\w) *\|(?<Version>[\d\.]+) *\|(?<ExternalIp>[\d\.]+)? *\|(?<Port>[\d]+) *\|(?<InternalIp>[\d\.]+)? *\|(?<Link>(?i)(UP|DOWN)) *\|(?<Mag>(?i)(Y|N))'

    # get the response
    $mc = $patt.Matches((icc $Device 'DUMPDMIPCONFIG'))

    # get the pattern group names
    $gname = $patt.GetGroupNames() | Where-Object {$_ -notin ($patt.GetGroupNumbers())}

    # create a custom object
    [PSCustomObject]$cobj = @()

    # iterate the matches
    foreach ($m in $mc)
    {
        # iterate the groups
        $x = New-Object -TypeName PSCustomObject
        foreach ($g in $gname)
        {
            Add-Member -InputObject $x -NotePropertyName $g -NotePropertyValue ($m.Groups[$g].Value)
        }
        $cobj += $x
    }

    # return the object
    $cobj
}
