# ---------------------------------------------------------
function Set-AirMediaBackground
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
        [string]$Password,

        [Parameter(Mandatory=$true)]
        [string]$ImageUrl,

        [Parameter(Mandatory=$false)]
        [bool]$Reboot
    )

    try
    {
        # convert to an IP
        $Device = [System.Net.Dns]::Resolve($Device).AddressList[0].IPAddressToString

        # secure and unsecure urls
        $url = "http://$Device/userlogin.html"
        $urls = "https://$Device/userlogin.html"

        # origin and referer headers
        $header = @{'Origin' = ('https://{0}' -f $Device);'Referer' = ('https://{0}/userlogin.html' -f $Device)}

        # create an intial session
        $res = Invoke-WebRequest -Uri $url -SessionVariable session -Headers $header -Method Get
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $url."}

        # add the credentials
        $form = $res.Forms[0]
        $form.Fields['login'] = $Username
        $form.Fields['passwd'] = $Password

        # open a secure session
        $res = Invoke-WebRequest -Uri $urls -WebSession $session -Method Post -Body $form.Fields -UseBasicParsing
        if ($res.StatusCode -ne 200) {throw "Failed to open session to $urls."}
        #$cookies = $session.Cookies.GetCookies($urls)

        # anti-CSRF feature for all the POST requests
        if($res.Headers['CREST-XSRF-TOKEN'] -ne $null)
            {$token = @{'X-CREST-XSRF-TOKEN' = $res.Headers['CREST-XSRF-TOKEN']}}
        else
            {$token = $null}

        # return the session
        [PSCustomObject]@{Device = $Device; Session = $session; Token = $token}

        # send the URL
        $json = '{"Device":{"App":{"Config":{"RunTimeSettings":{"Backgrounds":{"CustomBackgroundList":[{"Name":"0","URL":"#ImageUrl"}]}}}}}}' -replace '#ImageUrl',$ImageUrl
        $res = Invoke-WebRequest -Uri "https://$($Session.Device)/Device/App/Config/RunTimeSettings/Backgrounds/CustomBackgroundList/0" -WebSession $Session.Session `
        -Headers $Session.Token -Method Post -Body ($json) -ContentType "application/json"

        # update config
        $res = Invoke-CrestronCommand -Device $Device -Command 'AVFUPDATECONFIG' -Secure -Username $Username -Password $Password

        # (optional) reboot AirMedia unit
        if ($Reboot = $true) {
            $res = Invoke-CrestronCommand -Device $Device -Command 'REBOOT' -Secure -Username $Username -Password $Password
        }
        else {
            $null
        }
    }
    catch
    {
        throw
    }
}