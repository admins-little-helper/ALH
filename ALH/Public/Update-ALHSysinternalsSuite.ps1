<#PSScriptInfo

.VERSION 1.5.0

.GUID 37ba3cb8-5fdd-4b1b-beb1-06a8f4c09c6f

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
    - Initial release

    1.1.0
    - Implemented file compare to copy only changed files.

    1.2.0
    - Implemented parameters 'Clean' and 'CleanAll'.
    - Cleand up code

    1.3.0
    - Added check for starting WebClient service

    1.4.0
    - Cleaned up code

    1.5.0
    - Added pipeline support for destination path

#>


<#

.DESCRIPTION
 Contains a function to install or update SysinternalsSuite.

#>


function Update-ALHSysinternalsSuite {
    <#
    .SYNOPSIS
    Installs or updates SysinternalsSuite.

    .DESCRIPTION
    Installs or updates SysinternalsSuite tools either from any given source path or from https://live.sysinternals.com.
    The function compares the last modified date of the files in the source and destination path and only copies newer files from the source path.

    .PARAMETER SourcePath
    The source path from where to copy SysinternalsSuite tools. Defaults to https://live.sysinternals.com.

    .PARAMETER DestinationPath
    The destination path to which the files should be copied. The folder will be created in case the it does not yet exist.

    .PARAMETER Clean
    If specified, any files in the destination folder that do not exist in the source folder will be deleted before the update.

    .PARAMETER CleanAll
    If specified, all files in the destination folder will be deleted before copying files from the source.

    .EXAMPLE
    Update-ALHSysinternalsSuite -DestinationPath C:\Admin\SysinternalsSuite

    # Install Sysinternals tools from https://live.sysinternals.com to the local path C:\Admin\SysinternalsSuite.

    .EXAMPLE
    Update-ALHSysinternalsSuite -SourcePath \\server\share\SysinternalsSuiteFolder -DestinationPath C:\Admin\SysinternalsSuite

    # Update Sysinternals tools from a local network share.

    .EXAMPLE
    Update-ALHSysinternalsSuite -DestinationPath C:\Admin\SysinternalsSuite -Clean -Verbose

    # Update Sysinternals tools and delete any existing files in the destionation path, that do not exist in the source path. Show verbose output.

    .EXAMPLE
    Update-ALHSysinternalsSuite -DestinationPath C:\Admin\SysinternalsSuite -CleanAll -Verbose

    # Update Sysinternals tools and delete all existing files in the destination path first. Show verbose output.

    .INPUTS
    System.String

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Update-ALHSysinternalsSuite.txt
    #>

    [Cmdletbinding(SupportsShouldProcess, DefaultParametersetName = "default")]
    [Alias("Install-ALHSysinternalsSuite")]
    param (
        [ValidateScript({
                # Check if the given path is valid.
                if (-not (Test-Path -Path $_) ) {
                    throw "Folder does not exist"
                }
                # Check if the given path is a directory.
                if (-not (Test-Path -Path $_ -PathType Container) ) {
                    throw "The Path argument must be a folder. File paths are not allowed."
                }
                return $true
            })]
        [string]
        $SourcePath = "\\live.sysinternals.com\DavWWWRoot\tools",

        [ValidateScript({
                # Check if the given path exists and is valid.
                if (-not (Test-Path -Path $_) ) {
                    Write-Warning -Message "Folder does not exist."
                    if (Test-Path -Path $_ -IsValid) {
                        Write-Warning -Message "The given path is a valid path string. Will create new folder."
                    }
                }
                # Check if the given path is a directory.
                if (-not (Test-Path -Path $_ -PathType Container) ) {
                    throw "The Path argument must be a folder. File paths are not allowed."
                }
                return $true
            })]
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $DestinationPath,

        [Parameter(Mandatory, ParameterSetName = "CleanAll")]
        [switch]
        $CleanAll,

        [Parameter(Mandatory, ParameterSetName = "Clean")]
        [switch]
        $Clean
    )

    begin {
        $startTime = (Get-Date)
        Write-Verbose -Message "Start at --> $StartTime"

        if ($SourcePath -eq "\\live.sysinternals.com\DavWWWRoot\tools" -or $SourcePath -match "^https?://") {
            Write-Verbose -Message "Detected http/https source - assuming WebDav source"
            Write-Verbose -Message "Checking service 'WebClient' to be able to copy data from WebDav source..."

            if ($SourcePath -match "^https?://") {
                Write-Verbose -Message "Convert URL to UNC path..."
                Write-Verbose -Message "--> $SourcePath"
                $SourcePath = $SourcePath -replace "^https?:", ''
                $SourcePath = $SourcePath -replace "/", '\'
                Write-Verbose -Message "--> $SourcePath"
            }

            if (((Get-Service -Name WebClient).Status -ne 'Running')) {
                Write-Verbose -Message "Service 'WebClient' is not running. Trying to start service 'WebClient'. This requires administrator privileges and migth fail."
                try {
                    Start-Service -Name WebClient -ErrorAction Stop
                }
                catch [System.Management.Automation.MethodInvocationException], [Microsoft.PowerShell.Commands.ServiceCommandException] {
                    Write-Verbose -Message "Could not start service 'WebClient'"
                    Write-Verbose -Message "Trying to start it indirectly by running net use..."

                    Start-Process -FilePath "$env:WINDIR\system32\net.exe" -ArgumentList "use $SourcePath" -Wait -WindowStyle Hidden
                }
                catch {
                    Write-Error -Message "Unknown error occured"
                }
            }
            else {
                Write-Verbose -Message "Service 'WebClient' is running already."
            }
        }
    }

    process {
        foreach ($DestinationPathElement in $DestinationPath) {
            $FileUpdateCounter = 0
            $FileSameVersionCounter = 0
            $FileNewCounter = 0
            $FileRemoveCounter = 0

            if (Test-Path -Path $DestinationPathElement -ErrorAction SilentlyContinue) {
                Write-Verbose -Message "Destination path exists."
                if ($CleanAll.IsPresent) {
                    Write-Verbose -Message "Parameter -CleanAll specified. Deleting all files from destination path first..."
                    Get-ChildItem -Path $DestinationPathElement -File -Force -ErrorAction Stop | ForEach-Object {
                        Remove-Item -Path $_.FullName -Force -Confirm:$false -Verbose
                        $FileRemoveCounter = $FileRemoveCounter + 1
                    }
                }

                Write-Verbose -Message "Getting list of files in source directory..."
                $FilesInSource = [ordered]@{}
                Get-ChildItem -Path $SourcePath -File -Force -ErrorAction Stop | ForEach-Object { $FilesInSource.Add($_.Name.Trim([char]0), $_.LastWriteTime) }

                Write-Verbose -Message "Getting list of files in destination directory..."
                $FilesInDestination = [ordered]@{}
                Get-ChildItem -Path $DestinationPathElement -File | ForEach-Object { $FilesinDestination.Add($_.Name.Trim([char]0), $_.LastWriteTime) }

                Write-Verbose -Message "Comparing source and destination files..."
                $FilesInDestiantionNotInSource = $FilesinDestination.Keys | ForEach-Object {
                    if ($FilesinDestination.Contains($_) -and !$FilesInSource.Contains($_)) {
                        $_
                    }
                }

                if ($FilesInDestiantionNotInSource.Count -gt 0) {
                    foreach ($file in $FilesInDestiantionNotInSource) {
                        Write-Verbose -Message "This file exists in destination but not in source folder: $file"

                        if ($Clean.IsPresent) {
                            Write-Verbose -Message "Parameter -Clean specified. Deleting file existing in destination path that do not exist in source path."
                            Remove-Item -Path $(Join-Path -Path $DestinationPathElement -ChildPath $file) -Force -Confirm:$false -Verbose
                            $FileRemoveCounter = $FileRemoveCounter + 1
                        }
                    }
                }

                Write-Information -MessageData "Update started..." -InformationAction Continue

                foreach ($File in $FilesInSource.Keys) {
                    Write-Verbose "Checking file --> $($File)"
                    if ($File) {
                        $SourceFileDate = $FilesInSource["$($File)"]
                        $DestinationFileDate = $FilesinDestination["$($File)"]

                        if ($SourceFileDate -ne $DestinationFileDate) {
                            try {
                                if ($null -eq $DestinationFileDate) {
                                    $FileNewCounter++
                                }
                                else {
                                    $FileUpdateCounter++
                                }

                                $SourceFile = Join-Path -Path $SourcePath -ChildPath $File
                                Copy-Item -LiteralPath "$SourceFile" -Destination "$DestinationPathElement" -Force
                                Write-Information -MessageData "Copied/Updated: $File" -InformationAction Continue
                            }
                            catch {
                                Write-Information -MessageData -Message "An error occurred: $_" -InformationAction Continue
                            }
                        }
                        else {
                            $FileSameVersionCounter++
                            Write-Information -MessageData "Same version/date: $File" -InformationAction Continue
                        }
                    }
                }

                $FilesinDestinationAfterUpdate = [ordered]@{}
                Write-Verbose -Message "Getting files in destination after update..."
                Get-ChildItem -Path $DestinationPathElement -File | ForEach-Object { $FilesinDestinationAfterUpdate.Add($_.Name, $_.LastWriteTime) }
                $FileDiff = $FilesinDestinationAfterUpdate.Count - $FilesInSource.Count

                Write-Information -MessageData "Update finished..." -InformationAction Continue
                Write-Information -MessageData "# of files updated: $FileUpdateCounter" -InformationAction Continue
                Write-Information -MessageData "# of files with same date: $FileSameVersionCounter" -InformationAction Continue
                Write-Information -MessageData "# of files new in destination: $FileNewCounter" -InformationAction Continue
                Write-Information -MessageData "# of files total in source: $($FilesinSource.Count)" -InformationAction Continue
                Write-Information -MessageData "# of files total in destination: $($FilesinDestinationAfterUpdate.Count)" -InformationAction Continue
                Write-Information -MessageData "# of files removed in destination: $FileRemoveCounter" -InformationAction Continue

                Write-Verbose -Message "Comparing source and destination files after update..."
                $FilesInDestiantionNotInSourceAfterUpdate = $FilesinDestinationAfterUpdate.Keys | ForEach-Object {
                    if ($FilesinDestinationAfterUpdate.Contains($_) -and !$FilesInSource.Contains($_)) {
                        $_
                    }
                }

                if ($FilesInDestiantionNotInSourceAfterUpdate.count -gt 0) {
                    Write-Information -MessageData "WARNING: there are more files in the destination folder than in the source folder: $FileDiff" -InformationAction Continue
                }
                else {
                    Write-Verbose -Message "Source and destination contain the same files."
                }
            }
            else {
                try {
                    Write-Information -MessageData "Destination path does not exist. Creating it..." -InformationAction Continue
                    New-Item -Path $DestinationPathElement -ItemType Directory -Force | Out-Null

                    if (Test-Path -Path $DestinationPathElement) {
                        Write-Verbose "Destination path created successfully"
                        Update-ALHSysinternalsSuite -SourcePath $SourcePath -DestinationPath $DestinationPathElement
                    }
                    else {
                        Write-Error "Destination path could not be created"
                    }

                }
                catch {
                    Write-Information -MessageData -Message "An error occurred: $_" -InformationAction Continue
                }
            }
        }
    }

    end {
        Write-Information -MessageData "`nDONE - Elapsed time in seconds: $((((Get-Date) - $startTime).Totalseconds))" -InformationAction Continue
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
