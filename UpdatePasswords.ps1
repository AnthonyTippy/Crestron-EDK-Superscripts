Import-Module PSCrestron
Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1')

$username = 'usernamehere'
$oldpassword = 'oldpasswordhere'
$newpassword = 'newpasswordhere'

try
	{
	$devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'devices.txt'))
	Write-Host 'Obtaining list of devices'
	}
catch
	{
	Write-Host 'Error Obtaining list of devices'
	}

foreach ($d in $devs)
{
	Write-Host 'Updating Authentication for:' $d
	Update-Authentication -Device $d -Username $username -OldPassword $oldpassword -NewPassword $newpassword
}