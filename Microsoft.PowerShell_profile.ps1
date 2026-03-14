### PowerShell Profile - Minimal
# Profile directory
$profileDir = $PSScriptRoot

function Clear-Cache {
    Write-Host "Clearing cache..." -ForegroundColor Cyan
    Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cache clearing completed." -ForegroundColor Green
}

# Editor
$EDITOR = 'code'
Set-Alias -Name vim -Value $EDITOR

function Edit-Profile { & $EDITOR $PROFILE.CurrentUserAllHosts }
Set-Alias -Name ep -Value Edit-Profile

function touch($file) { [System.IO.File]::OpenWrite($file).Close() }
function ff($name) {
    Get-ChildItem -recurse -filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.FullName)"
    }
}

# System Utilities
function admin {
    if ($args.Count -gt 0) {
        $argList = $args -join ' '
        Start-Process wt -Verb runAs -ArgumentList "pwsh.exe -NoExit -Command $argList"
    } else {
        Start-Process wt -Verb runAs
    }
}

# Set UNIX-like aliases for the admin command, so sudo <command> will run the command with elevated rights.
Set-Alias -Name su -Value admin
Set-Alias -Name cl -Value Clear-Host

function uptime {
    try {
        $bootTime = Get-Uptime -Since
        Write-Host ("System started on: " + $bootTime.ToString('dddd, MMMM dd, yyyy HH:mm:ss')) -ForegroundColor DarkGray
        $up = (Get-Date) - $bootTime
        Write-Host ("Uptime: {0} days, {1} hours, {2} minutes, {3} seconds" -f $up.Days, $up.Hours, $up.Minutes, $up.Seconds) -ForegroundColor Blue
    } catch {
        Write-Error "An error occurred while retrieving system uptime."
    }
}

function unzip ($file) {
    Write-Output("Extracting", $file, "to", $pwd)
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}
function grep($regex, $dir) {
    if ( $dir ) {
        Get-ChildItem $dir | select-string $regex
        return
    }
    $input | select-string $regex
}

function df {
    get-volume
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function rnm($from, $to) { Rename-Item -Path $from -NewName $to }

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pkill($name) {
    Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
    Get-Process $name
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10, [switch]$f = $false)
    Get-Content $Path -Tail $n -Wait:$f
}

# Quick File Creation
function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

# Directory Management
function mkcd { param($dir) mkdir $dir -Force; Set-Location $dir }

function trash($path) {
    $fullPath = (Resolve-Path -Path $path).Path

    if (Test-Path $fullPath) {
        $item = Get-Item $fullPath

        if ($item.PSIsContainer) {
            # Handle directory
            $parentPath = $item.Parent.FullName
        } else {
            # Handle file
            $parentPath = $item.DirectoryName
        }

        $shell = New-Object -ComObject 'Shell.Application'
        $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

        if ($item) {
            $shellItem.InvokeVerb('delete')
            Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
        } else {
            Write-Host "Error: Could not find the item '$fullPath' to trash."
        }
    } else {
        Write-Host "Error: Item '$fullPath' does not exist."
    }
}

### Quality of Life Aliases

# Navigation Shortcuts
function docs {
    $docs = if(([Environment]::GetFolderPath("MyDocuments"))) {([Environment]::GetFolderPath("MyDocuments"))} else {$HOME + "\Documents"}
    Set-Location -Path $docs
}

function dtop {
    $dtop = if ([Environment]::GetFolderPath("Desktop")) {[Environment]::GetFolderPath("Desktop")} else {$HOME + "\Documents"}
    Set-Location -Path $dtop
}

# Simplified Process Management
function k9 { Stop-Process -Name $args[0] }

# Enhanced Listing with Terminal-Icons (lazy-loaded)
$_terminalIconsLoaded = $false

