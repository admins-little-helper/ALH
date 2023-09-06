<#PSScriptInfo

.VERSION 1.3.0

.GUID 6683d9ba-f92a-43d0-b84b-5b552fe9e123

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
- Initial version

1.1.0
- Added possibilitey to query AD group members Recursely

1.1.1
- Made returning result to show only unique values

1.1.2
- Changed function names to include module name

1.2.0
- Added handling of groups and computer object as group members

1.3.0
- Cleaned up code

#>


<#

.DESCRIPTION
Contains a function to query all members of an AD group of a given objectClass.

#>


function Get-ALHADGroupMember {
    <#
    .SYNOPSIS
    Queries all members of an AD group of a given objectClass.

    .DESCRIPTION
    Queries all members of an AD group of a given objectClass.

    .PARAMETER Identity
    The samAccountName of the group to query.

    .PARAMETER Recurse
    If specified, the query runs recursivly if the given group has any other groups as member.

    .PARAMETER ObjectClass
    The name of the objectClass to query. Defaults to 'User'.

    .EXAMPLE
    $members = Get-ALHADGroupMember -Identity "myGroup"
    $members

    .EXAMPLE
    $members = Get-ALHADGroupMember -Identity "myGroup" -Recurse
    $members

    .EXAMPLE
    $members = Get-ALHADGroupMember -Identity "myGroup" -Recurse -ObjectClass User, Group, Compuer
    $members

    .INPUTS
    Nothing

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADGroupMember.txt
    #>

    param
    (
        [parameter(Mandatory)]
        [ValidateNotNull()]
        [String]$Identity,

        [ValidateNotNull()]
        [switch]$Recurse,

        [ValidateSet("User", "Group", "Computer")]
        [String[]]$ObjectClass = "User"
    )

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

    # set variable $FilterSet to remmber if Filter is already defined, this is important when the function
    #  is executed Recursely. Otherwise the filter string is appended with every iteration.
    if (-not $FilterSet) {
        switch ($ObjectClass) {
            "User" {
                if ($null -eq $Filter) {
                    $Filter = 'objectClass -eq "user" -and objectClass -ne "computer"'
                }
                else {
                    $Filter = $Filter + ' -or objectClass -eq "user" -and objectClass -ne "computer"'
                }
            }
            "Group" {
                if ($null -eq $Filter) {
                    $Filter = 'objectClass -eq "group"'
                }
                else {
                    $Filter = $Filter + ' -or objectClass -eq "group"'
                }
            }
            "Computer" {
                if ($null -eq $Filter) {
                    $Filter = 'objectClass -eq "computer"'
                }
                else {
                    $Filter = $Filter + ' -or objectClass -eq "computer"'
                }
            }
            Default {
                $Filter = 'objectClass -eq "user" -and objectClass -ne "computer"'
            }
        }
        $FilterSet = $true
    }

    if ($null -eq $AllADObjectsOfObjectClass) {
        # Create a hash table to store all AD account objects of the given object type from Active Directory
        Set-Variable -Name AllADObjectsOfObjectClass -Value @{}

        # Return all objects from Active Directory with some additional properties and store them in the hash table
        Get-ADObject -Filter $Filter -Property Name, displayName, memberOf, mail, department, description, employeeID |
            ForEach-Object { $AllADObjectsOfObjectClass[$_.DistinguishedName] = $_ }
    }

    # Get the content of the member attribute of the given group. This contains the distinguishedNames of all member objects
    # The distinguished name can be used as key in the hash table.
    $GroupMembers = Get-ADGroup -Identity $Identity -Properties Member
    $GroupMemberAccounts = $GroupMembers |
        Select-Object -ExpandProperty Member |
            ForEach-Object { ($AllADObjectsOfObjectClass[$_]) }

    # In case we need to search also subgroups, store all groups in AD in a hash table and then
    #  the function calls itself for each member group
    if ($Recurse.IsPresent) {
        # in case AD groups have not already been queried, first get all groups from AD
        if ($null -eq $AllADGroups) {
            Set-Variable -Name AllADGroups -Value @{}
            # Return all groups from Active Directory with some additional properties and store them in the hash table
            Get-ADGroup -Filter '*' -Properties Member |
                ForEach-Object { $AllADGroups[$_.DistinguishedName] = $_ }
        }

        # Get the content of the member attribute of the given group. This contains the distinguishedNames of all member objects
        # The distinguished name can be used as key in the hash table.
        $GroupMembersGroupAccounts = $GroupMembers |
            Select-Object -ExpandProperty Member |
                ForEach-Object { if ($AllADGroups[$_]) { ($AllADGroups[$_]) } }

        # If the parent group has other groups as member, then also get the members of those childs
        if ($null -ne $GroupMembersGroupAccounts) {
            $GroupMemberAccounts += foreach ($Group in $GroupMembersGroupAccounts) {
                Get-ALHADGroupMember -Identity "$($Group.Name)" -Recurse -ObjectClass $ObjectClass
            }
        }
    }
    # return the list of unique objects found to be member of the group
    return $GroupMemberAccounts | Select-Object -Unique | Sort-Object -Property Name
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
