# get invocation path
$invocationPath = Split-Path $myInvocation.MyCommand.Path

# load TagLib assembly
[Reflection.Assembly]::LoadFile($invocationPath + "\lib\taglib-sharp.dll") > $null


# character that is used for replacing illegal characters in files names
Set-Variable -option constant ReplaceChar ''

# separator within filenames (e.g. to separate artist and album, etc.)
Set-Variable -option constant Separator '_-_'

# separator for albums on multi-disc releases
Set-Variable -option constant SeparatorMultiDisc ' + '

# separator for multiple artists
Set-Variable -option constant SeparatorMultiArtists ' + '

# recording type constants
Set-Variable -option constant RegularAlbum 0
Set-Variable -option constant VariousArtists 1
Set-Variable -option constant ClassicalRecording 2
Set-Variable -option constant MultipleOnOne 3
Set-Variable -option constant MultipleOnOneWithMultipleArtists 4
Set-Variable -option constant CompilationWithMainArtist 5

#
# Removes CD<n> suffix of the provided album string.
# This function is used to compare multi disc releases.
#
function RemoveMultiDiscAlbumSuffix([string]$album) {

    return $album -creplace '(CD|Disc) ?\d+$', ''
}

#
# Removes [<n>x Set] suffix of provided album string.
# This suffix is used for 2-on-1, 3-on-1, etc. CD releases.
#
function RemoveMultiSetAlbumSuffix([string]$album) {

    return $album -creplace " \[\d+x Set\]", ''
}

#
# checks whether the files in the given path represent a compilation album
#
function IsCompilation([IO.FileInfo[]]$files) {

    $media = [TagLib.File]::Create($files[0].FullName)
    $albumArtist = ReplaceIllegalChars($media.Tag.AlbumArtists[0])

    if (($albumArtist -eq "Various") -or ($albumArtist -eq "Various Artists")) {
        return $true
    }
    else {
        return $false
    }
}

#
# Checks whether the given files represent a compilation with a main artist
# (i.e. not a various artists compilation!)
#
function IsCompilationWithMainArtist([IO.FileInfo[]]$files) {

    $return = $false

    foreach ($file in $files) {
        $media = [TagLib.File]::Create($file.FullName)
        $albumArtist = $media.Tag.AlbumArtists[0]
        $artist = $media.Tag.Performers[0]

        if (($albumArtist -eq "Various") -or ($albumArtist -eq "Various Artists")) {
            # Various artists compilations do not fit the main artist pattern
            return $false
        }

        # Update "previous" variables
        if (-not $previousAlbumArtist) {
            $previousAlbumArtist = $albumArtist
        }
        if (-not $previousArtist) {
            $previousArtist = $artist
        }

        if ($previousAlbumArtist -ne $albumArtist) {
            # If the album artist changes, there's no main artists
            return $false
        }

        if ($albumArtist -and ($previousArtist -ne $artist)) {
            $return = $true
        }
    }

    return $return
}

#
# Checks whether the files in the provided path represent a classical music recordings album.
#
function IsClassicalRecording([IO.FileInfo[]]$files) {

    $media = [TagLib.File]::Create($files[0].FullName)
    $genre = $media.Tag.Genres[0]

    if ($genre -eq "Classical") {
        return $true
    }
    else {
        return $false
    }
}

#
# Checks whether the given path represents a "multiple on one" disc
#
function IsMultipleOnOne([IO.FileInfo[]]$files, [switch]$multi) {

    for ($i = 0; $i -lt $files.Length; $i++) {
        $media = [TagLib.File]::Create($files[$i].FullName)
        $album = ReplaceIllegalChars($media.Tag.Album)

        if ($multi) {
            # remove CD<n> multi-disc album suffix
            $album = RemoveMultiDiscAlbumSuffix $album
        }

        if (-not $previousAlbum) {
            $previousAlbum = $album
        }
        elseif ($previousAlbum -ne $album) {
            return $true
        }
    }

    return $false
}

