<#PSScriptInfo

.VERSION 1.0.0

.GUID f1a69c66-41e4-4c72-9bef-1ab85548cfb9

.AUTHOR diko@admins-little-helper.de

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
    Initial release

#>


<#

.DESCRIPTION
Contains a function to retrieve a status code message for a given http status code.

.LINK
https://github.com/admins-little-helper/ALH

#>


function Get-ALHHttpStatusCode {
    <#
    .SYNOPSIS
    Retrieves a status code message for a given http status code.

    .DESCRIPTION
    Retrieves a status code message for a given http status code.

    .PARAMETER StatusCode
    HTTP status code number as integer.

    .EXAMPLE
    Get-ALHHttpStatusCode -StatusCode 400

    .INPUTS
    System.Int32

    .OUTPUTS
    System.String

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHHttpStatusCode.txt
    #>

    [Cmdletbinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [int[]]
        $StatusCode
    )

    process {
        foreach ($StatusCodeElement in $StatusCode) {
            switch ( $StatusCodeElement ) {
                400 { "Bad Request." }
                401 { "Unauthorized." }
                403 { "Authorization failed. Please supply a valid ApiKey." }
                404 { "Not found." }
                413 { "Payload too large." }
                414 { "URI too long." }
                429 { "Too many requests. Please wait and resend your request." }
                456 { "Quota exceeded." }
                500 { "Internal Server error." }
                503 { "Resource currently unavailable. Try again later." }
                504 { "Service unavailable." }
                529 { "Too many requests. Please wait and resend your request." }
                default { $_ -as [System.Net.HttpStatusCode] }
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
