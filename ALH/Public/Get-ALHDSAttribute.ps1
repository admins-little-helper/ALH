<#PSScriptInfo

.VERSION 1.0.2

.GUID ff110b23-d1d8-4232-bcaf-14097550a75f

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
    Changed the way to create the DirectryEntry object to correctly pass credentials to it.

    1.0.2
    Fixed duplicate parameter for Get-ALHDSObject
    Fixed value name in ValidateSet for parameter 'ClassName'

#>


<#

.DESCRIPTION
Contains a function to query Active Directory for all attributes of a given class.

#>

function Get-ALHDSAttribute {
    <#
    .SYNOPSIS
        Function to query Active Directory for all attributes of a given class.

    .DESCRIPTION
        Function to query Active Directory for all attributes of a given class.

    .PARAMETER ClassName
        Name of the class for which the attribues should be queried.
        Can not be used together with parameter -CustomClassName

    .PARAMETER CustomClassName
        AD Class name if notthing of the of pre-defined classes for -ClassName matches.
        Can not be used together with parameter -ClassName

    .PARAMETER DomainName
        FQDN of the value to query.
        If omitted the domain of the machine is used.

    .PARAMETER Server
        Specify the name or fqdn of a server (Domain Controller) to run the query against.
        If omitted a Domain Controller will be automatically detected based on OS default mechanism.

    .PARAMETER Credential
        Credential object used to connect to Active Directory.
        If omitted the connection atempt is made in the current user's context.

    .EXAMPLE
        $Result = Get-ALHDSObject -SearchBase "CN=MyComputer,OU=MyComputerOU,DC=domain,DC=tld" -Verbose
        $Result | Select-Object -Property Name, Parent, objectClass, objectCategory | Format-Table -AutoSize

        Shows a list of all attributes of all objects in Active Directory.

    .INPUTS
        Nothing

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHDSAttribute.txt
    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ClassName")]
        [ArgumentCompleter({ "Computer", "Group", "User", "OrganizationalUnit" })]
        [string[]]
        $ClassName,

        [string]
        [ValidateNotNullOrEmpty()]
        $DomainName = (Get-CimInstance -ClassName "Win32_ComputerSystem").Domain,

        [string]
        [ValidateNotNullOrEmpty()]
        $Server,

        [PSCredential]
        $Credential,

        [switch]
        $BaseClassOnly
    )

    begin {
        try {
            Write-Verbose -Message "Getting Active Direcotry domain of computer"
            if ($null -ne $Credential) {
                Write-Verbose -Message "Trying to connect with credentials specified by parameter for user '$($Credential.UserName)'"
                try {
                    $Forest = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest", $DomainName, $Credential.UserName, $($Credential.GetNetworkCredential().password))
                }
                catch [System.Management.Automation.ExtendedTypeSystemException] {
                    Write-Error -Message "Unable to connect: The user name or password is incorrect or account is locked."
                }
                catch {
                    $_
                }
            }
            else {
                $Forest = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest", $DomainName)
                Write-Verbose -Message "Trying to connect with credentials of current user's scope for user '$($env:USERDOMAIN)\$($env:USERNAME)'"
            }

            $ADSchema = [System.DirectoryServices.ActiveDirectory.ActiveDirectorySchema]::GetSchema($Forest)

            Write-Verbose -Message "Setting parameter values for Get-ALHDSObject"
            $GetALHADObjectParams = @{}
            if (-not ([string]::IsNullOrEmpty($DomainName))) { $GetALHADObjectParams.SearchBase = $ADSchema.Name }
            if (-not ([string]::IsNullOrEmpty($Server))) { $GetALHADObjectParams.Server = $Server }
            if ($null -ne $Credential) { $GetALHADObjectParams.Credential = $Credential }
        }
        catch {
            Write-Error $_
        }
    }

    process {
        foreach ($ClassNameItem in $ClassName) {
            $Loop = !($BaseClassOnly.IsPresent)
            $ClassArray = [System.Collections.ArrayList]@()
            $ClassAttributes = @()

            $ClassNameToQuery = $ClassNameItem

            try {
                do {
                    $Class = Get-ALHDSObject @GetALHADObjectParams -LDAPFilter "(&(lDAPDisplayName=$ClassNameToQuery))"

                    if ($Class.ldapDisplayName -eq $Class.subClassOf) {
                        $Loop = $false
                    }

                    [void]$ClassArray.Add($Class)
                    $ClassNameToQuery = $Class.subClassOf
                }
                while ($Loop)

                foreach ($ClassItem in $ClassArray) {
                    $Aux = $ClassItem.AuxiliaryClass

                    $AuxItems = foreach ($AuxItem in $Aux) {
                        Get-ALHDSObject -SearchBase $ADSchema.Name -LDAPFilter "(&(ldapDisplayName=$AuxItem))" @GetALHADObjectParams
                    }

                    $ClassAttributes += $AuxItems | Select-Object @{Name = "Attributes"; Expression = { $_.mayContain + $_.mustContain + $_.systemMaycontain + $_.systemMustContain } } |
                        Select-Object -ExpandProperty Attributes

                    $SysAux = $ClassItem.SystemAuxiliaryClass

                    $SysAuxItems = foreach ($SysAuxItem in $SysAux) {
                        Get-ALHDSObject -SearchBase $ADSchema.Name -LDAPFilter "(&(ldapDisplayName=$SysAuxItem))" @GetALHADObjectParams
                    }

                    $ClassAttributes += $SysAuxItems | Select-Object @{Name = "Attributes"; Expression = { $_.maycontain + $_.systemmaycontain + $_.systemMustContain } } |
                        Select-Object -ExpandProperty Attributes

                    $ClassAttributes += $ClassItem.mayContain + $ClassItem.mustContain + $ClassItem.systemMayContain + $ClassItem.systemMustContain
                }
            }
            catch {
                $_
            }

            $ClassAttributesObj = [PSCustomObject]@{
                Class      = $ClassNameItem
                Attributes = $ClassAttributes | Sort-Object -Unique
            }

            $ClassAttributesObj
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
