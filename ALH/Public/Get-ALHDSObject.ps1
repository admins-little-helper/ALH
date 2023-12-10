<#PSScriptInfo

.VERSION 1.0.4

.GUID d4fb8639-cd4a-4885-9ee2-b1de8b78118a

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

    1.0.1
    Added custom properties for converted values like ALHobjectGuid or ALHobjectSID

    1.0.2
    Changed the way to create the DirectryEntry object to correctly pass credentials to it.

    1.0.3
    Added parameter 'DomainName'
    Removed parameter 'SizeLimit' and set PageSize to a value of 500 for the DirectorySearcher object
    Fixed how to get the proper objectClass for ALHobjectClass property

    1.0.4
    Added custom attribute ALHProtectedFromAccidentalDeletion

#>


<#

.DESCRIPTION
Function to query Active Directory using ADSI DirectorySearch and therefore no dependency to the ActiveDirectory PowerShell module.

 #>


function Get-ALHDSObject {
    <#
    .SYNOPSIS
        Query Active Directory using ADSI DirectorySearch and therefore no dependency to the ActiveDirectory PowerShell module.

    .DESCRIPTION
        The function 'Get-ALHDSObject' queries Active Directory withtout any dependency to the ActiveDirectory PowerShell module.
        For more information about the Directory Searcher refer to https://docs.microsoft.com/en-us/dotnet/api/system.directoryservices.directorysearcher?view=dotnet-plat-ext-6.0.

    .PARAMETER LDAPFilter
        LDAP filter syntax to use for the query.
        If omitted the default filter of '(&(objectClass=*))' is used.

    .PARAMETER SearchBase
        Specifies an Active Directory path to search.
        If omitted the Active Directory root will be used. Can not be used together with parameter -DomainName.

    .PARAMETER DomainName
        FQDN of the value to query.
        If omitted the domain of the machine is used. Cannot be used togethe with parameter -SearchBase.

    .PARAMETER Server
        Specify the name or fqdn of a server (Domain Controller) to run the query against.
        If omitted a Domain Controller will be automatically detected based on OS default mechanism.

    .PARAMETER Credential
        Credential object used to connect to Active Directory.
        If omitted the connection atempt is made in the current user's context.

    .PARAMETER SizeLimit
        Specifying the maximum number of results in a query.
        If omitted this default's to 10000.

    .EXAMPLE
        $Result = Get-ALHDSObject -Server "dc.domain.tld" -SearchBase "DC=domain,DC=tld" -Verbose
        $Result | Select-Object -Property Name, Parent, objectClass, objectCategory | Format-Table -AutoSize

    .INPUTS
        Nothing

    .OUTPUTS
        PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHDSObject.txt
    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [ValidateNotNullOrEmpty()]
        [string]
        $LDAPFilter,

        [Parameter(ParameterSetName = "SearchBase")]
        [ValidateNotNullOrEmpty()]
        [string]
        $SearchBase,

        [Parameter(ParameterSetName = "DomainName")]
        [ValidateNotNullOrEmpty()]
        [string]
        $DomainName = (Get-CimInstance -ClassName "Win32_ComputerSystem").Domain,

        [ValidateNotNullOrEmpty()]
        [string]
        $Server,

        [PSCredential]
        $Credential
    )

    $StopWatch = [System.Diagnostics.Stopwatch]::new()
    $StopWatch.Start()
    Write-Verbose -Message "Elapsed time since program start: $($StopWatch.Elapsed)"

    if ([string]::IsNullOrEmpty($SearchBase)) {
        if ([string]::IsNullOrEmpty($DomainName)) {
            Write-Verbose -Message "Setting default SearchBase"
            try {
                $DomainConnection = [adsi]""
            }
            catch {
                $_
            }
        }
        else {
            Write-Verbose -Message "Setting SearchBase based on specified DomainName: '$DomainName'"
            if ($null -ne $Credential) {
                try {
                    $DomainConnection = [adsi]::new("LDAP://$DomainName", $Credential.UserName, $($Credential.GetNetworkCredential().Password))
                }
                catch {
                    $_
                }
            }
            else {
                try {
                    $DomainConnection = [adsi]::new("LDAP://$DomainName")
                }
                catch {
                    $_
                }
            }
        }

        if ($DomainConnection.distinguishedName) {
            $SearchBase = $DomainConnection.distinguishedName[0]
            $DomainConnection.Dispose()
        }
        else {
            $_
            Write-Error -Message "Could not connect to domain '$DomainName'"
            break
        }
    }
    else {
        Write-Verbose -Message "Setting SearchBase specified by parameter '$SearchBase'"
    }

    if ($SearchBase -ne $(([adsi]"").distinguishedName[0])) {
        Write-Verbose -Message "Running query for a different domain, than the current user is in. Need to identify a server to query."
        $Server = (Get-ALHDSDomainController -DomainName $DomainName).Name.Substring(2)
    }

    if ([string]::IsNullOrEmpty($Server)) {
        Write-Verbose -Message "Using default Domain Controller detected by client"
        $ConnectString = "LDAP://$SearchBase"
    }
    else {
        Write-Verbose -Message "Using Domain Controller specified by parameter: '$Server'"
        $ConnectString = "LDAP://$Server/$SearchBase"
    }

    Write-Verbose -Message "ConnectString: '$ConnectString'"

    if ($null -ne $Credential) {
        Write-Verbose -Message "Trying to connect with credentials specified by parameter for user '$($Credential.UserName)'"
        try {
            # Create an object "DirectoryEntry" and specify the domain, username and password
            $Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $ConnectString, $($Credential.UserName), $($Credential.GetNetworkCredential().password)
        }
        catch [System.Management.Automation.ExtendedTypeSystemException] {
            Write-Error -Message "Unable to connect: The user name or password is incorrect or account is locked."
        }
        catch {
            $_
        }
    }
    else {
        Write-Verbose -Message "Trying to connect with credentials of current user's scope for user '$($env:USERDOMAIN)\$($env:USERNAME)'"
        $Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $ConnectString
    }

    if ($null -eq $Domain.Path) {
        Write-Warning -Message "Could not connect to Active Directory. Aborting!"
    }
    else {
        Write-Verbose -Message "Successfully connected to Active Directory. Starting query."
        Write-Verbose -Message "Elapsed time since program start: $($StopWatch.Elapsed)"

        $DS = [adsisearcher]$Domain

        if ([string]::IsNullOrEmpty($LDAPFilter)) {
            $Filter = "(&(objectClass=*))"
            Write-Verbose -Message "Setting default filter for query: '$Filter'"
        }
        else {
            Write-Verbose -Message "Setting LDAP filter specified by parameter: '$LDAPFilter'"
            $Filter = $LDAPFilter
        }

        $DS.Filter = $Filter
        $DS.PageSize = 500
        $DS.SizeLimit = 0

        $AllADObjects = $DS.FindAll()
        Write-Verbose -Message "# objects returned by query: $($AllADObjects.Count)"

        # taken from https://stackoverflow.com/questions/51761894/regex-extract-ou-from-distinguished-name
        $RegExDN = "^(?:(?<cn>CN=(?<name>.*?)),)?(?<parent>(?:(?<path>(?:CN|OU).*?),)?(?<domain>(?:DC=.*)+))$"

        [array]$AllADObjectsCustomObj = foreach ($item in $AllADObjects) {
            $ADObjectHT = @{}
            if ($item.Properties.distinguishedname.count -ne 0) {
                $RegExDnMatches = [regex]::matches($item.Properties.distinguishedname[0], $RegExDN)
                $ADObjectHT.Parent = $RegExDnMatches.Groups.Where({ $_.Name -eq 'parent' }).value
                $ADObjectHT.ALHProtectedFromAccidentalDeletion = [bool]$item.GetDirectoryEntry().ObjectSecurity.Access.where({ $_.IdentityReference -eq (([System.Security.Principal.SecurityIdentifier]::new("S-1-1-0")).Translate([System.Security.Principal.NTAccount])).Value -and $_.AccessControlType -eq "Deny" })

                foreach ($itemprop in $item.Properties.GetEnumerator()) {
                    switch ($itemprop.Name) {
                        "objectClass" { $ADObjectHT.ALHobjectClass = $itemprop.value[$itemprop.value.count - 1] } #[-1] does not work here to get the last element in the array
                        "objectguid" { $ADObjectHT.ALHobjectGuid = [Guid]::New( $itemprop.value[0] ) }
                        "objectsid" { $ADObjectHT.ALHobjectSid = [Security.Principal.SecurityIdentifier]::new( $itemprop.value[0], 0 ) }
                        "pwdlastset" { $ADObjectHT.ALHpwdLastSet = [DateTime]::FromFileTime($itemprop.value[0]) }
                        "lastlogon" { $ADObjectHT.ALHlastLogon = [DateTime]::FromFileTime($itemprop.value[0]) }
                        "lastlogontimestamp" { $ADObjectHT.ALHlastLogonTimestamp = [DateTime]::FromFileTime($itemprop.value[0]) }
                        "lastlogoff" { $ADObjectHT.ALHlastlogoff = [DateTime]::FromFileTime($itemprop.value[0]) }
                        "badPasswordTime" { $ADObjectHT.ALHbadPasswordTime = [DateTime]::FromFileTime($itemprop.value[0]) }
                    }

                    $ADObjectHT."$($itemprop.Name)" = foreach ($itempropvalue in $itemprop.Value) {
                        $itempropvalue
                    }
                }

                $ADObject = [pscustomobject]$ADObjectHT
                $ADObject
            }
            else {
                Write-Warning -Message "Item has no DistinguishedName property, skipping to add to results. Item ADSPath: '$($item.Path)'"
            }
        }

        Write-Verbose -Message "# valid objects returned by query: $($AllADObjectsCustomObj.Count)"
        Write-Verbose -Message "Elapsed time since program start: $($StopWatch.Elapsed)"
        $StopWatch.Stop()

        $AllADObjectsCustomObj
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
