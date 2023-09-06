<#PSScriptInfo

.VERSION 1.0.0

.GUID cd8d88e5-9da0-4603-85e9-c0d99392e78d

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

#>


<#

.DESCRIPTION
 Contains a function to retrieve information about scheduled tasks on local or remote systems.

#>


function Get-ALHScheduledTaskInfo {
    <#
    .SYNOPSIS
    Function to retrieve information about scheduled tasks on local or remote systems.

    .DESCRIPTION
    Function to retrieve information about scheduled tasks on local or remote systems.

    .PARAMETER Computer
    One or more names of remote computers to query scheduled task information from.

    .PARAMETER TaskName
    Specifies an array of one or more names of a scheduled task. You can use "*" for a wildcard character query.

    .PARAMETER TaskPath
    Specifies an array of one or more paths for scheduled tasks in Task Scheduler namespace.
    You can use "*" for a wildcard character query. You can use \* for the root folder.
    To specify a full TaskPath you need to include the leading and trailing \.
    If you do not specify a path, the cmdlet uses the root folder.

    .PARAMETER Recurse
    Will make sure that scheduled task information is queried for all specifed task names including subfolders.

    .PARAMETER Credential
    Credentials to get scheduled task info.

    .EXAMPLE
    Get-ALHScheduledTaskInfo -Computer "MyComputer1" -TaskPath "\" -Credential (Get-Credential) -Verbose

    Get a list of all scheduled tasks in root folder on computer named 'MyComputer1' using credentials entered during execution.

    .INPUTS
    String

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHScheduledTaskInfo.txt
    #>

    [CmdletBinding()]
    param(
        [parameter(ValueFromPipeline, HelpMessage = 'Enter one or more computer names')]
        [string[]]$Computer,

        [parameter(HelpMessage = 'Enter one or more task names')]
        [string[]]$TaskName,

        [parameter(HelpMessage = 'Enter one or more paths to scheduled tasks')]
        [string[]]$TaskPath,

        [switch]
        $Recurse,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    process {
        if ($null -eq $Computer) {
            [array]$Computer = $env:COMPUTERNAME
        }

        if ($null -eq $TaskName) {
            [array]$TaskName = "*"
            Write-Verbose -Message "TaskName not specified by parameter. Set it to $TaskName"
        }

        if ($null -eq $TaskPath) {
            [array]$TaskPath = "\$(if ($Recurse.IsPresent) {"*"})"
            Write-Verbose -Message "TaskPath not specified by parameter. Set it to $TaskPath"
        }

        if ($Recurse.IsPresent) {
            $TaskPath = foreach ($Path in $TaskPath) {
                if ($Path -match "^(.*)[\\]$") {
                    Write-Verbose -Message "TaskPath ends with '\'. Recurse parameter specified, so changing TaskPath to '\*'"
                    $Path = "$Path*"
                    $Path
                }

                if (-not ($Path -match "^(.*)[\\][*]$")) {
                    Write-Verbose -Message "TaskPath does not end with '\*'. Recurse parameter specified, so changing TaskPath to '\*'"
                    $Path = "$Path\*"
                    $Path
                }
                else {
                    $Path
                }
            }
        }

        foreach ($SingleComputer in $Computer) {
            Write-Verbose -Message "Trying to get data from computer $SingleComputer"

            if ($SingleComputer -eq $env:COMPUTERNAME) {
                Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue | ForEach-Object {
                    Get-ScheduledTaskInfo $_ | `
                            Select-Object -Property @{Name = 'PSComputerName'; Expression = { $env:COMPUTERNAME } }, `
                            TaskName, `
                            TaskPath, `
                            LastRunTime, `
                            LastTaskResult, `
                            NextRunTime, `
                            NumberOfMissedRuns
                    }
                }
                else {
                    Write-Verbose -Message "Trying to connect to computer $SingleComputer"

                    try {
                        $Session = New-CimSession -ComputerName $SingleComputer -Credential $Credential -ErrorAction Stop
                    }
                    catch {
                        Write-Warning -Message "Connection failed"
                    }

                    if ($null -ne $Session) {
                        Write-Verbose -Message "Successfully connected to computer $SingleComputer"

                        Get-ScheduledTask -CimSession $Session -TaskPath $TaskPath -ErrorAction SilentlyContinue | ForEach-Object {
                            Get-ScheduledTaskInfo $_ | `
                                    Select-Object -Property PSComputerName, `
                                    TaskName, `
                                    TaskPath, `
                                    LastRunTime, `
                                    LastTaskResult, `
                                    NextRunTime, `
                                    NumberOfMissedRuns
                            }

                            Write-Verbose -Message "Disconnecting from computer $SingleComputer"
                            $Session | Remove-CimSession
                        }
                        else {
                            Write-Warning -Message "Could not connect to computer $SingleComputer. Make sure WSMAN connection is possible."
                        }
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
