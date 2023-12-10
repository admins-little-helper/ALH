<#PSScriptInfo

.VERSION 1.0.0

.GUID 27db6c7c-0d12-4235-8ac8-0ba11affcd01

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
    Initial release

#>


<#

.DESCRIPTION
 Contains a function to find circular nested groups in Active Directory.

.LINK
https://github.com/admins-little-helper/ALH

#>


function Get-ALHADCircularNestedGroup {
    <#
    .SYNOPSIS
        Find circular nested groups in Active Directory.

    .DESCRIPTION
        The 'Get-ALHADCircularNestedGroup' function searches for instances of circular nested groups in Active Directory.

        Sometimes it happens that circular nested groups get created accidentally.
        For example GroupA has GroupB as member. GroupB has GroupC as member. And GroupC has GroupA as member.
        This function helps to identify these conflicts.

    .PARAMETER SearchBase
        One ore more names of organizational unites to search in recursively for nested groups.
        If not specified, the entire domain will be searched.

    .EXAMPLE
        Get-ALHADCircularNestedGroup -SearchBase 'OU=Groups,DC=contoso,DC=com' -Verbose

        Find all circular groups in two different organizational units and show verbose messages.

    .EXAMPLE
        Get-ALHADCircularNestedGroup

        Find all circular groups in the domain.

    .INPUTS
        System.String for parameter 'SearchBase'

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADCircularNestedGroup.txt
    #>

    [CmdLetBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [String[]]
        $SearchBase
    )

    begin {
        $StartDateTime = Get-Date

        if ( [string]::IsNullOrEmpty($SearchBase)) {
            try {
                $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                Write-Verbose "Searching for groups in entire AD domain '$($Domain.Name)'"
                $SearchBase = ($Domain.GetDirectoryEntry()).DistinguishedName
            }
            catch {
                $_
                break
            }
        }
    }

    process {
        foreach ($SearchBaseElement in $SearchBase) {
            try {
                Write-Verbose -Message "Trying to get groups from AD..."
                $AllGroups = Get-ALHADGroupMemberHT -SearchBase $SearchBaseElement
                Write-Verbose "# Groups found $(($AllGroups | Measure-Object).Count)"
            }
            catch {
                throw "Failed getting circular group membership: $_"
            }

            try {
                $GroupMembers = @{}

                # Enumerate groups and populate hashtable.
                # The key value will be the Distinguished Name of the group.
                # The item value will be an array of the Distinguished Names of all members of the group that are groups.
                # The item value starts out as an empty array, since we don't know yet which members are groups.
                foreach ($Group in $AllGroups) {
                    $DN = [String]$Group.properties.Item('distinguishedName')
                    Write-Debug -Message "Adding group with DN to hashtable: $DN"
                    $GroupMembers.Add($DN, @())
                }

                # Now enumerate the groups again to populate the item value arrays.
                foreach ($Group in $AllGroups) {
                    $DN = [String]$Group.properties.Item('distinguishedName')
                    $Members = @($Group.properties.Item('member'))

                    foreach ($Member in $Members) {
                        If ($GroupMembers.ContainsKey($Member)) {
                            Write-Debug -Message "Adding member to group --> $DN"
                            Write-Debug -Message "Group member           -->--> $Member"
                            $GroupMembers[$DN] += $Member
                        }
                    }
                }

                $NestedGroups = foreach ($Group in $GroupMembers.Keys) {
                    Get-ALHNestetdGroup -Identity $Group -Parent @($Group) -GroupMember $GroupMembers
                }

                $NestedGroups

                Write-Verbose -Message "Found '$(($NestedGroups | Measure-Object).Count)' nested groups in $SearchBaseElement"
            }
            catch {
                throw "Failed retrieving circular group membership: $_"
            }
        }
    }

    end {
        Write-Verbose -Message "Search finished"
        Write-Verbose -Message "Elapes time in seconds: $($(Get-Date) - $StartDateTime)"
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
