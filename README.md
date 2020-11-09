# Crestron-EDK-Superscript
Crestron Powershell script to pull device information and issue commands to many devices on an IP list.  

This powershell script requires fairly little modification and can be used to gather information on hundreds of crestron devices on a network across multiple subnets.

# Get-Started
1. ## set your username and password
$cUsername = "USERNAME"
$cPassword = "PASSWORD"

2. ## Set the name of your IP.txt list
$deviceList = Get-Content (Join-Path $PSScriptRoot 'IP.txt')

3. ## Paste IP addresses in IP.txt file (make sure there's no whitespace after the IP's as it can cause issues)

4.## Run the script!

NOTE: The script is not perfect and can take some time, but I've tried to provide as much updates regarding the processes it runs to show progress.  

Here's the exact flow of the script

1. ## Script attempts to connect /authenticate to device in IP list via the following methods (in order)
-SSH with username/password provided
-SSH crestron default password
-SSH admin/admin credentials
-If port 22 not open, it tries to connect via CTP admin admin
-If port 41795 is not open and all above methods have failed, script displays "error connecting" message and logs it appropriately
Additionally, during this process the script runs "Get-VersionInfo" which provides a wealth of information about the device such as Model #, serial #, mac address, firmware version, compile date...etc

2.##  Once the script is able to connect to the device, script will open a crestron session with the device based on the successful authentication method

3 ## Once a crestron session has been opened, the script issues 2 commands
- 'PROGCOMMENTS' = reports back current program running  (if control system)
- 'DHCP' = Shows DHCP status of device 

4.  ##cript adds gained information to the CSV output file and moves on to the next IP address on the list

5. ## Once completed, the script reports back total time for the script. 
Error log output file can be found in same directory as script under SuperScript ERROR LOG.txt

