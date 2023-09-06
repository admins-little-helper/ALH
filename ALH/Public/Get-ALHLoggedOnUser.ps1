
<#PSScriptInfo

.VERSION 1.0.0

.GUID cec0fe6a-c91c-4919-95bc-bf040f64fadf

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
 - Initial Release

#>


<#

.DESCRIPTION
Contains function to check for any logged on users (either interactivly on the console or via Remote Desktop)

#>

function Get-ALHLoggedOnUser {
    <#
    .SYNOPSIS
    Returns all users currently logged on to local or or remote computer

    .DESCRIPTION
    Returns all users currently logged on to local or or remote computer

    .PARAMETER ComputerName
    One or more computernames

    .EXAMPLE
    Get-ALHLoggedOnUser

    ComputerName   : MYCOMPUTER
	ComputerStatus : Online
	Username       : user1
	SessionName    : rdp-tcp#17
	ID             : 2
	State          : Active
	IdleTime       : .
	LogonTime      : 02.12.2022 07:26:00

    Shows the users logged into the local system

    .EXAMPLE
    Get-ALHLoggedOnUser -Computer server1,server2,server3 | Format-Table -AutoSize

	ComputerName   ComputerStatus Username SessionName ID State  IdleTime LogonTime
	------------   -------------- -------- ----------- -- -----  -------- ---------
	SERVER1        Online         userA    rdp-tcp#17  2  Active .        02.12.2022 07:26:00
	SERVER2        Online         userB    console     2  Active .        02.12.2022 07:28:00
	SERVER3        Online         userC    rdp-tcp#18  2  Active .        02.12.2022 08:42:00

    Shows the users logged into server1, server2, and server3

    .INPUTS
    System.String for parameter 'ComputerName'

    .OUTPUTS
    System.Boolean

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHLoggedOnUser.txt
    #>

    [OutputType([PSCustomObject])]
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [string[]]
        $ComputerName = $env:COMPUTERNAME,

        [switch]
        $SkipConnectionTest
    )

    process {
        foreach ($SingleComputer in $ComputerName) {
            # Prepare empty object to have something to return.
            $Result = [PSCustomObject]@{
                ComputerName   = $SingleComputer
                ComputerStatus = $null
                Username       = $null
                SessionName    = $null
                ID             = $null
                State          = $null
                IdleTime       = $null
                LogonTime      = $null
            }

            if ($SingleComputer -eq $env:COMPUTERNAME) {
                Write-Verbose -Message "Skipping connection test for local computer."
                $ComputerOnline = $true
            }
            elseif ($SkipConnectionTest.IsPresent) {
                Write-Verbose -Message "Skipping connection test."
                $ComputerOnline = $true
            }
            else {
                Write-Verbose -Message "Testing if computer is online: '$SingleComputer'"
                $ComputerOnline = Test-Connection -ComputerName $SingleComputer -Count 2 -Quiet -ErrorAction SilentlyContinue
            }

            if ($ComputerOnline) {
                $Result.ComputerStatus = "Online"

                $stringOutput = quser /server:$SingleComputer 2>$null

                if ([string]::IsNullOrEmpty($stringOutput)) {
                    Write-Verbose "No logged on user found for computer '$SingleComputer'"
                }
                else {
                    foreach ($line in $stringOutput) {
                        if ($line -notmatch "logon time") {
                            $Result.Username = $line.SubString(1, 20).Trim()
                            $Result.SessionName = $line.SubString(23, 17).Trim()
                            $Result.ID = $line.SubString(42, 2).Trim()
                            $Result.State = $line.SubString(46, 6).Trim()
                            $Result.IdleTime = $line.SubString(54, 9).Trim()
                            $Result.LogonTime = [datetime]::Parse($line.SubString(65))

                            # Initialize the time variables.
                            $Minutes = $Hours = $Days = 0

                            if ($Result.IdleTime -match "\d") {
                                # In case the idle time contains a digit, we try to parse it to get minutes, hours and days.
                                # Replace '.' with '0' because the string contains only a dot in case of an active session.
                                # Split the string by '+' and ':'.
                                # '+' separates days and hours.
                                # ':' separates hours and minutes.
                                $Tokens = $Result.IdleTime -replace '\.', '0' -split ':' -split '\+'

                                # reverse the results, so the first element in the array contains the minutes.
                                # if there is a second element (hours), it will contain hours.
                                # if there is a third element, it will contain days.
                                [array]::Reverse($Tokens)

                                if ($Tokens.Count -ge 1) { $Minutes = $Tokens[0] }
                                if ($Tokens.Count -ge 2) { $Hours = $Tokens[1] }
                                if ($Tokens.Count -ge 3) { $Days = $Tokens[2] }
                            }

                            # Set the IdleTime to a TimeSpan value.
                            $Result.IdleTime = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes
                        }
                    }
                }
            }
            else {
                Write-Verbose "Computer is offline: $SingleComputer"
                $Result.ComputerStatus = "Offline"
            }

            $Result.psobject.TypeNames.Insert(0, 'ALHLoggedOnUser')
            $Result
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
