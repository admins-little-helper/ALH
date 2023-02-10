<#PSScriptInfo

.VERSION 1.0.0

.GUID 8855ce9f-551a-44e2-a4e6-1c11c4e52c1d

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
Contains a function to search for groups in Active Directory using System.DirectoryServices.DirectorySearcher instead of the Active Directory PowerShell module.

.LINK
https://github.com/admins-little-helper/ALH

#>


Function Get-ALHADGroupMemberHT {
<#

    .SYNOPSIS
    Searches Active Directory for groups and returns results in a hash table.

    .DESCRIPTION
    Searches Active Directory for groups and returns results in a hash table.
    This function uses System.DirectoryServices.DirectorySearcher instead of the Active Directory PowerShell module.

    .PARAMETER SearchBase
    Name of the organizational unit to start searching recursively for groups.
    If not specified, the entire domain will be searched.

    .PARAMETER Identity
    Name of the group to search for. Wildcards supported.
    If not specified, * is used.

    .EXAMPLE
    Get-ALHADGroupMemberHT -SearchBase 'OU=Groups1,DC=contoso,DC=com','OU=Groups2,DC=contoso,DC=com' -Verbose

    Find all groups in two different organizational units and show verbose messages.

    .EXAMPLE
    Get-ALHADGroupMemberHT

    Find all groups in the domain.

    .EXAMPLE
    "OU=Groups,OU=Organization,DC=domain,DC=tld", "OU=Distribution Lists,OU=Organization,DC=domain,DC=tld" | Get-ALHADGroupMemberHT

    Pipe OU distinguished names to search in to function.

    .EXAMPLE
    Get-ALHADGroupMemberHT -Identity "group_*"

    Find all groups where name is staring with 'group_' in the entire domain.

    .INPUTS
    System.String for parameter 'SearchBase'

    .OUTPUTS
    System.DirectoryServices.SearchResult

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADGroupMemberHT.txt
    #>

    [CmdLetBinding()]
    [OutputType([System.DirectoryServices.SearchResult])]
    param (
        [Parameter(ValueFromPipeline)]
        [String[]]$SearchBase,

        [ValidateNotNullOrEmpty()]
        [String]$Identity = "*"
    )

    begin {
        Write-Verbose -Message "Defining LDAP filter..."

        if ($Identity -ne "*") {
            $Filter = '(&(objectCategory=group)' + "(name=$Identity))"
        }
        else {
            $Filter = '(objectCategory=group)'
        }    

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

        Write-Verbose -Message "Using LDAPFilter: $Filter"

        # Define re-usable script block for the AD search
        $RunSearch = {
            $Searcher = New-Object System.DirectoryServices.DirectorySearcher
            $Searcher.SearchRoot = $SearchRoot
            $Searcher.PageSize = 200
            $Searcher.SearchScope = 'subtree'
            $Searcher.PropertiesToLoad.Add('distinguishedName') > $null
            $Searcher.PropertiesToLoad.Add('member') > $null
            $Searcher.Filter = $Filter
            $Searcher.FindAll()
        }
    }
    
    process {        
        foreach ($OU in $SearchBase) {
            try {
                Write-Verbose "Searching for groups in OU '$OU'"
                $SearchRoot = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$OU")
                $Result = & $RunSearch
                Write-Verbose -Message "# Groups found: $($Result.Count)"
                $Result
            }
            catch {
                throw "Error searching OU '$OU': $_"
            }
        }
    }
    end {
        Write-Verbose -Message "Search finished"
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
