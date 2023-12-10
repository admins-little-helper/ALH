<#PSScriptInfo

.VERSION 1.0.0

.GUID 531acbf8-aa34-4a20-98ac-9de1932d73bc

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
 Contains a function to check if a given string is a valid UPN.

#>

function Test-ALHIsUpn {
    <#
    .SYNOPSIS
        Check if a given string is a valid UPN.

    .DESCRIPTION
        Checkif a given string is a valid UPN.

    .EXAMPLE
        Test-ALHIsUpn -UPN "somebody@somedomain.tld"

    .INPUTS
        System.String

    .OUTPUTS
        System.Boolean

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHIsUpn.txt
    #>

    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]
        $UPN
    )

    process {
        try {
            if ($null -eq ($UPN -as [System.Net.Mail.MailAddress])) {
                $false
            }
            else {
                $true
            }
        }
        catch {
            Write-Error $_
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
