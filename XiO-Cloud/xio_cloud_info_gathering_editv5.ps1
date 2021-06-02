$filelocation = $PSScriptRoot + '\devices.csv'

# import the module
Import-Module PSCrestron

# gather the info on the subnet then write to workbook
Get-AutoDiscovery -ShowProgress |
    Select-Object -ExpandProperty IP |
    Get-VersionInfo | 
    ForEach-Object {[PSCustomObject]@{'MAC Address' = $_.MACAddress;
        'Serial Number' = $_.Serial;
        'Name' = $_.Hostname}} |
Export-Csv -Path $filelocation -Force -NoTypeInformation