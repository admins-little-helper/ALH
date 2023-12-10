<#PSScriptInfo

.VERSION 1.2.0

.GUID 044cd38b-8558-4820-b412-c56121c12018

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
    Added parameter 'AsLocalTime'

    1.2.0
    Added pipeline support. Set defaut value to current date/time for parameter 'DateTime'

#>


<#

.DESCRIPTION
 Contains a function to convert miliseconds since 1970 or 1601 or ticks since 1601 to a DateTime value.

#>


function ConvertTo-ALHDateTime {

    <#
    .SYNOPSIS
        Converts miliseconds since 1970 or 1601 or ticks since 1601 to a DateTime value.

    .DESCRIPTION
        Converts miliseconds since 1970 or 1601 or ticks since 1601 to a DateTime value (by defaults in UTC time).
        The function returns $null

    .PARAMETER DateTimeValue
        Miliseconds since 01.01.1700 00:00:00 or miliseconds since 01.01.1601 00:00:00 or ADDateTime value.

    .PARAMETER AsLocalTime
        If specified, the resulting DateTime value will be interpreted in local time zone, instead of UTC.

    .EXAMPLE
        ConvertTo-ALHDateTime -DateTimeValue 13270022798437

        DateTimeBase1970    DateTimeBase1601    DateTimeBaseAD
        ----------------    ----------------    --------------
        06.07.2390 03:26:38 06.07.2021 03:26:38 16.01.1601 08:36:42

        Convert a int64 value representing an miliseconds since 01.01.1601 to date/time in UTC format.

    .EXAMPLE
        ConvertTo-ALHDateTime -DateTimeValue 13270022798437

        DateTimeBase1970    DateTimeBase1601    DateTimeBaseAD
        ----------------    ----------------    --------------
        06.07.2390 03:26:38 06.07.2021 03:26:38 16.01.1601 08:36:42

        Convert a int64 value representing an miliseconds since 01.01.1601 to date/time in UTC format.

    .EXAMPLE
        (Get-ADUser -Filter * -Property lastLogonTimeStamp).lastLogonTimeStamp | ConvertTo-ALHDateTime

        DateTimeBase1970 DateTimeBase1601 DateTimeBaseAD
        ---------------- ---------------- --------------
                                          04.11.2022 09:43:10
                                          04.11.2022 09:43:10
                                          23.02.2020 17:59:40
                                          23.02.2020 17:59:40
                                          23.11.2015 05:57:05
                                          09.11.2022 11:14:48

        This example shows how to retrieve the lastLogonTimeStamp for all users in Active Directory and get the DateTime value
        of for it.

    .INPUTS
        System.Int64

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/ConvertTo-ALHDateTime.txt
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [double[]][AllowNull()]
        $DateTimeValue,

        [switch]
        $AsLocalTime
    )

    begin {
        $DT1970 = Get-Date -Date "1970-01-01T00:00:00"
        $DT1601 = Get-Date -Date "1601-01-01T00:00:00"

        $DateTimeConverted = [PSCustomObject]@{
            DateTimeBase1970 = $DT1970.AddMilliseconds($DateTimeValueElement)
            DateTimeBase1601 = $DT1601.AddMilliseconds($DateTimeValueElement)
            DateTimeBaseAD   = [DateTime]::FromFileTime($DateTimeValueElement)
        }
    }

    process {
        if ($null -eq $DateTimeValue) {
            # return a PSCustomObject with $null values for each property
            $DateTimeConverted
        }
        else {
            foreach ($DateTimeValueElement in $DateTimeValue) {
                try {
                    if (($DateTimeValueElement * 10000) -lt [DateTime]::MaxValue.Ticks) {
                        [datetime]$LocalDTBase1970 = $DT1970.AddMilliseconds($DateTimeValueElement)
                        [datetime]$LocalDTBase1601 = $DT1601.AddMilliseconds($DateTimeValueElement)
                    }
                }
                catch {
                    $_
                }

                try {
                    [datetime]$LocalDTBaseAD = [DateTime]::FromFileTime($DateTimeValueElement)
                }
                catch {
                    $_
                }

                if ($AsLocalTime.IsPresent) {
                    $DateTimeConverted.DateTimeBase1970 = $( if ($null -ne $LocalDTBase1970) { $LocalDTBase1970 } )
                    $DateTimeConverted.DateTimeBase1601 = $( if ($null -ne $LocalDTBase1601) { $LocalDTBase1601 } )
                    $DateTimeConverted.DateTimeBaseAD = $( if ($null -ne $LocalDTBaseAD) { $LocalDTBaseAD } )
                }
                else {
                    $DateTimeConverted.DateTimeBase1970 = $( if ($null -ne $LocalDTBase1970) { $LocalDTBase1970.ToUniversalTime() } )
                    $DateTimeConverted.DateTimeBase1601 = $( if ($null -ne $LocalDTBase1601) { $LocalDTBase1601.ToUniversalTime() } )
                    $DateTimeConverted.DateTimeBaseAD = $( if ($null -ne $LocalDTBaseAD) { $LocalDTBaseAD.ToUniversalTime() } )
                }

                $DateTimeConverted
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
