<#PSScriptInfo

.VERSION 1.1.0

.GUID 31231287-50ef-41f6-a780-411712bee2fe

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
 Initial Release.

 1.1.0
 Made script accept values for paramter Identity from pipeline.

#>


<#

.DESCRIPTION
Contains function to test if a given user, group, computer or contact is member of a given Active Directory group.

#>


function Test-ALHADGroupmembership {
    <#
    .SYNOPSIS
        A PowerShell function to test if a given user, group, computer or contact is member of a given Active Directory group.

    .DESCRIPTION
        A PowerShell function to test if a given user, group, computer or contact is member of a given Active Directory group.
        The function returns a PSCustomObject showing some information about the object found in AD and true or false about memberhsip of the
        given group, in case it was found.

    .PARAMETER Identity
        The samAccountName of the AD object, for which group membership should be checked.

    .PARAMETER Group
        The samAccountName of the AD group, whose members will be checked.

    .PARAMETER SearchBase
        AD SearchBase. If omitted, the base DN will be set from current AD domain.

    .EXAMPLE
        Test-GroupMembership -Identity $env:USERNAME -Group "GroupA"

        Check, if the currently logged on user is member of a group named GroupA.

    .EXAMPLE
        Test-GroupMembership -Identity mike,john -Group "Group1"

        Check, if the users named mike and john are member of a group named Group1.

    .INPUTS
        System.String

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHADGroupmembership.txt
    #>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, HelpMessage = 'Enter one or more user names')]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Identity,

        [Parameter(Mandatory)]
        [string]
        $Group,

        [AllowEmptyString()]
        [string]
        $SearchBase,

        [switch]
        $Recurse
    )

    begin {
        function Get-xADGroupMember {
            [CmdletBinding()]
            param(
                [Parameter(Mandatory = $true)]
                [string]
                $Group
            )

            $SearchFilter = "(&(objectCategory=group)(samaccountname=$Group))"
            $Search = New-Object DirectoryServices.DirectorySearcher($SearchFilter)

            try {
                $Results = $Search.FindAll()
                $Results | Out-Null

                foreach ($member in $Results.Properties["Member"]) {
                    Write-Verbose -Message "Checking if member is also a group: $member"
                    $MemberSearchFilter = "(&(objectCategory=group)(distinguishedName=$member))"
                    $MemberSearch = New-Object DirectoryServices.DirectorySearcher($MemberSearchFilter)

                    try {
                        $MemberResults = $MemberSearch.FindAll()
                        $MemberResults | Out-Null
                    }
                    catch {
                        Write-Verbose -Message "An unknown error occured"
                    }

                    if ($null -ne $MemberResults -and $MemberResults.Count -gt 0) {
                        Write-Verbose -Message "Member is a group. Call function recursively."
                        Get-xADGroupMember -Group $MemberResults.Properties["samAccountName"]
                    }
                }

                $Results
            }
            catch {
                Write-Verbose -Message "An unknown error occured"
            }
        }

        [array]$GroupResults = Get-xADGroupMember -Group $Group

        if ($Recurse.IsPresent) {
            Write-Verbose -Message "Running recursivly..."

            $GroupResults += foreach ($member in $GroupResults.Properties["Member"]) {
                Write-Verbose -Message "Checking if member is also a group: $member"
                $MemberSearchFilter = "(&(objectCategory=group)(distinguishedName=$member))"
                $MemberSearch = New-Object DirectoryServices.DirectorySearcher($MemberSearchFilter)

                try {
                    $MemberResults = $MemberSearch.FindAll()
                    $MemberResults | Out-Null
                }
                catch {
                    Write-Verbose -Message "An unknown error occured"
                }

                if ($null -ne $MemberResults -and $MemberResults.Count -gt 0) {
                    Write-Verbose -Message "Member is a group. Call function recursively."
                    Get-xADGroupMember -Group $MemberResults.Properties["samAccountName"]
                }
            }
        }
    }

    process {
        if ($null -ne $GroupResults -and $GroupResults.Count -gt 0) {
            foreach ($SingleIdentity in $Identity) {
                $samAccountName = $null
                $distinguishedName = $null
                $objectCategory = $null
                $IsMember = $null
                $MemberOfGroup = @()

                $ADObjectSearchFilter = "(|(&(objectCategory=computer)(samaccountname=$SingleIdentity`$))(&(objectCategory=person)(samaccountname=$SingleIdentity))(&(objectCategory=group)(samaccountname=$SingleIdentity)))"
                $ADObjectSearch = New-Object DirectoryServices.DirectorySearcher($ADObjectSearchFilter)

                try {
                    $ADObjectResult = $ADObjectSearch.FindAll()
                    $ADObjectResult | Out-Null
                }
                catch [System.Management.Automation.RuntimeException] {
                    Write-Verbose -Message "Error occured"
                }
                catch [System.ArgumentException] {
                    if ($_.Exception.InnerException.Message -eq "The $($ADObjectSearchFilter) search filter is invalid.") {
                        Write-Verbose -Message "Search filter invalid. Most probably the given samAccountName was not found in AD for any user, computer or contact."
                    }
                    else {
                        Write-Verbose -Message $_.Exception.InnerException.Message
                    }
                }
                catch {
                    Write-Verbose -Message "An unknown error occured"
                }

                if ($null -ne $ADObjectResult -and $ADObjectResult.Count -gt 0) {
                    Write-Verbose -Message "AD object found: $($ADObjectResult.Properties["distinguishedName"])"
                    $samAccountName = $ADObjectResult.Properties["samAccountName"][0]
                    $distinguishedName = $ADObjectResult.Properties["distinguishedName"][0]
                    $objectCategory = $ADObjectResult.Properties["objectCategory"][0]
                    $BaseObject = $ADObjectResult

                    foreach ($GroupResult in $GroupResults) {
                        Write-Verbose -Message "Group found: $($GroupResult.Properties["distinguishedName"])"
                        Write-Verbose -Message "Group member count: $($GroupResult.Properties["Member"].count)"

                        if ($GroupResult.Properties["Member"] -contains $ADObjectResult.Properties["distinguishedName"]) {
                            Write-Verbose -Message "AD object is member of group"
                            $IsMember = $true
                            $MemberOfGroup += $GroupResult.Properties["Name"]
                        }
                        else {
                            if ($Group -eq "Domain Users") {
                                Write-Warning -Message "You specified domain users group. This group is special because it's member attribute by default is empty. See https://ldapwiki.com/wiki/Domain%20Users for more information."
                            }
                            else {
                                Write-Verbose -Message "AD object is NOT member of group"
                                $IsMember = $false
                            }
                        }
                    }
                }
                else {
                    Write-Verbose -Message "No AD object found with samAccountName '$SingleIdentity'"
                }

                [PSCustomObject] @{
                    IdentitySeachString = $SingleIdentity
                    samAccountName      = $samAccountName
                    distinguishedName   = $distinguishedName
                    objectCategory      = $objectCategory
                    Group               = $Group
                    IsMember            = $IsMember
                    MemberOfGroup       = $MemberOfGroup
                    BaseObject          = $BaseObject
                }
            }
        }
        else {
            Write-Verbose -Message "No AD group found with samAccountName '$Group'"
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
