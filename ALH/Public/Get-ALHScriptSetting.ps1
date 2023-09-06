
<#PSScriptInfo

.VERSION 1.1.0

.GUID a1c1ff85-41e7-4514-84bf-e6368f7904e3

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
 1.0.0
 - Initial Release

 1.1.0
 - Cleaned up code

#>

<#

.DESCRIPTION
Conatins a function to read settings for a script from one or more json files.

#>


function Get-ALHScriptSetting {
    <#
    .SYNOPSIS
        A PowerShell function for reading settings used in a script from json files.

    .DESCRIPTION
        This PowerShell function reads settings for a script from one or more .json files.
        If no filename is specified, the function tries to read the script's main settings from a
        file named "settings.json" in the $PSScriptRoot directory. This settings file can contain
        a path to additional settings files. The function will then try to read all .json files
        from the specified path (non-recursive).

    .PARAMETER Path
        The path to the .json file to be read. If omitted, the script assumes '$PSScriptRoot\settings.json'

    .PARAMETER Encoding
        Allows to specify the encoding of the file to be read. Defaults to 'utf8'.

    .PARAMETER DefaultSettings
        Allows to specify some default settings as fall back that are returned if the specified settings file
        can not be read successfully or the file is empty.

    .EXAMPLE
        $Settings = Get-ALHScriptSetting -Path 'C:\MyScript\Settings.json' -Verbose
        Returns the settings saved in the JSON file as PSCustomObject.

    .INPUTS
        Nothing

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHScriptSetting.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        [ValidateScript({
                # Check if the given path is valid.
                if (-not (Test-Path -Path $_) ) {
                    throw "The specified settings file does not exist."
                }
                # Check if the given path is a directory.
                if (Test-Path -Path $_ -PathType Container) {
                    throw "The Path argument must be a file. Folder paths are not allowed."
                }
                return $true
            })]
        [System.IO.FileInfo[]]
        $Path,

        [System.Text.Encoding]
        $Encoding = "utf8",

        [PSCustomObject]
        $DefaultSettings = @{
            Global = @{
                LogDir    = $env:Temp
                InputDir  = $null
                OutputDir = $env:Temp
            }
        }
    )

    try {
        Write-Verbose -Message "Trying to read [$Path]..."
        $Settings = Get-Content -Path $Path -Raw -Encoding $Encoding | ConvertFrom-Json

        if ($null -eq $Settings) {
            Write-Warning -Message "No valid settings could be read from file or file does not exist. Using default settings."
            $Settings = $DefaultSettings
        }
        else {
            Write-Verbose -Message "Settings successfully read from file."
        }
    }
    catch {
        Write-Error $_
    }

    $Settings
}

#region EndOfScript
<#
################################################################################
################################################################################
#
#        ______           _          __    _____           _       _
#       |  ____|         | |        / _|  / ____|         (_)     | |
#       | |__   _ __   __| |   ___ | |_  | (___   ___ _ __ _ _ __ | |_
#       |  __| | '_ \ / _` |  / _ \|  _|  \___ \ / __| '__| | '_ \| __|
#       | |____| | | | (_| | | (_) | |    ____) | (__| |  | | |_) | |_
#       |______|_| |_|\__,_|  \___/|_|   |_____/ \___|_|  |_| .__/ \__|
#                                                           | |
#                                                           |_|
################################################################################
################################################################################
# created with help of http://patorjk.com/software/taag/
#>
#endregion
