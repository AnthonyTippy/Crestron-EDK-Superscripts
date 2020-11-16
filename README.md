# Crestron-EDK-Superscript
Crestron Powershell script to pull device information and issue commands to many devices on an IP list.  Once script has ran, it will export the data gathered out to a CSV file for consumption.

This powershell script requires fairly little modification and can be used to gather information on hundreds of crestron devices on a network across multiple subnets.

# Get-Started
1. Download and install the Crestron Powershell EDK 
-Non-Crestron Link: https://crestron-edk.software.informer.com/download/

2. Set your username and password
-$cUsername = "USERNAME"
-$cPassword = "PASSWORD"

3. Set the name of your IP.txt list
-$deviceList = Get-Content (Join-Path $PSScriptRoot 'IP.txt')

4. Paste IP addresses in IP.txt file (make sure there's no whitespace after the IP's as it can cause issues)

5. Run the script!

#### NOTE: The script is not perfect and can take some time, but I've tried to provide as much updates regarding the processes it runs to show progress.  

# Here's the exact flow of the script

1. Script attempts to connect /authenticate to device in IP list via the following methods (in order)
- SSH with username/password provided
- SSH crestron default password
- SSH admin/admin credentials
- If port 22 not open, it tries to connect via CTP admin admin
- If port 41795 is not open and all above methods have failed, script displays "error connecting" message and logs it appropriately

#### Additionally, during this process the script runs "Get-VersionInfo" which provides a wealth of information about the device such as Model #, serial #, mac address, firmware version, compile date...etc

2. Once the script is able to connect to the device, script will open a crestron session with the device based on the successful authentication method

3. Once a crestron session has been opened, the script issues 2 commands
- 'PROGCOMMENTS' = reports back current program running  (if control system)
- 'DHCP' = Shows DHCP status of device 

4. Script adds gained information to the CSV output file and moves on to the next IP address on the list

5. Once completed, the script reports back total time for the script. 
Error log output file can be found in same directory as script under SuperScript ERROR LOG.txt

# CrestFinder
CrestFinder.ps1 is a secondary script that utilizes the Read-Autodiscovery EDK function.  This script reaches out to device IP's from a text file and broadcasts out to other crestron devices on the same subnet.  This script helps to find other devices you may not know about based on a pre-existing IP list.

1.  Paste IP.txt list in root directory of script
2.  Change IP list name in script (to match name of your IP list)
3.  Run script

Script runs much quicker than superscript and returns IP address, Hostname, Device Model Info, Firmware version, compile date, and mac address.

# Firmware Upgrader
FirmwareUpgrader.ps1 is a secondary script that uses much of the same functionality as the superscript to initialize firmware upgrades across many devices on an IP list.

1. Download firmware file to be sent to devices to the same file location as script
2. Rename the variable "$FW" with the file name to be sent [FW = (Join-Path $PSScriptRoot 'tsw-xx60_2.009.0122.001.puf')]
3. Rename firmware file name [$fname = 'tsw-xx60_2.009.0122.00.puf']
4. Run script!


# More information about the crestron powershell module
https://sdkcon78221.crestron.com/sdk/Crestron_EDK_SDK/Content/Topics/Modules/CrestronSession-Module.htm
https://sdkcon78221.crestron.com/sdk/Crestron_EDK_SDK/Content/Topics/PSCrestron.htm#Get-VersionInfo
