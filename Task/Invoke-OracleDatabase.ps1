[CmdletBinding()]
param ()

$ScriptPath = Get-VstsInput -Name 'scriptPath' -Require
$User = Get-VstsInput -Name 'user' -Require
$Password = Get-VstsInput -Name 'password' -Require
$DatabaseName = Get-VstsInput -Name 'databaseName' -Require
$LogPath = Get-VstsInput -Name 'logPath' -Require
$TopLine = Get-VstsInput -Name 'topLine' -Default true
$Define = Get-VstsInput -Name 'define' -Default true
$Echo = Get-VstsInput -Name 'echo' -Default true
$Timing = Get-VstsInput -Name 'timing' -Default true
$SqlError = Get-VstsInput -Name 'sqlError' -Default true
$Copy = Get-VstsInput -Name 'copy' -Default true
$Move = Get-VstsInput -Name 'move' -Default true

function Write-File {
    param (
        [System.IO.FileInfo]$FilePath,
        [ValidateSet('UTF8','Default')]
        [string]$Encoding = 'Default',
        [Parameter(ValueFromPipeline)]
        [string]$Value
    )
    Try {
        Add-Content -Path $FilePath -Value $Value -Encoding $Encoding -ErrorAction Stop
    }
    Catch {
        throw $_
    }
}

function _Move {
    param (
        $Path,
        $Destination
    )
    Try {
        Move-Item -Path $Source -Destination $Destination -ErrorAction Stop
    }
    Catch {
        Write-Warning "Could not move $Source to $Destination"
        $_
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

Try {
    $SqlPath = (Find-VstsFiles -LegacyPath "$ScriptPath\**.sql" -ErrorAction Stop).FullName
    Try {
        New-Item -Path env:NLS_LANG -Value .AL32UTF8 -ErrorAction Stop
    }
    Catch {
        if ($_ -like '*access denied*') {
            throw $_
        }
        else {
            Write-Verbose 'NLS_LANG environment variable already set.'
        }
    }
    foreach ($SqlFile in $SqlPath) {
        Write-Output "spool $($SqlFile).log" |Write-File -FilePath "$($SqlFile).run"
        if ($TopLine) {
            Write-Output "-- top line" |Write-File -FilePath "$($SqlFile).run"
        }
        if ($Define) {
            Write-Output "set define off;" |Write-File -FilePath "$($SqlFile).run"
        }
        if ($Echo) {
            Write-Output "set echo on;" |Write-File -FilePath "$($SqlFile).run"
        }
        if ($Timing) {
            Write-Output "set timing on;" |Write-File -FilePath "$($SqlFile).run"
        }			
        if ($SqlError) {
            Write-Output "whenever sqlerror exit sql.sqlcode rollback;" |Write-File -FilePath "$($SqlFile).run"
        }
        Get-Content "$($SqlFile)" |Write-File -FilePath "$($SqlFile).run" -Encoding UTF8
        Write-Output "spool off" |Write-File -FilePath "$($SqlFile).run"
        Write-Output "exit" |Write-File -FilePath "$($SqlFile).run"
        sqlplus "$User/$Password@$DatabaseName" "@$($SqlFile).run"
        if ($Copy) {
            _Copy -Path $SqlFile -Destination $LogPath
        }
        if ($Move) {
            _Move -Path "$($SqlFile).log" -Destination $LogPath
        }
    }
}
Catch {
    throw "No sql files exist at $ScriptPath"
}