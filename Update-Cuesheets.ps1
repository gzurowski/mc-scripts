#
# Update-Cuesheets.ps1
#
# This script updates all cuesheet files in
# the given directory.
#

# Script parameters
param(
    [string]$path='.'
)

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

# load library functions
. (Join-Path $invocationPath AppConfig.ps1)

#
# UpdateCue
#
function UpdateCue([string]$cue) {
    $cueTable = @(Get-Content -literalPath $cue | Where-Object {$_ -match '^FILE\s+".+'})
    for ($i = 0; $i -lt $cueTable.Length; $i++) {
        if ($cueTable[$i] -match '^FILE "(.+)" WAVE') {
            $cueTable[$i] = $matches[1]
        }
    }

    $originalContent = Get-Content -LiteralPath $cue
    $originalContent = [string]::Join("`r`n", $originalContent)
    $content = $originalContent
    $audiofiles = @(Get-ChildItem -literalPath $path | Sort | Where-Object { $_.Name -like "*.flac" })

    # exit function if number of files does not match number of FILE entries
    if ($audiofiles.length -ne $cueTable.length) {
        WriteError ("ERROR: Number of files (" + $audiofiles.length + ") does not match number of entries (" + $cueTable.length + ") in cue sheet file '" + $cue + "'!")
        return
    }

    $audioFiles | foreach {
        if ($_.Name -match '^(?<track>\d\d)_-_' -or $_.Name -match '(_-_)?.+_-_(?<track>\d\d)_-_') {
            $index = $matches.track - 1
            $oldName = $cueTable[$index]
            $oldName = [regex]::Escape($oldName)
            $fileNameWave = $_.Name -replace "\.($AudioExt)$", '.wav'

            # replace file name in cue
            $tmpContent = $content
            $content = $content -replace $oldName, $fileNameWave

            if ($content -ne $tmpContent) {
                $output += '* track <' + ($index+1) + '> ==> <' + $fileNameWave + ">`n"
            }
        }
  }

  # Write new cue sheet only when content has changed
  if (@(Compare-Object $content $originalContent -syncWindow 0).Length -ne 0) {
    $content | Set-Content -literalPath $cue
    $output = $output -replace "`n$", ''
    ($output + "`nCue sheet file <$cue> updated.")
  }
}

Get-ChildItem -literalPath $path | Where { $_.Name -like '*.cue' } | Foreach-Object {
    'Checking cue sheet file <' + $_.Name + '>...'
    UpdateCue $_.FullName
}
