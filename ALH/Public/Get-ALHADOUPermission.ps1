<#PSScriptInfo

.VERSION 1.3.0

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

1.2.0
- Reworked code.

1.3.0
- Added parameter 'Recurse'.

#>


<#

.DESCRIPTION
 Contains a function to query the securtiy event log for event id 4740 which is logged in case a user account gets locked out.

#>


function Get-ALHADOUPermission {
    <#
    .SYNOPSIS
        Retrieves permissions set on a specified Active Directory organizational unit or container.

    .DESCRIPTION
        The 'Get-ALHADOUPermission' function retrieves permissions set on a specified Active Directory organizational unit or container.

    .PARAMETER OrganizationalUnit
        One or more distinguished Names of Active Directory organizational units or containers for which to retrieve permissions.

    .PARAMETER IncludeContainer
        If specified, the query will include permissions for containers. Otherwise permissions are quried only for Organizational Units.

    .PARAMETER Recurse
        If specified, the query will include permissions for the specified OU string(s) and all child OUs (and containers if parameter 'IncludeContainer' was specified).

    .EXAMPLE
        Get-ALHADOUPermission

        Get permissions for all OUs in current domain.

    .EXAMPLE
        Get-ALHADOUPermission -OrganizationalUnit "OU=DepartmentX,DC=company,DC=tld"

        Get permissions for a specific OU in current domain.

    .EXAMPLE
        Get-ALHADOUPermission -OrganizationalUnit "OU=DepartmentX,DC=company,DC=tld" -Recurse

        Get permissions for a specific OU and all sub-OUs in current domain.

    .EXAMPLE
        Get-ALHADOUPermission -OrganizationalUnit "*" -IncludeContainer

        Get permissions for all OUs and containers in current domain.

    .INPUTS
        System.String

    .OUTPUTS
        System.DirectoryServices.ActiveDirectoryAccessRule

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADOUPermission.txt
    #>

    [OutputType([System.DirectoryServices.ActiveDirectoryAccessRule])]
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more organizational unit DNs')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $OrganizationalUnit = @(, "*"),

        [switch]
        $IncludeContainer,

        [switch]
        $Recurse
    )

    begin {
        # Define required modules for this function and check if these are available and loaded.
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

        # Make sure the AD PSDrive is available.
        if (-not (Test-Path -Path "AD:")) {
            $null = New-PSDrive -Name "AD" -PSProvider ActiveDirectory -Root "//RootDSE/" -Scope Global
        }

        $SchemaGUIDList = @{}

        # Get the GUID of all object in the AD schema.
        $GetADObjectParamsSchemaIDGUID = @{
            SearchBase = (Get-ADRootDSE).schemaNamingContext
            LDAPFilter = "(schemaIDGUID=*)"
            Properties = @("Name", "schemaIDGUID")
        }
        $SchemaIdGuids = Get-ADObject @GetADObjectParamsSchemaIDGUID

        # Add the schema GUIDs to the hashtable.
        foreach ($Guid in $SchemaIdGuids) {
            if (-not $SchemaGUIDList.ContainsKey([System.GUID]$Guid.schemaIDGUID)) {
                $SchemaGUIDList.add([System.GUID]$Guid.schemaIDGUID, $Guid.Name)
            }
        }

        # Get the GUID of all access rights.
        $GetADObjectParamsRightsGUID = @{
            SearchBase = "CN=Extended-Rights,$((Get-ADRootDSE).configurationNamingContext)"
            LDAPFilter = "(objectClass=controlAccessRight)"
            Properties = @("Name", "rightsGUID")
        }
        $RightsGUIDs = Get-ADObject @GetADObjectParamsRightsGUID

        # Add the access rights GUIDs to the hashtable, if there is not already the same GUID in the list.
        foreach ($Guid in $RightsGUIDs) {
            if (-not $SchemaGUIDList.ContainsKey([System.GUID]$Guid.rightsGUID)) {
                $SchemaGUIDList.add([System.GUID]$Guid.rightsGUID, $Guid.Name)
            }
        }

        # Get all OUs and containers in the current AD domain.
        if ($IncludeContainer.IsPresent) {
            Write-Verbose -Message "Including containers in query."
            $AllOUs = Get-ADObject -Filter { objectClass -eq 'organizationalUnit' -or objectClass -eq 'Container' }
        }
        else {
            Write-Warning -Message "Ignoring containers in query. Use parameter '-IncludeContainer' to include them in the results."
            $AllOUs = Get-ADObject -Filter { objectClass -eq 'organizationalUnit' }
        }
    }

    process {
        if ( $OrganizationalUnit -eq "*" ) {
            Write-Verbose -Message "Getting all OUs in current domain..."
            $OUsToProcess = $AllOUs
        }
        else {
            Write-Verbose -Message "Checking if specfied OU(s) exist in current domain..."
            $OUsToProcess = foreach ($OUString in $OrganizationalUnit) {
                if ($AllOUs.DistinguishedName -contains $OUString) {
                    if ($Recurse.IsPresent) {
                        # return the OU objects where the DN ends with the specified OU string.
                        $AllOUs.where({ $_.DistinguishedName -like "*$OUString" })
                    }
                    else {
                        # return the OU object where the DN is exactle the specified OU string.
                        $AllOUs.where({ $_.DistinguishedName -eq $OUString })
                    }
                }
                else {
                    Write-Warning -Message "No OU or container found with DistinguishedName [$OUString]."
                }
            }
        }

        if ($null -ne $OUsToProcess) {
            Write-Verbose -Message "Getting OU permissions..."
            foreach ($OU in $OUsToProcess) {
                Write-Verbose -Message "Getting permissions for OU [$($OU.DistinguishedName)]."
                $OUACL = Get-Acl -Path "AD:\$($OU.DistinguishedName)"
                $AccessEntries = $OUACL.Access

                foreach ($AccessEntry in $AccessEntries) {
                    # Add properties.
                    $AccessEntry | Add-Member -Name "organizationalUnit" -MemberType NoteProperty -Value $null
                    $AccessEntry | Add-Member -Name "objectTypeName" -MemberType NoteProperty -Value $null
                    $AccessEntry | Add-Member -Name "inheritedObjectTypeName" -MemberType NoteProperty -Value $null

                    # Add property values.
                    $AccessEntry.organizationalUnit = $OU
                    $AccessEntry.objectTypeName = $(
                        if ($AccessEntry.objectType.ToString() -eq '00000000-0000-0000-0000-000000000000') {
                            'All'
                        }
                        else {
                            $SchemaGUIDList.Item($AccessEntry.objectType)
                        }
                    )
                    $AccessEntry.inheritedObjectTypeName = $SchemaGUIDList.Item($AccessEntry.inheritedObjectType)

                    # Return updated access object.
                    $AccessEntry
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
