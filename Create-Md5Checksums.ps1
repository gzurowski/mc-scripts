#
# Create-Md5Checksums.ps1
#
# This script create MD5 checksum files in all
# sub-directories of the current working directory
#

# Script parameters
param(
    [string]$path=".",
    [string]$prefix
)

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

. (Join-Path $invocationPath AppConfig.ps1)
. (Join-Path $invocationPath Library-Audio.ps1)


#
# Calculates the hash of a file and returns it as a string.
# (see http://blogs.msdn.com/powershell/archive/2006/04/25/583225.aspx)
#
function Get-MD5([System.IO.FileInfo] $file = $(throw 'Usage: Get-MD5 [System.IO.FileInfo]'))
{
    $stream = $null;
    $cryptoServiceProvider = [System.Security.Cryptography.MD5CryptoServiceProvider];

    $hashAlgorithm = new-object $cryptoServiceProvider
    $stream = [System.IO.File]::Open($file.fullname, "Open", "Read", "ReadWrite")
    $hashByteArray = $hashAlgorithm.ComputeHash($stream);
    $stream.Close();

    # We have to be sure that we close the file stream if any exceptions are thrown.
    trap
    {
        if ($stream -ne $null)
        {
            $stream.Close();
        }
        break;
    }

    # convert bytestream into string with hexadecimal representation
    $ret = [string]::Join("", ($hashByteArray | foreach {$_.ToString("x2")}))

    return [string]$ret;
}

#
# Main
#

$files = Get-ChildItem -literalPath $path | Where { $_.Mode -notlike "d*" } | Sort

if ($files.Length -gt 0) {
    $content = ";`n; Created with MC Scripts on " + (Get-Date -format d) + "`n; https://github.com/gzurowski/mc-scripts`n;`n"
    foreach ($file in $files) {
        $md5 = Get-MD5 $file
        $content += $md5 + '  ' + $file.Name + "`n"
        $md5 + '  ' + $file.Name # console output
    }
}

if ($files.Length -gt 0) {
    # generate prefix if not provided
    if (-not $prefix) {
        $audiofiles = @(Get-ChildItem -literalPath $path | where {$_.name -match "\.($AudioExt)$"})
        if ($audiofiles.length -gt 0) {
            $prefix = GetArtifactPrefix $audiofiles
        }
    }
    $md5FileName = $prefix + 'Checksum.md5'
    "Writing checksum file <$md5FileName>..."
    [System.IO.File]::WriteAllText((Join-Path (Get-Item -literalPath $path) $md5FileName), $content, [Text.Encoding]::UTF8)
}
