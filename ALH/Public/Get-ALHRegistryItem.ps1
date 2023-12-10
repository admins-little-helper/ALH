<#PSScriptInfo

.VERSION 1.2.0

.GUID 340f3e43-7088-4966-9f8a-b79416ec5b64

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
- Initial release

1.1.0
- Renamed script/function
- Fixed issue with computername in case no computername was specified

1.1.1
- Changed what results are returned in case a ValueName was specified

1.1.2
- Removed parameter 'RegistryHive'
- Fixed typo
- Fixed issue with path names in recursion

1.1.3
- Fixed issue of incorrect handling of root path

1.1.4
- Added error handling

1.2.0
- Changed name of custom type ALHRegistryItem

#>


<#

.DESCRIPTION
 Function to read registry keys and values from local or remote computers

#>

function Get-ALHRegistryItem {
    <#
    .SYNOPSIS
        Read Registry values from local or remote computer.

    .DESCRIPTION
        The function allows to list and read registry keys and values from local or remote computer(s).

    .PARAMETER ComputerName
        Optional. Name of a computer. If no name is sepcified, the command runs agains the local computer.
        Multiple Names can be specified as comma separated strings.

    .PARAMETER Path
        Mandatory. Registry Path to query.

    .PARAMETER ValueName
        Optional. Name of a registry value to query. If ommitted, all values under a key will be returned.

    .PARAMETER RegistryView
        Optional. Specifies which registry view to target on a 64-bit operating system.
        See https://docs.microsoft.com/en-us/dotnet/api/microsoft.win32.registryview?view=net-6.0 for details

    .PARAMETER Recurse
        Optional. Run query recursively (query sub keys).

    .PARAMETER SkipConnectionTest
        If specified, no attempt to ping the computer before trying to retrieve the update channel information is made.

    .EXAMPLE
        Get-ALHRegistryItem -ComputerName Computer1 -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common" -Recurse -Verbose
        Get all registry subkeys and values recursively under "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\office\16.0\common" from Computer "Computer1"

    .EXAMPLE
        (Get-ADComputer -SearchBase "OU=myOU,DC=myDomain,DC=tld" -Filter *).Name | Get-ALHRegistryItem -Path "HKLM:\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" -ValueName "enableautomaticupdates"
        Get all registry subkeys and values recursively under "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\office\16.0\common\officeupdate" from Computer "Computer1".

    .INPUTS
        System.String

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHRegistryItem.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param
    (
        [parameter(ValueFromPipeline = $true)]
        [String[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory)]
        [String]
        $Path,

        [String]
        $ValueName,

        [ValidateSet('Default', 'Registry32', 'Registry64')]
        [String]
        $RegistryView = 'Default',

        [Switch]
        $Recurse,

        [switch]
        $SkipConnectionTest
    )

    begin {
        $IsRecursive = (Get-PSCallStack)[1].Command -eq $MyInvocation.MyCommand
        $Hive = ""

        if ($Path -match "\\") {
            $Hive = $Path.Substring(0, $Path.IndexOf("\"))
            $Path = $Path.Substring($Path.IndexOf("\") + 1)
        }
        else {
            $Hive = $Path
            $Path = ""
        }

        $RegistryHiveList = @{
            "HKCR" = @{
                "ShortName" = "HKCR:"
                "HiveName"  = "ClassesRoot"
            }
            "HKCU" = @{
                "ShortName" = "HKCU:"
                "HiveName"  = "CurrentUser"
            }
            "HKLM" = @{
                "ShortName" = "HKLM:"
                "HiveName"  = "LocalMachine"
            }
            "HKU"  = @{
                "ShortName" = "HKU:"
                "HiveName"  = "Users"
            }
            "HKCC" = @{
                "ShortName" = "HKCC:"
                "HiveName"  = "CurrentConfig"
            }
        }

        switch ($Hive) {
            { "HKCR:", "HKEY_CLASSES_ROOT", "ClassesRoot" -contains $_ } { $RegistryHive = $RegistryHiveList."HKCR" }
            { "HKCU:", "HKEY_CURRENT_USER", "CurrentUser" -contains $_ } { $RegistryHive = $RegistryHiveList."HKCU" }
            { "HKLM:", "HKEY_LOCAL_MACHINE", "LocalMachine" -contains $_ } { $RegistryHive = $RegistryHiveList."HKLM" }
            { "HKU:", "HKEY_USERS", "Users" -contains $_ } { $RegistryHive = $RegistryHiveList."HKU" }
            { "HKCC:", "HKEY_CURRENT_CONFIG", "CurrentConfig" -contains $_ } { $RegistryHive = $RegistryHiveList."HKCC" }
            default {
                Write-Error -Message "Registry hive not detected!"
                break;
            }
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $IsComputerOnline = $false

            if ($IsRecursive) {
                Write-Debug -Message "Recusion detected. Skipping 'Test-Connection'"
                $IsComputerOnline = $true
            }
            else {
                Write-Verbose -Message "Reading values from Computer: $Computer"
                if ($SkipConnectionTest.IsPresent) {
                    Write-Verbose -Message "Skipping Test-Connection"
                    $IsComputerOnline = $true
                }
                else {
                    Write-Verbose -Message "Checking if system is online."
                    $IsComputerOnline = Test-Connection $Computer -Count 1 -Quiet
                    Write-Verbose -Message "Test result: $IsComputerOnline"
                }
            }

            if ($IsComputerOnline) {
                try {
                    $Registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($($RegistryHive.HiveName), $Computer, $RegistryView)
                    $RegistryKey = $Registry.OpenSubKey($Path)
                }
                catch [System.Security.SecurityException] {
                    Write-Warning -Message "Registry key does not exist or can not be read: '$($RegistryHive.ShortName)\$Path'"
                }
                catch {
                    Write-Warning -Message "Unknown error occured reading registry key: '$($RegistryHive.ShortName)\$Path'"
                }

                if ($RegistryKey) {
                    $Path = "$($RegistryHive.ShortName)\$Path"

                    if ($null -eq $ValueName -or $ValueName -eq "") {
                        $SearchValueName = "*"
                    }
                    else {
                        $SearchValueName = $ValueName
                    }

                    [array]$RegKeys = foreach ($Subkey in $RegistryKey.GetSubKeyNames()) {
                        $RegistryKeyObject = [PSCustomObject]@{
                            Computer = $Computer
                            Path     = $Path
                            SubKey   = $SubKey
                        }
                        $RegistryKeyObject.psobject.TypeNames.Insert(0, "ALHRegistryItem")

                        if ($Recurse.IsPresent) {
                            Get-ALHRegistryItem `
                                -ComputerName $Computer `
                                -Path ("$Path\$Subkey" -replace "\\\\", "\")  `
                                -RegistryView $RegistryView `
                                -ValueName $SearchValueName `
                                -Recurse:($Recurse.IsPresent)
                        }

                        # Only return RegistryKeyObject if no value was specified - means we return everything
                        # If a ValueName was specified, we only want to see results for this ValueName
                        if ($null -eq $ValueName -or $ValueName -eq "") {
                            $RegistryKeyObject
                        }
                    }

                    [array]$RegVals = foreach ($Value in ($RegistryKey.GetValueNames().where({ $_ -like "$SearchValueName" }))) {
                        $Data = $RegistryKey.GetValue($Value)
                        $DataType = $RegistryKey.GetValueKind($Value)

                        $RegistryValObject = [PSCustomObject]@{
                            Computer = $Computer
                            Path     = $Path
                            Value    = $Value
                            Data     = $Data
                            DataType = $DataType
                        }
                        $RegistryValObject.psobject.TypeNames.Insert(0, "ALHRegistryItem")
                        $RegistryValObject
                    }

                    if ($null -eq $RegVals) {
                        if ($SearchValueName -eq "*") {
                            Write-Verbose -Message "Registry '$Path' does not contain any values"
                        }
                        else {
                            Write-Verbose -Message "Registry value '$SearchValueName' does not exits in key '$Path'"
                        }
                    }

                    $RegKeys
                    $RegVals
                }
                else {
                    Write-Verbose -Message "Nothing found for specified key."
                }
            }
            else {
                Write-Warning -Message "Computer not reachable: $Computer"
            }
        }
    }
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
