# MC Scripts

## Introduction

Music Collection Scripts (MC Scripts) helps organizing digital audio collections with a set of PowerShell scripts that provide the following functionality:

* Renaming audio files by using metadata from embedded tags.
* Renaming of all artifacts (such as cover scans, CUE sheets, playlists, extraction logs) that are associated with the audio files.
* Creation of playlist files.
* Creation of checksum files.
* Creation of parity files.

## Use Case

The main use case is to run MC Scripts before adding new audio files to your digital audio archive.

After ripping a CDs and scanning covers, the resulting files usually look similar to the following listing:

```
back.jpg
Blue Train [RVG Editon].cue
book01.jpg
book02.jpg
book03.jpg
book04.jpg
cd.jpg
folder.jpg
front.jpg
John Coltrane_-_Blue Train [RVG Editon].log
John Coltrane_-_Blue Train [RVG Editon]_-_01_-_Blue Train.flac
John Coltrane_-_Blue Train [RVG Editon]_-_02_-_Moment's Notice.flac
John Coltrane_-_Blue Train [RVG Editon]_-_03_-_Locomotion.flac
John Coltrane_-_Blue Train [RVG Editon]_-_04_-_I'm Old Fashioned.flac
John Coltrane_-_Blue Train [RVG Editon]_-_05_-_Lazy Bird.flac
John Coltrane_-_Blue Train [RVG Editon]_-_06_-_Blue Train (Alternate Take) [Bonus Track].flac
John Coltrane_-_Blue Train [RVG Editon]_-_07_-_Lazy Bird (Alternate Take) [Bonus Track].flac
```

Although most CD extraction or tagging tools provide some form of renaming capabilities, they usually do not extend these capabilities to associated artifacts such as cover scans or CUE sheet files. In addition to uniformly rename all artifacts, MC Scripts can create checksum files and parity files for data integrity verification and recovery purposes. The result of running MC Scripts on the above set of files would look as follows:

```
folder.jpg
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-Back.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-Booklet01.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-Booklet02.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-Booklet03.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-Booklet04.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-CD.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Artwork-Front.png
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Checksum.md5
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Cue.cue
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Cue.cue.orig
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Log.log
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol000+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol027+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol054+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol081+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol108+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol135+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol162+27.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Parity.vol189+26.par2
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Playlist.m3u
John Coltrane_-_Blue Train [RVG Editon]_-_00_-_Playlist.m3u8
John Coltrane_-_Blue Train [RVG Editon]_-_01_-_Blue Train.flac
John Coltrane_-_Blue Train [RVG Editon]_-_02_-_Moment's Notice.flac
John Coltrane_-_Blue Train [RVG Editon]_-_03_-_Locomotion.flac
John Coltrane_-_Blue Train [RVG Editon]_-_04_-_I'm Old Fashioned.flac
John Coltrane_-_Blue Train [RVG Editon]_-_05_-_Lazy Bird.flac
John Coltrane_-_Blue Train [RVG Editon]_-_06_-_Blue Train (Alternate Take) [Bonus Track].flac
John Coltrane_-_Blue Train [RVG Editon]_-_07_-_Lazy Bird (Alternate Take) [Bonus Track].flac
```

## Overview

MC Scripts contains separate scripts for separate concerns. The following table provides an overview of all scripts:

| Script Name | Concern | Description |
| ------------ | ------------- | ------------- |
| Clean-Stage.ps1 | Automation | Remove all additional artifacts that have been created by MC Scripts including playlists, checksum files and parity files. |
| Create-Md5Checksums.ps1 | Data Integrity | Creates MD5 checksum files using the md5sum output format (see https://en.wikipedia.org/wiki/Md5sum). |
| Create-ParFiles.ps1 | Data Integrity | Creates Parchive files using an MultiPar executable (see https://en.wikipedia.org/wiki/Parchive). |
| Create-Playlists.ps1 | Playlists | Creates playlist files in the extended M3U or M3U8 format (see https://en.wikipedia.org/wiki/M3U). |
| Process-Stage.ps1 | Automation | Invoke all scripts in order to process all audio artifacts in the staging directory. |
| Rename-AudioArtifacts.ps1 | Naming | Rename all audio files and associated artifacts using metadata embedded in the audio files. |
| Test-FlacFiles.ps1 | Data Integrity | Tests all FLAC audio files using an external FLAC executable (see https://en.wikipedia.org/wiki/FLAC). |
| Update-Cuesheets.ps1 | CUE Sheets | Updates CUE sheets with correct audio file names, so that they can be processed by EAC. |

## Assumptions

MC Scripts is heavily opinionated and makes the following assumptions by default:

* All audio files are organized by release type (album, box set) in separate directories.
* All audio files are either FLAC or MP3 encoded.
* All audio files are properly tagged with at least the basic tags for artists, albums, track number and track name.
* All associated artifacts are name following a predefined convention (e.g. front.jpg for the front cover scan).

## Usage

Get a copy of MC Scripts either by cloning with Git or downloading the project archive:

**Clone with Git**

```
> git clone https://github.com/gzurowski/mc-scripts.git
```

**Download archive**

Download the archive located at https://github.com/gzurowski/mc-scripts/archive/master.zip and decompress to your local machine.

**Running setup**

After acquiring MC Scripts, run the setup procedure:

```
> Setup.cmd
```

The setup procedure will download all external dependencies that are needed for running MC Scripts. It will also ask to enter the location of your staging location. After running the setup procedure, you can start using MC Scripts.

