<#PSScriptInfo

.VERSION 1.0.7

.GUID 6f529bee-9368-4255-854b-1dde3fc76e86

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) Dieter Koch. All rights reserved.

.TAGS 

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
    1.0.0
    Initial Release

	1.0.1
	Fixed handling of $null value on input data

	1.0.2
	Fixed handling of $null parameter value for parameter 'Data'

	1.0.3
	Added html tags <thead> and <tbody> to html tabl code.
	Changed how a html table becomes sortable (just adding class and later use javascript to add click event)

	1.0.4
	Fixed issue in applying CellFormat correctly

	1.0.5
	Fixed issue in applying <tbody> and <thead> tags corretly in array of strings (instead of a single big string)
	
	1.0.6
	Fixed TableRowCount in case it's one ('.Count' only works for arrays, not for a single object)

	1.0.7
	Replaced linebreaks with "<br/>" html tag for title, subtitle, infotext and footer
#>

<# 

.DESCRIPTION 
Contains a function to create a html table fragment

#> 


function Out-ALHHtmlReport {
    <# 
    .SYNOPSIS 
    A PowerShell function to create a html table fragment.

    .DESCRIPTION 
    This functions takes an object or an array of objects and creates a html table fragment out of it.
    Additionally it allows to format cells in the table based on filter expressions. It also can make a table sortable and filterable.
    The returned ALHHtmlReport object can then be used as input in function 'Out-HtmlDoc' function to create a complete html document.

    .PARAMETER Data
    An objet or an array of objects which will be displayed in the html table.

    .PARAMETER Title
    A title for the report (html table).

	.PARAMETER Subtitle
    A subtitle for the report (html table).

	.PARAMETER Infotext
    This text will be shown above the table.

	.PARAMETER Footer
	This text will be shown below the table.

	.PARAMETER CellFormat
	A hashtable specifying the parameters and values for the function Set-CelLColor to format
    the html table cells based on filter expressions.

	.PARAMETER AddSort
    If specified, the table will be made sortable.

	.PARAMETER AddFilter
	If specified, the table will be filterable.

	.EXAMPLE
    Get-Process | Select-Object -Propert Name,ID | Out-ALHHtmlReport -Title "Process on my computer" -Subtitle "Process list" -Infotext "A list of processes running a my computer" -Footer "Process list at $(Get-Date)" -AddSort -AddFilter

    .INPUTS
    Object

    .OUTPUTS 
    ALHHtmlReport

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Out-ALHHtmlReport.txt

    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)][AllowNull()]
        [object]
        $Data,

        [string]
        $Title,

        [string]
        $SubTitle,

        [string]
        $InfoText,

        [string]
        $Footer,

        [PSCustomObject[]]
        $CellFormat,

        [switch]
        $AddSort,

        [switch]
        $AddFilter
    )

    $CRLF = "`r`n"
    $MyALHHtmlReport = New-Object -TypeName ALHHtmlReport

    if ($null -ne $Data) {
        if ($Data -is [array]) {
            $DataProperties = Get-Member -InputObject $Data[0] -MemberType Property, AliasProperty, NoteProperty, ScriptProperty, CodeProperty            	
        }
        else {
            $DataProperties = Get-Member -InputObject $Data -MemberType Property, AliasProperty, NoteProperty, ScriptProperty, CodeProperty            
        }
    }
	
    Write-Verbose -Message "Collected object member properties: $($DataProperties -join ", ")"

    $MyTableId = "Table_$(New-Guid)"
    Write-Verbose -Message "Created unique table name: '$MyTableId'"

    $htmlTable = $Data | ConvertTo-Html -Fragment

    Write-Verbose -Message "Applying conditional cell format..."
    foreach ($Format in $CellFormat) {
        $FilterString = "$($Format.ColumnName) $($Format.Operator) `"$($Format.Value)`""
        $htmlTable = Set-CellColor -InputObject $htmlTable -Filter $FilterString -Color $($Format.Color) -Row:$($Format.Row)
    }
        
    $htmlTable = foreach ($line in $htmlTable) {
        $line -replace "<table>", "<table id=`"$MyTableId`">"
    }

    if ($AddSort.IsPresent) {
        Write-Verbose -Message "Adding class 'sortable' to table so it becomes sortable later..."
        $htmlTable = foreach ($line in $htmlTable) {
            $line -replace "<table id=`"$MyTableId`">", "<table id=`"$MyTableId`" class=`"sortable`">" 
        }
    }

    if ($AddFilter.IsPresent) {
        Write-Verbose -Message "Making table filterable..."
        $i = 0
                
        $FilterInput = foreach ($DataProperty in $DataProperties) {
            "<input type=`"text`" id=`"myInput_$MyTableId`_$i`" onkeyup=`"filterTable('$MyTableId', $i)`" placeholder=`"Filter Column $i...`" title=`"Filter_Col_$i`">$CRLF"
            $i++
        }
    }

    Write-Verbose -Message "Adding <thead> and <tbody> element tags..."
    $htmlTable = $htmlTable -replace "(<tr><th)", "<thead><tr><th"
    $htmlTable = $htmlTable -replace "(</th></tr>)", "</th></tr></thead><tbody>"
    $htmlTable = $htmlTable -replace "(</table>)", "</tbody></table>"

    $MyALHHtmlReport.HtmlTable = $htmlTable
    $MyALHHtmlReport.HtmlTableFilter = $FilterInput
    $MyALHHtmlReport.HtmlTableCellFormat = $CellFormat
    $MyALHHtmlReport.Sort = $AddSort.IsPresent
    $MyALHHtmlReport.Filter = $AddFilter.IsPresent
    $MyALHHtmlReport.Title = $Title -replace "`r`n", "`r`n<br/>"
    $MyALHHtmlReport.Subtitle = $SubTitle -replace "`r`n", "`r`n<br/>"
    $MyALHHtmlReport.InfoText = $InfoText -replace "`r`n", "`r`n<br/>"
    $MyALHHtmlReport.Footer = $Footer -replace "`r`n", "`r`n<br/>"
    $MyALHHtmlReport.TableRowCount = $($Data | Measure-Object).Count

    return $MyALHHtmlReport
    Write-Verbose -Message "Done"
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
