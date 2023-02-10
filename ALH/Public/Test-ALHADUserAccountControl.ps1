<#PSScriptInfo

.VERSION 1.0.2

.GUID db7b7c25-39c2-4ea1-9cbd-36905aa261c4

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    1.0.0
    Initial release

    1.0.1
    Corrected comments

    1.0.2
    Corrected description of parameters

#>


<#

.DESCRIPTION
 Contains function to convert an integer value to UserAccountControl flags.

#>


function Test-ALHADUserAccountControl {
    <#
    .SYNOPSIS
    Tests if a given UserAccountControl value matches a specific UAC flag.

    .DESCRIPTION
    Tests if a given UserAccountControl value matches a specific UAC flag.

    .PARAMETER UacFlagToCheck
    Optional. UAC Flag to test for.

    .PARAMETER UacValue
    Optional. The value of the UserAccountControl attribute of an AD object.

    .PARAMETER ReturnInt
    Optional. If specified, the function returns the integer value of the UAC flag.

    .EXAMPLE
    Check if a given UserAccountControl value means that the account is disabled. Returns $true or $false
    Test-ALHADUserAccountControl -UacFlagToCheck ACCOUNTDISABLE -UacValue (Get-ADUser -Identity User1 -Property UserAccountControl).UserAccountControl

    .EXAMPLE
    Check if a given UserAccountControl value means that the account is disabled. Returns the integer value of the UserAccountControl flag
    Test-ALHADUserAccountControl -UacFlagToCheck ACCOUNTDISABLE -UacValue 514 -ReturnInt

    .INPUTS
    Integer

    .OUTPUTS
    Boolean or Integer

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Test-ALHADUserAccountControl.txt

    .LINK
    http://woshub.com/decoding-ad-useraccountcontrol-value/
    
    .LINK
    https://docs.microsoft.com/en-US/troubleshoot/windows-server/identity/useraccountcontrol-manipulate-account-properties
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [ValidateSet ("SCRIPT",
            "ACCOUNTDISABLE",
            "HOMEDIR_REQUIRED",
            "LOCKOUT",
            "PASSWD_NOTREQD",
            "PASSWD_CANT_CHANGE",
            "ENCRYPTED_TEXT_PWD_ALLOWED",
            "TEMP_DUPLICATE_ACCOUNT",
            "NORMAL_ACCOUNT",
            "INTERDOMAIN_TRUST_ACCOUNT",
            "WORKSTATION_TRUST_ACCOUNT",
            "SERVER_TRUST_ACCOUNT",
            "DONT_EXPIRE_PASSWORD",
            "MNS_LOGON_ACCOUNT",
            "SMARTCARD_REQUIRED",
            "TRUSTED_FOR_DELEGATION",
            "NOT_DELEGATED",
            "USE_DES_KEY_ONLY",
            "DONT_REQ_PREAUTH",
            "PASSWORD_EXPIRED",
            "TRUSTED_TO_AUTH_FOR_DELEGATION",
            "PARTIAL_SECRETS_ACCOUNT")]
        [string]
        $UacFlagToCheck,

        [int]
        $UacValue,

        [switch]
        $ReturnInt
    )

    $UacFlags = [hashtable][ordered]@{}
    $UacFlags.Add('SCRIPT', 1)
    $UacFlags.Add('ACCOUNTDISABLE', 2)
    $UacFlags.Add('HOMEDIR_REQUIRED', 8)
    $UacFlags.Add('LOCKOUT', 16)
    $UacFlags.Add('PASSWD_NOTREQD', 32)
    $UacFlags.Add('PASSWD_CANT_CHANGE', 64)
    $UacFlags.Add('ENCRYPTED_TEXT_PWD_ALLOWED', 128)
    $UacFlags.Add('TEMP_DUPLICATE_ACCOUNT', 256)
    $UacFlags.Add('NORMAL_ACCOUNT', 512)
    $UacFlags.Add('INTERDOMAIN_TRUST_ACCOUNT', 2048)
    $UacFlags.Add('WORKSTATION_TRUST_ACCOUNT', 4096)
    $UacFlags.Add('SERVER_TRUST_ACCOUNT', 8192)
    $UacFlags.Add('DONT_EXPIRE_PASSWORD', 65536)
    $UacFlags.Add('MNS_LOGON_ACCOUNT', 131072)
    $UacFlags.Add('SMARTCARD_REQUIRED', 262144)
    $UacFlags.Add('TRUSTED_FOR_DELEGATION', 524288)    
    $UacFlags.Add('NOT_DELEGATED', 1048576)
    $UacFlags.Add('USE_DES_KEY_ONLY', 2097152)
    $UacFlags.Add('DONT_REQ_PREAUTH', 4194304)
    $UacFlags.Add('PASSWORD_EXPIRED', 8388608)
    $UacFlags.Add('TRUSTED_TO_AUTH_FOR_DELEGATION', 16777216)
    $UacFlags.Add('PARTIAL_SECRETS_ACCOUNT', 67108864)

    if ($null -eq $UacValue -or $UacValue -eq 0) {
        $Result = $UacFlags.$UacFlagToCheck
    }
    else {
        if ($ReturnInt.IsPresent) {
            if ([bool]$($UacValue -band $UacFlags.$UacFlagToCheck)) {
                $Result = $UacValue
            }
            else {
                $Result = -1
            }
        }
        else {
            $Result = [bool]$($UacValue -band $UacFlags.$UacFlagToCheck)
        }
    }

    $Result
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
