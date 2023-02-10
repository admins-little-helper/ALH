<#PSScriptInfo

.VERSION 1.1.0

.GUID dff730a8-af84-4b38-8fc3-de34ffd1e170

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
1.0.0
- Initial release

1.1.0
- Made script accept values for paramter ComputerName from pipeline.

#>


<#

.DESCRIPTION
 Contains function to query 'lastLogon' and 'lastLogonTimestamp' attributes from Domain Controllers in the current AD domain for one ore more user objects.

#>


function Get-ALHADUserLogonTime {
    <#
    .SYNOPSIS
    Queries 'lastLogon' and 'lastLogonTimestamp' attributes from multiple Domain Controllers in the current AD domain for one ore more user objects.
    
    .DESCRIPTION
    Queries 'lastLogon' and 'lastLogonTimestamp' attributes from multiple Domain Controllers in the current AD domain for one ore more user objects.
    
    .PARAMETER Identity
    One ore more user names (SamAccountName) to query information for. Separate list with commas.
    If no value is provied, the $env:USERNAME will be used.
    
    .PARAMETER DomainController
    One ore more Domain Controller names to query information for. Separate list with commas.
    If no value is provied, all DCs in the current domain are queried.
    
    .EXAMPLE
    Get-ALHADUserLogonTime -Identity User1
    
    .EXAMPLE
    Get-ALHADUserLogonTime -Identity User1, User2
    
    .EXAMPLE
    Get-ALHADUserLogonTime -Identity User2, User2 -DomainController adds1,adds2
    
    .EXAMPLE
    (Get-ADUser -Filter {name -like "a*"}).Name | Get-ALHADUserLogonTime -DomainController $(Get-ALHADDSDomainController -All)

    Get lastlogontime for all users in AD where name starts with 'a', from all domain controllers in the current domain.

    .INPUTS
    String
    
    .OUTPUTS
    PSCustomObject
    
    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADUserLogonTime.txt
    #>
        
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more user names')]        
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Identity = $env:USERNAME,
    
        [Parameter(HelpMessage = 'Enter one or more domain controllers to query')]    
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
                Write-Verbose -Message "Trying to get list of all domain controllers..."
                $DCs = Get-ADDomainController -Filter * -ErrorAction Stop
            }
            catch {
                Write-Information -Message "Error getting domain controllers" -InformationAction Continue
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
        $UserCount = ($Identity | Measure-Object).Count
        $j = 0
        $DCCount = ($DCs | Measure-Object).Count
    
        foreach ($user in $Identity) {
            Write-Verbose -Message "Querying information for user $user..."
            Write-Progress -Activity "Querying information for user $user" -Status "$i out of $UserCount done" -PercentComplete $([int] 100 / $UserCount * $i) 
            $i++
            $j = 0
    
            foreach ($DC in $DCs) {
                try {
                    Write-Verbose -Message "Querying information from domain controller $($DC.Name)..."
                    Write-Progress -Id 1 -Activity "Querying information from DC $($DC.Name)" -Status "$j out of $DCCount done" -PercentComplete $([int] 100 / $DCCount * $j) 
                    $j++
    
                    $userInfo = $null
                    
                    if ($DC.Available) {
                        $userInfo = Get-ADUser -Server $DC.Name -Filter { samAccountName -eq $user } -Properties mail, lastLogon, lastLogonTimestamp
                        $userInfo = $userInfo | Select-Object -Property SamAccountName, `
                            Name, `
                            Mail, `
                        @{Name = 'lastLogon'; Expression = { [datetime]::FromFileTime($_.lastLogon) } }, `
                        @{Name = 'lastLogonTimestamp'; Expression = { [datetime]::FromFileTime($_.lastLogonTimestamp) } }, `
                        @{Name = 'DC'; Expression = { $DC.Name } },
                        @{Name = 'DCExists'; Expression = { $DC.Exists } },
                        @{Name = 'DCAvailable'; Expression = { $DC.Available } }
                    }
                    else {
                        $userInfo = [PSCustomObject]@{
                            Name               = $user
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
    
                $userInfo
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
    