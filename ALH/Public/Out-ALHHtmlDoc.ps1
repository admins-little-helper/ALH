<#PSScriptInfo

.VERSION 1.3.4

.GUID 1c1ad99a-dbb6-41cb-b269-81b7d2891928

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

	1.1.0
	Added possibility to collapse a section

	1.2.0
	Remove parameter 'AddToc' and added paramter 'AddTableRowToButton'

	1.3.0
	Updated Css.
	Replaced JavaScript code for sorting table function

	1.3.1
	Fixed Css to make tbody vertically scrollable

	1.3.2
	Updated CSS for 'reportFooter'
	Removed replacing linebreaks with '<br/>' html tag because this is done in Out-ALHHtmlReport already
	
	1.3.3
	Updated CSS for showing whole table in a block and remove thead and tbody styles. This way, the header and body columns have the same width
		and the table gets horizontal and vertical scroll bars if it can not be displayed completely.

	1.3.4
	Updated CSS for 'table' element type (set font-size to 12px)

#>

<# 

.DESCRIPTION 
Contains a function to create a html document out of ALHHtmlTables.

Some helpful information was found here:
	https://www.kryogenix.org/code/browser/sorttable/
	https://stackoverflow.com/questions/59282842/how-to-make-sorting-html-tables-faster
#> 


