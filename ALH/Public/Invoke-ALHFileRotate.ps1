<#PSScriptInfo

.VERSION 1.0.0

.GUID e003ab87-5857-46dd-b13b-1859eb538678

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) Dieter Koch. All rights reserved.

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH

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
Contains a function to rotate file names by appending a number or date.

#>


function Invoke-ALHFileRotate {
    <#
    .SYNOPSIS
        A PowerShell function to rotate file names by appending a number or date.

    .DESCRIPTION
        This function can be used for log rotation. It searches for a given filename (exact match!) in a given path or multiple paths.
        Path recursion is also supported. If the file is found, it will be renamed based on a given naming schema.
        This can be either appending a number up to a given threshold. Or the file creation date, file creation date and time or the
        file last write date or file last write date and time.

    .PARAMETER Path
        One or multiple valid file paths. Each path will be searched for the file specified for 'FileName' parameter.

    .PARAMETER FileName
        A filename to serach for in the given paths.

	.PARAMETER Threshold
        Default value is 3. The number of files to keep in case the 'Number' naming schema was selected with the 'NamingSchema' parameter.

	.PARAMETER NamingSchema
        Default value is 'Number'. One of the following values is possible:
        'Number', 'CreationDate', 'CreationDateTime', 'LastWriteDate', 'LastWriteDateTime'

	.EXAMPLE
        Invoke-ALHFileRotate -Path C:\temp\testCCC\ -FileName logfile.log -NamingSchema Number -Threshold 9 -Verbose

        Search for a file with name 'logfile.log' in path 'C:\Temp\testCCC'. If found, files will be renamed to 'logfile_x.log'
        where 'x' is the number. At maximum 9 versions of the file will be kept. If more exist alreay, the file with the highest number will be deleted.

	.EXAMPLE
        Invoke-ALHFileRotate -Path C:\temp\testCCC\ -FileName logfile.log -NamingSchema Number -Recurse -Verbose

        Search for a file with name 'logfile.log' in path 'C:\Temp\testCCC' and all subfolders ('Recurse'). If found, files will be renamed to 'logfile_x.log'
        where 'x' is the number. At maximum 3 versions (default value for 'Threshold') of the file will be kept.
        If more exist alreay, the file with the highest number will be deleted.

    .EXAMPLE
        Invoke-ALHFileRotate -Path C:\temp\testCCC\ -FileName logfile.log -NamingSchema LastWriteDateTime -Verbose

        Search for a file with name 'logfile.log' in path 'C:\Temp\testCCC'. If found, files will be renamed to 'logfile_yyyyMMdd-HHmmss.log'
        where 'yyyyMMdd-HHmmss' is the file's last modified date. If a file with that name already exists, it will be deleted.

    .INPUTS
        Nothing

    .OUTPUTS
        Nothing

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Invoke-ALHFileRotate.txt
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0, HelpMessage = 'Enter one or more path names')]
        [string[]]
        $Path,

        [Parameter(Mandatory = $true, HelpMessage = 'Enter exact filename to search for')]
        [string]
        $FileName,

        [Parameter(Mandatory = $false, HelpMessage = 'Enter number of files to keep if Number schema is selected. Ignored for all other schemas')]
        [int]
        $Threshold = 9,

        [ValidateSet("Number", "CreationDate", "CreationDateTime", "LastWriteDate", "LastWriteDateTime")]
        [string]
        $NamingSchema = "Number",

        [switch]
        $Recurse
    )

    begin {
        $StopWatch = [System.Diagnostics.Stopwatch]::new()
        $StopWatch.Start()
    }

    process {
        Write-Verbose -Message "Checking if path(s) exists and is/are accessible"

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

        foreach ($Folder in $FoldersToSearchIn) {
            Write-Verbose -Message "Searching files with exact name '$FileName' in folder $($Folder.FullName)"
            [array]$FilesFoundByFilter = Get-ChildItem -Path $Folder.FullName -Directory:$false -Filter $FileName
            $FileFound = $FilesFoundByFilter.where({ $_.Name -eq $FileName })

            if ($null -eq $FileFound -or $FileFound.Count -eq 0) {
                Write-Warning -Message "No file found with name '$FileName' in folder $($Folder.FullName)"
                continue
            }
            else {
                Write-Verbose -Message "File with name '$FileName' found in folder $($Folder.FullName)"
            }

            switch ($NamingSchema) {
                "Number" {
                    for ($i = $Threshold; $i -ge 0; $i--) {
                        $TargetFileName = Join-Path -Path $FileFound.DirectoryName -ChildPath "$($FileFound.BaseName)_$($i + 1)$($FileFound.Extension)"

                        if ($i -eq 0) {
                            $SourceFileName = $FileFound.FullName
                        }
                        else {
                            $SourceFileName = Join-Path -Path $FileFound.DirectoryName -ChildPath "$($FileFound.BaseName)_$($i)$($FileFound.Extension)"
                        }

                        if (Test-Path -Path $SourceFileName -PathType Leaf) {
                            if ($i -eq $Threshold) {
                                Write-Warning -Message "Deleting file '$SourceFileName' because threshold of $Threshold is reached"
                                Remove-Item -Path $SourceFileName
                            }
                            else {
                                Write-Verbose -Message "Renaming file: '$SourceFileName' ==> '$TargetFileName'"
                                Rename-Item -Path $SourceFileName -NewName $TargetFileName
                            }
                        }
                    }
                }
                "CreationDate" {
                    $TargetFileName = Join-Path -Path $FileFound.DirectoryName -ChildPath "$($FileFound.BaseName)_$(Get-Date -Date $test[-1].CreationTime -Format 'yyyyMMdd')$($FileFound.Extension)"
                }
                "CreationDateTime" {
                    $TargetFileName = Join-Path -Path $FileFound.DirectoryName -ChildPath "$($FileFound.BaseName)_$(Get-Date -Date $test[-1].CreationTime -Format 'yyyyMMdd-HHmmss')$($FileFound.Extension)"
                }
                "LastWriteDate" {
                    $TargetFileName = Join-Path -Path $FileFound.DirectoryName -ChildPath "$($FileFound.BaseName)_$(Get-Date -Date $test[-1].LastWriteTime -Format 'yyyyMMdd')$($FileFound.Extension)"
                }
                "LastWriteDateTime" {
                    $TargetFileName = Join-Path -Path $FileFound.DirectoryName -ChildPath "$($FileFound.BaseName)_$(Get-Date -Date $test[-1].LastWriteTime -Format 'yyyyMMdd-HHmmss')$($FileFound.Extension)"
                }
            }

            if ($NamingSchema -ne "Number") {
                $SourceFileName = $FileFound.FullName
                if (Test-Path -Path $TargetFileName -PathType Leaf) {
                    Write-Warning -Message "Deleting file '$TargetFileName' because it already exists"
                    Remove-Item -Path $TargetFileName
                }
                Write-Verbose -Message "Renaming file: '$SourceFileName' ==> '$TargetFileName'"
                Rename-Item -Path $SourceFileName -NewName $TargetFileName
            }
        }
    }

    end {
        $StopWatch.Stop()
        Write-Verbose -Message "Elapsed time total: $($StopWatch.Elapsed)"

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
