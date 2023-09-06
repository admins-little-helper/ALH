<#PSScriptInfo

.VERSION 1.1.0

.GUID cc3e2ec8-a161-4c47-91e2-53af08fdfcf8

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
    - Added parameter 'UpdateChannel'
#>


<#

.DESCRIPTION
 Contains a function to retrieve the M365 Apps for Enterprise update information.

#>


function Get-ALHOffice365UpdateStatus {
    <#
    .SYNOPSIS
    Retrieves the M365 Apps for Enterprise update information.

    .DESCRIPTION
    Retrieves the M365 Apps for Enterprise update information.

    .PARAMETER UpdateChannel
    The name of the update channel to retrieve. If none is specified, all channels are returned.

    .EXAMPLE
    Get-ALHOffice365UpdateStatus
    Returns information about all update channels.

    .EXAMPLE
    Get-ALHOffice365UpdateStatus -UpdateChannel MonthylEnterprise
    Returns information about the MonthlyEnterprise update channel.

    .INPUTS
    Nothing

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHOffice365UpdateStatus.txt
    #>

    [CmdletBinding()]
    param (
        [ValidateSet("MonthlyEnterprise", "Current", "CurrentPreview", "SemiAnnualEnterprise", "SemiAnnualEnterprisePreview", "Beta")]
        [string]
        $UpdateChannel
    )

    $ChannelIdMapping = @{
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

    $M365AppsUpdateStatusUrl = "https://mrodevicemgr.officeapps.live.com/mrodevicemgrsvc/api/v2/C2RReleaseData"
    $M365AppsUpdateStatus = Invoke-RestMethod -Method Get -Uri $M365AppsUpdateStatusUrl

    foreach ($object in $M365AppsUpdateStatus) {
        $object.PSObject.TypeNames.Insert(0, "ALHM365AppsUpdateStatus")
        $object | Add-Member -Name "Channel" -MemberType NoteProperty -Value $ChannelIdMapping."$($object.FFN)"

        if ([string]::IsNullOrEmpty($UpdateChannel)) {
            $object
        }
        else {
            if ($UpdateChannel -eq $object.Channel) {
                $object
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
