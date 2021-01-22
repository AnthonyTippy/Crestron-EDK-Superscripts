###Crestron Device Discovery Script
###Script will call IP addresses from list and gather device information via autodiscovery 
write-host @"  



 ██████╗██████╗ ███████╗███████╗████████╗███████╗██╗███╗   ██╗██████╗ ███████╗██████╗ 
██╔════╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔════╝██║████╗  ██║██╔══██╗██╔════╝██╔══██╗
██║     ██████╔╝█████╗  ███████╗   ██║   █████╗  ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝
██║     ██╔══██╗██╔══╝  ╚════██║   ██║   ██╔══╝  ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗
╚██████╗██║  ██║███████╗███████║   ██║   ██║     ██║██║ ╚████║██████╔╝███████╗██║  ██║
 ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝
                                                                                      
    v1.4
    Written By: Anthony Tippy





                                                                                                                                                           
"@
#Stopwatch feature
$stopwatch =  [system.diagnostics.stopwatch]::StartNew()

#Credentials
$username = 'USERNAME'
$password = 'PASSWORD'


# make sure the PSCrestron Cmdlets are loaded into PowerShell
Import-Module PSCrestron

#Delete old fILES
Remove-Item ".\Desktop\CrestFinder Results.csv" -ErrorAction SilentlyContinue
Remove-Item ".\Desktop\CrestFinder Results SORTED.csv" -ErrorAction SilentlyContinue

# declare an object to hold the results table
$ResultsTable =@()

$outputpath = ".\Desktop\CrestFinder Results.csv"

#load IP from TXT list
$devs = Get-Content (Join-Path $PSScriptRoot 'IP.txt')

#Run Autodiscovery in parallel processes
Invoke-RunspaceJob -InputObject $devs -ScriptBlock {
    try {
        $d = $_
        $DeviceResultItem = New-Object PSObject

        Write-host -f Green  "Discovering : $d`n"

        $DeviceResultItem = Read-AutoDiscovery $d  -secure -ErrorAction "SilentlyContinue"

        #Add line to the report
        $DeviceResultsData = $DeviceResultItem

        $DeviceResultsData | export-csv -Path (".\Desktop\CrestFinder Results.csv") -NoTypeInformation -Append
        }
    Catch {
        Try{
        Write-host -f green "Discovering : $d`n"

        $DeviceResultItem = Read-AutoDiscovery $d -secure -username $username -password $password -ErrorAction "SilentlyContinue"

        #Add line to the report
        $DeviceResultsData = $DeviceResultItem

        $DeviceResultsData | export-csv -Path (".\Desktop\CrestFinder Results.csv") -NoTypeInformation -Append
        }

        Catch{
        write-host -f Red "$d Unable to connect`n`n"
        #$d | export-csv -Path (".\Desktop\CrestFinder Results.csv") -NoTypeInformation -Append
        }

        }

 }-ThrottleLimit 50  -ShowProgress

 #Remove Duplicate Entries
Import-Csv (".\Desktop\CrestFinder Results.csv") | sort IP –Unique | export-csv ".\Desktop\CrestFinder Results SORTED.csv" -NoTypeInformation -Force

#Delete Unneeded Duplicate Raw Output File
Remove-Item ".\Desktop\CrestFinder Results.csv" -ErrorAction SilentlyContinue

#Total time of script
$stopwatch

Read-Host -Prompt “Press Enter to exit”
