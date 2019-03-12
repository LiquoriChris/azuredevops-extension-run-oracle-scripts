[CmdletBinding()]
param ()

$ScriptPath = Get-VstsInput -Name 'scriptPath' -Require
$User = Get-VstsInput -Name 'user' -Require
$Password = Get-VstsInput -Name 'password' -Require
$DatabaseName = Get-VstsInput -Name 'databaseName' -Require
$LogPath = Get-VstsInput -Name 'logPath'
$TopLine = Get-VstsInput -Name 'topLine'
$Define = Get-VstsInput -Name 'define'
$Echo = Get-VstsInput -Name 'echo'
$Timing = Get-VstsInput -Name 'timing'
$SqlError = Get-VstsInput -Name 'sqlError'
$Copy = Get-VstsInput -Name 'copy' -Default true
$Move = Get-VstsInput -Name 'move' -Default true

function Write-File {
    param (
        [System.IO.FileInfo]$FilePath,
        [ValidateSet('UTF8','Default')]
        [string]$Encoding = 'Default',
        [Parameter(ValueFromPipeline)]
        [string]$Value,
        [switch]$Top
    )
    Process {
        Try {
            if ($Top) {
                $($Value; Get-Content $FilePath -ErrorAction Stop) |Out-File -FilePath $FilePath -Encoding $Encoding
            }
            else {
                $(Get-Content -Path $FilePath; $Value) |Out-File -FilePath $FilePath -Encoding $Encoding
            }
        }
        Catch {
            throw $_
        }
    }
}

function _Copy {
    param (
        $Path,
        $Destination
    )
    Try {
        Copy-Item -Path $Path -Destination $Destination -ErrorAction Stop
    }
    Catch {
        Write-Warning "Could not copy $Path to $Destination"
        $_
    }
}

$SqlPath = Find-VstsFiles -LiteralDirectory $ScriptPath -LegacyPattern **.sql
if ($SqlPath) {
    Try {
        New-Item -Path env:NLS_LANG -Value .AL32UTF8 -ErrorAction Stop
    }
    Catch {
        if ($_ -like '*access denied*') {
            throw $_
        }
        else {
            return 'NLS_LANG environment variable already set.'
        }
    }
    foreach ($SqlFile in $SqlPath) {	
        if ($SqlError) {
            Write-Output "whenever sqlerror exit sql.sqlcode rollback;" |Write-File -FilePath $SqlFile -Top
        }
        if ($Timing) {
            Write-Output "set timing on;" |Write-File -FilePath $SqlFile -Top
        }	
        if ($Echo) {
            Write-Output "set echo on;" |Write-File -FilePath $SqlFile -Top
        }
        if ($Define) {
            Write-Output "set define off;" |Write-File -FilePath $SqlFile -Top 
        }
        if ($TopLine) {
            Write-Output "-- top line" |Write-File -FilePath $SqlFile -Top
        }
        Write-Output "spool $($SqlFile).log" |Write-File -FilePath $SqlFile -Top
        Write-Output "spool off" |Write-File -FilePath $SqlFile
        Write-Output "exit" |Write-File -FilePath $SqlFile	
        sqlplus "$User/$Password@$DatabaseName" "@$($SqlFile)"
        if ($LogPath) {
            _Copy -Path "$($SqlFile).log" -Destination $LogPath
            if ($Copy) {
                _Copy -Path $SqlFile -Destination $LogPath
            }
        }
        else {
            Write-VstsTaskWarning -Message "No log path specified." 
            Write-VstsTaskWarning -Message "Log files are located: $ScriptPath"
        }
    }
}
else {
    return "No sql files exist at $ScriptPath"
}