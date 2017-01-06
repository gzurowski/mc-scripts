#
# Rename-AudioArtifacts.ps1
#
# This script was created to migrate all audio artefacts
# (images, cue-sheets, logs) to the new standard naming scheme.
#

# Script parameters
param(
    [string]$path=".",
    [switch]$audio,
    [switch]$artwork,
    [switch]$artifacts,
    [switch]$md5,
    [switch]$recurse,
    [string]$prefix
)

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

# load library functions
. (Join-Path $invocationPath Library-Audio.ps1)

# load TagLib assembly
[Reflection.Assembly]::LoadFile($invocationPath + "\lib\taglib-sharp.dll") > $null

#
# Internal shortcut function to properly format artwork file names
#
function GetArtworkFileName([string]$type, [string]$prefix, [string]$extension, [string]$cd, [string]$no)
{

    $cd = $( if ($cd) { "CD" + $cd + "-" } else { "" } )
    $no = $( if ($no) { "{0:0#}" -f [int]$no } else { "" } )

    return $prefix + "Artwork-" + $cd + $type + $no + "." + $extension
}

#
# Renames artwork files
#
function RenameArtwork ([string]$prefix) {

    $files = @(Get-ChildItem -literalPath $path | where {$_.name -match "\.($BitmapExt)$"})

    foreach ($file in $files)
    {
        $newName = $null

        if ($file.Name -match "^(cd(?<cd>\d+)-?)?book(?<no>\d+)\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Booklet(?<no>\d+)\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Booklet" $prefix $matches.ext $matches.cd $matches.no
        }
        elseif ($file.Name -match "^(cd(?<cd>\d+)-?)?front\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Front\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Front" $prefix $matches.ext $matches.cd
        }
        elseif ($file.Name -match "^(cd(?<cd>\d+)-?)?inside(?<no>\d+)?\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Inside(?<no>\d+)?\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Inside" $prefix $matches.ext $matches.cd $matches.no
        }
        elseif ($file.Name -match "^(cd(?<cd>\d+)-?)?back\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Back\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Back" $prefix $matches.ext $matches.cd
        }
        elseif ($file.Name -match "^(cd(?<cd>\d+)-?)?digipac?k\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Digipak-Outside\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Digipak-Outside" $prefix $matches.ext $matches.cd
        }
        elseif ($file.Name -match "^(cd(?<cd>\d+)-?)?digipac?k\-inside(?<no>\d+)?\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Digipak-Inside(?<no>\d+)?\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Digipak-Inside" $prefix $matches.ext $matches.cd $matches.no
        }
        elseif ($file.Name -match "^slip-?f(ront)?\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-Slipcase-Front.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Slipcase-Front" $prefix $matches.ext
        }
        elseif ($file.Name -match "^slip-?b(ack)?\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-Slipcase-Back.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Slipcase-Back" $prefix $matches.ext
        }
        elseif ($file.Name -match "^slip-?spine\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-Slipcase-Spine.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Slipcase-Spine" $prefix $matches.ext
        }
        elseif ($file.Name -match "^cd(?<cd>\d*)-?(cd)?(?<side>_?[ab])?\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-CD(?<cd>\d*)(-CD)?(?<side>_?[ab])?\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName ("CD" + $matches.side) $prefix $matches.ext $matches.cd
        }
        elseif ($file.Name -match "^dvd(?<dvd>\d*)-?(dvd)?(?<side>_?[ab])?\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-DVD(?<dvd>\d*)(-DVD)?(?<side>_?[ab])?\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName ("DVD" + $matches.side) $prefix $matches.ext $matches.dvd
        }
        elseif ($file.Name -match "^(cd(?<cd>\d+)-?)?mini.jpg$" -or $file.Name -match "_-_Artwork-(CD(?<cd>\d+)-)?Front_small\.jpg$") {
            $newName = GetArtworkFileName "Front_small" $prefix "jpg" $matches.cd
        }
        elseif ($file.Name -match "^obi\.(?<ext>$BitmapExt)$" -or $file.Name -match "_-_Artwork-Obi\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName "Obi" $prefix $matches.ext
        }
        elseif ($file.Name -match "^sleeve-(?<side>front|back)\.(?<ext>$BitmapExt)$") {
            $newName = GetArtworkFileName ("Sleeve-" + $matches.side.Substring(0, 1).ToUpper() + $matches.side.Substring(1).ToLower()) $prefix $matches.ext
        }
        elseif ($file.Name -eq "folder.jpg") {
            # do nothing
        }
        else {
            'no rule for <' + $file.Name + '>'
        }

        if ($newName) {
            $newName = $file.Directory.FullName + '\' + $newName
            RenameFile $file.FullName $newName
        }
    }
}

