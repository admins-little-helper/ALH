<#PSScriptInfo

.VERSION 1.0.2

.GUID 4792f402-84a6-4418-9dd4-7145433dd58b

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
    1.0
    Initial release

    1.0.1
    - Fixed issue with parameter TargetName for cmdlet Test-Connection when running on PowerShell version < 7.
    Using parameter name "-ComputerName" which works on PowerShell 5 and older and is also available as alias
    on PowerShell version 7 for the cmdlet Test-Connection.

    1.0.2
    - Fixed issue with parameter Ping for cmdlet Test-Connection when running on PowerShell verion < 7.
    The parameter "Ping" was introduced for the cmdlet Test-Connection in PowerShell 7.x and therefore is unknown in older versions of PowerShell.
    Removed this parameter in this function as the default behaviour of the Test-Connection cmdlet is to do a ping.

#>


<#

.DESCRIPTION
 Contains a function to check if a computer is running on battery.

#>


Function Test-ALHIsOnBattery {
    <#
    .SYNOPSIS
    Checks if a computer is running on battery.

    .DESCRIPTION
    Checks if a computer is running on battery.

    .PARAMETER ComputerName
    The name of the computer to check. Defaults to local computer.

    .EXAMPLE
    Test-ALHIsOnBattery

    ComputerName   IsOnBattery ComputerOnline TestStatus          Error
	------------   ----------- -------------- ----------          -----
	MYCOMPUTER                           True NO_BATTERY_DETECTED None

    Check if local computer is running on battery.

    .EXAMPLE
    Test-ALHIsOnBattery -ComputerName "Computer1","Computer2"

    ComputerName   IsOnBattery ComputerOnline TestStatus Error
	------------   ----------- -------------- ---------- -----
	COMPUTER1             True           True SUCCESS    None
	COMPUTER2            False           True SUCCESS    None

    Check if computer1 and computer2 is running on battery.

    .INPUTS
    System.String for parameter 'ComputerName'

    .OUTPUTS
    System.Boolean

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHIsOnBattery.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]
        $ComputerName = $env:COMPUTERNAME
    )

    process {
        foreach ($SingleComputer in $ComputerName) {
            $ComputerOnline = $false
            $ErrorMessage = "None"

            # Set parameters for the 'Get-CimClass' and 'Get-CimInstance' cmdlet.
            $GetCimParams = @{
                ClassName   = 'BatteryStatus'
                Namespace   = 'root/wmi'
                ErrorAction = 'Stop'
            }

            if ($SingleComputer -eq $env:COMPUTERNAME) {
                Write-Verbose -Message "Skipping connection test for local computer."
                $ComputerOnline = $true
            }
            else {
                Write-Verbose -Message "Testing if computer is online: '$SingleComputer'"
                $ComputerOnline = Test-Connection -ComputerName $SingleComputer -Count 2 -Quiet -ErrorAction SilentlyContinue

                # Set also the 'ComputerName' parameter for the Get-CimInstance cmdlet because we're running against a remote computer.
                $GetCimParams.ComputerName = $SingleComputer
            }

            if ($ComputerOnline) {
                Write-Verbose -Message "Checking batttery status for computer: '$SingleComputer'"

                try {
                    Get-CimClass @GetCimParams
                }
                catch [Microsoft.Management.Infrastructure.CimException] {
                    if ($_.Exception -eq "Not found") {
                        Write-Verbose -Message "System does not have a battery."
                    }
                }
                catch {
                    $_
                }

                try {
                    $CheckResult = Get-CimInstance @GetCimParams
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                }
            }
            else {
                Write-Warning -Message "Computer is not reachable: '$SingleComputer'"
            }

            $Result = [PSCustomObject]@{
                ComputerName   = $SingleComputer
                IsOnBattery    = if ($null -ne $CheckResult) {
                    !$CheckResult.PowerOnline
                }
                else {
                    $null
                }
                ComputerOnline = [bool]$ComputerOnline
                TestStatus     = if ($null -ne $CheckResult) {
                    "SUCCESS"
                }
                else {
                    "NO_BATTERY_DETECTED"
                }
                Error          = $ErrorMessage
            }

            $Result
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
