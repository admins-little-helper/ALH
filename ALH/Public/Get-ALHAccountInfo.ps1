<#PSScriptInfo

.VERSION 1.0.0

.GUID b94366ad-e928-4b4d-9140-ad332576416e

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
 Contains a function to get an account's SID by account name and domain name, or get an account's domain and name by it's SID.

#>


function Get-ALHAccountInfo {
    <#
    .SYNOPSIS
        Get an account's SID by account name and domain name, or get an account's domain and name by it's SID.

    .DESCRIPTION
        The 'Get-ALHAccountInfo' function gets an account's SID by account name and domain name, or get an account's domain and name by it's SID.

    .PARAMETER Identity
        An accounts SID or username in the format '<domain>\<username>' or '<user@domain.tld>'.
        To get the SID for a computer account, remember to add the '$' trailing character to the account name.

    .EXAMPLE
        Get-ALHAccountInfo -Identity "Domain\Computer1$"

        AccountName DomainName SIDValue
        ----------- ---------- --------
        Computer1   DOMAIN     S-1-5-21-3332716652-4045636879-1442444979-2117

        Get SID for computer account 'Computer1' in domain 'Domain'.

    .EXAMPLE
        Get-ALHAccountInfo -Identity "S-1-5-32-544"

        AccountName     DomainName   SIDValue
        -----------     ----------   --------
        administrators  BUILT-IN     S-1-5-32-544

        Get account information for a SID value.

    .EXAMPLE
        Get-Content -Path "C:\Temp\Accountnames.txt" | Get-ALHAccountInfo

        Get SID for a multiple accounts retrieved from a text file via pipeline input.

    .INPUTS
        System.String

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHAccountInfo.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = 'Enter account name or SID')]
        [string[]]
        $Identity
    )

    begin {
        Write-Verbose -Message "Defining SID regex pattern."
        $SIDPattern = '^S-\d-(\d+-){1,14}\d+$'
    }

    process {
        foreach ($SingleIdentity in $Identity) {
            $IdentityInfo = [PSCustomObject]@{
                AccountName = $null
                DomainName  = $null
                SIDValue    = $null
            }

            Write-Verbose -Message "Testing SID value for validity."

            if ($SingleIdentity -match $SIDPattern) {
                Write-Verbose -Message "SID is a valid SID: '$SingleIdentity'"
                $IdentityInfo.SIDValue = $SingleIdentity

                try {
                    $IdentitySID = [System.Security.Principal.SecurityIdentifier]::new($IdentityInfo.SIDValue)
                    $IdentityObject = $IdentitySID.Translate([System.Security.Principal.NTAccount])
                    $SingleIdentity = $IdentityObject.Value.ToString()
                }
                catch {
                    $_
                }
            }
            else {
                Write-Verbose -Message "SID is not a valid SID: '$SingleIdentity'"
            }

            if ($SingleIdentity -match "\\") {
                Write-Verbose -Message "Username contains '\' - parsing username and domain name from this"
                $IdentityInfo.DomainName = ($SingleIdentity -split "\\")[0]
                $IdentityInfo.AccountName = ($SingleIdentity -split "\\")[1]
            }
            elseif ($SingleIdentity -match "@") {
                Write-Verbose -Message "Username contains '@' - assuming UPN and getting username and domain values from it"
                $IdentityInfo.AccountName = ($SingleIdentity -split "@")[0]
                $IdentityInfo.DomainName = ($SingleIdentity -split "@")[1]
            }
            else {
                $IdentityInfo.AccountName = $SingleIdentity
                $IdentityInfo.DomainName = $env:COMPUTERNAME
            }

            $IdentityInfo.AccountName = ($IdentityInfo.AccountName).ToLower()
            $IdentityInfo.DomainName = ($IdentityInfo.DomainName).ToUpper()

            if ([string]::IsNullOrEmpty($IdentityInfo.SIDValue)) {
                Write-Verbose -Message "Trying to get SID by account domain and name."
                try {
                    $IdentityObject = [System.Security.Principal.NTAccount]::new($IdentityInfo.DomainName, $IdentityInfo.AccountName)
                    $IdentitySID = $IdentityObject.Translate([System.Security.Principal.SecurityIdentifier])
                    $IdentityInfo.SIDValue = $IdentitySID.Value
                }
                catch {
                    $_
                }
            }

            $IdentityInfo
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