#
# Renames log files
#
function RenameLogs ([string]$prefix) {

    $files = @(Get-ChildItem -literalPath $path | where {$_.name -like '*.log'})

    foreach ($file in $files)
    {
        if ($file.Name -like '*.log')
        {
            # i.e.: John Williams_-_Star Wars The Empire Strikes Back [Special Edition 1997] CD1_-_00_-_Log.log
            # or:   John Williams_-_Star Wars The Empire Strikes Back [Special Edition 1997] CD1_-_00_-_Log01.log
            # or:   John Williams - Star Wars  A New Hope [Special Edition 1997] CD1.log
            # or:   John Williams - Star Wars  A New Hope [Special Edition 1997] CD1#01.log
            # or:   John Williams - Star Wars  A New Hope.log
            # or:   John Williams - Star Wars  A New Hope01.log
            # or:   999 - 999#.log
            # or:   999 - 999#01.log
            if ($file.Name -match 'Log(?<no>\d+)?\.log$' -or $file.Name -match 'CD\d+(#(?<no>\d+))?\.log$' -or $file.Name -match '#?(?<no>\d+)?\.log$')
            {
                $newName = $file.Directory.FullName + '\' + $prefix + 'Log' + $matches.no + '.log'
                RenameFile $file.FullName $newName
            }
        }
    }
}

#
# Renames cuesheet files
#
function RenameCues ([string]$prefix) {

    $files = @(Get-ChildItem -literalPath $path | where {$_.name -like '*.cue' -or $_.name -like "*.cue.$CueSheetBackupExt"})

    foreach ($file in $files)
    {
        if ($file.Name -match " (CD|Disc) ?\d+#(?<no>\d+)\.cue(?<bak>\.$CueSheetBackupExt)?$" -or $file.Name -match "(Cue(?<no>\d*))?\.cue(?<bak>\.$CueSheetBackupExt)?$")
        {
            $newName = $file.Directory.FullName + '\' + $prefix + 'Cue' + $matches.no + '.cue' + $matches.bak
            RenameFile $file.FullName $newName
        }
    }
}

#
# Renames md5 checksum files
#
function RenameMd5s ([string]$prefix) {

    $files = @(Get-ChildItem -literalPath $path | where {$_.name -like '*.md5'})

    foreach ($file in $files)
    {
        $newName = $file.Directory.FullName + '\' + $prefix + 'Checksum.md5'
        RenameFile $file.FullName $newName
    }
}

#
# Renames all audio files
#
function RenameAudioFiles ([switch]$recurse) {

    if ($recurse) {
        Get-ChildItem -literalPath $path -recurse | where {$_.Mode -like "d*"} | Foreach-Object {
            RenameAudioFilesInDirectory $_.FullName
        }
    }
    else {
        RenameAudioFilesInDirectory $path
    }
}

#
# Renames all audio files
#
function RenameAudioFilesInDirectory ([string]$path) {

    $files = @(Get-ChildItem -literalPath $path | where {$_.name -match '\.(flac|mp3)$'})
    $type = GetRecordingType $files

    Write-Host "Recording Type: $type"

    foreach($file in $files) {
        $newFileName = $file.Directory.FullName + '\' + (GetFormattedFileName $file $type)
        RenameFile $file.FullName $newFileName
    }
}

#
# Composite function to rename all audio artifacts
#
function RenameAudioArtifacts ([string]$prefix) {

    RenameArtwork $prefix
    RenameLogs $prefix
    RenameCues $prefix
    RenameMd5s $prefix
}


#
# Main
#

$dirInfo = Get-Item -literalPath $path

# Rename audio files
if ($audio) {
    if ($recurse) {
        RenameAudioFiles -recurse
    }
    else {
        RenameAudioFiles
    }

    return
}

# Generate prefix if none was specified
if (-not $prefix) {
        $files = @(Get-ChildItem -literalPath $path | where {$_.name -match "\.(flac|mp3)$"})
        $prefix = GetArtifactPrefix $files
}

# Rename all audio artifacts
if ($artifacts) {
    RenameAudioArtifacts $prefix
}

# Rename artwork
if ($artwork) {
    RenameArtwork $prefix
}

# Rename md5 files
if ($md5) {
    RenameMd5s $prefix
}
