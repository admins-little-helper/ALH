<#PSScriptInfo

.VERSION 1.0.0

.GUID 780b6167-683c-4d94-a62e-1b85e339206e

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
 Contains a function to search for nested groups in Active Directory.

.LINK
https://github.com/admins-little-helper/ALH

#>

function Get-ALHNestetdGroup {    
    <#
    .SYNOPSIS
    Function to recursively enumerate members of a group.

    .DESCRIPTION
    Recursively checks if a given group is member of one of it's childs.

    .PARAMETER Identity
    The unique name of the group whose membership is being evaluated (ideally this should be the distinguishedName)

    .PARAMETER Parent
    An array of all parent groups of $Identity.
    This parameter can be empty when manually calling the function. It will be used during recursion when the
    function calls it self to iterate through the group membership.

    .PARAMETER GroupMember
    Mandatory. A hashtable containing all groups (keys) and associated members (values) to check for.
    
    .PARAMETER Hierarchy
    Will only be used during recursion to show how groups membership hierarchy.
    
    .INPUTS
    Nothing

    .OUTPUTS
    System.Object

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHNestetdGroup.txt
    #>

    [CmdLetBinding()]
    param (
        [parameter(Mandatory)]
        [String[]]$Identity,

        [String[]]$Parent,
        
        [parameter(Mandatory)]
        $GroupMember,

        [string]$Hierarchy
    )

    Write-Debug -Message "Checking group nesting of group '$Identity'"

    foreach ($Member In $GroupMember["$Identity"]) {
        Write-Debug -Message "Member: $Member"
        if ($Hierarchy -eq '') {
            $Hierarchy = "'$Identity'"
        }
        else {
            $Hierarchy = "$Hierarchy --> '$Identity'"
        }

        Write-Debug -Message "Hierarchy: $Hierarchy"

        foreach ($ParentItem In $Parent) {
            if ($Member -eq $ParentItem) {
                Write-Verbose "Found circular nested group: Group '$Identity' --> '$ParentItem'"
                return $ParentItem
            } 
        }
        
        # Check all group members for group membership.
        if ($GroupMember.ContainsKey($Member)) {
            # Add this member to array of parent groups. 
            # However, this is not a parent for siblings. 
            # Recursively call function to find nested groups. 
            $Temp = $Parent
            $Temp += $Member
            Get-ALHNestetdGroup -Identity $Member -Parent ($Temp) -GroupMember $GroupMember -Hierarchy $Hierarchy
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
