<#PSScriptInfo

.VERSION 1.0.0

.GUID 4d46bf47-f49f-4418-abfd-5d9d4bfa7467

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
Contains a function to trigger the baseline evaluation on a Configuration Manger client.

#>


function Invoke-ALHCMBaselineEvaluation {
    <#
    .SYNOPSIS
	    Triggers the baseline evaluation on a Configuration Manger client.

    .DESCRIPTION
	    The function 'Invoke-ALHCMBaselineEvaluation' triggers the baseline evaluation on a Configuration Manger client.

    .PARAMETER ComputerName
	    Computer to check. Default is the local computer.

    .EXAMPLE
	    Invoke-CMBaselineEvaluation -BaselineName "MyBaseline1"

        Triggers the evaluation of baseline with name "MyBaseline1" on the local computer.

    .EXAMPLE
    	Invoke-CMBaselineEvaluation

        Triggers the evaluation of all baselines on the local computer.

    .EXAMPLE
	    Invoke-CMBaselineEvaluation -ComputerName CLIENT01 -BaselineName "Baseline XYZ"

        Triggers the evaluation of baseline with name "Baseline XYZ" on the remote computer named "CLIENT01".

    .INPUTS
        System.String for parameter 'ComputerName'

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
	    Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Invoke-ALHCMBaselineEvaluation.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(ValueFromPipeline)]
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
                $Baseline = $null

                Write-Verbose -Message "Trying to run on computer: $SingleComputer"
                try {
                    Write-Verbose -Message "Trying to enumerate the baselines existing on computer '$SingleComputer'"
                    $Baseline = Get-CimInstance @GetCimInstanceParams | Where-Object { $_.DisplayName -like $BaselineName }
                }
                catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Warning -Message "Error enumerating baselines on computer '$SingleComputer': $ErrorMessage"
                }

                foreach ($BaselineItem in $Baseline) {
                    $Result = [PSCustomObject]@{
                        ComputerName                 = $SingleComputer
                        BaselineName                 = $BaselineItem.Name
                        BaselineDisplayName          = $BaselineItem.DisplayName
                        BaselineVersion              = $BaselineItem.Version
                        BaselineLastEvalTime         = $BaselineItem.LastEvalTime
                        BaselineStatus               = $BaselineItem.Status
                        BaselineLastComplianceStatus = $BaselineItem.LastComplianceStatus
                        ReturnValue                  = $null
                        JobId                        = $null
                        Error                        = $null
                    }

                    Write-Verbose -Message "Triggering Baseline $($BaselineItem.Name)"

                    try {
                        Write-Verbose -Message "Trying to trigger baseline '$($BaselineItem.Name)' on computer '$SingleComputer'"
                        $BaselineObj = [wmiclass]"\\$SingleComputer\$($GetCimInstanceParams.Namespace):$($GetCimInstanceParams.ClassName)"
                        $TriggerResult = $BaselineObj.TriggerEvaluation($BaselineItem.Name, $BaselineItem.Version)
                        $Result.ReturnValue = $TriggerResult.ReturnValue
                        $Result.JobId = $TriggerResult.JobId
                    }
                    catch {
                        $ErrorMessage = $_.Exception.Message
                    }

                    $Result.Error = $ErrorMessage
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