#
# Checks whether the given path represents a "multiple on one" disc
# but with multiple artists (not a regular VA compilation!)
#
function IsMultipleOnOneMultipleArtists([IO.FileInfo[]]$files, [switch]$multi) {

    for ($i = 0; $i -lt $files.Length; $i++) {
        $media = [TagLib.File]::Create($files[$i].FullName)
        $artist = ReplaceIllegalChars($media.Tag.Performers[0])
        $album  = ReplaceIllegalChars($media.Tag.Album)

        if ($multi) {
            # remove CD<n> multi-disc album suffix
            $album = RemoveMultiDiscAlbumSuffix $album
        }

        if ((-not $previousArtist) -or (-not $previousAlbum))   {
            $previousArtist = $artist
            $previousAlbum = $album
        }
        else {
            if (($previousAlbum -ne $album) -and ($previousArtist -ne $artist)) {
                return $true
            }

            if ($previousArtist -ne $artist) {
                $previousArtist = $artist
            }
            if ($previousAlbum -ne $album) {
                $previousAlbum = $album
            }
        }
    }

    return $false
}

#
# Returns a string containing all albums for a "multiple-on-one" disc
#
function GetAlbumsOfMultipleOnOneAlbums([IO.FileInfo[]]$files, [switch]$multi) {

    for ($i = 0; $i -lt $files.Length; $i++) {
        $media = [TagLib.File]::Create($files[$i].FullName)
        $album = ReplaceIllegalChars($media.Tag.Album)

        if ($multi) {
            # remove CD<n> multi-disc recording suffix
            $album = RemoveMultiDiscAlbumSuffix $album
        }

        if ($previous -ne $album) {
            $previous = $album
            $albums = $albums + $album + $SeparatorMultiDisc
        }
    }

    return $albums.Substring(0, $albums.Length - 3)
}

#
# Returns a string containing all artists for a "multiple-on-one" disc
#
function GetArtistsOfMultipleOnOneAlbums([IO.FileInfo[]]$files) {

    for ($i = 0; $i -lt $files.Length; $i++) {
        $media = [TagLib.File]::Create($files[$i].FullName)
        $artist = GetArtistString $media.Tag.Performers

        if ($previous -ne $artist) {
            $previous = $artist
            $artists = $artists + $artist + $SeparatorMultiDisc
        }
    }

    return $artists.Substring(0, $artists.Length - 3)
}

#
# returns an appropriate prefix for the current record type
#
function GetArtifactPrefix([IO.FileInfo[]]$files, [switch]$multi) {

    $files = $files | Sort-Object

    $type = GetRecordingType $files -multi:$multi

    $prefix = GetArtifactPrefixByType $files $type

    if ($multi)
    {
        # remove "CD<n>" string for multi-disc sets
        $prefix = $prefix -replace " (CD|Disc) ?\d+.*_-_", "_-_"
    }

    # remove "[<n>x Set]" from prefix
    $prefix = RemoveMultiSetAlbumSuffix $prefix

    return $prefix
}

#
# returns an appropriate prefix for the current record type
#
function GetArtifactPrefixByType([IO.FileInfo[]]$files, [int]$type, [switch]$multi) {

    if ($type -eq $ClassicalRecording) {
        $prefix = '00' + $Separator
    }
    elseif ($type -eq $VariousArtists -or $type -eq $CompilationWithMainArtist) {
        $media = [TagLib.File]::Create($files[0].FullName)
        $album = ReplaceIllegalChars $media.Tag.Album

        $prefix = $album + $Separator + '00' + $Separator
    }
    elseif ($type -eq $MultipleOnOne) {
        $albums = GetAlbumsOfMultipleOnOneAlbums $files $multi
        $media = [TagLib.File]::Create($files[0].FullName)
        $artist = GetArtistString $media.Tag.Performers

        $prefix = $artist + $Separator + '00' + $Separator + $albums + $Separator
    }
    elseif ($type -eq $MultipleOnOneWithMultipleArtists) {
        $albums = GetAlbumsOfMultipleOnOneAlbums $files $multi
        $artists = GetArtistsOfMultipleOnOneAlbums $files

        $prefix = '00' + $Separator + $artists + $Separator + $albums + $Separator
    }
    else {  # regular album
        $media = [TagLib.File]::Create($files[0].FullName)
        $artist = GetArtistString $media.Tag.Performers
        $album  = ReplaceIllegalChars($media.Tag.Album)
        $prefix = $artist + $Separator + $album + $Separator + '00' + $Separator
    }

    return $prefix
}

