#
# Clean-Stage.ps1
#

# Script parameters
param(
    [string]$path='.'
)

Set-Variable counter 0 -scope script

function RemoveFile($path) {
    "Removing " + $path
    Set-Variable counter (++$counter) -scope script
    Remove-Item -literalPath $path
}

$extensions = "m3u|m3u8|md5|par2"

Get-ChildItem -recurse -literalPath $path | Where { $_.Name -match "\.($extensions)$" } | ForEach {
    RemoveFile $_.FullName
}

"`n$counter files removed."
