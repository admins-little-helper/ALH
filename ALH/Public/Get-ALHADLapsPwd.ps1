<#PSScriptInfo

.VERSION 1.0.0

.GUID f4522bed-6942-452a-9b5a-3bc325efc1ba

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS LAPS, AD, Active Directory

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH

.ICONURI

.EXTERNALMODULEDEPENDENCIES EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    1.0.0
    Initial release

#>


<#

.DESCRIPTION
Contains function to retrieve the LAPS Password for computer account from Active Directory.
This functions is a proxy function for the 'Get-ADComputer' cmdlet.

.LINK
https://github.com/admins-little-helper/ALH

#>


function Get-ALHADLapsPwd {
    <#
    .SYNOPSIS
    Retrieves the LAPS Password for a computer account from Active Directory.

    .DESCRIPTION
    The function 'Get-ALHADLapsPwd' retrieves the LAPS Password for a computer account from Active Directory.
    This functions is a proxy function for the 'Get-ADComputer' cmdlet. It supports the same parameters as the
    'Get-ADComputer' cmdlet. For more information check out the help for that cmdlet.

    .EXAMPLE
    Get-ALHADLapsPwd -Identity MyComputer

    .EXAMPLE
    Get-ALHADLapsPwd -Identity MyComputer1, MyComputer2

    .EXAMPLE
    MyComputer1, MyComputer2 | Get-ALHADLapsPwd

    .INPUTS
    System.String

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADLapsPwd.txt
    #>

    [CmdletBinding(DefaultParameterSetName = 'Filter')]
    param()

    dynamicparam {
        try {
            $PSBoundParameters.Remove('Properties') | Out-Null
            $PSBoundParameters.Add('Properties', @('ms-Mcs-AdmPwd', 'ms-Mcs-AdmPwdExpirationTime'))
            $targetCmd = $ExecutionContext.InvokeCommand.GetCommand('ActiveDirectory\Get-ADComputer', [System.Management.Automation.CommandTypes]::Cmdlet, $PSBoundParameters)
            $dynamicParams = @($targetCmd.Parameters.GetEnumerator() | Microsoft.PowerShell.Core\Where-Object { $_.Value.IsDynamic })
            if ($dynamicParams.Length -gt 0) {
                $paramDictionary = [Management.Automation.RuntimeDefinedParameterDictionary]::new()
                foreach ($param in $dynamicParams) {
                    $param = $param.Value

                    if (-not $MyInvocation.MyCommand.Parameters.ContainsKey($param.Name)) {
                        $dynParam = [Management.Automation.RuntimeDefinedParameter]::new($param.Name, $param.ParameterType, $param.Attributes)
                        $paramDictionary.Add($param.Name, $dynParam)
                    }
                }

                return $paramDictionary
            }
        }
        catch {
            throw
        }
    }

    begin {
        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
                $PSBoundParameters['OutBuffer'] = 1
            }

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('ActiveDirectory\Get-ADComputer', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters | Select-Object -Property Name, @{Name = "Password"; Expression = { $_.'ms-Mcs-AdmPwd' } }, @{Name = "PwdExpirationTime"; Expression = { [datetime]::FromFileTime($_.'ms-Mcs-AdmPwdExpirationTime') } } }

            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        }
        catch {
            throw
        }
    }

    process {
        try {
            $steppablePipeline.Process($_)
        }
        catch {
            throw
        }
    }

    end {
        try {
            $steppablePipeline.End()
        }
        catch {
            throw
        }
    }

    <#
    #.ForwardHelpTargetName ActiveDirectory\Get-ADComputer
    #.ForwardHelpCategory Cmdlet
    #>
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
