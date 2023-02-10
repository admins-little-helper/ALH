<#PSScriptInfo

.VERSION 1.4.2

.GUID f1dd360e-d18d-4a35-bcdc-fa1cc17f6498

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
1.0
- Initial release

1.0.1
- Fixed issue with username in report not shown correctly.

1.1.0
- Fixed issue with color code for a cell
- Code clenaup and reformatting
- Made function Set-ALHCellColor to accept pipline input
- Added support for -Row parameter which was not passed from Out-ALHHtml to Set-ALHCellColor
- Changed parameter -HeaderBackgroundColor to support only pre-defined color names
- Added parameter -HeaderBackgroundColorHexcode to support still color hex codes for custom colors
- Added parameter -Font to support only pre-defined fonts
- Added parameter -FontCustom to support specifying a custom font name

1.2.0
- Changed parameter names --> HeaderBackgroundColor* to MainBackgroundColor*
- Removed parameter FontCustom
- Changed parameter Font to allow String instead of ValidatSet values
- Cleaned up code

1.3.0
- Added parmeter MakeSortable
- Added parmeter MakeFilterable

1.4.0
- Added pipeline support

1.4.1
- Fixed handling of data when getting it from pipeline

1.4.2
- Added check for color hex code parameter

#>


<#

.DESCRIPTION
 Contains functions to create a nice looking html report out of a plain html table.

#>

# Vaguely based on 
# https://community.spiceworks.com/scripts/show/2450-change-cell-color-in-html-table-with-powershell-set-cellcolor


