Import-Module PSCrestron

$DeviceList = ""

$file = ''

##FTP site##
Get-FTPFile -Device '' -RemoteFile '' -Username crestron -Password crestron -LocalPath $file


Import-Csv -Path $DeviceList |
    Select-Object -ExpandProperty IP |
    Send-FTPFile -Device $_.IPAddress -LocalFile $file -Username $_.Username -Password $_.Password -RemoteFile '\firmware' |
    Invoke-CrestronCommand 'puf'