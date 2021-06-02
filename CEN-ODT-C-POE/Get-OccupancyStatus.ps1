# ---------------------------------------------------------
function Get-OccupancyStatus
# ---------------------------------------------------------
{

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
        [string]$Password
    )

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")

$body = "login=$Username&passwd=$Password"

Invoke-RestMethod "https://$Device/userlogin.html" -Method 'POST' -Headers $headers -Body $body -SessionVariable session -SkipCertificateCheck | Out-Null

Invoke-RestMethod "https://$Device/Device/OccupancySensor/IsRoomOccupied" -Method 'GET' -Headers $headers -WebSession $session -SkipCertificateCheck | ConvertTo-Json
}