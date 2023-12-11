<#PSScriptInfo

.VERSION 1.0.0

.GUID 8123d13f-7262-4e67-8a6e-363a00781935

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

#>


<#

.DESCRIPTION
 Retrieve the name of the M365 Apps (Office 365) update channel configured on a computer.

#>



function Get-ALHOffice365UpdateChannel {
    <#
    .SYNOPSIS
        Retrieve the name of the M365 Apps (Office 365) update channel configured on a computer.

    .DESCRIPTION
        The function 'Get-ALHOffice365UpdateChannel' retrieves the name of the M365 Apps (Office 365) update channel configured on a computer.

    .PARAMETER ComputerName
        Specifies the name of the computer for which to retrieve the update channel information. Defaults to the local computername.

    .PARAMETER SkipConnectionTest
        If specified, no attempt to ping the computer before trying to retrieve the update channel information is made.

    .EXAMPLE
        Get-ALHOffice365UpdateChannel

        Computer      EffectiveChannel ConfiguredChannels
        --------      ---------------- ------------------
        LocalComputer Current          @{Channel=Current; ChannelGuid=492350f6-3a01-4f97-b9c0-c7c6ddf67d60; ChannelRegVal=http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60; Prio=4}

        Returns the update channel information for the local computer.

    .EXAMPLE
        Get-ALHOffice365UpdateChannel -ComputerName RemoteComputer1, RemoteComputer2

        Computer        EffectiveChannel ConfiguredChannels
        --------        ---------------- ------------------
        RemoteComputer1 Current          @{Channel=Current; ChannelGuid=492350f6-3a01-4f97-b9c0-c7c6ddf67d60; ChannelRegVal=http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60; Prio=4}
        RemoteComputer2 Current          @{Channel=Current; ChannelGuid=492350f6-3a01-4f97-b9c0-c7c6ddf67d60; ChannelRegVal=http://officecdn.microsoft.com/pr/492350f6-3a01-4f97-b9c0-c7c6ddf67d60; Prio=4}

        Returns the update channel information for the two computers 'RemoteComputer1' and 'RemoteComputer2'. This only works if the specified
        computers are online and if the user executing the function has administrator privileges on them to read the registry remotely.

    .INPUTS
        System.String

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHOffice365UpdateChannel.txt

    .LINK
        https://techcommunity.microsoft.com/t5/microsoft-365-blog/how-to-manage-office-365-proplus-channels-for-it-pros/ba-p/795813

    .LINK
        https://learn.microsoft.com/en-us/deployoffice/updates/change-update-channels
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Position = 0, HelpMessage = "The name of the computer to retrieve information for.")]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(Position = 1, HelpMessage = "Skip to check if the specified computer is online.")]
        [switch]
        $SkipConnectionTest
    )

    begin {
        # Define the Channel Ids and their corrosponding names.
        $ChannelIdMapping = @{
            "Current"                              = "Current"
            "FirstReleaseCurrent"                  = "CurrentPreview"
            "MonthlyEnterprise"                    = "MonthlyEnterprise"
            "Deferred"                             = "SemiAnnualEnterprise"
            "FirstReleaseDeferred"                 = "SemiAnnualEnterprisePreview"
            "InsiderFast"                          = "Beta"

            "55336b82-a18d-4dd6-b5f6-9e5095c314a6" = "MonthlyEnterprise"
            "492350f6-3a01-4f97-b9c0-c7c6ddf67d60" = "Current"
            "64256afe-f5d9-4f86-8936-8840a6a4f5be" = "CurrentPreview"
            "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" = "SemiAnnualEnterprise"
            "b8f9b850-328d-4355-9145-c59439a0c4cf" = "SemiAnnualEnterprisePreview"
            "5440fd1f-7ecb-4221-8110-145efaa6372f" = "Beta"

            # https://github.com/ItzLevvie/Office16/blob/master/defconfig
            "ea4a4090-de26-49d7-93c1-91bff9e53fc3" = "_Dogfood_DevMain"
            "f3260cf1-a92c-4c75-b02e-d64c0a86a968" = "_Dogfood_CC"
            "b61285dd-d9f7-41f2-9757-8f61cba4e9c8" = "_Microsoft_DevMain"
            "5462eee5-1e97-495b-9370-853cd873bb07" = "_Microsoft_CC"
            "9a3b7ff2-58ed-40fd-add5-1e5158059d1c" = "_Microsoft_FRDC"
            "f4f024c8-d611-4748-a7e0-02b6e754c0fe" = "_Microsoft_DC"
            "86752282-5841-4120-ac80-db03ae6b5fdb" = "_Microsoft_LTSC2021"
            "1d2d2ea6-1680-4c56-ac58-a441c8c24ff9" = "_Microsoft_LTSC"
            "f2e724c1-748f-4b47-8fb8-8e0d210e9208" = "_Production_LTSC"
            <#
            "5440fd1f-7ecb-4221-8110-145efaa6372f" = "Insiders_DevMain"
            "64256afe-f5d9-4f86-8936-8840a6a4f5be" = "Insiders_CC"
            "b8f9b850-328d-4355-9145-c59439a0c4cf" = "Insiders_FRDC"
            "492350f6-3a01-4f97-b9c0-c7c6ddf67d60" = "Production_CC"
            "55336b82-a18d-4dd6-b5f6-9e5095c314a6" = "Production_MEC"
            "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" = "Production_DC"
            "5030841d-c919-4594-8d2d-84ae4f96e58e" = "Production_LTSC2021"
            #>
        }

        # Define the registry paths and values that are qureied to determine the configured update channels.
        $RegistryPaths = @(
            [PSCustomObject]@{
                RegPath = "HKLM:\software\policies\microsoft\office\16.0\common\officeupdate"
                Value   = "updatepath"
                Prio    = 0
            }
            [PSCustomObject]@{
                RegPath = "HKLM:\software\policies\microsoft\office\16.0\common\officeupdate"
                Value   = "updatebranch"
                Prio    = 1
            }
            [PSCustomObject]@{
                RegPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
                Value   = @("UpdateURL", "UpdatePath")
                Prio    = 2
            }
            [PSCustomObject]@{
                RegPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
                Value   = "UnmanagedUpdateURL"
                Prio    = 3
            }
            [PSCustomObject]@{
                RegPath = "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration"
                Value   = "CDNBaseUrl"
                Prio    = 4
            }
        )
    }

    process {
        foreach ($Computer in $ComputerName) {
            try {
                # Create an object of type PSCustomObject that's used to carry the information we want to return.
                $UpdateInfo = [PSCustomObject]@{
                    Computer           = $Computer
                    ConfiguredChannels = @()
                    EffectiveChannel   = $null
                    EffectivePrio      = $null
                }

                # Check if the specififed computer is online.
                $IsComputerOnline = $false
                if ($SkipConnectionTest.IsPresent) {
                    Write-Verbose -Message "[$Computer]: Skipping connection test."
                    $IsComputerOnline = $true
                }
                else {
                    Write-Verbose -Message "[$Computer]: Checking if system is online."
                    $IsComputerOnline = Test-Connection $Computer -Count 1 -Quiet
                    Write-Verbose -Message "[$Computer]: Is online: $IsComputerOnline"
                }

                if ($IsComputerOnline) {
                    Write-Verbose -Message "[$Computer]: Trying to get update channel information for computer."
                    foreach ($Entry in $RegistryPaths) {
                        Write-Verbose -Message "[$Computer]: Checking UpdateChannel Prio [$($Entry.Prio)] - [$($Entry.RegPath)]."
                        foreach ($ValueName in $Entry.Value) {
                            # Define the paramters for the Get-ALHRegistryItem function, which will finally read the registry on the (remote) computer.
                            $GetALHRegistryItemParams = @{
                                ComputerName       = $Computer
                                Path               = $Entry.RegPath
                                ValueName          = $ValueName
                                SkipConnectionTest = $true
                            }
                            $RegistryValue = (Get-ALHRegistryItem @GetALHRegistryItemParams).Data

                            # Check if the value retured is something or nothing...
                            if ([string]::IsNullOrEmpty($RegistryValue)) {
                                Write-Verbose -Message "[$Computer]: RegistryValue is empty, so not in use."
                            }
                            else {
                                Write-Verbose -Message "[$Computer]: RegistryValue: [$RegistryValue]."

                                # Get the GUID value from the URL value.
                                $ChannelGuid = $RegistryValue -replace 'http://officecdn.microsoft.com/pr/', ''
                                Write-Verbose -Message "[$Computer]: This computer is configured for update channel [$($ChannelIdMapping[$ChannelGuid])]."

                                # Fill the 'ToBeReturned' object with data.
                                $UpdateInfo.ConfiguredChannels += [PSCustomObject]@{
                                    Channel       = $($ChannelIdMapping[$ChannelGuid])
                                    ChannelGuid   = $ChannelGuid
                                    ChannelRegVal = $RegistryValue
                                    Prio          = $Entry.Prio
                                }
                            }
                        }
                    }
                }

                # Calculate the effective channel.
                Write-Verbose -Message "[$Computer]: If multiple channels are configued, the one with the lowest priority value wins."
                $UpdateInfo.EffectiveChannel = ($UpdateInfo.ConfiguredChannels | Sort-Object -Property Prio | Select-Object -First 1).Channel
                $UpdateInfo.EffectivePrio = ($UpdateInfo.ConfiguredChannels | Sort-Object -Property Prio | Select-Object -First 1).Prio

                # Define custom type name for the PSCustomObject to make sure the custom format is applied.
                $UpdateInfo.PSObject.TypeNames.Insert(0, "ALHM365AppsUpdateChannel")

                # Return the object.
                $UpdateInfo
            }
            catch {
                $_
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
