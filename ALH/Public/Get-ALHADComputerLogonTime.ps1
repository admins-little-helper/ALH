<#PSScriptInfo

.VERSION 1.1.1

.GUID 82dca212-e866-44d7-b801-297bbc45ad61

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
- Initial release

1.1.0
- Made script accept values for paramter ComputerName from pipeline.

1.1.1
- Corrected typos and cleaned up usage of write-host

#>


<#

.DESCRIPTION
 Contains function to query 'lastLogon' and 'lastLogonTimestamp' attributes from multiple Domain Controller in the current AD domain for one ore more computer objects.

#>


function Get-ALHADComputerLogonTime {
    <#
    .SYNOPSIS
    Queries 'lastLogon' and 'lastLogonTimestamp' attributes from multiple Domain Controller in the current AD domain for one ore more computer objects.

    .DESCRIPTION
    Queries 'lastLogon' and 'lastLogonTimestamp' attributes from multiple Domain Controller in the current AD domain for one ore more computer objects.

    .PARAMETER ComputerName
    One ore more computer names to query information for. Separate list with commas.
    If no value is provied, the local computer will be used.

    .PARAMETER DomainController
    One ore more Domain Controller names to query information for. Separate list with commas.
    If no value is provied, all DCs in the current domain are queried.

    .EXAMPLE
    Get-ALHADComputerLogonTime -ComputerName MyComputer

    .EXAMPLE
    Get-ALHADComputerLogonTime -ComputerName MyComputer1, MyComputer2

    .EXAMPLE
    Get-ALHADComputerLogonTime -ComputerName MyComputer1, MyComputer2 -DomainController adds1,adds2

    .EXAMPLE
    (Get-ADComputer -Filter {name -like "a*"}).Name | Get-ALHADComputerLogonTime -DomainController $(Get-ALHADDSDomainController -All)

    Get lastlogontime for all computers in AD where name starts with 'a', from all domain controller in the current domain.

    .INPUTS
    String or array of string

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADComputerLogonTime.txt
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more computer names')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [Parameter(HelpMessage = 'Enter one or more domain controller to query')]
        [string[]]
        $DomainController
    )

    begin {
        $RequiredModules = "ActiveDirectory"

        foreach ($RequiredModule in $RequiredModules) {
            if (-not [bool](Get-Module -Name $RequiredModule)) {
                if (-not [bool](Get-Module -Name $RequiredModule -ListAvailable)) {
                    Write-Warning -Message "Module $RequiredModule not found. Stopping function."
                    break
                }

                Write-Verbose -Message "Importing $RequiredModule Module"
                Import-Module ActiveDirectory
            }
        }

        if ($null -eq $DomainController -or $DomainController.Length -eq 0) {
            try {
                Write-Verbose -Message "Trying to get list of all domain controller..."
                $DCs = Get-ADDomainController -Filter * -ErrorAction Stop
            }
            catch {
                Write-Error "Error getting domain controller"
                break
            }
        }
        else {
            Write-Verbose -Message "DCs specified..."
            Write-Verbose -Message "$($DomainController -join '; ')"

            $UniqueDCs = $DomainController | Select-Object -Unique

            Write-Verbose -Message "Unique DC names..."
            Write-Verbose -Message "$($UniqueDCs -join '; ')"

            $DCs = foreach ($DC in $UniqueDCs) {
                Write-Verbose -Message "Checking if DC exists: $DC..."
                $DCInfo = Get-ADDomainController -Filter { Name -eq $DC } -ErrorAction SilentlyContinue
                $DCInfo
            }
        }

        $DCs = foreach ($DCtoTest in $DCs) {
            if ($null -eq $DCtoTest) {
                Write-Verbose -Message "DC not found in domain: $DCtoTest..."

                $DCInfo = [PSCustomObject]@{
                    Name      = $DCtoTest
                    Exists    = $false
                    Available = $false
                }
            }
            else {
                Write-Verbose -Message "Checking if DC is available: $DCtoTest..."

                $DCInfo = $DCtoTest | Select-Object -Property *, `
                @{Name = 'Exists'; Expression = { $true } }, `
                @{Name = 'Available'; Expression = { Test-Connection -ComputerName $DCtoTest -Count 2 -Quiet } }
                $DCInfo
            }
        }
    }

    process {
        $i = 0
        $ComputerCount = ($ComputerName | Measure-Object).Count
        $j = 0
        $DCCount = ($DCs | Measure-Object).Count

        foreach ($computer in $ComputerName) {
            Write-Verbose -Message "Querying information for computer $computer..."
            Write-Progress -Activity "Querying information for computer $computer" -Status "$i out of $ComputerCount done" -PercentComplete $([int] 100 / $ComputerCount * $i)
            $i++
            $j = 0

            foreach ($DC in $DCs) {
                try {
                    Write-Verbose -Message "Querying information from domain controller $($DC.Name)..."
                    Write-Progress -Id 1 -Activity "Querying information from DC $($DC.Name)" -Status "$j out of $DCCount done" -PercentComplete $([int] 100 / $DCCount * $j)
                    $j++

                    $ComputerInfo = $null

                    if ($DC.Available) {
                        $ComputerInfo = Get-ADComputer -Server $DC.Name -Filter { Name -eq $computer } -Properties lastLogon, lastLogonTimestamp
                        $ComputerInfo = $ComputerInfo | Select-Object -Property Name,
                        @{Name = 'lastLogon'; Expression = { [datetime]::FromFileTime($_.lastLogon) } },
                        @{Name = 'lastLogonTimestamp'; Expression = { [datetime]::FromFileTime($_.lastLogonTimestamp) } },
                        @{Name = 'DC'; Expression = { $DC.Name } },
                        @{Name = 'DCExists'; Expression = { $DC.Exists } },
                        @{Name = 'DCAvailable'; Expression = { $DC.Available } }
                    }
                    else {
                        $ComputerInfo = [PSCustomObject]@{
                            Name               = $computer
                            lastLogon          = ''
                            lastLogonTimestamp = ''
                            DC                 = $DC.Name
                            DCExists           = $DC.Exists
                            DCAvailable        = $DC.Available
                        }
                    }
                }
                catch {
                    Write-Error $_
                }

                $ComputerInfo
            }
        }
    }
}

#region EndOfScript
<#
################################################################################
################################################################################
#
#<       ______           _          __    _____           _       _
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
