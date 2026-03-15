
#region conda initialize (lazy-loaded)
# !! Conda initialization deferred until first use !!
$_condaExe = "D:\SDKs\miniforge3\Scripts\conda.exe"
$_condaInitialized = $false

function global:_initCondaOnce {
    if (-not $global:_condaInitialized -and (Test-Path $_condaExe)) {
        (& $_condaExe "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
        $global:_condaInitialized = $true
    }
}

function global:conda {
    _initCondaOnce
    & $_condaExe @args
}
#endregion