function Out-ALHHtml {
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object]
        $Data,

        [string]
        $MainTitle,

        [string]
        $ReportTitle,

        [Parameter(ParameterSetName = "ColorName")]
        [ValidateSet("alhBlue", "Red", "DarkRed", "LightRed", "Yellow", "DarkYellow", "LightYellow", "Blue", "DarkBlue", "LightBlue", "Green", "DarkGreen", "LightGreen", "Purple", "DarkPurple", "LightPurple", "Orange", "DarkOrange", "LighOrange")]
        [string]
        $MainBackgroundColor = "blue",

        [Parameter(ParameterSetName = "ColorCode")]
        [string]
        $MainBackgroundColorHexcode = "#0066a1",

        [string]
        $Font = "Verdana",
        
        [string]
        $LogoText,

        [string]
        $FooterDisclaimerText = "Note: errors and omissions excepted / Hinweis: Alle Angaben ohne Gew&aumlhr",

        [PSCustomObject[]]
        $CellFormat,

        [switch]
        $MakeSortable,

        [switch]
        $MakeFilterable
    )

    begin {
        $Colors = [ordered]@{
            'alhBlue'     = '#0066a1'
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
  
  
        # CSS for the output table...
        [string]$css = @"
<style type=`"text/css`">
    html body        { font-family: $Font; font-size: 12px; height: 100%; margin: 0; overflow: auto; }
    #header          { background: $MainBackgroundColorValue; color: #ffffff; width: 100% }
    #headerTop       { padding: 10px; }
    .logo1           { float: left;  font-size: 24px; font-weight: bold; padding: 0 7px 0 0; }
    .logo2           { float: left;  font-size: 24px; }
    .logo3           { float: right; font-size: 12px; text-align: right; }
    .headerRow       { background: #66a3c7; height: 5px; }
    .reportTitleRow  { background: #000000; color: #ffffff; font-size: 18px; padding: 10px; text-align: left; text-transform: uppercase; }
    .sectionRow      { background: $MainBackgroundColorValue; color: #ffffff; font-size: 13px; padding: 1px 5px!important; font-weight: bold; height: 15px!important; }
    .footer          { background: #000000; color: #ffffff; font-size: 10px; padding: 1px 5px!important; font-weight: bold; height: 15px!important; }
    table            { background: #eaebec; border: #cccccc 1px solid; border-collapse: collapse; margin: 0; width: 100%; }
    table th         { background: #ededed; border-top: 1px solid #fafafa; border-bottom: 1px solid #e0e0e0; border-left: 1px solid #e0e0e0; height: 45px; min-width: 55px; padding: 0px 15px; text-transform: capitalize; }
    table tr         { text-align: center; }
    table td         { border-top: 1px solid #ffffff; border-bottom: 1px solid #e0e0e0; border-left: 1px solid #e0e0e0; height: 55px; min-width: 55px; padding: 0px 10px; }
    table td:first-child           { min-width: 175px; text-align: left; }
    table tr:last-child td         { border-bottom: 0; }
    table tr:hover td              { background: #f2f2f2; }
    table tr:hover td.sectionRow   { background: #0066a1; }
    table tr:nth-child(odd)        { background: #b8d1f3; }
    table tr:nth-child(even)       { background: #dae5f4; }
    table tr:nth-child(odd):hover  { background: #588dbb; }
    table tr:nth-child(even):hover { background: #8994a2; }
</style>
"@

        [string]$SortScript = @"
<script>
function sortTable(ColumnIndex) {
  var table, rows, switching, i, x, y, shouldSwitch, dir, switchcount = 0;
  table = document.getElementById("myTable");
  switching = true;
  // Set the sorting direction to ascending:
  dir = "asc";
  /* Make a loop that will continue until
  no switching has been done: */
  while (switching) {
    // Start by saying: no switching is done:
    switching = false;
    rows = table.rows;
    /* Loop through all table rows (except the
    first, which contains table headers): */
    for (i = 1; i < (rows.length - 1); i++) {
      // Start by saying there should be no switching:
      shouldSwitch = false;
      /* Get the two elements you want to compare,
      one from current row and one from the next: */
      x = rows[i].getElementsByTagName("TD")[ColumnIndex];
      y = rows[i + 1].getElementsByTagName("TD")[ColumnIndex];
      /* Check if the two rows should switch place,
      based on the direction, asc or desc: */
      if (dir == "asc") {
        if (x.innerHTML.toLowerCase() > y.innerHTML.toLowerCase()) {
          // If so, mark as a switch and break the loop:
          shouldSwitch = true;
          break;
        }
      } else if (dir == "desc") {
        if (x.innerHTML.toLowerCase() < y.innerHTML.toLowerCase()) {
          // If so, mark as a switch and break the loop:
          shouldSwitch = true;
          break;
        }
      }
    }
    if (shouldSwitch) {
      /* If a switch has been marked, make the switch
      and mark that a switch has been done: */
      rows[i].parentNode.insertBefore(rows[i + 1], rows[i]);
      switching = true;
      // Each time a switch is done, increase this count by 1:
      switchcount ++;
    } else {
      /* If no switching has been done AND the direction is "asc",
      set the direction to "desc" and run the while loop again. */
      if (switchcount == 0 && dir == "asc") {
        dir = "desc";
        switching = true;
      }
    }
  }
}
</script>
"@

        [string]$FilterScript = @"
<script>
function filterTable(ColumnIndex) {
  var input, filter, table, tr, td, i, txtValue, filterColumn;
  filterColumn = "myInput"+ColumnIndex
  input = document.getElementById(filterColumn);
  filter = input.value.toUpperCase();
  table = document.getElementById("myTable");
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
</script>
"@

        [string]$CurrentDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        [string]$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.ToLower()

        # Page header rows...
        [string]$body = @"
<div id="header"> 
    <div id="headerTop">
        <div class="logo1">$LogoText</div>
        <div class="logo2">$MainTitle</div>
        <div class="logo3">&nbsp;<br/>Generated by $CurrentUser on $CurrentDate</div>
        <div style="clear:both;"></div>
    </div>
    <div style="clear:both;"></div>
</div>
<div class="headerRow"></div>
<div class="reportTitleRow">$ReportTitle</div>
<div class="headerRow"></div>
"@

        <# footer#>
        [string]$footer = @"
<table><tr><td class="sectionRow">$FooterDisclaimerText</td></tr></table>
<p class='footer'>Report created: $CurrentDate || Computername: $env:COMPUTERNAME || Username: $CurrentUser || ScriptPath: $PSCommandPath</p>
"@

        # Add required assemblies
        Add-Type -AssemblyName System.Web, PresentationFramework, PresentationCore
    }

    process {
        [array]$DataToProcess += foreach ($item in $Data) { $item }
    }

    end {
        # Create a full HTML report file that also will be attached to the email
        [string[]]$htmlReport = $DataToProcess | `
                ConvertTo-Html -Head $css -Body $body -PostContent "$footer"
    
        foreach ($Format in $CellFormat) {
            $FilterString = "$($Format.ColumnName) $($Format.Operator) `"$($Format.Value)`""
            $htmlReport = Set-ALHCellColor -InputObject $htmlReport -Filter $FilterString -Color $($Format.Color) -Row:$($Format.Row)
        }

        Write-Verbose -Message "Adding table ID..."
        [regex]$PatternTable = "<table>"
        $htmlReport = $PatternTable.replace($htmlReport, '<table id="myTable">', 1) 
    
        Write-Verbose -Message "Getting column count"
        [int]$ColumnCount = ([regex]::Matches($htmlReport, "<th>")).Count

        if ($MakeSortable.IsPresent) {
            Write-Verbose -Message "Making table headers sortable..."
            [regex]$PatternTH = "<th>"

            0..$ColumnCount | ForEach-Object {
                $htmlReport = $PatternTH.Replace($htmlReport, "<th onclick=`"sortTable($_)`">", 1)
            }

            Write-Verbose -Message "Adding sort script to html code"
            $htmlReport = $htmlReport + "`r`n" + $SortScript
        }

        if ($MakeFilterable.IsPresent) {
            [regex]$PatternMyTable = "<table id=`"myTable`">"

            0..($ColumnCount - 1) | ForEach-Object {
                $htmlReport = $PatternMyTable.Replace($htmlReport, "<input type=`"text`" id=`"myInput$_`" onkeyup=`"filterTable($_)`" placeholder=`"Filter column $($_ + 1)...`" title=`"FilterColumn$($_ + 1)`"> `r`n<table id=`"myTable`">", 1)
            }
        
            Write-Verbose -Message "Adding filter script to html code"
            $htmlReport = $htmlReport + "`r`n" + $FilterScript
        }

        $htmlReport
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
    