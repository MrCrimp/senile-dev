<#
.SYNOPSIS
    All reminders we need
        
.NOTES
    Name: Remind-Me
    Author: me
 
.EXAMPLE
    Remind-Me -Foo "username"
  
.LINK
    https://helpurl
#>

iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI" #Update Powershell to latest verison

Get-Command                                               # Retrieves a list of all the commands available to PowerShell
                                                          # (native binaries in $env:PATH + cmdlets / functions from PowerShell modules)
Get-Command -Module Microsoft*                            # Retrieves a list of all the PowerShell commands exported from modules named Microsoft*
Get-Command -Name *item                                   # Retrieves a list of all commands (native binaries + PowerShell commands) ending in "item"

Get-Help                                                  # Get all help topics
Get-Help -Name about_Variables                            # Get help for a specific about_* topic (aka. man page)
Get-Help -Name Get-Command                                # Get help for a specific PowerShell function
Get-Help -Name Get-Command -Parameter Module              # Get help for a specific parameter on a specific command

# 🚀 Icons? Install VsCode Emojii pack

###################################################
# Script setup
###################################################
$ErrorActionPreference = "Stop"                           # SilentlyContinue | Continue (ask to continue) | Inquire (prompt) | Stop (terminate process with error)
$DebugPreference = "SilentlyContinue"                     # SilentlyContinue | Continue
Write-Debug "Not displayed unless $DebugPreference == Continue"

# The famous git error handling WTF
$env:GIT_REDIRECT_STDERR = '2>&1'

# The OS 
$IsWindows 
$IsLinux 
$IsMacOS

###################################################
# Working dir
###################################################

$prevPwd = $PWD
Set-Location -ErrorAction Stop -LiteralPath $PSScriptRoot       # Start at script dir, then go back
Set-Location $prevPwd

$TargetDir = resolve-path "$HOME"                               # Find user home
if (-not(test-path "$TargetDir" -pathType container)) {
    throw "Home directory at 📂$TargetDir doesn't exist (yet)"
}

###################################################
# Operators
###################################################

$a = 2                                                    # Basic variable assignment operator
$a += 1                                                   # Incremental assignment operator
$a -= 1                                                   # Decrement assignment operator

$a -eq 0                                                  # Equality comparison operator
$a -ne 5                                                  # Not-equal comparison operator
$a -gt 2                                                  # Greater than comparison operator
$a -lt 3                                                  # Less than comparison operator

$FirstName = 'Trevor'
$FirstName -like 'T*'                                     # Perform string comparison using the -like operator, which supports the wildcard (*) character. Returns $true

$BaconIsYummy = $true
$FoodToEat = $BaconIsYummy ? 'bacon' : 'beets'            # Sets the $FoodToEat variable to 'bacon' using the ternary operator

###################################################
# Regular Expressions
###################################################

'Trevor' -match '^T\w*'                                   # Perform a regular expression match against a string value. # Returns $true and populates $matches variable
$matches[0]                                               # Returns 'Trevor', based on the above match

@('Trevor', 'Billy', 'Bobby') -match '^B'                 # Perform a regular expression match against an array of string values. Returns Billy, Bobby

$regex = [regex]'[-a-zA-Z0-9@:%_\+.~#?&//=]{2,256}\.[a-z]{2,4}\b(\/[-a-zA-Z0-9@:%_\+.~#?&//=]*)\ig'
$regex.Matches('Trevor Bobby Dillon Joe Jacob').Value     # Find multiple matches against a singleton string value.

###################################################
# Flow Control
###################################################

$gitHist = (git log --no-merges --format="%ai`t%H`t%an`t%ae`t%s" -n 100) | ConvertFrom-Csv -Delimiter "`t" -Header ("Date", "CommitId", "Author", "Email", "Subject")
$gitHist | Group-Object -Property Author -NoElement | Sort-Object -Property Count -Descending   # Now you can do iterate over each commit in PowerShell, group sort etc.
$gitHist | % { if ($_.Author -eq "X K") { "Me" } else { "Someone else" } }                      # Example do something for each commit

if ( (1 -eq 1) -or (2 -eq 2) ) { }                                          # Do something if 1 is equal to 1

do { 'hi' } while ($false)                                # Loop while a condition is true (always executes at least once)

while ($false) { 'hi' }                                   # While loops are not guaranteed to run at least once
while ($true) { }                                         # Do something indefinitely
while ($true) { if (1 -eq 1) { break } }                  # Break out of an infinite while loop conditionally

for ($i = 0; $i -le 10; $i++) { Write-Host $i }           # Iterate using a for..loop
foreach ($item in (Get-Process)) { }                      # Iterate over items in an array

