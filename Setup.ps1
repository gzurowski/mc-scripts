#
# Setup.ps1
#
# Download external dependencies and configure application.
#

$invocationPath = Split-Path $MyInvocation.MyCommand.Path

# Load configuration
. (Join-Path $invocationPath AppConfig.ps1)

Add-Type -assembly "system.io.compression.filesystem"

$arch = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

# Download URLs
Set-Variable FlacDownloadUrl -Value "http://downloads.xiph.org/releases/flac/flac-1.3.4-win.zip" -Option Constant
Set-Variable ParDownloadUrl -Value "https://ftp.vector.co.jp/74/39/3430/MultiPar131.zip" -Option Constant
Set-Variable TaglibDownloadUrl -Value "https://www.nuget.org/api/v2/package/taglib/2.1.0" -Option Constant

# Temporary directory for setup files
Set-Variable SetupPath -Value (Join-Path $env:temp ("mc-scripts-" + [System.Guid]::NewGuid().ToString())) -Option ReadOnly

#
# Create directories
#
function CreateAppDirectories()
{
    if (-Not (Test-Path $BinPath -PathType Container))
    {
        "Creating directory '$BinPath'..."
        New-Item -ItemType Directory -Force -Path $BinPath | Out-Null
    }

    if (-Not (Test-Path $LibPath -PathType Container))
    {
        "Creating directory '$LibPath'"
        New-Item -ItemType Directory -Force -Path $LibPath | Out-Null
    }
}

#
# Install the dependency given the provided URL
#
function InstallDependency($name, $url)
{
    $path = (Join-Path $setupPath $name)

    if (Test-Path $path)
    {
        Remove-Item -Recurse $path
    }

    $archive = (Join-Path $setupPath "$name.zip")

    Invoke-WebRequest -Uri $url -OutFile $archive

    [io.compression.zipfile]::ExtractToDirectory($archive, $path)
    
    return $path
}

#
# Install FLAC
#
function InstallFlac()
{
    "Installing Flac..."
    $setupPathFlac = InstallDependency "flac" $FlacDownloadUrl
    # Copy the correct binary corresponding to the current CPU architecture
    Copy-Item -Force ($setupPathFlac + "\flac*\" + (@{$true = "win64"; $false = "win32"}[$arch -eq "64-bit"]) + "\flac.exe") $BinPath
}

#
# Install PAR2
#
function InstallPar()
{
    "Installing PAR2..."
    $setupPathPar = InstallDependency "par" $ParDownloadUrl
    # Copy the correct binary corresponding to the current CPU architecture
    Copy-Item -Force ($setupPathPar + "\par2j" + (@{$true = "64"; $false = ""}[$arch -eq "64-bit"]) + ".exe") $BinPath
}

#
# Install Taglib#
#
function InstallTaglib()
{
    "Installing Taglib#..."
    $setupPathTaglib = InstallDependency "taglib" $TaglibDownloadUrl
    Copy-Item -Force ($setupPathTaglib + "\lib\*") $LibPath
}

#
# Configure staging directory
#
function ConfigureStaging()
{
    $stagingDirectory = Read-Host -Prompt 'Please enter the path to your staging directory (e.g. "c:\music\stage")'

    if (-Not (Test-Path -PathType Container $stagingDirectory))
    {
        $createStagingDirectory = Read-Host "Directory '$stagingDirectory' does not exist. Do you want to create directory '$stagingDirectory'"

        if ($createStagingDirectory -eq 'y')
        {
            New-Item $stagingDirectory -Type Directory | Out-Null
            "Directory $stagingDirectory created."
        }
        else
        {
            "You will need to create directory '$stagingDirectory' manually."
        }
    }

    "Writing new configuration file 'Config.cmd'..."
    (Get-Content Config.cmd.template).replace('${STAGE_DIR}', $stagingDirectory) | Set-Content "$invocationPath\Config.cmd"

}

#
# Setup configuration file
#
function SetupConfigFile()
{
    if (-Not (Test-Path -PathType Leaf (Join-Path $invocationPath 'Config.ps1')))
    {
        "Creating an empty user configuration settings file 'Config.ps1'"
        Copy-Item (Join-Path $invocationPath 'Config.ps1.template') (Join-Path $invocationPath 'Config.ps1')
    }
}

##
## Main
##

Try
{
    # Create temporary setup directory
    New-Item -ItemType Directory -Force -Path $SetupPath | Out-Null

    CreateAppDirectories
    InstallFlac
    InstallPar
    InstallTaglib
    ConfigureStaging
    SetupConfigFile
}
Finally
{
    # Clean up
    if (Test-Path $SetupPath -PathType Container)
    {
        Remove-Item -Recurse -Force $SetupPath
    }
}
