<#PSScriptInfo

.VERSION 1.2.0

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
- Initial release

1.1.0
- Made script accept values for paramter ComputerName from pipeline.

1.2.0
- Added parameter 'TimeRange' to allow more user-friendly input

#>


<#

.DESCRIPTION
 Contains a function to query the securtiy event log for event id 4625 and 4771 which are logged for failed logon attempts.

#>


function Get-ALHADFailedLogonAttempt {
    <#
    .SYNOPSIS
    Function to query the securtiy event log for event id 4625 and 4771 which are logged for failed logon attempts.

    .DESCRIPTION
    Function to query the securtiy event log for event id 4625 and 4771 which are logged for failed logon attempts.
    The function can query one or multiple computers for one, multiple or any user in a given timeframe.
    This helps to identify the source of the invalid logon attempts because the events contain the source IP
    address of the logon attempt.

    .PARAMETER DomainName
    The AD domain name in which the Domain Controller will be queried, if no value
    is specified for the -Compuername parameter.

    .PARAMETER Identity
    One or more usernames (samAccountName) to search for. If ommited, events for all users ("*") are searched.

    .PARAMETER StartTime
    The datetime to start searching from. If ommited, it's set for the last two hours.

    .PARAMETER ComputerName
    One or more computernames to search for. If ommited, the script tries to get the domain controller
    with the PDC emulator role for the current domain or the domain specified with the -DomainName parameter.

    .PARAMETER ResolveDNS
    If specified, the script will try to lookup the DNS hostname of the ip address found in the event log record.
    Note that this can be misleading because the ip address shown in the event can be assigned to anohter system at the time
    of the check.

    .PARAMETER CheckLockoutStatus
    If specified, the script will check the current lockout status of the user account found in the event.

    .PARAMETER Credential
    Credentials used to query the event log. If ommited, the credentials of the user running the script are used.

    .EXAMPLE
    Get-ALHADFailedLogonAttempt

    Get events for all users in the last 2 hours from the domain ctonroller with the PDC emulator role.

    .EXAMPLE
    Get-ALHADFailedLogonAttempt -Identity 'mike' -StartTime (Get-Date).AddHours(-8)

    Get events for user with samAccountName 'mike' within the last 8 hours.

    .EXAMPLE
    Get-ALHADFailedLogonAttempt -StartTime (Get-Date).AddDays(-1) -ComputerName dc1,dc2

    Get events for any user within last 24 hours from a computers (Domain Controller) dc1 and dc2.

    .EXAMPLE
    Get-ALHADFailedLogonAttempt -Identity 'user1','user2' -StartTime (Get-Date).AddDays(-1)

    Get events for two users within the last 24 hours from Domain Controller running the PDC role.

    .EXAMPLE
    Get-Content -Path C:\Temp\Userlist.txt | Get-ALHADFailedLogonAttempt -StartTime (Get-Date).AddDays(-1)

    Get events for users from pipeline input within the last 24 hours from Domain Controller running the PDC role.

    .INPUTS
    Nothing

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADFailedLogonAttempt.txt
    #>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [string]$DomainName = $env:USERDOMAIN,

        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more user names')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Identity,

        [Parameter(ParameterSetName = "DateTime")]
        [ValidateNotNullOrEmpty()]
        [datetime]$StartTime = (Get-Date).AddHours(-2),

        [Parameter(ParameterSetName = "TimeRange")]
        [ValidateSet("1h", "2h", "4h", "6h", "8h", "12h", "15h", "18h", "21h", "1d", "2d", "3d", "4d", "5d", "6d", "7d")]
        [ValidateNotNullOrEmpty()]
        [string]$TimeRange = "1d",

        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain((New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $DomainName))).PdcRoleOwner.Name,

        [ValidateNotNullOrEmpty()]
        [switch]$ResolveDns = $false,

        [ValidateNotNullOrEmpty()]
        [switch]$CheckLockoutStatus = $false,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
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

        if ($null -eq $Credential -or $Credential.Username -eq '') {
            $CredentialsOfUser = "$env:USERDOMAIN\$env:USERNAME"
        }
        else {
            $CredentialsOfUser = $Credential.Username
        }

        $ComputerTotal = $ComputerName.Count
        $UserTotal = $Identity.Count

        #"StatusHex;StatusDec;StatusText;StatusDesc
        $Event4625FailureReasons = @{
            '-1073741715' = @{
                StatusCodeHex     = '0XC000006D'
                StatusText        = 'STATUS_LOGON_FAILURE'
                StatusDescription = 'This is either due to a bad username or authentication information'
            }
            '-1073741714' = @{
                StatusCodeHex     = '0XC000006E'
                StatusText        = 'STATUS_ACCOUNT_RESTRICTION'
                StatusDescription = 'Unknown user name or bad password'
            }
            '-1073741421' = @{
                StatusCodeHex     = '0XC0000193'
                StatusText        = 'STATUS_ACCOUNT_EXPIRED'
                StatusDescription = 'Account Expired'
            }
            '-1073741428' = @{
                StatusCodeHex     = '0XC000018C'
                StatusText        = 'STATUS_TRUSTED_DOMAIN_FAILURE'
                StatusDescription = 'The logon request failed because the trust relationship between the primary domain and the trusted domain failed'
            }
            '-1073741730' = @{
                StatusCodeHex     = '0XC000005E'
                StatusText        = 'STATUS_NO_LOGON_SERVERS'
                StatusDescription = 'There are currently no logon servers available to service the logon request'
            }
            '-1073741604' = @{
                StatusCodeHex     = '0XC00000DC'
                StatusText        = 'STATUS_INVALID_SERVER_STATE'
                StatusDescription = 'Indicates the Sam Server was in the wrong state to perform the desired operation'
            }
            '-1073741276' = @{
                StatusCodeHex     = '0XC0000224'
                StatusText        = 'STATUS_PASSWORD_MUST_CHANGE'
                StatusDescription = 'User is required to change password at next logon'
            }
            '-1073741422' = @{
                StatusCodeHex     = '0XC0000192'
                StatusText        = 'STATUS_NETLOGON_NOT_STARTED'
                StatusDescription = 'An attempt was made to logon, but the netlogon service was not started'
            }
            '-1073740781' = @{
                StatusCodeHex     = '0XC0000413'
                StatusText        = 'STATUS_AUTHENTICATION_FIREWALL_FAILED'
                StatusDescription = 'Logon Failure: The machine you are logging onto is protected by an authentication firewall. The specified account is not allowed to authenticate to the machine'
            }
            '-1073741260' = @{
                StatusCodeHex     = '0xC0000234'
                StatusText        = 'STATUS_ACCOUNT_LOCKED_OUT'
                StatusDescription = 'Account locked out'
            }
        }

        $Event4771FailureReasons = @{
            '18' = @{
                StatusCodeHex     = '0x12'
                StatusText        = 'Clients credentials have been revoked'
                StatusDescription = 'Account disabled, expired, locked out, logon hours'
            }
            '23' = @{
                StatusCodeHex     = '0x17'
                StatusText        = 'Password has expired'
                StatusDescription = 'Password has expired'
            }
            '24' = @{
                StatusCodeHex     = '0x18'
                StatusText        = 'Pre-authentication information was invalid'
                StatusDescription = 'Usually means bad password'
            }
            '37' = @{
                StatusCodeHex     = '0x25'
                StatusText        = 'Clock skew too big'
                StatusDescription = 'Clock skew too big'
            }
        }

        if ($PsCmdlet.ParameterSetName -eq "TimeRange") {
            if ($TimeRange -match "^\d{1,2}[d]$") {
                $StartTime = (Get-Date).AddDays( - ($TimeRange -replace "d", ""))

            }
            elseif ($TimeRange -match "^\d{1,2}[h]$") {
                $TimeRange -replace "h", ""
                $StartTime = (Get-Date).AddHours( - ($TimeRange -replace "h", ""))
            }
            else {
                Write-Warning -Message "Not a valid timerange. Using default time range of 2h"
                $StartTime = (Get-Date).AddHours(-2)
            }
        }

        Write-Information -MessageData "Searching in domain                       : $DomainName" -InformationAction Continue
        Write-Information -MessageData "Checking security event log on cmputer(s) : $($Computername -join ';')" -InformationAction Continue
        Write-Information -MessageData "Search timeframe                          : $StartTime - $(Get-Date)" -InformationAction Continue
        Write-Information -MessageData "Running with credentials of user          : $CredentialsOfUser" -InformationAction Continue
        Write-Information -MessageData "Searching for username(s)                 : $($Identity -join ';')" -InformationAction Continue
        Write-Information -MessageData "Resolving IP to hostname                  : $($ResolveDns.IsPresent)" -InformationAction Continue
        Write-Information -MessageData "Check current lockout status              : $($CheckLockoutStatus.IsPresent)" -InformationAction Continue
    }

    process {
        $StartTimeProc = Get-Date

        if ($input) {
            $UserTotal = $Input.Count
        }

        foreach ($computer in $ComputerName) {
            $i = 0
            Write-Progress -Activity "Searching on computer $computer" -PercentComplete ($i / $ComputerTotal * 100) -Status "Progress ->" -CurrentOperation OuterLoop
            $i++

            foreach ($user in $Identity) {
                $j = 0
                Write-Progress -Activity "Searching for user '$user'" -PercentComplete ($j / $UserTotal * 100) -Status "Progress ->" -CurrentOperation InnerLoop
                $j++

                try {
                    Write-Verbose -Message "Searching for user '$user'"

                    $Events4625 = Get-WinEvent -ComputerName $computer -FilterHashtable @{LogName = 'Security'; Id = 4625; StartTime = $StartTime } -Credential $Credential -ErrorAction SilentlyContinue
                    $StartTimeQuery4625 = Get-Date
                    Write-Verbose -Message "Number events found for id 4625 before applying filter: $(($Events4625 | Measure-Object).Count)"

                    if ($(($Events4625 | Measure-Object).Count) -gt 0) {
                        if ($user -ne "*") {
                            Write-Verbose -Message "Filtering for user $user"
                            $Events4625 = $Events4625.where( { $_.Properties[5].Value -like "$user" } )
                            Write-Verbose -Message "Number events found for id 4625 after applying filter: $(($Events4625 | Measure-Object).Count)"
                        }

                        $Events4625 `
                        | Select-Object -Property TimeCreated, `
                        @{Name = 'UserName'; Expression = { $_.Properties[5].Value } }, `
                        @{Name = 'EventID'; Expression = { '4625' } } ,
                        @{Name = 'IpAddress'; Expression = { $_.Properties[19].Value } }, `
                        @{Name = 'ClientName'; Expression = { if ($ResolveDns.IsPresent) { ([system.net.dns]::GetHostByAddress($_.Properties[19].Value)).hostname } } },
                        @{Name = 'FailureCode'; Expression = { $_.Properties[7].Value } },
                        @{Name = 'FailureReason'; Expression = { $Event4625FailureReasons."$($_.Properties[7].Value)".StatusDescription } }, `
                        @{Name = 'CurrentlyLocked'; Expression = { if ($CheckLockoutStatus.IsPresent) { (Get-ADUser $_.Properties[5].Value -Properties LockedOut).LockedOut } } }, `
                        @{Name = 'Computer'; Expression = { $computer } }
                    }
                    $StartTimeFormat4625 = Get-Date

                    $Events4771 = Get-WinEvent -ComputerName $computer -FilterHashtable @{LogName = 'Security'; Id = 4771; StartTime = $StartTime } -Credential $Credential -ErrorAction SilentlyContinue
                    $StartTimeQuery4771 = Get-Date
                    Write-Verbose -Message "Number events found for id 4771: $(($Events4771 | Measure-Object).Count)"

                    if ($(($Events4771 | Measure-Object).Count) -gt 0) {
                        if ($user -ne "*") {
                            Write-Verbose -Message "Filtering for user $user"
                            $Events4771 = $Events4771.where( { $_.Properties[0].Value -like "$user" } )
                            Write-Verbose -Message "Number events found for id 4771 after applying filter: $(($Events4771 | Measure-Object).Count)"
                        }

                        $Events4771 `
                        | Select-Object -Property TimeCreated, `
                        @{Name = 'UserName'; Expression = { $_.Properties[0].Value } }, `
                        @{Name = 'EventID'; Expression = { '4771' } },
                        @{Name = 'IpAddress'; Expression = { if ($_.Properties[6].Value -match "::ffff:") { $_.Properties[6].Value.Substring(7) } else { $_.Properties[6].Value } } }, `
                        @{Name = 'ClientName'; Expression = { if ($ResolveDns.IsPresent) { ([system.net.dns]::GetHostByAddress($_.Properties[6].Value)).hostname } else { '' } } },
                        @{Name = 'FailureCode'; Expression = { $_.Properties[4].Value } },
                        @{Name = 'FailureReason'; Expression = { $Event4771FailureReasons."$($_.Properties[4].Value)".StatusDescription } }, `
                        @{Name = 'CurrentlyLocked'; Expression = { if ($CheckLockoutStatus.IsPresent) { (Get-ADUser $_.Properties[5].Value -Properties LockedOut).LockedOut } else { '' } } }, `
                        @{Name = 'Computer'; Expression = { $computer } }
                    }
                    $StartTimeFormat4771 = Get-Date
                }
                catch [System.Exception] {
                    if ($_.FullyQualifiedErrorID -eq 'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand') {
                        Write-Verbose -Message "No events returned in search"
                    }
                    else {
                        $_
                    }
                }
                catch {
                    $_
                }
            }
        }
    }

    end {
        <#
        if ($($LockedOutUsers | Measure-Object).Count -eq 0) {
            Write-Information -MessageData "`n`nNo records found matching search criteria. Try extending the timeframe.`n" -InformationAction Continue
        }
        else {
            $LockedOutUsers | Sort-Object -Property Username, TimeCreated
        }
        #>

        Write-Verbose -Message "Elapsed time in seconds - TOTAL:      $((((Get-Date) - $StartTimeProc).Totalseconds))"
        Write-Verbose -Message "Elapsed time in seconds - QUERY4625:  $((($StartTimeQuery4625 - $StartTimeProc).Totalseconds))"
        Write-Verbose -Message "Elapsed time in seconds - FORMAT4625: $((($StartTimeFormat4625 - $StartTimeQuery4625).Totalseconds))"
        Write-Verbose -Message "Elapsed time in seconds - QUERY4771:  $((($StartTimeQuery4771 - $StartTimeFormat4625).Totalseconds))"
        Write-Verbose -Message "Elapsed time in seconds - FORMAT4771: $((($StartTimeFormat4771 - $StartTimeQuery4771).Totalseconds))"
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
