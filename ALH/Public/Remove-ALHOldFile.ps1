<#PSScriptInfo

.VERSION 2.2.0

.GUID ef26e9d5-cfb8-4cb8-bda5-b0b03888ca61

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
1.0.0
- Initial Release

1.1.0
- Added support for -WhatIf parameter
- Added and corrected verbose/error messages in case path is/is not accessible.

1.2.0
- Changed parameter '-Path' type from string to an array of strings to allow specifing multiple paths.
- Added parameter '-Recurse' to be able to deal with subfolders of the given path(s).
- Added parameter '-IncludeHiddenAndSystemFiles' to include hidden or system files in the search.
- Added parameter '-KeepOldest' to reverse the files to keep sort order based on a file's 'LastWriteTime' property.
- Added parameter '-Start' to be able to limit the scope of the file search based on a file's 'LastWriteTime' property.
- Added parameter '-End' to be able to limit the scope of the file search based on a file's 'LastWriteTime' property.
- Added parameter '-TimeSpan' to be able to limit the scope of the file search based on a file's 'LastWriteTime' property.
  TimeSpan is an alternative to parameters -Start and -End.
- Added parameter '-RemoveAllOlderThanStart' to be able to remove all files matching the filename pattern before the given Start date/time.
  This is intended to use for cleaning up all older files than a given Start date/time and therefore only keep files for a given time range.
- Added parameter '-RemoveAllNewerThanEnd' as opposite to '-RemoveAllOlderThanStart'.

1.2.1
- Updated description in examples to be more precise and added another example.

2.0.0
- Renamed function and file from Clear-FileHistory to Remove-ALHOldFile.

2.1.0
- Made function public instead of private within ALH module.

2.2.0
- Made script accept values for paramter Path from pipeline.

#>


<# 

.DESCRIPTION 
Contains function to clean up old files of a given filename pattern.

#> 