function Out-ALHHtmlDoc {
	<# 
    .SYNOPSIS 
	A PowerShell function to create a html document out of ALHHtmlTables.

    .DESCRIPTION 
	This functions takes one or multiple 'ALHHtmlTable' objects as input and creates a html document.
	The given html tables will be shown one after another in the resulting html document with their own
	titles, subtitles, footers etc.

    .PARAMETER HtmlReport
	One or multiple PFCHtmlReport objects to create the document from.

    .PARAMETER Title
    A title for the document.

	.PARAMETER Subtitle
	A subtitle for the document.

	.PARAMETER Infotext
	This text will be shown in the header.

	.PARAMETER Footer
	This text will be shown at the document footer.

	.PARAMETER MainBackgroundColor
	Color name for the document background color.

	.PARAMETER MainBackgroundColorHexcode
	Color hex code for the document background color.

	.PARAMETER Font
	Font used for the whole html document. Default value is 'Verdana'.

	.PARAMETER FontInfoText
	Font used for the html report info text. Default values is 'Courier New'.

	.PARAMETER AddTableRowCountToButton
	If specified, the value of the 'TableRowCount' property of the ALHHtmlReport class object is added to the button text.

	.EXAMPLE
	Out-ALHHtmlDoc -HtmlReport $HtmlReport -Title "DocTitle" -SubTitle "DocSubtitle" -InfoText "DocInfoText" -Footer "DocFooter" -MainBackgroundColorHexcode "#3366cc" | Out-File -FilePath C:\temp\testhtml4.html

	$HtmlReport = Get-Process | Select-Object -Propert Name,ID | Out-ALHHtmlTable -Title "Process on my computer" -Subtitle "Process list" -Infotext "A list of processes running a my computer" -Footer "Process list at $(Get-Date)" -AddSort -AddFilter

    .INPUTS
	ALHHtmlReport

    .OUTPUTS 
	String

	.NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Out-ALHHtmlDoc.txt
    #>
    
	[CmdletBinding(DefaultParameterSetName = "default")]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[ALHHtmlReport[]]
		$HtmlReport,

		[string]
		$Title = "HTML Report",

		[string]
		$SubTitle,

		[string]
		$InfoText,

		[string]
		$Footer,

		[Parameter(ParameterSetName = "ColorName")]
		[ValidateSet("Red", "DarkRed", "LightRed", "Yellow", "DarkYellow", "LightYellow", "Blue", "DarkBlue", "LightBlue", "Green", "DarkGreen", "LightGreen", "Purple", "DarkPurple", "LightPurple", "Orange", "DarkOrange", "LighOrange")]
		[string]
		$MainBackgroundColor = "blue",

		[Parameter(ParameterSetName = "ColorCode")]
		[string]
		$MainBackgroundColorHexcode = "#0066a1",

		[string]
		$Font = "Verdana",

		[string]
		$FontInfoText = "Courier New",

		[switch]
		$AddTableRowCountToButton
	)

	begin {
		$Colors = [ordered]@{
			'Red'         = '#ff0000'
			'DarkRed'     = '#990000'
			'LightRed'    = '#ffcccc'
			'Yellow'      = '#ffff00'
			'DarkYellow'  = '#ffff00'
			'LightYellow' = '#ffff00'
			'Blue'        = '#0000ff'
			'DarkBlue'    = '#000099'
			'LightBlue'   = '#ccccff'
			'Green'       = '#00ff55'
			'DarkGreen'   = '#009933'
			'LightGreen'  = '#ccffdd'
			'Purple'      = '#cc00cc'
			'DarkPurple'  = '#990099'
			'LightPurple' = '#ffccff'
			'Orange'      = '#ff6600'
			'DarkOrange'  = '#993d00'
			'LighOrange'  = '#ffe0cc'
		}

		if ($PSBoundParameters.ContainsKey('MainBackgroundColor')) {
			$MainBackgroundColorValue = $Colors[$MainBackgroundColor]
		}
		elseif ($PSBoundParameters.ContainsKey('MainBackgroundColorHexcode')) {
			$MainBackgroundColorValue = $MainBackgroundColorHexcode
		}
  
		[string]$CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
		[string]$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.ToLower()
		
		if ([string]::IsNullOrEmpty($MyInvocation.PSCommandPath)) {
			$ScriptPath = "$((Get-Location).Path) --> $($MyInvocation.MyCommand)"
		}
		else {
			$ScriptPath = $MyInvocation.PSCommandPath
		}

		[string]$HtmlDocFooter = @"
			<table id=`"Table_HtmlDocFooter`">
				<tr>
					<td class="docFooter">$Footer</td>
				</tr>
			</table>
			<div class='docSectionRow'>Report created: $CurrentDate &#149; Computername: $env:COMPUTERNAME &#149; Username: $CurrentUser &#149; ScriptPath: $ScriptPath</div>
"@

		[string]$Css = @"
			<style type=`"text/css`">
			html body {
				font-family: $Font;
				font-size: 12px;
				height: 100%;
				margin: 0;
				overflow: auto;
			}
		
			#docHeader {
				background: $MainBackgroundColorValue;
				color: #ffffff;
				width: 100%
			}
		
			#docHeaderTop {
				padding: 10px;
			}
		
			.docTitle {
				float: left;
				font-size: 24px;
				font-weight: bold;
				padding: 0 7px 0 0;
			}
		
			.docSubtitle {
				float: left;
				font-size: 24px;
			}
		
			.docInfoText {
				float: right;
				font-size: 12px;
				text-align: right;
			}
		
			#reportHeader {
				background: $MainBackgroundColorValue;
				color: #ffffff;
				width: 100%;
				margin: 5px 5px 0px 5px;
			}
		
			#reportHeaderTop {
				padding: 10px 10px 10px 20px;
			}
		
			.reportTitle {
				float: left;
				font-size: 20px;
				font-weight: bold;
				padding: 0 7px 0 0;
				width: 100%;
			}
		
			.reportSubtitle {
				float: left;
				font-size: 16px;
				padding: 5px 0 0 20px;
				width: 100%;
			}
		
			.reportInfoText {
				padding: 10px 10px 10px 30px;
				float: left;
				font-family: $FontInfoText;
				font-size: 12px;
				text-align: left;
				color: #ffff00;
			}
		
			.headerRow {
				background: #66a3c7;
				height: 5px;
			}
		
			.reportTitleRow {
				background: #000000;
				color: #ffffff;
				font-size: 18px;
				padding: 10px;
				text-align: left;
			}
		
			.docSectionRow {
				background: #000000;
				color: #ffffff;
				font-size: 12px;
				padding: 3px 5px !important;
				font-weight: bold;
			}
		
			.reportSeparationRow {
				background: #ffffff;
				color: #ffffff;
				font-size: 12px;
				padding: 1px 5px !important;
				font-weight: bold;
				height: 15px !important;
			}
		
			.docFooter {
				background: $MainBackgroundColorValue;
				color: #ffffff;
				font-size: 14px;
				padding: 1px 5px !important;
				font-weight: bold;
				height: 15px !important;
			}
		
			.reportFooter {
				background: #808080;
				color: #ffffff;
				font-size: 12px;
				padding: 1px 5px !important;
				font-weight: bold;
				min-height: 15px !important;
				margin: 5px;
			}
		
			table {
				background: #eaebec;
				border: #cccccc 1px solid;
				border-collapse: collapse;
				margin: 5px;
				width: 100%;
				table-layout: fixed;
				display: block;
				overflow: auto;				
				max-height: 500px;
				text-align: left;
				font-size: 12px;
			}
		
			table th {
				background: #ededed;
				border-top: 1px solid #fafafa;
				border-bottom: 1px solid #e0e0e0;
				border-left: 1px solid #e0e0e0;
				height: 45px;
				min-width: 55px;
				padding: 0px 15px;
			}
		
			table td {
				border-top: 1px solid #ffffff;
				border-bottom: 1px solid #e0e0e0;
				border-left: 1px solid #e0e0e0;
				padding: 0px 10px;
			}
		
			table tr:last-child td {
				border-bottom: 0;
			}
		
			table tr:hover td {
				background: #f2f2f2;
			}
		
			table tr:hover td.sectionRow {
				background: #0066a1;
			}
		
			table tr:nth-child(odd) {
				background: #b8d1f3;
			}
		
			table tr:nth-child(even) {
				background: #dae5f4;
			}
		
			table tr:nth-child(odd):hover {
				background: #588dbb;
			}
		
			table tr:nth-child(even):hover {
				background: #8994a2;
			}
		
			/* Style table header showing up/down arrows based on applied sort order */
			table.sortable th:not(.sorttable_sorted):not(.sorttable_sorted_reverse):not(.sorttable_nosort):after { 
				content: " \25B4\25BE" 
			}

			.line {
				width: 100%;
				height: 47px;
				border-bottom: 1px solid #ffff00;
				margin-left: 20px;
				margin-right: 20px;
			}
		
			/* Style the button that is used to open and close the collapsible content */
			.collapsible {
				background-color: #eee;
				color: #444;
				cursor: pointer;
				padding: 18px;
				width: 100%;
				border: none;
				text-align: left;
				outline: none;
				font-size: 15px;
			}
		
			.collapsible:after {
				content: '\02795';
				/* Unicode character for "plus" sign (+) */
				font-size: 13px;
				color: white;
				float: right;
				margin-left: 5px;
			}
		
			.active:after {
				content: "\2796";
				/* Unicode character for "minus" sign (-) */
			}
		
			.collapsible[value="0"] {
				/* If value of button equals "=", the button background will be made light green */
				background-color: #99e699
			}
		
			/* Add a background color to the button if it is clicked on (add the .active class with JS), and when you move the mouse over it (hover) */
			.active,
			.collapsible:hover {
				background-color: #ccc;
			}
		
			/* Style the collapsible content. Note: hidden by default */
			.content {
				padding: 0 18px;
				background-color: white;
				max-height: 0;
				overflow: hidden;
				transition: max-height 0.2s ease-out;
			}
		</style>
