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
    if (-Not (Test-Path -Path $Destination)) {
        Try {
            New-Item -Path $Destination -ItemType Directory -ErrorAction Stop
        }
        Catch {
            throw $_
        }
    }
    Try {
        Copy-Item -Path $Path -Destination $Destination -Recurse -ErrorAction Stop
    }
    Catch {
        Write-Warning "Could not copy $Path to $Destination"
        $_
    }
}