function _llGrid {
    param([object[]]$items)
    if (-not $items) { return }
    
    # Lazy-load Terminal-Icons on first use
    if (-not $_terminalIconsLoaded) {
        $env:PSModulePath = "$PSScriptRoot\Modules" + [System.IO.Path]::PathSeparator + $env:PSModulePath
        Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue
        $global:_terminalIconsLoaded = $true
    }
    
    $str = @()
    foreach ($item in $items) {
        try {
            $formatted = $item | Format-TerminalIcons -ErrorAction SilentlyContinue
            if ($formatted) { $str += $formatted }
        } catch {
            $str += $item.Name
        }
    }
    
    if (-not $str) { return }
    
    $maxLen = ($str | ForEach-Object { ($_ -replace '\x1b\[[0-9;]*m','').Length } | Measure-Object -Maximum).Maximum
    $spacing = $maxLen + 3
    $col = [Math]::Max(1, [Math]::Floor($Host.UI.RawUI.WindowSize.Width / $spacing))
    $i = 0
    
    foreach ($s in $str) {
        $cleanLen = ($s -replace '\x1b\[[0-9;]*m','').Length
        $pad = $spacing - $cleanLen
        Write-Host -NoNewline "$s$(' ' * $pad)"
        if ((++$i) % $col -eq 0) { Write-Host }
    }
    if ($i % $col -ne 0) { Write-Host }
}
function la { _llGrid (Get-ChildItem -File)      }
function lf { _llGrid (Get-ChildItem -Directory) }
function ll { _llGrid (Get-ChildItem)             }



function g { Set-Location 'D:\codebases' }
function c. { code . }

# Git shortcuts
if (Get-Command ga -ErrorAction SilentlyContinue) { Remove-Item Alias:ga -Force -ErrorAction SilentlyContinue }
if (Get-Command gs -ErrorAction SilentlyContinue) { Remove-Item Alias:gs -Force -ErrorAction SilentlyContinue }
if (Get-Command gaa -ErrorAction SilentlyContinue) { Remove-Item Alias:gaa -Force -ErrorAction SilentlyContinue }
if (Get-Command gcm -ErrorAction SilentlyContinue) { Remove-Item Alias:gcm -Force -ErrorAction SilentlyContinue }
if (Get-Command gps -ErrorAction SilentlyContinue) { Remove-Item Alias:gps -Force -ErrorAction SilentlyContinue }

function gs { git status @args }
function gaa { git add . }
function gcm { git commit -m ($args -join ' ') }
function gps { git push @args }

# Networking
function flushdns {
    Clear-DnsClientCache
    Write-Host "DNS has been flushed"
}

# Clipboard Utilities
function cpy { Set-Clipboard $args[0] }

function pst { Get-Clipboard }

# PSReadLine — single call block
$_isCore = $PSVersionTable.PSEdition -eq 'Core'
Set-PSReadLineOption -EditMode Windows `
    -HistoryNoDuplicates `
    -HistorySearchCursorMovesToEnd `
    -BellStyle None `
    -MaximumHistoryCount 10000 `
    -Colors @{
        Command   = '#87CEEB'; Parameter = '#98FB98'; Operator  = '#FFB6C1'
        Variable  = '#DDA0DD'; String    = '#FFDAB9'; Number    = '#B0E0E6'
        Type      = '#F0E68C'; Comment   = '#D3D3D3'; Keyword   = '#8367c7'
        Error     = '#FF6347'
    }
if ($_isCore) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin -PredictionViewStyle ListView
}
Remove-Variable _isCore

Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d'          -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w'          -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d'           -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow'  -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z'          -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y'          -Function Redo

Set-PSReadLineOption -AddToHistoryHandler {
    param($line)
    return ($line -notmatch 'password|secret|token|apikey|connectionstring')
}

# Oh My Posh - Velvet Custom Theme (Windows logo, purple outline, no heart/time/ms)
$ompTheme = "$PSScriptRoot\velvet_custom.omp.json"
if (Test-Path $ompTheme) {
    oh-my-posh init pwsh --config $ompTheme | Out-String | Invoke-Expression
}


clear-host



