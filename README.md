# Get-Started/Installation
1. Download and install the Crestron Powershell EDK 

   -[Non-Crestron Link](Https://crestron-edk.software.informer.com/download)

   -[Direct Crestron Link](https://sdkcon78221.crestron.com/sdk/Crestron_EDK_SDK/Content/Topics/Installation)

2.  Download this repository or individual scripts you'd like to run

# SuperScript
### SYNOPSIS

Crestron PowerShell script to pull device information and issue commands to many devices on an IP list.  Once script has ran, it will export the data gathered out to a CSV file.

This PowerShell script requires fairly little modification and can be used to gather information on hundreds of Crestron devices on a network across multiple subnets.
### REQUIREMENTS

1. Download the above module
2. Set your username and password (Line 117/118)
-$username = "USERNAME"
-$password = "PASSWORD"

3. Add IP's to your IP.txt list (in same folder as script)
4. Run Script
5. Script will attempt to connect to each device and grab various device information from it.
6. Script will also discover any control subnet devices as well as Cresnet devices that may be connected

This script is very efficient in its performance and can very quickly filter through hundreds of devices in minutes.

### OUTPUT
Script outputs all information found to csv report `C:\Superscript Results.csv` as well as `C:\Superscript Results Log.csv` which is a persistent log of results

### EXAMPLE
```
Start of Script

[Default Password] Working on => CP3N-TEST1 192.168.1.1

5 control subnet devices found in 192.168.1.1 - CP3N-TEST1
- 0 : DM-DGE-200-C 
- 1 : DM-DGE-200-C 
- 2 : DM-DGE-200-C 
- 3 : DM-MD16x16 Cntrl Eng 
- 4 : TSW-1060 

2 cresnet devices found in 192.168.1.1 - CP3N-TEST1
- 0 : STATUSSIGN
- 1 : GLS-ODT-C-CN



[Default Password] Working on => CP3N-TEST2 192.168.1.2

2 control subnet devices found in 192.168.1.2 - CP3N-TEST2
- 0 : DM-DGE-200-C 
- 1 : DM-MD8x8 Cntrl Eng 

2 cresnet devices found in 192.168.1.2 - CP3N-TEST2
- 0 : STATUSSIGN
- 1 : GLS-ODT-C-CN



[Custom Password] Working on => TSW-1060-ConfC 192.168.1.3

0 control subnet devices found in 192.168.1.3 - TSW-1060-ConfC

2 cresnet devices found in 192.168.1.3 - TSW-1060-ConfC
- 0 : STATUSSIGN
- 1 : GLS-ODT-C-CN


Results can be found at C:\Superscript Results.csv
```

# ScreenGrabber
### SYNOPSIS
Screengrabber connects to the devices in IP.txt, issues the screenshot command, names the screenshot taken after the device's hostname, transfers the screenshot to your PC via FTP and then deletes screenshot file from the device memory

### REQUIREMENTS
-IP.txt file of IP addresses
#### Modify Username/Password to be set (Line 91)
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'

### OUTPUT
All Screenshots are exported and saved to a C:\Desktop\Screenshots folder that is created.  Folder and all screenshots will be deleted with each run of the ScreenGrabber script.

This script is very useful for checking the online status of MTR room touch panels or Room Scheduler panels. 
### EXAMPLE
```
[Default Password]  Grabbing Screenshot for: 192.168.1.1 ==> TSW-Room 1



[Custom Password]  Grabbing Screenshot for: 192.168.1.2 ==> TSW-Room 2



[Custom Password]  Grabbing Screenshot for: 192.168.1.3 ==> TSW-Room 3

IsRunning           : True
Elapsed             : 00:00:06.0209322
ElapsedMilliseconds : 6020
ElapsedTicks        : 60209529



Screenshots saved to C:\Desktop\Screenshots

```
# CrestFinder
### SYNOPSIS
CrestFinder is a secondary script that utilizes the Read-Autodiscovery EDK function.  This script reaches out to device IP's from a text file and broadcasts out to other Crestron devices on the same subnet.  This script helps to find other devices you may not know about based on a pre-existing IP list.

### REQUIREMENTS
-IP.txt file of IP addresses
#### Modify Username/Password to be set (Line 96/97)
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'

### OUTPUT
Script runs much quicker than superscript and returns IP address, Hostname, Device Model Info, Firmware version, compile date, and mac address. Script outputs report to user root directory

# Firmware Upgrader
### SYNOPSIS
FirmwareUpgrader will attempt upgrade or downgrade the firmware version of all the devices in the IP.txt list and return firmware upgrade results to a csv file.

### REQUIREMENTS
1. Download firmware file to be sent to devices
2. Rename the $FW variable (line 56) to the file path location of the downloaded firmware
3. Set the Credential variables $username and $password (line 50/51) 
4. Run script!

### OUTPUT

# Enable Authentication
### SYNOPSIS
  This script enables authentication on Crestron devices in IP list from default Crestron password.  Note: script processes through IP list sequentially instead of in runspace blocks due to sensitive nature of changing passwords.  Due to this, the script can take a bit longer than other scripts.

### REQUIREMENTS
-IP.txt file of IP addresses
#### Modify Username/Password to be set (Line 96/97)
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'

### OUTPUT
Script outputs report of devices and changes made to C:\Password Change Results.csv

# Password Changer
### SYNOPSIS
Script changes password from *previously set password*.
### REQUIREMENTS

-IP.txt file of IP addresses
#### Modify Username/Password to be set (Line 107-110)
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'
  - $newpassword = 'ENTER PASSWORD'
### OUTPUT
Script outputs report of changes made to devices to "C:\Password Update Results.csv"

### EXAMPLE


# DHCP Killer
### SYNOPSIS
DHCP Killer is a script to automate the process of turning off DHCP and setting the ethernet settings to static.

### REQUIREMENTS
1.  Paste IP.txt list in root directory of script
2.  Change IP list name in script (to match name of your IP list)
3.  Edit DNS variables to desired IP's (defaults to googles DNS)
4.  Run script

- Script will filter import ip list and filter through device IP's
- script will pull device IP info (IP address, subnet mask, gateway) 
- script then sets device ethernet settings to static matching previously gathered info
- script disables DHCP
- Your device should have the same IP address it started with, but set to static


# UC-ENGINE Superscript 

### SYNOPSIS
  Asyncronously connects to UC-Engine and grabs windows Get-ComputerInfo details as well as connected devices, information about the touchpanel connected, and other various device info.

#### UC-Engine Username/Password
  - $username = 'ENTER YOUR USERNAME' 
  - $password = 'ENTER PASSWORD'

#### Crestron Device Username (Touchpanel)
  - $cusername = 'ENTER YOUR USERNAME'
  - $cpassword = 'ENTER PASSWORD'

  - IP.txt text file containing IP addresses of devices (One per line)

### REQUIREMENTS
  - Run script as **admin**
  - Each UC-Engine **MUST** have PSRemoting enabled 

*To enable: Run Powershell as administrator ON UC ENGINE ==> Issue the command "Enable-PSRemoting -SkipNetworkProfileCheck"*

  - PSCrestron module must be installed (Crestron EDK)
  - IP.txt file for IP's in same folder as script

### OUTPUTS
  C:\MTR  Results.csv
  
### EXAMPLE
  Modify BOTH SETS of username/password variables (Line 100) --> enter UC-ENGINE IP addresses into IP.txt file --> Run Script--> script will output device info to C:\MTR  Results.csv


# Crestron Port Scanner

### SYNOPSIS
  Asyncronously scans devices in IP.txt file across multiple ports. 

### DESCRIPTION
  Script will connect to up to 30 devices simultaneously scan for various open ports


### OUTPUTS
  C:\PortScan Results.csv
  
### EXAMPLE
  Enter IP's to scan into IP.txt file in root script directory --> Run script --> Script will scan each device for common ports as well as Crestron specific ports

# IP List Generator

### SYNOPSIS
  Generates sequential IP list between user inputted IP input

### DESCRIPTION
  With this script you can generate a list of all IP addresses between 2 ip addresses.  With this IP list, you can input the generated IP list into [Crestron Info Tool](https://www.crestron.com/Products/Control-Hardware-Software/Software/Development-Software/SW-INFOTOOL) as a batch mode which will discover all crestron devices on that network/IP list

### OUTPUTS
  Crestron Info Tool Report

### EXAMPLE
  Generate IP address list based on user input
     
#### Example: Generate All IP Addresses between 192.168.1.1 -192.168.100.245                                                                                             
```
Enter 1st Octet (XXX.168.1.1): 191
Enter 2nd Octet (191.XXX.1.1): 168
Enter 3rd Octet MIN (191.168.XXX.1): 1
Enter 3rd Octet Max (191.168.XXX.254): 100

Generating All IP Addresses between 191.168.1.1 - 191.168.100.254


26520 :Total IP addresses written to C:\Desktop\ip scan.txt


Press Enter to exit: 
```

# More information about the Crestron PowerShell module

[Crestron EDK Information](https://sdkcon78221.crestron.com/sdk/Crestron_EDK_SDK/Content/Topics/Modules/CrestronSession-Module)

[PSCRESTRON Module Wiki](https://sdkcon78221.crestron.com/sdk/Crestron_EDK_SDK/Content/Topics/PSCrestron.htm)
