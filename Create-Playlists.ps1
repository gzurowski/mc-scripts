#
# Create-Playlists.ps1
#
# This script creates M3U playlist files in all
# sub-directories of the current directory.
#

# Script parameters
param(
    [string]$path='.',
    [string]$encoding,
    [switch]$recurse,
    [string]$prefix
)

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

# load TagLib assembly
[Reflection.Assembly]::LoadFile($invocationPath + "\lib\taglib-sharp.dll") > $null

. (Join-Path $invocationPath AppConfig.ps1)
. (Join-Path $invocationPath Library-Audio.ps1)

#
# main
#

if ($encoding -eq 'utf8') {
    $encoding = 'UTF8'
    $ending = '.m3u8'
}
else {
    # default parameter
    $encoding = 'String'
    $ending = '.m3u'
}

if ($recurse) {
    $files = Get-ChildItem $path.Replace("[","``[").Replace("]","``]") -recurse | where {$_.name -match "\.($AudioExt)$"} | Sort directory, name
}
else {
    $files = Get-ChildItem -literalPath $path | where {$_.name -match "\.($AudioExt)$"} | Sort
}

if ($files.Length -gt 0) {
    # playlist file header
    $content = "#EXTM3U`r`n"

    foreach ($file in $files) {
        # get metadata
        $fileName = $file.Name
        $media = [TagLib.File]::Create($file.FullName)
        $totalSeconds = [Math]::Round($media.Properties.Duration.TotalSeconds)
        $artistTrack = $media.Tag.Performers[0] + ' - ' + $media.Tag.Title

        $dir = $(if ($recurse) { $file.Directory.Name + "/" } else { "" })

        # write track entry
        $content += "#EXTINF:" + $totalSeconds + ',' + $artistTrack + "`r`n"
        $content += $dir + $fileName + "`r`n"
    }

    if ($files.Length -gt 0) {
            # generate prefix if not provided
            if (-not $prefix) {
                $prefix = GetArtifactPrefix $files
            }
            $m3uFileName = $prefix + 'Playlist'

        "Writing playlist file <$m3uFileName$ending>..."
        $filename = $m3uFileName + $ending
        $content | Set-Content -Encoding $encoding -LiteralPath "$path\$filename"
    }
}