#
# Get the recording type for the provided set of files
#
function GetRecordingType([IO.FileInfo[]]$files, [switch]$multi) {

    if (IsClassicalRecording $files) {
        return $ClassicalRecording
    }
    elseif (IsCompilation $files) {
        return $VariousArtists
    }
    elseif (IsCompilationWithMainArtist $files) {
        return $CompilationWithMainArtist
    }
    elseif (IsMultipleOnOneMultipleArtists $files -multi:$multi) {
        return $MultipleOnOneWithMultipleArtists
    }
    elseif (IsMultipleOnOne $files -multi:$multi) {
        return $MultipleOnOne
    }
    else {
        return $RegularAlbum
    }
}

#
# Returns a string representation of all values of the ARTIST tag.
# In case multiple arists are presents, values are concatened.
#
function GetArtistString([string[]] $performers) {
    # concatenate all artists
    foreach ($performer in $performers)
    {
        $myArtist = $myArtist + (ReplaceIllegalChars $performer) + $SeparatorMultiArtists
    }
    return $myArtist.Trim($SeparatorMultiArtists)  # remove last separator and return
}

#
# Returns a formatted name for the provided file according to its recording type
#
function GetFormattedFileName([IO.FileInfo]$file, [int]$type) {

    $media = [TagLib.File]::Create($file.FullName)
    $artist = GetArtistString $media.Tag.Performers
    $album = ReplaceIllegalChars($media.Tag.Album)
    $track = ReplaceIllegalChars($media.Tag.Track)
    $track = $track.PadLeft(2, '0')
    $title = ReplaceIllegalChars($media.Tag.Title)

    if ($type -eq $MultipleOnOne) {
        return $artist + $Separator + $track + $Separator + $album + $Separator + $title + $file.Extension
    }
    elseif ($type -eq $VariousArtists -or $type -eq $CompilationWithMainArtist) {
        return $album + $Separator + $track + $Separator + $artist + $Separator + $title + $file.Extension
    }
    elseif ($type -eq $MultipleOnOneWithMultipleArtists) {
        return $track + $Separator + $artist + $Separator + $album + $Separator + $title + $file.Extension
    }
    elseif ($type -eq $ClassicalRecording) {
        return $track + $Separator + $title + $file.Extension
    }
    else {
        return $artist + $Separator + $album + $Separator + $track + $Separator + $title + $file.Extension
    }
}

#
# Replaces illegal charactars that cannot be used in file names.
#
function ReplaceIllegalChars([string] $string) {
    $string = $string.Replace('|', $ReplaceChar).Replace('\', $ReplaceChar).Replace(':', $ReplaceChar)
    $string = $string.Replace('*', $ReplaceChar).Replace('?', $ReplaceChar).Replace('"', $ReplaceChar)
    $string = $string.Replace('<', $ReplaceChar).Replace('>', $ReplaceChar).Replace('/', $ReplaceChar)
    return $string
}

#
# Renames the provided file.
#
function RenameFile([string]$fileName, [string]$newFileName) {

    $file = Get-Item -literalPath $fileName
    $newFileInfo = [IO.FileInfo] $newFileName

    if ($newFileName -cne $fileName) {
        'Renaming: <' + $file.Name + '> ==> <' + $newFileInfo.Name + '>'

        # Windows file name handling is case-insensitive.
        # Workaround for file of same name but different case.
        if ($newFileName -eq $fileName) {
            $tempFile = [IO.FileInfo] ([System.IO.Path]::GetRandomFileName())
            Move-Item -force -LiteralPath $file.FullName $tempFile.FullName
            $file = Get-Item -literalPath $tempFile.FullName
        }

        if (-not (Test-Path -literalPath $newFileInfo.Fullname)) {  # Do not overwrite existing file!
            # Workaround: Due to the fact that the cmdlet Rename-Item does not provide an
            # "literalPath" parameter in PowerShell 1.0, we use Move-Item instead
            Move-Item -force -LiteralPath $file.FullName $newFileInfo.FullName
        }
        else {
            WriteError ("ERROR: Rename failed. Target file '" + $newFileInfo.Name + "' already exists.")
        }
    }
}

#
# Writes the provided message as an error to the console.
#
function WriteError([string]$message, [switch]$alert, [switch]$noNewLine) {
    if ($alert) {
        $signal = "`a"
    }

    if (-not $noNewLine) {
        $newLine = "`n"
    }

    $host.ui.write("white", "red", $message + $newLine + $signal)
}
