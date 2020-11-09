### Crestron SuperScript V1.0  By Anthony Tippy
###Script will call IP addresses from list and gather device information as well as program and DHCP state data

###NOTE: You will need to edit the username and password ($cusername $cpassword) as well as the IP list name under $devicelist 

# make sure the PSCrestron Cmdlets are loaded into PowerShell
Import-Module PSCrestron

#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

# set username and password as needed
$cUsername = "USERNAME"
$cPassword = "PASSWORD"  

# declare an object to hold the results table
$ResultsTable =@()

#load IP from TXT list
$deviceList = Get-Content (Join-Path $PSScriptRoot 'NAME OF IP LIST.txt')  #Edit name of IP list

# for each device in the devicelist
foreach ($dev in $deviceList)
{ 
try {   
    # try to query the device a few different ways:
    # try ssh with username/password, then ssh no username, then ssh admin admin, then CTP
    # set $cMethod so we will know what worked later on in the script
        write-host $dev 'Trying SSH username / Password'
        write-host " " 
        $dVersionInfo = Get-VersionInfo -Device $dev -Secure -Username $cUsername -Password $cPassword  #normal ssh with provided credentials
        $cMethod = "SSH PW"

        if($dVersionInfo.ErrorMessage.Contains("Permission denied (password)"))   #wrong password, try the defaults
        {   write-host $dev 'Trying SSH default password'
            $dVersionInfo = Get-VersionInfo -Device $dev -Secure   #authentication not setup 
            $cMethod = "SSH Default"

            if($dVersionInfo.ErrorMessage.Contains("Permission denied (password)"))   #try admin admin
            {   write-host $dev 'Trying SSH admin admin'
                $dVersionInfo = Get-VersionInfo -Device $dev -Secure -Username "admin" -Password "admin" 
                $cMethod = "SSH admin"
            } 

        }
        
        if($dVersionInfo.ErrorMessage.Contains("Failed to find port 22 open"))   #device doesn't support ssh, try CTP
        {   write-host $dev 'Trying CTP defaults'
            $dVersionInfo = Get-VersionInfo -Device $dev -Username "admin" -Password "admin" -erroraction 'silentlycontinue'
            $cMethod = "CTP"
        }

        if($dVersionInfo.ErrorMessage.Contains("Failed to find port 41795 open"))   #device doesn't support ssh, try CTP
        {   write-host $dev 'Could not Connect'
            $cMethod = "ERROR"
        }
        }
catch{
$dVersionInfo.ErrorMessage.Contains("Failed to find port 41794 open")}

    #if control system category, query for CPU load
        If ($dVersionInfo.Device.Contains("10"))
            {

            #connect appropriately based on what we learned above
            if($cMethod.Contains("SSH PW"))
                {
                $consoleSession = Open-CrestronSession -Device $dev -Secure -username $cUsername -Password $cPassword -erroraction 'silentlycontinue'
                }
            elseif($cMethod.Contains("SSH Default"))
                {

                $consoleSession = Open-CrestronSession -Device $dev -Secure -erroraction 'silentlycontinue'
                }
            elseif($cMethod.Contains("SSH admin"))
                {
                $consoleSession = Open-CrestronSession -Device $dev -Secure -Username "admin" -Password "admin" -erroraction 'silentlycontinue'
                }
           elseif($cMethod.Contains("MTR CTP"))
                {
                $consoleSession = Open-CrestronSession -Device $dev -Secure -Username "admin" -Password "sfb" -erroraction 'silentlycontinue'
                }
           elseif($cMethod.Contains("ERROR"))
                {
                $consoleSession = write-host "ERROR SKIPPED"
                }
            <#else
                {
                $consoleSession = Open-CrestronSession -Device $dev -erroraction 'silentlycontinue'
                }#>
            if($cMethod.contains("ERROR")){ }

            else{
                #Run Crestron Device Commands PROGCOMMENTS
                write-host '-Connected - Running PROGCOMMENTS'
                $dCPULoad = Invoke-CrestronSession -Handle $consoleSession -Command 'progcomments' -ErrorAction SilentlyContinue

                #Run Crestron Command DHCP
                write-host '-Connected - Running DHCP'
                $dDHCP = Invoke-CrestronSession -Handle $consoleSession -Command 'DHCP' -ErrorAction SilentlyContinue
           
                #Close Crestron Session to device
                Close-CrestronSession -Handle $consoleSession -erroraction 'silentlycontinue'

                #Error Handling - If no error's add to record message
                if ($dVersionInfo.ErrorMessage.Contains(""))
                    {write-host '-SUCCESS - Added to Record'
                    write ' '}
                    }

            #Error Handling - If ErrorMessage clears out Program and DHCP info to prevent false info
            if ($dVersionInfo.ErrorMessage.Contains(" ")){
            $dDHCP = " "
            #$cMethod = "Error"
            $dCPULoad =" "}

            #Add program Results
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Program" -NotePropertyValue $dCPULoad -erroraction 'silentlycontinue'

            #Add DHCP Check Results
            Add-Member -InputObject $dVersionInfo -NotePropertyName "DHCP Check" -NotePropertyValue $dDHCP -erroraction 'silentlycontinue'

            #Add Connection Method Log
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Auth Method" -NotePropertyValue $cMethod -erroraction 'silentlycontinue'
            } 

    # not reporting back as a control system
        ELSE
            {
            $dCPULoad = 'N/A'
            Add-Member -InputObject $dVersionInfo -NotePropertyName "Program" -NotePropertyValue $dCPULoad -erroraction 'silentlycontinue'
            }
    

    # Add entry to the table
    #-----------------------
        $ResultsTable += $dVersionInfo

}

# Return the results
#-------------------
$Error | Out-File (Join-Path $PSScriptRoot 'SuperScript ERROR LOG.txt')  #export errors to text file for review
$ResultsTable | Out-GridView
$ResultsTable | Select-Object -Property "Device", "Hostname", "Prompt", "Serial", "MACAddress", "VersionOS", "Category", "Program", "Build" , "DHCP Check", "Auth Method", "ErrorMessage" | Export-Csv -Path $PSScriptRoot\"SuperScript Results.csv" -NoTypeInformation

#Total time of script
$stopwatch