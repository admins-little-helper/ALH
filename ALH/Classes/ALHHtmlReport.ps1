<#PSScriptInfo

.VERSION 1.0.0

.GUID 27f1452e-07e0-4330-84ed-89dd3a898e7e

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS 

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH/

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
    1.0.0
    Initial Release

#>

<# 

.DESCRIPTION 
A PowerShell class for html reports.

#> 

class ALHHtmlReport {
    [string]$HtmlTable
    [string]$HtmlTableFilter
    [PSCustomObject]$HtmlTableCellFormat
    [string]$Title
    [string]$Subtitle
    [string]$InfoText
    [string]$Footer
    [int]$TableRowCount
    [bool]$Sort
    [bool]$Filter
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
