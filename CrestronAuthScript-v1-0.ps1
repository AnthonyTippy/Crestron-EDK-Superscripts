# import libraries
Write-Host 'Importing libraries'
Import-Module PSCrestron
Import-Module (Join-Path $PSScriptRoot 'Authentication.psm1')

# define variables
$username = 'usernamehere'
$password = 'passwordhere'
$passwordminlength = ''
$lockouttimeout = ''
$sntpserver = ''

# import file
try
	{
	$devs = @(Get-Content -Path (Join-Path $PSScriptRoot 'authdevices.txt'))
	Write-Host 'Obtaining list of devices'
	}
catch
	{
	Write-Host 'Error Obtaining list of devices'
	}
	

# loop for each device to enable authentication
foreach ($d in $devs)
	{
	Write-Host 'Setting Authentication for:' $d
	Set-Authentication -Device $d -AuthUsername $username -AuthPassword $password -PasswordLength $passwordminlength -LockoutTime $lockouttimeout -TimeServer $sntpserver
	}