function Remove-ALHOldFile {
    <# 
    .SYNOPSIS 
    A PowerShell function to remove old files in a given folder.

    .DESCRIPTION 
    A PowerShell function to remove old files of a given filename pattern in a given folder.
    It's also possible to specify either start and end date/time or a timespan to limit the search results to
    files within that time range (based on LastWriteTime of the file).
    This is can be used for example to clean up old logfiles.

    .PARAMETER Path
    One or more folder paths to search in. The file search is executed for each individual folder.

    .PARAMETER FileNamePattern
    One or more filter strings used to search for filename. Accepts * and ? for wildcards (same as Get-ChildItem).

    .PARAMETER NumOfFilesToKeep
    The number of (newest) files to keep. If ommited, all files will be kept.
    All older (or newer in case '-KeepOldest' is specified) files within the defined scope (=matching FileNamePattern and time range)
    will be deleted.

    .PARAMETER Recurse
    If specified, the specified path(s) are processed recursively. The file search still is done for each individual folder.

    .PARAMETER KeepOldest
    If specified, the function will keep the oldest number of files defined by 'NumOfFilesToKeep', instead of the newest.

    .PARAMETER IncludeHiddenAndSystemFiles
    If specified, the file search will include hidden and system files (equal to 'Get-ChildItem -Force')

    .PARAMETER TimeSpan
    If specified, the file search will only cover files in the given time range calculated from current date/time backwards.

    .PARAMETER Start
    If specified, the file search will only include files with LastWriteTime newer than Start.
    If ommited, the Start will be set to earliest possible date/time (-Year 1 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0)

    .PARAMETER End
    If specified, the file search will only include files with LastWriteTime older than End.
    If ommitted, the current date/time will be used instead.

    .PARAMETER RemoveAllOlderThanStart
    If specified, *ALL* files matching the filter string(s), and older than the specified Start date/time will be deleted.

    .PARAMETER RemoveAllNewerThanEnd
    If specified, *ALL* files matching the filter string(s), and newer than the specified End date/time will be deleted.

    .EXAMPLE
    # Delete files in directory C:\MyScript with pattern "ReportFile*". Keep the newest 14 files and delete all older.
    Remove-ALHOldFile -Path "C:\MyScript" -FileNamePattern "ReportFile*" -NumOfFilesToKeep 14 -Verbose

    .EXAMPLE
    # Delete files in directory C:\MyScript with pattern "ReportFile*". Keep only the newest 3 files last modified within the last 14 days and delete all older.
    Remove-ALHOldFile -Path "C:\MyScript" -FileNamePattern "ReportFile*" -NumOfFilesToKeep 14 -TimeSpan (New-TimeSpan -Days 14) -RemoveAllOlderThanStart -Verbose

    .EXAMPLE
    # Delete files in directory C:\MyScript and all subdirectories with pattern "ReportFile*". Keep only the newest 3 files last modified within the last 14 days and delete all older.
    Remove-ALHOldFile -Path "C:\MyScript" -FileNamePattern "ReportFile*" -NumOfFilesToKeep 14 -TimeSpan (New-TimeSpan -Days 14) -RemoveAllOlderThanStart -Recurse -Verbose

    .EXAMPLE
    # Delete files in directory C:\MyScript with pattern "ReportFile*". Keep the newest 2 files modified between 21 and 14 days ago and delete all older file in the same time range.
    Remove-ALHOldFile -Path "C:\MyScript" -FileNamePattern "ReportFile*" -NumOfFilesToKeep 14 -Start (Get-Date).AddDays(-21) End (Get-Date).AddDays(-14) -Verbose

    .EXAMPLE
    # Delete files in directory C:\MyScript and C:\MyOtherScript with pattern "LogFile*.txt". Keep only the newest 3 files last modified within the last 14 days and delete all older.
    Remove-ALHOldFile -Path "C:\MyScript","C:\MyOtherScript" -FileNamePattern "LogFile*.txt" -NumOfFilesToKeep 14 -TimeSpan (New-TimeSpan -Days 14) -RemoveAllOlderThanStart -Verbose

    .EXAMPLE
    # Keep newest 2 "Logfile*.txt" files for each day within the last 14 days in folder C:\MyScripts\Log
    
    14..1 | ForEach-Object {
        Remove-ALHOldFile -Path "C:\MyScript\Log" -FileNamePattern "LogFile*.txt" -NumOfFilesToKeep 2 -Start (Get-Date).AddDays($_ *-1) -End (Get-Date).AddDays(($_ - 1) *-1) -Verbose
    }

    # Then remove all files older than 14 days
    Remove-ALHOldFile -Path "C:\MyScript\Log" -FileNamePattern "LogFile*.txt" -NumOfFilesToKeep 0 -End (Get-Date).AddDays(-14) -Verbose

    .INPUTS
    Nothing

    .OUTPUTS 
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Remove-ALHOldFile.txt
    #>
    
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParametersetName = "default")]
    param(
        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more path names', Position = 0)]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter filter pattern')]
        [string[]]
        $FileNamePattern,

        [Parameter(Mandatory = $false, HelpMessage = 'Enter number of files to keep for all files matching pattern and timespan/start/end')]
        [int16]
        $NumOfFilesToKeep = -1,

        [switch]
        $Recurse,

        [switch]
        $KeepOldest,

        [switch]
        $IncludeHiddenAndSystemFiles,

        [Parameter(Mandatory = $true, ParameterSetName = "CoverTimeSpan")]
        [timespan]
        $TimeSpan,

        [Parameter(Mandatory = $false, ParameterSetName = "CoverStartEnd")]
        [datetime]
        $Start,

        [Parameter(Mandatory = $false, ParameterSetName = "CoverStartEnd")]
        [datetime]
        $End,

        [Parameter(Mandatory = $false, ParameterSetName = 'CoverTimeSpan')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CoverStartEnd')]
        [switch]
        $RemoveAllOlderThanStart,

        [Parameter(Mandatory = $false, ParameterSetName = 'CoverTimeSpan')]
        [Parameter(Mandatory = $false, ParameterSetName = 'CoverStartEnd')]
        [switch]
        $RemoveAllNewerThanEnd
    )

    begin {
    }

    process {
        Write-Verbose -Message "Checking if path exists and is accessible"

        [array]$FoldersToSearchIn = foreach ($SinglePath in $Path) {
            if (Test-Path -Path $SinglePath -PathType Container) {
                Write-Verbose -Message "Path is a directory, exists and is accessible: $SinglePath"
                
                [array]$FolderList = Get-Item -Path $SinglePath
                if ($Recurse.IsPresent) {
                    $FolderList = $FolderList + (Get-ChildItem -Path $SinglePath -Recurse -Directory)
                }

                Write-Verbose -Message "Number of folders to check: $(($FolderList | Measure-Object).Count)"
                
                Write-Verbose -Message "Folders to check: "
                foreach ($FolderItem in $FolderList) {
                    Write-Verbose -Message " --> $($FolderItem.FullName)"
                }
            }
            else {
                Write-Warning -Message "Path is not a directory, does not exist or is not accessible: $SinglePath"
            }
            $FolderList
        }

        if ($null -eq $FoldersToSearchIn -or ($FoldersToSearchIn | Measure-Object).Count -eq 0) {
            Write-Error -Message "No valid path specified. Stopping process."
            break
        }

        if ($Start -gt (Get-Date)) {
            Write-Error -Message "Start is in future. Stopping process."
            break
        }

        if ($null -ne $TimeSpan) {
            Write-Verbose -Message "Timespan specified. Calculating start date/time based on timespan from now on backwards."
            $Start = (Get-Date).AddTicks($TimeSpan.Ticks)
        }

        if ($null -eq $Start) {
            Write-Verbose -Message "Start date/time not specified. Setting it to earliest possible time."
            $Start = Get-Date -Year 1 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
        }

        if ($null -eq $End) {
            Write-Verbose -Message "End date/time not specified. Setting it to current date/time."
            $End = Get-Date
        }

        if ($Start -gt $End) {
            Write-Error -Message "Specified Start date/time is greater than End date/time. Stopping process."
            break
        }
        
        if ($NumOfFilesToKeep -le -1) {
            Write-Verbose -Message "No files will be deleted."
        }
        else {
            Write-Verbose -Message "Start date/time: $Start"
            Write-Verbose -Message "End date/time: $End"

            foreach ($Folder in $FoldersToSearchIn) {
                $FilesToDelete = $null

                foreach ($pattern in $FileNamePattern) {
                    Write-Verbose -Message "Searching files with pattern '$pattern' in folder $($Folder.FullName)"
                    [array]$FilesFoundByPattern = Get-ChildItem -Path $Folder.FullName -Directory:$false -Filter $pattern -Force:$IncludeHiddenAndSystemFiles.IsPresent
                    $NumFilesFoundMatchingPattern = ($FilesFoundByPattern | Measure-Object).Count
                    Write-Verbose -Message "Number of files found matching pattern: $NumFilesFoundMatchingPattern in folder $($Folder.FullName)"

                    [array]$FilesAlsoMatchingTimeSpan = $FilesFoundByPattern.where({ $_.LastWriteTime -ge $Start -and $_.LastWriteTime -le $End })
                    $NumFilesFoundTotal = ($FilesAlsoMatchingTimeSpan | Measure-Object).Count
                    Write-Verbose -Message "Number of files found matching pattern and given timespan/start/end: $NumFilesFoundTotal in folder $($Folder.FullName)"
            
                    $NumFilesToDelete = $NumFilesFoundTotal - $NumOfFilesToKeep
                    if ($NumFilesToDelete -gt 0) {
                        Write-Verbose -Message "Number of old files to delete: $NumFilesToDelete"
                        [array]$FilesToDelete = $FilesAlsoMatchingTimeSpan | Sort-Object -Property LastWriteTime -Descending:$($true -and $KeepOldest.IsPresent) | Select-Object -First $NumFilesToDelete
                    }
                    else {
                        Write-Verbose -Message "Number of files to keep is greater than files found - nothing to delete within timespan for search pattern."
                    }

                    if ($RemoveAllOlderThanStart.IsPresent) {
                        Write-Verbose -Message "Parameter 'RemoveAllOlderThanStart' specified. Adding ALL files older than start date/time to delete list."
                        $AdditionalFilesOlderThanStart = $FilesFoundByPattern.where({ $_.LastWriteTime -lt $Start })
                        $FilesToDelete = $FilesToDelete + $AdditionalFilesOlderThanStart
                        Write-Verbose -Message "Number of files found to be older thand start date/time: $(($AdditionalFilesOlderThanStart | Measure-Object).Count) in folder $($Folder.FullName)"
                    }

                    if ($RemoveAllNewerThanEnd.IsPresent) {
                        Write-Verbose -Message "Parameter 'RemoveAllNewerThanEnd' specified. Adding ALL files older than start date/time to delete list."
                        $AdditionalFilesNewerThanEnd = $FilesFoundByPattern.where({ $_.LastWriteTime -gt $End })
                        $FilesToDelete = $FilesToDelete + $AdditionalFilesNewerThanEnd
                        Write-Verbose -Message "Number of files found to be older thand start date/time: $(($AdditionalFilesNewerThanEnd | Measure-Object).Count) in folder $($Folder.FullName)"
                    }
                }
                
                if ($null -ne $FilesToDelete) {
                    Write-Verbose -Message "Deleting files..."
                    $FilesToDelete | Remove-Item -Verbose
                    Write-Verbose -Message "Total number of files deleted in folder $($Folder.FullName) --> $(($FilesToDelete | Measure-Object).Count)"
                }
            }
        }
    }

    end {
        Write-Verbose -Message "DONE"
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
