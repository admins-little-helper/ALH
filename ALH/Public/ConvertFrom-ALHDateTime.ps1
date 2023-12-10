<#PSScriptInfo

.VERSION 1.1.0

.GUID 15cfc452-2c60-428e-9a06-1fc3bd4e9f9f

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
    Initial release

    1.1.0
    Added pipeline support. Set defaut value to current date/time for parameter 'DateTime'

#>


<#

.DESCRIPTION
Contains a function to convert a local date/time to miliseconds since 1970 or milliseconds since 1601 or ticks since 1601.

.LINK
https://github.com/admins-little-helper/ALH

.LINK
https://docs.microsoft.com/en-US/troubleshoot/windows-server/identity/useraccountcontrol-manipulate-account-properties

#>


function ConvertFrom-ALHDateTime {
    <#
    .SYNOPSIS
        Converts a local date/time to miliseconds since 1970 or milliseconds since 1601 or ticks since 1601.

    .DESCRIPTION
        Converts a local date/time to miliseconds since 1970 or milliseconds since 1601 or ticks since 1601.

    .PARAMETER DateTime
        Date to convert. Defaults to current date/time.

    .EXAMPLE
        ConvertFrom-ALHDateTime

        DateTime            MillisecondsSince1970 MillisecondsSince1601     TicksSince1601
        --------            --------------------- ---------------------     --------------
        11.11.2022 21:14:49         1668201289484        13312674889484 133126748894840000

        This example shows how to convert the current date/time to MillisecondsSince1970, MillisecondsSince1601 and TicksSince1601.

    .EXAMPLE
        ConvertFrom-ALHDateTime -DateTime "11.11.2011 11:11:11"

        DateTime            MillisecondsSince1970 MillisecondsSince1601     TicksSince1601
        --------            --------------------- ---------------------     --------------
        11.11.2011 11:11:00         1321009860000        12965483460000 129654834600000000

        This example shows how to convert a date as string to MillisecondsSince1970, MillisecondsSince1601 and TicksSince1601.
        Note that in this example PowerShell automatically casts the String value to a DateTime value. Use this carefully to make sure the
        date/time format matches your local date time format.

    .INPUTS
        System.DateTime

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/ConvertFrom-ALHDateTime.txt
    #>

    [cmdletbinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [DateTime[]]
        $DateTime = @(, (Get-Date))
    )

    begin {
        $DT1970 = Get-Date -Date "1970-01-01T00:00:00"
        $DT1601 = Get-Date -Date "1601-01-01T00:00:00"
    }

    process {
        foreach ($DateTimeElement in $DateTime) {
            try {
                [int64]$MillisecondsSince1970 = ($DateTimeElement - $DT1970).TotalMilliseconds
                [int64]$MillisecondsSince1601 = ($DateTimeElement - $DT1601).TotalMilliseconds
            }
            catch {
                $_
            }

            $DateTimeConverted = [PSCustomObject]@{
                DateTime              = $DateTimeElement
                MillisecondsSince1970 = $MillisecondsSince1970
                MillisecondsSince1601 = $MillisecondsSince1601
                TicksSince1601        = $MillisecondsSince1601 * 10000
            }

            $DateTimeConverted
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