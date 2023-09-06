<#PSScriptInfo

.VERSION 1.0.0

.GUID c731d7d1-bf89-441a-8b85-47b435ac1492

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
- Made script accept values for paramter ComputerName from pipeline.

#>


<#

.DESCRIPTION
 Contains a function to query the securtiy event log for event id 4740 which is logged in case a user account gets locked out.

#>


function Get-ALHADOUPermission {
    <#
    .SYNOPSIS
    Function to query AD OU permissions.

    .DESCRIPTION
    Function to query permissions on an Active Directory (AD) Organizational Unit (OU).

    .PARAMETER -OrganizationalUnit
    One or more distinguished Names of OUs to query permissions for.

    .EXAMPLE
    Get-ALHADOUPermission

    Get permissions for all OUs in current domain.

    .EXAMPLE
    Get-ALHADOUPermission -OrganizationalUnit "OU=DepartmentX;DC=company,DC=tld"

    Get permissions for a specific OU in current domain.

    .INPUTS
    Nothing

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADOUPermission.txt
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more organizational unit DNs')]
        [ValidateNotNullOrEmpty()]
        [string[]]$OrganizationalUnit
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

        if (-Not (Test-Path -Path "AD:")) {
            New-PSDrive -Name "AD" -PSProvider ActiveDirectory -Root "//RootDSE/" -Scope Global
        }
        $schemaIDGUID = @{}

        #ignore duplicate errors if any#
        $ErrorActionPreference = 'SilentlyContinue'

        Get-ADObject -SearchBase (Get-ADRootDSE).schemaNamingContext -LDAPFilter '(schemaIDGUID=*)' -Properties name, schemaIDGUID | `
                ForEach-Object {
                $schemaIDGUID.add([System.GUID]$_.schemaIDGUID, $_.name)
            }

        Get-ADObject -SearchBase "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)" -LDAPFilter '(objectClass=controlAccessRight)' -Properties name, rightsGUID | `
                ForEach-Object {
                $schemaIDGUID.add([System.GUID]$_.rightsGUID, $_.name)
            }

        $ErrorActionPreference = 'Continue'
    }

    process {
        if ( $OrganizationalUnit -eq "*" ) {
            Write-Verbose -Message "Getting all OUs in current domain..."
            $OUs = Get-ADOrganizationalUnit -Filter * | Select-Object -ExpandProperty DistinguishedName
        }
        else {
            Write-Verbose -Message "Using OU(s) specified in parameter..."
            $OUs = $OrganizationalUnit
        }

        Write-Verbose -Message "Getting OU permissions..."
        foreach ($OU in $OUs) {
            $entry = Get-Acl -Path "AD:\$OU" | `
                    Select-Object -ExpandProperty Access | `
                        Select-Object @{Name = 'organizationalUnit'; Expression = { $OU } }, `
                    @{Name = 'objectTypeName'; Expression = { if ($_.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') { 'All' } else { $schemaIDGUID.Item($_.objectType) } } }, `
                    @{Name = 'inheritedObjectTypeName'; Expression = { $schemaIDGUID.Item($_.inheritedObjectType) } }, `
                        *
            $entry
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
