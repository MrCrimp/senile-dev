
Function ContinueOrAbortYN ($message) {
    Write-Host "$message" -ForegroundColor Yellow
    Write-Host -NoNewLine "Continue? (Y/N) "
    $response = Read-Host
    if ( $response -ne "Y" ) { Exit }
}

Function AskYN ($message) {
    Write-Host "$message" -ForegroundColor Yellow
    Write-Host -NoNewLine "Continue? (Y/N) "
    $response = Read-Host
    if($response -eq "") {return $false;}
    if ( ($response.ToUpper() -ne "Y") -or ($response.ToUpper() -ne "YES") ) { return $false }
}

Function Pause ($message) {
    Write-Host "$message" -ForegroundColor Yellow
    $x = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

Function CheckIfExists {
    Param ($command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try {
        if (Get-Command $command) {
            return $true
        }
    } Catch {
        return $false
    }
    Finally {
        $ErrorActionPreference=$oldPreference
    }
}