"@

		[string]$SortScript = @'
		<script type="text/javascript">
			/* 
				taken from https://stackoverflow.com/questions/59282842/how-to-make-sorting-html-tables-faster
				and slithly adjusted to also sort text instead of just numbers
			*/

			function sortTableRowsByColumn(table, columnIndex, ascending) {
				const rows = Array.from(table.querySelectorAll(':scope > tbody > tr'));
		
				rows.sort((x, y) => {
					const xValue = x.cells[columnIndex].textContent;
					const yValue = y.cells[columnIndex].textContent;
		
					const xNum = parseFloat(xValue);
					const yNum = parseFloat(yValue);
		
					if (isNaN(xNum)) {
						return ascending ? ('' + x.cells[columnIndex].textContent).localeCompare('' + y.cells[columnIndex].textContent) : ('' + y.cells[columnIndex].textContent).localeCompare('' + x.cells[columnIndex].textContent);
					}
					else {
						return ascending ? (xNum - yNum) : (yNum - xNum);
					}
		
				});
		
				rows.sort();
		
				for (let row of rows) {
					table.tBodies[0].appendChild(row);
				}
			}
		
			function onColumnHeaderClicked(ev) {
				const th = ev.currentTarget;
				const table = th.closest('table');
				const thIndex = Array.from(th.parentElement.children).indexOf(th);
		
				const ascending = !('sort' in th.dataset) || th.dataset.sort != 'asc';
		
				const start = performance.now();
		
				sortTableRowsByColumn(table, thIndex, ascending);
		
				const end = performance.now();
				console.log("Sorted table rows in %d ms.", end - start);
		
				const allTh = table.querySelectorAll(':scope > thead > tr > th');
				for (let th2 of allTh) {
					delete th2.dataset['sort'];
				}
		
				th.dataset['sort'] = ascending ? 'asc' : 'desc';
			}
		</script>
'@

		[string]$FilterScript = @"
			<script type="text/javascript">
				function filterTable(TableId, ColumnIndex) {
					var input, filter, table, tr, td, i, txtValue, filterColumn;
					filterColumn = "myInput_" + TableId + "_" + ColumnIndex
					input = document.getElementById(filterColumn);
					filter = input.value.toUpperCase();
					table = document.getElementById(TableId);
					tr = table.getElementsByTagName("tr");
					for (i = 0; i < tr.length; i++) {
						td = tr[i].getElementsByTagName("td")[ColumnIndex];
						if (td) {
							txtValue = td.textContent || td.innerText;
							if (txtValue.toUpperCase().indexOf(filter) > -1) {
								tr[i].style.display = "";
							} else {
								tr[i].style.display = "none";
							}
						}
					}
				}

				function makeTablesSortable() {
					var coll = document.getElementsByTagName("th");
					var i;

					for (i = 0; i < coll.length; i++) {
						coll[i].addEventListener("click", function () {
							onColumnHeaderClicked(event);
						});
					}
				}
			</script>
