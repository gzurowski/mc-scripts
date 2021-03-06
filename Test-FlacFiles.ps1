#
# Test-FlacFiles.ps1
#

# Script parameters
param(
    [string]$path='.'
)

Set-Variable files 0 -scope script
Set-Variable errors 0 -scope script

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

# load library functions
. (Join-Path $invocationPath Library-Audio.ps1)
. (Join-Path $invocationPath AppConfig.ps1)

function TestFiles([string]$dir) {
    Get-ChildItem -literalPath $dir | where {$_.name -like '*.flac'} | ForEach {
        Write-Host -noNewLine "$_... "
        $output = & $FlacExecutable -st $_.FullName 2>&1
        $files++
        if ($LASTEXITCODE -ne 0) {
            $errors++
            # output is of type "System.Management.Automation.ErrorRecord" and cannot be simply parsed as a string...
            if ($output[0].ToString() -match "error code \d+:(?<error>\w+)") {
                $error = $matches.error
            }
            WriteError -noNewLine "FAILED ($error)"
        }
        else {
            Write-Host -noNewLine "OK"
        }
        Write-Host "`r"
    }
}

#
# main
#

if (-not (Test-Path -literalPath $path -pathType Container))
{
    throw "Directory <$path> does not exist. Specify an existing directory."
}

# Process current directory...
Get-Item -literalPath $path | where {$_.mode -like "d*"} | ForEach {
    "Processing <" + $_.FUllName + ">"
    TestFiles $_.FullName
}

# ...and all subdirectories
Get-ChildItem -literalPath $path -recurse | where {$_.mode -like "d*"} | ForEach {
    "Processing <" + $_.FUllName + ">"
    TestFiles $_.FullName
}

"`n$files file(s) tested."
"$errors error(s)."
