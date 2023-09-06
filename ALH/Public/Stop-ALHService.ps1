<#PSScriptInfo

.VERSION 1.0.3

.GUID f2717702-3f1d-4207-8c86-cc0138cc9cfb

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

1.0.1
- Fixed issue in correctly determining service status and service state.

1.0.2
- Fixed typo.

1.0.3
- Changed message output.

#>


<#

.DESCRIPTION
Contains function to stop a service. Support running on a remote computer.
#>


function Stop-ALHService {
    <#
    .SYNOPSIS
	The function 'Stop-ALHService' stops a service or kills the service process.

    .DESCRIPTION
	The function 'Stop-ALHService' stops a service or kills the service process if it's in the degraded state.
    Can be run locally or on a remote computer. Requires WMI access.

    .PARAMETER ComputerName
	The name of the remote computer to stop the service on.

    .PARAMETER ServiceName
    The name of the service to stop.

    .PARAMETER KillDegraded
    If specified, the process of a services that is in status 'DEGRADED' will be killed. Normally running services will not be stopped.

    .EXAMPLE
	Stop-ALHService -ComputerName RemoteComputer -ServiceName wuauserv -KillDegraded

    Kills the Windows Update service if it's in degraded state on RemoteComputer.

    .EXAMPLE
	@(Computer1, Computer2, Computer3) | Stop-ALHService -ServiceName wuauserv -KillDegraded

    Kills the Windows Update service if it's in degraded state on Computer1, Computer2 and Computer3.

    .INPUTS
    System.String for parameter 'ComputerName'

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
	Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Stop-ALHService.txt
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $ComputerName = "Localhost",

        [Parameter(Mandatory = $true)]
        [string[]]
        $ServiceName,

        [switch]
        $KillDegraded
    )

    begin {
        $ProcessTerminateReturnCodes = @{
            0          = "Successful completion"
            2          = "Access denied"
            3          = "Insufficient privilege"
            8          = "Unknown failure"
            9          = "Path not found"
            21         = "Invalid parameter"
            22         = "Other"
            4294967295 = "Other"
        }

        $ServiceActionReturnCodes = @{
            0  = "The request was accepted."
            1  = "The request is not supported."
            2  = "The user did not have the necessary access."
            3  = "The service cannot be stopped because other services that are running are dependent on it."
            4  = "The requested control code is not valid, or it is unacceptable to the service."
            5  = "The requested control code cannot be sent to the service because the state of the service (Win32_BaseService.State property) is equal to 0, 1, or 2."
            6  = "The service has not been started."
            7  = "The service did not respond to the start request in a timely fashion."
            8  = "Unknown failure when starting the service."
            9  = "The directory path to the service executable file was not found."
            10 = "The service is already running."
            11 = "The database to add a new service is locked."
            12 = "A dependency this service relies on has been removed from the system."
            13 = "The service failed to find the service needed from a dependent service."
            14 = "The service has been disabled from the system."
            15 = "The service does not have the correct authentication to run on the system."
            16 = "This service is being removed from the system."
            17 = "The service has no execution thread."
            18 = "The service has circular dependencies when it starts."
            19 = "A service is running under the same name."
            20 = "The service name has invalid characters."
            21 = "Invalid parameters have been passed to the service."
            22 = "The account under which this service runs is either invalid or lacks the permissions to run the service."
            23 = "The service exists in the database of services available from the system."
            24 = "The service is currently paused in the system."
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            foreach ($Service in $ServiceName) {
                try {
                    Write-Verbose -Message "Computer [$Computer]: trying to get service on computer."

                    $GetCimInstanceServiceParam = @{
                        Class  = "Win32_Service"
                        Filter = "Name LIKE '$Service'"
                    }

                    if ($Computer -ne "Localhsot") {
                        $GetCimInstanceServiceParam.ComputerName = $Computer
                    }

                    $ServiceObject = Get-CimInstance @GetCimInstanceServiceParam

                    if ($null -ne $ServiceObject) {
                        if ($ServiceObject.Status -eq "Degraded") {
                            Write-Warning -Message "Computer [$Computer]: Service [$Service] is in state [$($ServiceObject.State)] with status [$($ServiceObject.Status)]."
                        }
                        else {
                            Write-Information -MessageData "Computer [$Computer]: Service [$Service] is in state [$($ServiceObject.State)] with status [$($ServiceObject.Status)]." -InformationAction Continue
                        }

                        switch ($ServiceObject.State) {
                            "Stop pending" {
                                if ($ServiceObject.Status -eq "Degraded") {
                                    if ($KillDegraded.IsPresent) {
                                        $GetCimInstanceProcessParam = @{
                                            Class  = "Win32_Process"
                                            Filter = "ProcessId='$($ServiceObject.ProcessId)'"
                                        }
                                        if ($Computer -ne "Localhost") { $GetCimInstanceProcessParam.ComputerName = $Computer }

                                        $ServiceProcess = Get-CimInstance @GetCimInstanceProcessParam

                                        $InvokeCimMethodParams = @{
                                            InputObject = $ServiceProcess
                                            Method      = "Terminate"
                                        }
                                        if ($Computer -ne "Localhost") { $InvokeCimMethodParams.ComputerName = $Computer }

                                        if ($PSCmdlet.ShouldProcess("Terminating service process '$ServiceProcess' on computer '$Computer'")) {
                                            $ReturnVal = Invoke-CimMethod @InvokeCimMethodParams
                                            $ReturnValInt32 = [convert]::ToInt32($ReturnVal.ReturnValue, 10)

                                            if ($ReturnVal -eq 0) {
                                                Write-Information -MessageData "Computer [$Computer] - [$Service]: Process terminate return code: $($ProcessTerminateReturnCodes[$ReturnValInt32])" -InformationAction Continue
                                            }
                                            else {
                                                Write-Warning -Message "Computer [$Computer] - [$Service]: Process terminate return code: $($ProcessTerminateReturnCodes[$ReturnValInt32])"
                                            }
                                        }
                                    }
                                }
                            }
                            "Running" {
                                if (-not ($KillDegraded)) {
                                    $InvokeCimMethodParams = @{
                                        InputObject = $ServiceObject
                                        Method      = "StopService"
                                    }
                                    if ($Computer -ne "Localhost") { $InvokeCimMethodParams.ComputerName = $Computer }

                                    if ($PSCmdlet.ShouldProcess("Stopping service '$Service' on computer '$Computer'")) {

                                        $ServiceStopStatus = Invoke-CimMethod @InvokeCimMethodParams
                                        $ServiceStopStatusInt32 = [convert]::ToInt32($ServiceStopStatus.ReturnValue, 10)

                                        if ($ServiceStopStatusInt32 -eq 0) {
                                            Write-Information -MessageData "Computer [$Computer] - [$Service]: Service action return code: $($ServiceActionReturnCodes[$ServiceStopStatusInt32])" -InformationAction Continue
                                        }
                                        else {
                                            Write-Warning -Message "Computer [$Computer] - [$Service]: Service action return code: $($ServiceActionReturnCodes[$ServiceStopStatusInt32])"
                                        }
                                    }
                                }
                                else {
                                    Write-Information -MessageData "Service is running but '-KillDegraded' was specified. Only stopping if in degraded state." -InformationAction Continue
                                }
                            }
                            "Stopped" {
                                Write-Information -MessageData "Computer [$Computer]: Service [$Service] is already stopped." -InformationAction Continue
                            }
                        }
                    }
                    else {
                        Write-Warning -Message "Computer [$Computer]: Service [$Service] not found on computer."
                    }
                }
                catch {
                    Write-Error $_
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
