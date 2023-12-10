<#PSScriptInfo

.VERSION 1.1.0

.GUID 2138fa89-6384-4b9f-898b-f7014d9853f5

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

    1.1.0
    Added parameter msDSUserAccountControlComputed required by a change for attribute userAccountControl in Windows Server 2003 AD.
    For details see https://docs.microsoft.com/en-US/troubleshoot/windows-server/identity/useraccountcontrol-manipulate-account-properties

#>


<#

.DESCRIPTION
Contains a function to convert an integer value to UserAccountControl flags.

.LINK
https://github.com/admins-little-helper/ALH

.LINK
https://docs.microsoft.com/en-US/troubleshoot/windows-server/identity/useraccountcontrol-manipulate-account-properties

#>


function Convert-ALHADUserAccountControl {
    <#
    .SYNOPSIS
        Converts an integer value to UserAccountControl flags.

    .DESCRIPTION
        The function 'Convert-ALHADUserAccountControl' converts an integer value to UserAccountControl flags.
        This allows to take the raw value form the 'UserAccountControl' and/or 'msDS-User-Account-Control-Computed' property
        of an Active Directory object and get a describtive name for the flags set.

    .PARAMETER UserAccountControl
        Integer value of the 'UserAccountControl' attribute of an Active Directory object.

    .PARAMETER msDSUserAccountControlComputed
        Integer value of the 'msDS-User-Account-Control-Computed' attribute of an Active Directory object.

    .EXAMPLE
        Convert-ALHADUserAccountControl -UserAccountControl 514

        ACCOUNTDISABLE
        NORMAL_ACCOUNT

        Returns the flags for value 514.

    .EXAMPLE
        Convert-ALHADUserAccountControl -UserAccountControl 514 -msDSUserAccountControlComputed 8388624

        ACCOUNTDISABLE
        LOCKOUT
        NORMAL_ACCOUNT
        PASSWORD_EXPIRED

        Returns the flags for UserAccountControl value of 514 and ms-sDSUserAccountControlComputed value of 8388624.

    .INPUTS
        System.Int32

    .OUTPUTS
        System.String

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Convert-ALHADUserAccountControl.txt
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [int]
        $UserAccountControl,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [int]
        $msDSUserAccountControlComputed
    )

    begin {
        # Combine the UserAccountControl value and the msDSUserAccountControlComputed value (see Microsoft documentation for details about this).
        $UserAccountControl = $UserAccountControl -bor $msDSUserAccountControlComputed

        $UACPropertyFlags = @(
            "SCRIPT",
            "ACCOUNTDISABLE",
            "RESERVED",
            "HOMEDIR_REQUIRED",
            "LOCKOUT",
            "PASSWD_NOTREQD",
            "PASSWD_CANT_CHANGE",
            "ENCRYPTED_TEXT_PWD_ALLOWED",
            "TEMP_DUPLICATE_ACCOUNT",
            "NORMAL_ACCOUNT",
            "RESERVED",
            "INTERDOMAIN_TRUST_ACCOUNT",
            "WORKSTATION_TRUST_ACCOUNT",
            "SERVER_TRUST_ACCOUNT",
            "RESERVED",
            "RESERVED",
            "DONT_EXPIRE_PASSWORD",
            "MNS_LOGON_ACCOUNT",
            "SMARTCARD_REQUIRED",
            "TRUSTED_FOR_DELEGATION",
            "NOT_DELEGATED",
            "USE_DES_KEY_ONLY",
            "DONT_REQ_PREAUTH",
            "PASSWORD_EXPIRED",
            "TRUSTED_TO_AUTH_FOR_DELEGATION",
            "RESERVED",
            "PARTIAL_SECRETS_ACCOUNT"
            "RESERVED"
            "RESERVED"
            "RESERVED"
            "RESERVED"
            "RESERVED"
        )
    }

    process {
        <#
        # This is the long version of the code below. Just added it to explain how it works.

        $i = 0
        $FlagsSet = foreach($Flag in $UACPropertyFlags) {
            if($UserAccountControl -bAnd [math]::Pow(2, $i)) {
                foreach($item in $Flag) {
                    $UACPropertyFlags[$i]
                }
            }

            $i++
        }
        #>

        $FlagsSet = (0..($UACPropertyFlags.Length) | Where-Object { $UserAccountControl -bAnd [math]::Pow(2, $_) } | ForEach-Object { $UACPropertyFlags[$_] })
        $FlagsSet
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
