
<#PSScriptInfo

.VERSION 1.1.0

.GUID a1c1ff85-41e7-4514-84bf-e6368f7904e3

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS 

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI 

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


function Get-ALHScriptSettings {
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

    .EXAMPLE 
    Get-ALHScriptSettings -Path 'C:\MyScript\Settings.json' -Verbose

    Get-ALHScriptSettings

    .INPUTS
    Nothing

    .OUTPUTS 
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHScriptSettings.txt
    #>

    [CmdletBinding()]
    param(
        [ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]
        [string]
        $Path
    )

    if ([string]::IsNullOrEmpty($Path)) {
        $ScriptInfo = Get-PSCallStack
        $Path = "$env:LOCALAPPDATA\.ALH\$($ScriptInfo[1].Command -replace '.ps1', '.json')"
    }

    if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "Trying to read $Path..."
    
        try {
            $Settings = Get-Content -Path "$Path" | ConvertFrom-Json
            if ($null -ne $Settings) {
                Write-Verbose -Message "Settings successfully read."
            }
        }
        catch {
            Write-Error $_
        }
    }
    else {
        Write-Warning -Message "Settings file was not found: '$Path'"
        Write-Warning -Message "Will return empty default settings 'Global'"
    }
    
    Write-Verbose -Message "Checking filename..."
    $FileName = Split-Path -Path $Path -Leaf

    if ($FileName -eq "Settings.json") {
        Write-Verbose -Message "Filename 'settings.json' detected"
        Write-Verbose -Message "Checking for default file content..."
        if ($null -ne $Settings) {
            try {
                if ($Settings.PSobject.Properties.Name -contains "Global") {
                    if (($Settings.Global | Get-Member -MemberType NoteProperty | Select-Object -Property Name).Name -contains "logDir") {
                        if (-not ([string]::IsNullOrEmpty($Settings.Global.logDir))) {
                            Write-Verbose -Message "Resolving logDir path..."
                            $Settings.Global.logDir = $Settings.Global.logDir -replace '\$PSScriptRoot', "$PSScriptRoot"
                            Write-Verbose -Message "Testing logDir path: $($Settings.Global.logDir)"

                            if (Test-Path -Path $($Settings.Global.logDir)) {
                                Write-Verbose -Message "Logfile directory found and accessable: $($Settings.Global.logDir)"
                            }
                            else {
                                Write-Verbose -Message "Logfile directory not found or not accessable: $($Settings.Global.logDir)"
                                Write-Verbose -Message "Setting $env:Temp as logfile directory..."
                                $Settings.Global.logDir = $env:Temp
                            }
                        }
                    }
                    else {
                        $Settings.Global | Add-Member -MemberType NoteProperty -Name "logDir" -Value "$env:Temp"
                    }

                    if (($Settings.Global | Get-Member -MemberType NoteProperty | Select-Object -Property Name).Name -contains "inputDir") {
                        if (-not ([string]::IsNullOrEmpty($Settings.Global.inputDir))) {
                            Write-Verbose -Message "Resolving inputDir path..."
                            $Settings.Global.inputDir = $Settings.Global.inputDir -replace '\$PSScriptRoot', "$PSScriptRoot"
                            Write-Verbose -Message "Testing inputDir path: $($Settings.Global.inputDir)"

                            if (Test-Path -Path $Settings.Global.inputDir) {
                                Write-Verbose -Message "Input directory found and accessable: $($Settings.Global.inputDir)"
                            }
                            else {
                                Write-Verbose -Message "Input directory not found or not accessable: $($Settings.Global.inputDir)"
                                Write-Verbose -Message "Setting input directory to null"
                                $Settings.Global.inputDir = $null
                            }
                        }
                    }
                    else {
                        $Settings.Global | Add-Member -MemberType NoteProperty -Name "inputDir" -Value $null
                    }

                    if (($Settings.Global | Get-Member -MemberType NoteProperty | Select-Object -Property Name).Name -contains "outputDir") {
                        if (-not ([string]::IsNullOrEmpty($Settings.Global.outputDir))) {
                            Write-Verbose -Message "Resolving outputDir path..."
                            $Settings.Global.outputDir = $Settings.Global.outputDir -replace '\$PSScriptRoot', "$PSScriptRoot"
                            Write-Verbose -Message "Testing outputDir path: $($Settings.Global.outputDir)"

                            if (Test-Path -Path $Settings.Global.outputDir) {
                                Write-Verbose -Message "Output directory found and accessable: $($Settings.Global.outputDir)"
                            }
                            else {
                                Write-Verbose -Message "Output directory not found or not accessable: $($Settings.Global.outputDir)"
                                Write-Verbose -Message "Setting $env:Temp as Output directory..."
                                $Settings.Global.outputDir = $env:Temp
                            }
                        }
                    }
                    else {
                        $Settings.Global | Add-Member -MemberType NoteProperty -Name "outputDir" -Value "$env:Temp"
                    }
                }
            }
            catch {
                Write-Error $_
            }
        }
        else {
            Write-Verbose -Message "Using default settings..."
            $Settings = [PSCustomObject]@{
                Global = @{
                    logDir    = $env:Temp
                    inputDir  = $null
                    outputDir = $env:Temp
                }
            }            
        }
            
        if ($null -ne $Settings.Global.inputDir) {
            Write-Verbose -Message "Trying to load additional settings from input path..."
            $AdditionalSettingsFiles = Get-ChildItem -Path $Settings.Global.inputDir -Filter *.json
        
            foreach ($file in $AdditionalSettingsFiles) {
                Write-Verbose -Message "Working on file $($file.FullName)..."
                $AdditionalSettings = Get-ScriptSettings -Path $file.FullName
                $Settings | Add-Member -Name $file.BaseName -MemberType NoteProperty -Value $AdditionalSettings 
            }
        }
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
