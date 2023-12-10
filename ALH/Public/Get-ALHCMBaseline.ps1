
<#PSScriptInfo

.VERSION 1.0.0

.GUID cd2fe7d0-d9da-4203-b8d2-b6932bcf5b24

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
 - Initial Release

#>


<#

.DESCRIPTION
Contains function to get a list of baselines on a Configuration Manger client.

#>


function Get-ALHCMBaseline {
    <#
    .SYNOPSIS
	    Gets a list of baselines on a Configuration Manger client.

    .DESCRIPTION
	    The function 'Get-ALHCMBaseline' gets a list of baselines on a Configuration Manger client.

    .PARAMETER ComputerName
	    Computer to check. Default is the local computer.

    .EXAMPLE
	    Get-ALHCMBaseline -BaselineName "MyBaseline1"

        Triggers the evaluation of baseline with name "MyBaseline1" on the local computer.

    .EXAMPLE
    	Get-ALHCMBaseline

        Triggers the evaluation of all baselines on the local computer.

    .EXAMPLE
	    Get-ALHCMBaseline -ComputerName CLIENT01 -BaselineName "Baseline XYZ"

        Triggers the evaluation of baseline with name "Baseline XYZ" on the remote computer named "CLIENT01".

    .INPUTS
        System.String for parameter 'ComputerName'

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
	    Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHCMBaseline.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [string]
        $BaselineName = "*"
    )

    process {
        foreach ($SingleComputer in $ComputerName) {
            $ComputerOnline = $false
            $ErrorMessage = "None"

            # Set parameters for the Get-CimInstance cmdlet
            $GetCimInstanceParams = @{
                Namespace   = 'root\ccm\dcm'
                ClassName   = 'SMS_DesiredConfiguration'
                ErrorAction = 'Stop'
            }
            if ($SingleComputer -eq $env:COMPUTERNAME) {
                Write-Verbose -Message "Skipping connection test for local computer."
                $ComputerOnline = $true
            }
            else {
                Write-Verbose -Message "Testing if computer is online: $SingleComputer"
                $GetCimInstanceParams.ComputerName = $SingleComputer
                $ComputerOnline = Test-Connection -ComputerName $SingleComputer -Count 2 -Quiet -ErrorAction SilentlyContinue
            }

            if ($ComputerOnline) {
                $Baselines = $null

                Write-Verbose -Message "Trying to run on computer: $SingleComputer"
                try {
                    Write-Verbose -Message "Trying to enumerate the baselines existing on computer '$SingleComputer'"
                    $Baselines = Get-CimInstance @GetCimInstanceParams
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Warning -Message "Error enumerating baselines on computer '$SingleComputer': $ErrorMessage"
                }

                foreach ($BaselineItem in $Baselines) {
                    $Result = [PSCustomObject]@{
                        ComputerName                 = $SingleComputer
                        BaselineName                 = $BaselineItem.Name
                        BaselineDisplayName          = $BaselineItem.DisplayName
                        BaselineVersion              = $BaselineItem.Version
                        BaselineLastEvalTime         = $BaselineItem.LastEvalTime
                        BaselineStatus               = $BaselineItem.Status
                        BaselineLastComplianceStatus = $BaselineItem.LastComplianceStatus
                    }

                    $Result
                }
            }
            else {
                Write-Warning "Computer is not reachable: $SingleComputer"
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