switch ('test') { 'test' { 'matched'; break } }           # Use the switch statement to perform actions based on conditions. Returns string 'matched'
switch -regex (@('Trevor', 'Daniel', 'Bobby')) {          # Use the switch statement with regular expressions to match inputs
  'o' { $PSItem; break }                                  # NOTE: $PSItem or $_ refers to the "current" item being matched in the array
}
switch -regex (@('Trevor', 'Daniel', 'Bobby')) {          # Switch statement omitting the break statement. Inputs can be matched multiple times, in this scenario.
  'e' { $PSItem }
  'r' { $PSItem }
}

###################################################
# Variables
###################################################


$a = 0                                                    # Initialize a variable
[int] $a = 'Trevor'                                       # Initialize a variable, with the specified type (throws an exception)
[string] $a = 'Trevor'                                    # Initialize a variable, with the specified type (doesn't throw an exception)

Get-Command -Name *varia*                                 # Get a list of commands related to variable management

Get-Variable                                              # Get an array of objects, representing the variables in the current and parent scopes 
Get-Variable | ? { $PSItem.Options -contains 'constant' } # Get variables with the "Constant" option set
Get-Variable | ? { $PSItem.Options -contains 'readonly' } # Get variables with the "ReadOnly" option set

New-Variable -Name FirstName -Value Trevor
New-Variable FirstName -Value Trevor -Option Constant     # Create a constant variable, that can only be removed by restarting PowerShell
New-Variable FirstName -Value Trevor -Option ReadOnly     # Create a variable that can only be removed by specifying the -Force parameter on Remove-Variable

Remove-Variable -Name firstname                           # Remove a variable, with the specified name
Remove-Variable -Name firstname -Force                    # Remove a variable, with the specified name, that has the "ReadOnly" option set

###################################################
# Collections - since arrays are fixed size..
###################################################

# Some input data - simplified for example purposes
$SomeData = @('be', 'me', 'one', 'more', 'time')
$GenericList1 = [System.Collections.Generic.List[Object]]::new()
$GenericList2 = [System.Collections.Generic.List[Object]]::new()
foreach ($Something in $SomeData) {
    $GenericList1.Add("MyValue $Something")
    $GenericList2.Add("Other $Something")
}
$GenericList1.Count
$GenericList2.Count
$GenericList1.Remove('MyValue be')
$GenericList1.Count
$GenericList1 -join ','

# Prefer Generic lists instead ^
$myList = [System.Collections.ArrayList]@();
$myList.Add('item');
$myList.Remove('item')

[System.Collections.ArrayList]$Combined3 = @()
$files | ForEach-Object{

    $obj = [PSCustomObject]@{
        FileName  = $_.fullname
        LastWrite = $_.Lastwritetime
    }
    $Combined3.Add($obj)|Out-Null
}

###################################################
# Functions
###################################################

function add ($a, $b) { $a + $b }                         # A basic PowerShell function

function Do-Something {                                   # A PowerShell Advanced Function, with all three blocks declared: BEGIN, PROCESS, END
  #[CmdletBinding]()]
  param ()
  #begin { } #runs once with multiple input
  process { }
  #end { }
}

###################################################
# Working with Modules
###################################################

Get-Command -Name *module* -Module mic*core                 # Which commands can I use to work with modules?

Get-Module -ListAvailable                                   # Show me all of the modules installed on my system (controlled by $env:PSModulePath)
Get-Module                                                  # Show me all of the modules imported into the current session

$PSModuleAutoLoadingPreference = 0                          # Disable auto-loading of installed PowerShell modules, when a command is invoked

Import-Module -Name NameIT                                  # Explicitly import a module, from the specified filesystem path or name (must be present in $env:PSModulePath)
Remove-Module -Name NameIT                                  # Remove a module from the scope of the current PowerShell session

New-ModuleManifest                                          # Helper function to create a new module manifest. You can create it by hand instead.

New-Module -Name trevor -ScriptBlock {                      # Create an in-memory PowerShell module (advanced users)
  function Add($a,$b) { $a + $b } }

New-Module -Name trevor -ScriptBlock {                      # Create an in-memory PowerShell module, and make it visible to Get-Module (advanced users)
  function Add($a,$b) { $a + $b } } | Import-Module

###################################################
# Module Management
###################################################

Get-Command -Module PowerShellGet                           # Explore commands to manage PowerShell modules

Find-Module -Tag cloud                                      # Find modules in the PowerShell Gallery with a "cloud" tag
Find-Module -Name ps*                                       # Find modules in the PowerShell Gallery whose name starts with "PS"

Install-Module -Name NameIT -Scope CurrentUser -Force       # Install a module to your personal directory (non-admin)
Install-Module -Name NameIT -Force                          # Install a module to your personal directory (admin / root)
Install-Module -Name NameIT -RequiredVersion 1.9.0          # Install a specific version of a module

Uninstall-Module -Name NameIT                               # Uninstall module called "NameIT", only if it was installed via Install-Module

