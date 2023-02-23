<#PSScriptInfo

.VERSION 1.0.1

.GUID 759f9aaf-e0c8-4a27-bf43-72acf1dca5db

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS Bitlocker, AD, Active Directory

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH

.ICONURI

.EXTERNALMODULEDEPENDENCIES EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    1.0.0
    Initial release.

    1.0.1
    Fixed issue in returning computer name.

#>


<#

.DESCRIPTION
Contains a function to retrieve the Bitlocker recovery key for a computer account stored in Active Directory.
This functions is a proxy function for the 'Get-ADComputer' cmdlet.

.LINK
https://github.com/admins-little-helper/ALH

#>


function Get-ALHADBitlockerRecoveryKey {
    <#
    .SYNOPSIS
    Retrieves the Bitlocker recovery key for a computer account stored in Active Directory.

    .DESCRIPTION
    Queries the Bitlocker recovery key for a computer account stored in Active Directory.
    This functions is a proxy function for the 'Get-ADComputer' cmdlet. It supports the same parameters as the 
    'Get-ADComputer' cmdlet. For more information check out the help for that cmdlet.

    .EXAMPLE
    Get-ALHADBitlockerRecoveryKey -Identity MyComputer

    .EXAMPLE
    Get-ALHADBitlockerRecoveryKey -Identity MyComputer1, MyComputer2

    .EXAMPLE
    MyComputer1, MyComputer2 | Get-ALHADBitlockerRecoveryKey

    .INPUTS
    System.String

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADBitlockerRecoveryKey.txt
    #>

    [CmdletBinding(DefaultParameterSetName = 'Filter')]
    param()

    dynamicparam {
        try {
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
            $scriptCmd = { & $wrappedCmd @PSBoundParameters | ForEach-Object { 
                    $BitlockerInfo = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase $_.DistinguishedName -Properties 'msFVE-RecoveryPassword'
                
                    if ($null -ne $BitlockerInfo) {
                        foreach ($BitlockerRecoveryKey in $BitlockerInfo) {
                            $ComputerInfo = [ordered]@{}
                            $ComputerInfo.Name = $_.Name
                            $ComputerInfo.PasswordID = ($BitlockerRecoveryKey.Name -split "{")[1] -replace "}", ""
                            $ComputerInfo.PasswordDate = Get-Date (($BitlockerRecoveryKey.Name -split "{")[0])
                            $ComputerInfo.RecoveryPassword = $BitlockerRecoveryKey.'msFVE-RecoveryPassword'

                            foreach ($Parameter in $PSBoundParameters.Properties) {
                                $ComputerInfo.$Parameter = $_.$Parameter
                            }
                        
                            $ComputerInfoObj = New-Object -TypeName PSObject -Property $ComputerInfo                        
                            $ComputerInfoObj
                        }
                    }
                    else {
                        Write-Verbose -Message "No Bitlocker information found for computer '$($_.Name)'"
                    }
                }
            }

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