"@

		[string]$CollapsScript = @'
			<script type="text/javascript">
				function collapseSection() {
					var coll = document.getElementsByClassName("collapsible");
					var i;
			
					for (i = 0; i < coll.length; i++) {
						coll[i].addEventListener("click", function () {
							this.classList.toggle("active");
							var content = this.nextElementSibling;
			
							if (content.style.maxHeight) {
								content.style.maxHeight = null;
							} else {
								content.style.maxHeight = content.scrollHeight + "px";
							}
						});
					}
				}
			</script>
'@

		[string]$DomLoadedScript = @'			
			<script type="text/javascript">
				document.addEventListener("DOMContentLoaded", function () {
					// do things after the DOM loads partially
					console.log("DOM is loaded");
					collapseSection();
					makeTablesSortable();
				});
			</script>
'@

		$CRLF = "`r`n"	
	}

	process {
		[string]$body = ""

		$body = $body + "<div id=`"docHeader`">"
		$body = $body + "<div id=`"docHeaderTop`">"
		$body = $body + "<div class=`"docTitle`">$Title</div>"
		$body = $body + "<div class=`"docSubtitle`">$SubTitle</div>"
		$body = $body + "<div class=`"docInfoText`">$InfoText</div>"
		$body = $body + "<div style=`"clear:both;`"></div></div>"
		$body = $body + "<div style=`"clear:both;`"></div>"
		$body = $body + "</div>"

		foreach ($SingleReport in $htmlReport) {
			if ($AddTableRowCountToButton.IsPresent) {
				$body = $body + "<button type=`"button`" class=`"collapsible`" value=`"$($SingleReport.TableRowCount)`">[$($SingleReport.TableRowCount)] $($SingleReport.Title)</button>$CRLF"
			}
			else {
				$body = $body + "<button type=`"button`" class=`"collapsible`" value=`"$($SingleReport.TableRowCount)`">$($SingleReport.Title)</button>$CRLF"
			}

			$body = $body + "<div class=`"content`">$CRLF"
			$body = $body + "<div id=`"reportHeader`">$CRLF"
			$body = $body + "<div id=`"reportHeaderTop`">$CRLF"
			$body = $body + "<div class=`"reportTitle`">$($SingleReport.Title)</div>$CRLF"
			$body = $body + "</div>$CRLF"
			$body = $body + "<div class=`"reportSubtitle`">$($SingleReport.SubTitle)</div>$CRLF"
			$body = $body + "<div class=`"line`"></div>"
			$body = $body + "<div class=`"reportInfoText`">$($SingleReport.InfoText)</div>$CRLF"
			$body = $body + "<div style=`"clear:both;`"></div></div>$CRLF"
			$body = $body + "<div style=`"clear:both;`"></div>$CRLF"
			
			if ($SingleReport.Filter) {
				$body = $body + "$($SingleReport.HtmlTableFilter) $CRLF"
			}

			$body = $body + "$($SingleReport.HtmlTable)$CRLF $CRLF"
			$body = $body + "<div class=`"reportFooter`">$($SingleReport.Footer)</div>$CRLF"
			$body = $body + "<div class=`"reportSeparationRow`"> &nbsp; </div>$CRLF"
			$body = $body + "<div style=`"clear:both;`"></div></div>$CRLF"
		}

		$body = ("$body $CRLF $CRLF $HtmlDocFooter")
	}

	end {
		$Head = "$Css $CRLF $CRLF <title>$Title</title>"
		$Head = ("$DomLoadedScript $CRLF $CRLF $Head")
		$Head = ("$CollapsScript $CRLF $CRLF $Head")

		if ($htmlReport.Sort) {
			$Head = ("$SortScript $CRLF $CRLF $Head")
		}

		if ($htmlReport.Filter) {
			$Head = ("$FilterScript $CRLF $CRLF $Head")
		}

		$htmlDoc = ConvertTo-Html -Body $body -Head $Head
		# remove an emtpy table tag added by the ConvertTo-Html
		$htmlDoc = ($htmlDoc | Out-String) -replace "(<table>\s+<\/table>)", ""

		return $htmlDoc
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
