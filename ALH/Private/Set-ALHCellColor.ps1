<#PSScriptInfo

.VERSION 1.0.0

.GUID a63fcce8-1f0b-471b-990e-d67d95d35a8e

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

#>


<#

.DESCRIPTION
 Contains functions to set the cell color in a html table based on it's value.

#>

# Vaguely based on
# https://community.spiceworks.com/scripts/show/2450-change-cell-color-in-html-table-with-powershell-set-cellcolor


function Set-ALHCellColor {
    <#
    .SYNOPSIS
    Function to set cell color of a html table based on filter criteria.

    .DESCRIPTION
    This functions allows to change the cell color in a html table (InputObject) based on the cell value.

    .PARAMETER InputObject
    PowerShell object html code containing a table definition.

    .PARAMETER Filter
    Filter string to be used to identify the cells, that's color should be set.

    .PARAMETER Color
    The color code as hex value (e.g. #000000)

    .PARAMETER Row
    If specified, the background color will be set for the whole row instead of just the single cell in the table.

    .EXAMPLE
    $htmlReport = Set-CellColor -InputObject $htmlReport -Filter $FilterString -Color $($Format.Color) -Row:$($Format.Row)

    Update an html report string.

    .INPUTS
    Object

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Set-ALHCellColor.txt
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateNotNull()]
        [Object[]]
        $InputObject,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string]
        $Filter,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Color,

        [switch]
        $Row
    )

    begin {
        $Property = ($Filter.Split(' ')[0])

        if ($Filter.ToUpper().IndexOf($Property.ToUpper()) -ge 0) {
            $Filter = $Filter.ToUpper().Replace($Property.ToUpper(), '$value')

            try {
                [scriptblock]$Filter = [scriptblock]::Create($Filter)
            }
            catch {
                exit
            }
        }
        else {
            exit
        }
    }

    process {
        foreach ($input in $InputObject) {
            [string]$line = $input

            if ($line.IndexOf('<tr><th') -ge 0) {
                [int]$index = 0
                [int]$count = 0

                $search = $line | Select-String -Pattern '<th>(.*?)</th>' -AllMatches

                foreach ($match in $search.Matches) {
                    if ($match.Groups[1].Value -eq $Property) {
                        $index = $count
                    }
                    $count++
                }

                if ($index -eq $search.Matches.Count) {
                    $index = -99
                    break
                }
            }

            if ($line -match '<tr><td') {
                $line = $line.Replace('<td></td>', '<td> </td>')
                $search = $line | Select-String -Pattern '<td(.*?)</td>' -AllMatches

                if (($null -ne $search) -and ($search.Matches.Count -ne 0) -and ($index -ne -99)) {
                    if (-not ($null -eq $search.Matches[$index].Groups)) {
                        $value = ($search.Matches[$index].Groups[1].Value -replace ",", ".").Split('>')[1] -as [double]

                        if ($null -eq $value) {
                            $value = ($search.Matches[$index].Groups[1].Value).Split('>')[1]
                        }

                        if (Invoke-Command $Filter) {
                            if ($Row.IsPresent) {
                                $line = $line.Replace('<td>', ('<td style="background:{0};">' -f $Color))
                            }
                            else {
                                [string[]]$arr = $line.Replace('><', '>§<') -split ('§')

                                if ($arr[$index + 1].StartsWith('<td')) {
                                    $arr[$index + 1] = $arr[$index + 1].Replace($search.Matches[$index].Value, ('<td style="background:{0};">{1}</td>' -f $Color, $value))
                                    $line = [string]::Join('', $arr)
                                }
                            }
                        }
                    }
                }
            }

            if ($PSCmdlet.ShouldProcess("Replacing intput '$input' with '$line'")) {
                $line
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
