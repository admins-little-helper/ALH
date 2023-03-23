<#PSScriptInfo

.VERSION 1.0.0

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

    .EXAMPLE
    Get-ALHOffice365UpdateStatus

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
    param ()
    
    $ChannelIdMapping = @{
        "55336b82-a18d-4dd6-b5f6-9e5095c314a6" = "MonthlyEnterprise"
        "492350f6-3a01-4f97-b9c0-c7c6ddf67d60" = "Current"
        "64256afe-f5d9-4f86-8936-8840a6a4f5be" = "CurrentPreview"
        "7ffbc6bf-bc32-4f92-8982-f9dd17fd3114" = "SemiAnnualEnterprise"
        "b8f9b850-328d-4355-9145-c59439a0c4cf" = "SemiAnnualEnterprisePreview"
        "5440fd1f-7ecb-4221-8110-145efaa6372f" = "Beta"
    }

    $M365AppsUpdateStatusUrl = "https://mrodevicemgr.officeapps.live.com/mrodevicemgrsvc/api/v2/C2RReleaseData"
    $M365AppsUpdateStatus = Invoke-RestMethod -Method Get -Uri $M365AppsUpdateStatusUrl
    foreach ($object in $M365AppsUpdateStatus) {
        $object.PSObject.TypeNames.Insert(0, "ALHM365AppsUpdateStatus")
        $object | Add-Member -Name "Channel" -MemberType NoteProperty -Value $ChannelIdMapping."$($object.FFN)"
        $object
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