Register-PSRepository -Name $repo -SourceLocation $uri    # Configure a private PowerShell module registry
Unregister-PSRepository -Name $repo                        # Deregister a PowerShell Repository


###################################################
# File system & Use of .NET
###################################################

[System.IO.File]::WriteAllText('Also works')
Add-Content C:\temp\test.txt "`nThis is a new line"         #Append to end of file
Set-Content "$PSScriptRoot/release-notes.txt" $history      #Replace contents

New-Item -Path c:\test -ItemType Directory                  # Create a directory
mkdir c:\test2                                              # Create a directory (short-hand)

New-Item -Path c:\test\myrecipes.txt                        # Create an empty file
Set-Content -Path c:\test.txt -Value ''                     # Create an empty file
[System.IO.File]::WriteAllText('testing.txt', '')           # Create an empty file using .NET Base Class Library

Remove-Item -Path testing.txt                               # Delete a file
[System.IO.File]::Delete('testing.txt')                     # Delete a file using .NET Base Class Library

###################################################
# Hashtables (Dictionary)
###################################################

$Person = @{
  FirstName = 'Trevor'
  LastName = 'Sullivan'
  Likes = @(
    'Bacon',
    'Beer',
    'Software'
  )
}                                                           # Create a PowerShell HashTable

$Person.FirstName                                           # Retrieve an item from a HashTable
$Person.Likes[-1]                                           # Returns the last item in the "Likes" array, in the $Person HashTable (software)
$Person.Age = 50                                            # Add a new property to a HashTable

###################################################
# Windows Management Instrumentation (WMI) (Windows only)
###################################################

Get-CimInstance -ClassName Win32_BIOS                       # Retrieve BIOS information
Get-CimInstance -ClassName Win32_DiskDrive                  # Retrieve information about locally connected physical disk devices
Get-CimInstance -ClassName Win32_PhysicalMemory             # Retrieve information about install physical memory (RAM)
Get-CimInstance -ClassName Win32_NetworkAdapter             # Retrieve information about installed network adapters (physical + virtual)
Get-CimInstance -ClassName Win32_VideoController            # Retrieve information about installed graphics / video card (GPU)

Get-CimClass -Namespace root\cimv2                          # Explore the various WMI classes available in the root\cimv2 namespace
Get-CimInstance -Namespace root -ClassName __NAMESPACE      # Explore the child WMI namespaces underneath the root\cimv2 namespace



###################################################
# Asynchronous Event Registration
###################################################

#### Register for filesystem events
$Watcher = [System.IO.FileSystemWatcher]::new('c:\tmp')
Register-ObjectEvent -InputObject $Watcher -EventName Created -Action {
  Write-Host -Object 'New file created!!!'
}                                                           

#### Perform a task on a timer (ie. every 5000 milliseconds)
$Timer = [System.Timers.Timer]::new(5000)
Register-ObjectEvent -InputObject $Timer -EventName Elapsed -Action {
  Write-Host -ForegroundColor Blue -Object 'Timer elapsed! Doing some work.'
}
$Timer.Start()

###################################################
# PowerShell Drives (PSDrives)
###################################################

Get-PSDrive                                                 # List all the PSDrives on the system
New-PSDrive -Name videos -PSProvider Filesystem -Root x:\data\content\videos  # Create a new PSDrive that points to a filesystem location
New-PSDrive -Name h -PSProvider FileSystem -Root '\\storage\h$\data' -Persist # Create a persistent mount on a drive letter, visible in Windows Explorer
Set-Location -Path videos:                                  # Switch into PSDrive context
Remove-PSDrive -Name xyz                                    # Delete a PSDrive

###################################################
# Data Management
###################################################

Get-Process | Group-Object -Property Name                   # Group objects by property name
Get-Process | Sort-Object -Property Id                      # Sort objects by a given property name
Get-Process | Where-Object -FilterScript { $PSItem.Name -match '^c' } # Filter objects based on a property matching a value
gps | where Name -match '^c'                                # Abbreviated form of the previous statement


###################################################
# Terminal output 
###################################################

# Write-Output writes to a return array. 
Write-Output "`nStatistics of $filename `:"            # To return array from script

# Write-Host writes immediately (and only) to the console,
Write-Host "This one" -ForegroundColor Green
('This is **Bold** text' | ConvertFrom-MarkDown -AsVt100EncodedString).VT100EncodedString
Write-Host -ForegroundColor White 'This is Bold ' -NoNewline; Write-Host -ForegroundColor red "and this red not"

Clear-Host # Cls | Clear
Write-Host "================ Title ================"
Write-Host "1: Press '1' for this option."

###################################################
# Errors

    try {
        An error                    # Illegal statement
    }
    catch {
       "An error occurred"
    }

    $error[0] | fl                   # The latest
    $error[$error.count-1] | fl      # The first