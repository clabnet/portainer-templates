param([switch]$WhatIf)

$root    = $PSScriptRoot
$enc     = New-Object System.Text.UTF8Encoding($false)
$files   = Get-ChildItem -Recurse -Filter "*.yml" $root |
           Where-Object { $_.Name -notlike "DOCKER~*" } |
           Sort-Object FullName
$changed = 0

foreach ($f in $files) {
    $shortPath = $f.FullName.Substring($root.Length)
    $original  = [System.IO.File]::ReadAllText($f.FullName, $enc)

    $lines = $original -split "\r?\n"

    # -split produces a trailing empty element when the file ends with \n; strip it
    if ($lines.Count -gt 0 -and $lines[-1] -eq '') {
        $lines = $lines[0..($lines.Count - 2)]
    }

    $ops = [System.Collections.Generic.List[string]]::new()

    # nginxpm only: halve leading indentation (4-space -> 2-space)
    if ($f.FullName -like "*nginxpm*") {
        $ops.Add("4space->2space")
        $lines = $lines | ForEach-Object {
            if ($_ -match '^( +)') {
                $n = $Matches[1].Length
                (' ' * [int]($n / 2)) + $_.Substring($n)
            } else { $_ }
        }
    }

    # trim trailing whitespace
    $newLines = $lines | ForEach-Object { $_.TrimEnd() }
    if (($lines | Where-Object { $_ -ne $_.TrimEnd() }).Count -gt 0) {
        $ops.Add("trailing-whitespace")
    }

    # detect CRLF in original
    if ($original -match "`r") { $ops.Add("CRLF->LF") }

    # detect missing trailing newline in original
    $bytes = [System.IO.File]::ReadAllBytes($f.FullName)
    if ($bytes[-1] -ne 10) { $ops.Add("added-trailing-newline") }

    $newContent = ($newLines -join "`n") + "`n"

    if ($newContent -ne $original) {
        $opsStr = if ($ops.Count) { $ops -join ", " } else { "normalized" }
        if ($WhatIf) {
            Write-Host "WOULD FIX: $shortPath  [$opsStr]"
        } else {
            [System.IO.File]::WriteAllText($f.FullName, $newContent, $enc)
            Write-Host "FIXED:     $shortPath  [$opsStr]"
            $changed++
        }
    } else {
        Write-Host "OK:        $shortPath"
    }
}

Write-Host ""
if ($WhatIf) { Write-Host "Dry run complete. $($files.Count) files scanned." }
else         { Write-Host "Done. $changed / $($files.Count) files modified." }
