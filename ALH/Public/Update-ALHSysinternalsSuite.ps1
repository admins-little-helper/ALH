<#PSScriptInfo

.VERSION 2.0.0

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

    2.0.0
    - Changed how the script retrieves source files. Instead of using downloading indiviual files via WebDav, now by default the full ZipFile is downloaded and used as source.
#>


<#

.DESCRIPTION
    Contains a function to install or update SysinternalsSuite tools.

.LINK
    https://sysinternals.com

.LINK
    https://live.sysinternals.com

#>


function Update-ALHSysinternalsSuite {
    <#
    .SYNOPSIS
        Installs or updates SysinternalsSuite tools.

    .DESCRIPTION
        Installs or updates SysinternalsSuite tools either from a given source path or from https://live.sysinternals.com.
        The function compares the last modified date of the files in the source and destination path and only copies newer files from the source path.

    .PARAMETER SourcePath
        Specifies the source path from where to copy SysinternalsSuite tools.
        If not specified, 'SysinternalsSuite.zip' from http://download.sysinternals.com/files/ will be downloaded and used as source.
        Allows to specify the keyword 'WebDav' which will then set the SourcePath to 'https://live.sysinternals.com/tools'.

    .PARAMETER DestinationPath
        Specifies the destination path to which the files should be copied. The destination folder will be created in case the it does not yet exist.
        Multiple destination paths can be specified to update SysinternalsSuite for example on multiple remote systems.

    .PARAMETER Clean
        If specified, any file in the destination folder that does not exist in the source folder will be deleted before the update.

    .PARAMETER CleanAll
        If specified, all files in the destination folder will be deleted before copying files from the source.

    .EXAMPLE
        Update-ALHSysinternalsSuite -DestinationPath C:\Admin\SysinternalsSuite

        Install Sysinternals tools by downloading the 'SysinternalsSuite.zip' from http://download.sysinternals.com/files/SysinternalsSuite.zip, expanding the zip file
        and copying the files to the specified destiantion directory 'C:\Admin\SysinternalsSuite'.

    .EXAMPLE
        Update-ALHSysinternalsSuite -SourcePath \\server\share\SysinternalsSuiteFolder -DestinationPath C:\Admin\SysinternalsSuite

        Installing or updating the SysinternalsSuite tools from a local network share.

    .EXAMPLE
        Update-ALHSysinternalsSuite -DestinationPath C:\Admin\SysinternalsSuite -Clean -Verbose

        Install Sysinternals tools by downloading the 'SysinternalsSuite.zip' from http://download.sysinternals.com/files/SysinternalsSuite.zip, expanding the zip file
        and copying the files to the specified destination directory 'C:\Admin\SysinternalsSuite'. All files existing in the destination path that are not found in the
        source zip file, will be removed.

    .EXAMPLE
        Update-ALHSysinternalsSuite -DestinationPath C:\Admin\SysinternalsSuite -CleanAll -Verbose

        Install Sysinternals tools by downloading the 'SysinternalsSuite.zip' from http://download.sysinternals.com/files/SysinternalsSuite.zip, expanding the zip file
        and copying the files to the specified destiantion directory 'C:\Admin\SysinternalsSuite'. All files already existing in the destination path will be removed.

    .INPUTS
        Nothing

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
                if ($_ -eq 'WebDav') {
                    # In case 'WebDav' was specified as SourcePath, set the SourcePath to the live.sysinternals.com webdav path later.
                    $true
                }
                else {
                    # Check if the given path is valid.
                    if (-not (Test-Path -Path $_) ) {
                        throw "Folder does not exist"
                    }

                    # Check if the given path is a directory.
                    if (-not (Test-Path -Path $_ -PathType Container) ) {
                        throw "The Path argument must be a folder. File paths are not allowed."
                    }

                    # This point is only reached if all previous checks have been passed.
                    return $true
                }
            })]
        [Parameter(HelpMessage = "The path to the directory from which the SysinternalsSuite tools should be copied.")]
        [string]
        $SourcePath = "WebDav",

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

                # This point is only reached if all previous checks have been passed.
                return $true
            })]
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "The path(s) to the directory in that the SysinternalsSuite tools should be installed.")]
        [string[]]
        $DestinationPath,

        [Parameter(ParameterSetName = "Clean")]
        [switch]
        $Clean,

        [Parameter(ParameterSetName = "CleanAll")]
        [switch]
        $CleanAll
    )

    begin {
        # Remember when the process started to calculate how much time following actions took.
        $StartTime = (Get-Date)
        Write-Verbose -Message "Start date/time [$StartTime]."

        if ($PSBoundParameters.ContainsKey('SourcePath')) {
            # In case the parameter 'SourcePath' was specified, check it's value.
            if ($SourcePath -eq 'WebDav') {
                # In case 'WebDav' was specified as source, we set the SysinternalsSuite WebDav source.
                $SourcePath = "\\live.sysinternals.com\DavWWWRoot\tools"
                Write-Verbose -Message "Source was specified as 'WebDav'. Set SourcePath to [$SourcePath]."
            }
        }
        else {
            # Otherwise we download the SysinternalsSuite.zip from the web, extract it to a temporary folder und use that temporary folder as source.
            Write-Verbose -Message "No SourcePath was specified. Downloading SysinternalsSuite.zip from Web."

            $TempOutputPath = "$env:TEMP\Update-ALHSysinternalsSuite"

            # Create the temporary output directory.
            $null = New-Item -Path $TempOutputPath -ItemType Directory -Force

            # Define the parameters for the downloading the file.
            $InvokeWebRequestParams = @{
                Uri     = "http://download.sysinternals.com/files/SysinternalsSuite.zip"
                OutFile = "$TempOutputPath/SysinternalsSuite.zip"
            }

            try {
                # Execute the download.
                Invoke-WebRequest @InvokeWebRequestParams

                if (Test-Path -Path "$TempOutputPath\SysinternalsSuite.zip") {
                    # If the download was successful, we should have a valid zip file in the temporary folder.
                    try {
                        # Expand the zip file to a subdirectory of the temporary folder.
                        Expand-Archive -Path "$TempOutputPath\SysinternalsSuite.zip" -DestinationPath "$TempOutputPath\SysinternalsSuite\" -Force
                        $SourcePath = "$TempOutputPath\SysinternalsSuite\"
                    }
                    catch {
                        throw "Error expanding file '$TempOutputPath\SysinternalsSuite.zip' to directory '$TempOutputPath\SysinternalsSuite\'."
                    }
                }
            }
            catch {
                throw "Something went wrong downloading SysinternalsSuite.zip from '$($InvokeWebRequestParams.Uri)'"
            }
        }

        # Check the SourcePath.
        if ($SourcePath -eq "\\live.sysinternals.com\DavWWWRoot\tools" -or $SourcePath -match "^https?://") {
            # Seems a WebDav source was specified...
            Write-Verbose -Message "Detected http/https source - assuming WebDav source"
            Write-Verbose -Message "Checking service 'WebClient' to be able to copy data from WebDav source..."

            if ($SourcePath -match "^https?://") {
                Write-Verbose -Message "Convert URL to UNC path..."
                Write-Verbose -Message "SourcePath: [$SourcePath]."
                $SourcePath = $SourcePath -replace "^https?:", ''
                $SourcePath = $SourcePath -replace "/", '\'
                Write-Verbose -Message "Converted UNC Path: [$SourcePath]."
            }

            # Check the status of the 'WebClient' service and try to start it in case it's not running.
            $WebClientServiceStatus = Get-Service -Name 'WebClient'

            if ($null -eq $WebClientServiceStatus) {
                $ComputerInfo = Get-ComputerInfo -Property OSName
                if ($ComputerInfo.OsName -match "Server") {
                    Write-Warning -Message "It seems the 'WebClient' service is not installed on this system."
                    Write-Warning -Message "This system runs a Windows Server operating system. The 'WebClient' service is not installed on server os by default. You can install it using 'Install-WindowsFeature WebDav-Redirector' and reboot the system."
                    Write-Warning -Message "Alternatively you can run 'Update-SysinternalsSuite' without specifying the parameter 'SourcePath' to download the SysinternalsSuite.zip and use that as source."
                    throw "The service 'WebClient' seems to be not installed on this system."
                }
            }
            else {
                if (($WebClientServiceStatus.Status -ne 'Running')) {
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

        Write-Information -MessageData $("`nElapsed time for preparing update: {0:0.##}" -f $((((Get-Date) - $StartTime).Totalseconds))) -InformationAction Continue
    }

    process {
        foreach ($DestinationPathElement in $DestinationPath) {
            Write-Verbose -Message "`nWorkign on destination path [$DestinationPathElement]."

            # Remember when we start processing the current destination path.
            $LapTime = (Get-Date)

            # Define some counters for showing statistics.
            $FileCounter = @{
                UpdateCounter      = 0
                SameVersionCounter = 0
                NewCounter         = 0
                RemoveCounter      = 0
            }

            # Check if the destination path exists.
            if (Test-Path -Path $DestinationPathElement -ErrorAction SilentlyContinue) {
                Write-Verbose -Message "Destination path exists."
                if ($CleanAll.IsPresent) {
                    Write-Verbose -Message "Parameter -CleanAll specified. Deleting all files from destination path first..."
                    $FilesInDestination = Get-ChildItem -Path $DestinationPathElement -File -Force -ErrorAction Stop
                    foreach ($DestinationFile in $FilesInDestination) {
                        Remove-Item -Path $DestinationFile.FullName -Force -Confirm:$false
                        $FileCounter.RemoveCounter++
                    }
                }

                Write-Verbose -Message "Getting list of files in source directory..."
                $FilesInSourceHT = [ordered]@{}
                $FilesInSource = Get-ChildItem -Path $SourcePath -File -Force -ErrorAction Stop
                foreach ($SourceFile in $FilesInSource) {
                    $FilesInSourceHT.Add($SourceFile.Name.Trim([char]0), $SourceFile.LastWriteTime)
                }

                Write-Verbose -Message "Getting list of files in destination directory..."
                $FilesInDestinationHT = [ordered]@{}
                $FilesInDestination = Get-ChildItem -Path $DestinationPathElement -File
                foreach ($DestinationFile in $FilesInDestination) {
                    $FilesInDestinationHT.Add($DestinationFile.Name.Trim([char]0), $DestinationFile.LastWriteTime)
                }

                Write-Verbose -Message "Comparing source and destination files..."
                $FilesInDestiantionNotInSource = foreach ($Item in $FilesInDestinationHT.Keys) {
                    if ($FilesInDestinationHT.Contains($Item) -and !$FilesInSourceHT.Contains($Item)) {
                        $Item
                    }
                }

                if ($FilesInDestiantionNotInSource.Count -gt 0) {
                    foreach ($File in $FilesInDestiantionNotInSource) {
                        Write-Verbose -Message "This file exists in destination but not in source folder: $File"

                        if ($Clean.IsPresent) {
                            Write-Verbose -Message "Parameter -Clean specified. Deleting file existing in destination path that do not exist in source path."
                            Remove-Item -Path $(Join-Path -Path $DestinationPathElement -ChildPath $file) -Force -Confirm:$false -Verbose
                            $FileCounter.RemoveCounter++
                        }
                    }
                }

                Write-Information -MessageData "`nUpdate started for destination path [$DestinationPathElement]." -InformationAction Continue

                foreach ($File in $FilesInSourceHT.Keys) {
                    Write-Verbose "Checking file [$File]"
                    if ($File) {
                        $SourceFileDate = $FilesInSourceHT["$File"]
                        $DestinationFileDate = $FilesInDestinationHT["$File"]
                        $DestinationFilePath = Join-Path -Path $DestinationPathElement -ChildPath $File

                        if ($SourceFileDate -ne $DestinationFileDate) {
                            try {
                                if ($null -eq $DestinationFileDate) {
                                    $FileCounter.NewCounter++
                                }
                                else {
                                    $FileCounter.UpdateCounter++
                                }

                                $SourceFile = Join-Path -Path $SourcePath -ChildPath $File
                                Copy-Item -LiteralPath "$SourceFile" -Destination "$DestinationPathElement" -Force
                                Write-Information -MessageData "Copied/Updated file: [$DestinationFilePath]" -InformationAction Continue
                            }
                            catch {
                                Write-Information -MessageData "An error occurred: $_.Exception.Message" -InformationAction Continue
                            }
                        }
                        else {
                            $FileCounter.SameVersionCounter++
                            Write-Information -MessageData "Same version/date as source file: [$DestinationFilePath]" -InformationAction Continue
                        }
                    }
                }

                $FilesInDestinationHTAfterUpdate = [ordered]@{}
                Write-Verbose -Message "Getting files in destination after update..."
                $FilesInDestinationAfterUpdate = Get-ChildItem -Path $DestinationPathElement -File
                foreach ($DestinationFileAfterUpdate in $FilesInDestinationAfterUpdate) {
                    $FilesInDestinationHTAfterUpdate.Add($DestinationFileAfterUpdate.Name, $DestinationFileAfterUpdate.LastWriteTime)
                }

                $FileDiff = $FilesInDestinationHTAfterUpdate.Count - $FilesInSourceHT.Count

                Write-Information -MessageData "Update finished..." -InformationAction Continue
                Write-Information -MessageData "# of files updated: $($FileCounter.UpdateCounter)" -InformationAction Continue
                Write-Information -MessageData "# of files with same date: $($FileCounter.SameVersionCounter)" -InformationAction Continue
                Write-Information -MessageData "# of files new in destination: $($FileCounter.NewCounter)" -InformationAction Continue
                Write-Information -MessageData "# of files total in source: $($FilesInSourceHT.Count)" -InformationAction Continue
                Write-Information -MessageData "# of files total in destination: $($FilesInDestinationHTAfterUpdate.Count)" -InformationAction Continue
                Write-Information -MessageData "# of files removed in destination: $($FileCounter.RemoveCounter)" -InformationAction Continue

                Write-Verbose -Message "Comparing source and destination files after update..."
                $FilesInDestiantionNotInSourceAfterUpdate = $FilesInDestinationHTAfterUpdate.Keys | ForEach-Object {
                    if ($FilesInDestinationHTAfterUpdate.Contains($_) -and !$FilesInSourceHT.Contains($_)) {
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
                # Otherwise try to create it.
                try {
                    Write-Information -MessageData "Destination path does not exist. Creating it..." -InformationAction Continue
                    New-Item -Path $DestinationPathElement -ItemType Directory -Force | Out-Null

                    if (Test-Path -Path $DestinationPathElement) {
                        Write-Verbose "Destination path created successfully"
                        # Call the function recursively to finally install SysinternalsSuite.
                        $UpdateALHSysinternalsSuiteParams = @{
                            SourcePath      = $SourcePath
                            DestinationPath = $DestinationPathElement
                            # Parameters -Clean and -CleanAll are not needed here because the destination folder was just created - so it's empty for sure.
                        }
                        Update-ALHSysinternalsSuite @UpdateALHSysinternalsSuiteParams
                    }
                    else {
                        Write-Error "Error creating destination path [$DestinationPathElement]."
                    }

                }
                catch {
                    Write-Information -MessageData -Message "An error occurred: $_.Exception.Message" -InformationAction Continue
                }
            }

            Write-Information -MessageData $("Elapsed time in seconds for current folder: {0:0.##}" -f $((((Get-Date) - $LapTime).Totalseconds))) -InformationAction Continue
        }
    }

    end {
        Write-Verbose -Message "Cleaning up..."
        if (Test-Path -Path "$TempOutputPath") {
            Remove-Item -Path "$TempOutputPath" -Force -Confirm:$false -Recurse
        }

        Write-Information -MessageData $("`nDONE - Total elapsed time in seconds:  {0:0.##}" -f $((((Get-Date) - $StartTime).Totalseconds))) -InformationAction Continue
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
