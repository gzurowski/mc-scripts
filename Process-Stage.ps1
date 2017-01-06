#
# Process-Stage
#

# Script parameters
param(
    [string]$path='.'
)

# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

. (Join-Path $invocationPath AppConfig.ps1)
. (Join-Path $invocationPath Library-Audio.ps1)

# load TagLib assembly
[Reflection.Assembly]::LoadFile($invocationPath + "\lib\taglib-sharp.dll") > $null

#
# Traverses the provided path recursively.
#
# Get-ChildItem -recurse can only provide a flat list all all directories, mixing root and subdirectories.
# This hides the acutal relationship of directories with its subdirectories.
# For this script, we want to keep this relationship, e.g. for mutli-disc releases and its
# individual disc folders:
# "1956 Elvis [Special Edition]", and its subfolders "CD1" and "CD2".
#
# Note that this behaviour is only required to provide a better user experience.
# The actual order of directories does not influence the processing of this script.
#
function TraverseDirectories([IO.DirectoryInfo]$dirInfo) {

    if (-not $dirInfo)
    {
        $dirInfo = Get-Item -literalPath .
    }

    'Processing <' + $dirInfo.FullName + '>'

    # check for multidisc directory
    $multiDiscDirs = @(Get-ChildItem -literalPath $dirInfo.FullName | where {$_.name -match '^(CD|Disc) ?\d+$' -and $_.mode -like "d*"})

    if ($multiDiscDirs.length -gt 0)
    {
        'Multi-disc recording found in <' + $dirInfo.Name + '>'
        ProcessMultiDiscRoot $dirInfo
    }
    else
    {
        # process directory only if it contains audio files
        $audiofiles = @(Get-ChildItem -LiteralPath $dirInfo.FullName | where {$_.name -match "\.($AudioExt)$"})

        if ($audiofiles.length -gt 0)
        {
            ProcessAudioDirectory $dirInfo
        }
        else
        {
            'No audio files found in <' + $dirInfo.Name + '>'
        }
    }

    # Continue traversal of directories...
    $dirs = @(Get-ChildItem -literalPath $dirInfo.FullName | where { $_.Mode -like "d*"} | Sort)

    foreach ($dir in $dirs) {
        TraverseDirectories $dir
    }
}

#
# Processes the root directory of a multi-disc recording
#
function ProcessMultiDiscRoot([IO.DirectoryInfo]$dirInfo) {

    # copy folder.jpg to all disc folders
    if (Test-Path -literalPath ($dirInfo.FullName + '\folder.jpg')) {
        $multiDiscDirs = @(Get-ChildItem -literalPath $dirInfo.FullName | where {$_.name -match '^(CD|Disc) ?\d+$' -and $_.mode -like "d*"})
        foreach($dir in $multiDiscDirs) {
            # do not overwrite existing folder.jpg, as there might be different folder.jpg for each disc
            if (-not (Test-Path -literalPath ($dir.FullName + '\folder.jpg'))) {
                "Copying folder.jpg to " + $dir.FullName
                Copy-Item -literalPath ($dirInfo.FullName + '\folder.jpg') $dir.FullName
            }
        }
    }

    # get audio files of all discs
    $files = @(Get-ChildItem $dirInfo.FullName.Replace("[","``[").Replace("]","``]") -recurse | where {$_.name -match "\.($AudioExt)$"} | Sort-Object directory, name)

    if ($files.length -gt 0) {
        # create filename prefix for multi disc sets
        $fileNamePrefix = GetArtifactPrefix $files -multi

        Rename-AudioArtifacts -artwork -path $dirInfo.FullName -prefix $fileNamePrefix

        # create playlist of all audio files

        # before creating a complete playlist, all audio files must be renamed correctly
        Rename-AudioArtifacts -audio -path $dirInfo.FullName -recurse

        Create-Playlists -path $dirInfo.FullName -prefix $fileNamePrefix -recurse
        Create-Playlists -path $dirInfo.FullName -prefix $fileNamePrefix -encoding "utf8" -recurse
        Create-Md5Checksums -path $dirInfo.FullName -prefix $fileNamePrefix
        Create-ParFiles -path $dirInfo.FullName -prefix $fileNamePrefix
    }
}

#
# Processes audio files and all artifacts of the current directory.
#
function ProcessAudioDirectory([IO.DirectoryInfo]$dirInfo) {

        BackupCueSheets $dirInfo.FullName
        Rename-AudioArtifacts -audio -path $dirInfo.FullName
        Update-Cuesheets -path $dirInfo.FullName
        Create-Playlists -path $dirInfo.FullName
        Create-Playlists -path $dirInfo.FullName -encoding "utf8"
        Rename-AudioArtifacts -artifacts -path $dirInfo.FullName
        Create-Md5Checksums -path $dirInfo.FullName
        Create-ParFiles -path $dirInfo.FullName
}

#
# Creates backup copies of original CUE sheet files
#
function BackupCueSheets([IO.DirectoryInfo]$dirInfo) {

        $cueFilesBackup = @(Get-ChildItem -LiteralPath $dirInfo.FullName | where {$_.Name -like "*.cue.$CueSheetBackupExt"})
        $cueFiles = @(Get-ChildItem -LiteralPath $dirInfo.FullName | where {$_.Name -like '*.cue'})

        if (($cueFilesBackup.length -eq 0) -and ($cueFiles.length -gt 0))
        {
            $cueFiles | foreach {
                $cueFileBackup = $_.FullName + "." + $CueSheetBackupExt
                "Creating backup copy of original CUE sheet $cueFileBackup..."
                Copy-Item -Force -LiteralPath $_.FullName $cueFileBackup
            }
        }
        elseif (($cueFilesBackup.length -gt 0) -and ($cueFiles.length -gt 0))
        {
            "Backup copy of original CUE sheet already exists."
        }
}

#
# Main
#

# Put this on the path to invoke easily invoke further scripts
if (!($env:path -like "*$invocationPath*"))
{
    $env:path = $env:path + ";$invocationPath"
}

if (-not (Test-Path -literalPath $path -pathType Container))
{
    throw "Directory <$path> does not exist. Specify an existing directory."
}

$dirInfo = Get-Item -literalPath $path

TraverseDirectories $dirInfo
