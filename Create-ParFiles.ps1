#
# Create-ParFiles.ps1
#
# This script creates PAR2 parity files in all
# sub-directories of the current directory.
#

# Script parameters
param(
    [string]$path='.',
    [string]$prefix
)

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

. (Join-Path $invocationPath AppConfig.ps1)
. (Join-Path $invocationPath Library-Audio.ps1)

#
# main
#

if (-not (Test-Path -literalPath $path -pathType Container))
{
    throw "Directory <$path> does not exist. Specify an existing directory."
}

# Generate prefix if none was specified
if (-not $prefix)
{
    $files = @(Get-ChildItem -literalPath $path | where {$_.name -match "\.($AudioExt)$"})

    if ($files.Length -gt 0)
    {
        $prefix = GetArtifactPrefix $files
    }
}

# Prefix neither provided nor generated in previous step
if (-not $prefix)
{
    throw "Prefix could not be generated and no prefix provided."
}

$parFileName = $path + '\' + $prefix + 'Parity'

& $Par2Executable c /up /fo /rf8 "/rr$Par2Redundancy" "$parFileName" "$path\*"
