write-host @"


██╗██████╗     ██╗     ██╗███████╗████████╗     ██████╗ ███████╗███╗   ██╗███████╗██████╗  █████╗ ████████╗ ██████╗ ██████╗ 
██║██╔══██╗    ██║     ██║██╔════╝╚══██╔══╝    ██╔════╝ ██╔════╝████╗  ██║██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
██║██████╔╝    ██║     ██║███████╗   ██║       ██║  ███╗█████╗  ██╔██╗ ██║█████╗  ██████╔╝███████║   ██║   ██║   ██║██████╔╝
██║██╔═══╝     ██║     ██║╚════██║   ██║       ██║   ██║██╔══╝  ██║╚██╗██║██╔══╝  ██╔══██╗██╔══██║   ██║   ██║   ██║██╔══██╗
██║██║         ███████╗██║███████║   ██║       ╚██████╔╝███████╗██║ ╚████║███████╗██║  ██║██║  ██║   ██║   ╚██████╔╝██║  ██║
╚═╝╚═╝         ╚══════╝╚═╝╚══════╝   ╚═╝        ╚═════╝ ╚══════╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝
         
                                                                                                                            
           Written By: Anthony Tippy                                                                                                        


"@

#Octet Subnet Range
$octone =(Read-Host "Enter 1st Octet (XXX.168.1.1)")
$octtwo = (Read-Host "Enter 2nd Octet (192.XXX.1.1)")
$s = (Read-Host "Enter 3rd Octet MIN (192.168.XXX.1)") 
$f = (Read-Host "Enter 3rd Octet Max (192.168.XXX.254)") 

#User input 3rd octet range (MIN -MAX)
$range = $s..$f

$ip=1..254

Write-host "`nGenerating All IP Addresses between $octone.$octtwo.$s.1 - $octone.$octtwo.$f.254"
#Generate List
$total =$range | ForEach-Object {
   $address = “$octone.$octtwo.$_.”

   $ip=1..254
   ForEach ($d in $address){
        ForEach ($d in $ip){
            $address + $d
            }
            
                        }
   }
Write-host "DONE!`n"

$total | Out-File (Join-Path $PSScriptRoot "ip scan.txt")

$i=0

$devs =@(Get-Content -Path (Join-Path $PSScriptRoot 'ip scan.txt'))
$count = 0
foreach ($d in $devs){
$count += 1}

Write-host -f green "`n`n$count Total IP addresses written to $PSScriptRoot \ip scan.txt`n`n"

Read-Host -Prompt “Press Enter to exit”
