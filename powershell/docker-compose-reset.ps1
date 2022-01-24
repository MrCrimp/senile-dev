
if(!$IsWindows){exit;}

# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
     $CommandLine = "-NoExit -File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments                
     Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine, $PWD.Path      
     Exit
    }
}

Write-Host "(If script pauses, press ENTER => and fix your powershell settings..)"

$vm = Get-VM -Name DockerDesktopVM
$feature = "Time Synchronization"

Disable-VMIntegrationService -vm $vm -Name $feature
Enable-VMIntegrationService -vm $vm -Name $feature

cd $args[0] 
Write-Host $PWD

cd ../some-dir
docker system prune
docker-compose build --pull;

Write-Host " "
Write-Host "-------------------"
Write-Host "Done. Everything was rebuilt."

Exit
