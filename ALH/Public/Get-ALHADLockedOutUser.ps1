<#PSScriptInfo

.VERSION 1.2.0

.GUID 2d7def26-aa85-4328-9e02-6c7ed0068024

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
- Initial release

1.1.0
- Made script accept values for paramter ComputerName from pipeline.

1.2.0
- Added parameter 'TimeRange' to allow more user-friendly input
#>


<#

.DESCRIPTION
 Contains a function to query the securtiy event log for event id 4740 which is logged in case a user account gets locked out.

#>


function Get-ALHADLockedOutUser {
    <#
    .SYNOPSIS
    Function to query the securtiy event log for event id 4740 which is logged in case a user account gets locked out.
     
    .DESCRIPTION
    Function to query the securtiy event log for event id 4740 which is logged in case a user account gets locked out.
    The function can query one or multiple computers for one, multiple or any user in a given timeframe.
    This helps to identify the source of the invalid logon attemps because the events contain the source IP
    address of the logon attempt.
     
    .PARAMETER DomainName
    The AD domain name in which the Domain Controller will be queried, if no value 
    is specified for the -Compuername parameter
     
    .PARAMETER Identity
    One or more usernames (samAccountName) to search for. If ommited, events for all users ("*") are searched.
     
    .PARAMETER StartTime
    The datetime to start searching from. If ommited, it's set for the last two hours.
     
    .PARAMETER ComputerName
    One or more computernames to search for. If ommited, the script tries to get the domain controller
    with the PDC emulator role for the current domain or the domain specified with the -DomainName parameter.
     
    .PARAMETER Credential
    Credentials used to query the event log. If ommited, the credentials of the user running the script are used.
     
    .EXAMPLE
    Get events for all users in the last 2 hours from the domain ctonroller with the PDC emulator role.
    Get-ALHADFailedLogonAttemps
     
    .EXAMPLE
    Get events for user with samAccountName 'mike' within the last 8 hours
    Get-ALHADFailedLogonAttemps -Identity 'mike' -StartTime (Get-Date).AddHours(-8)
     
    .EXAMPLE
    Get events for any user within last 24 hours from a computers (Domain Controller) dc1 and dc2 
    Get-ALHADFailedLogonAttemps -StartTime (Get-Date).AddDays(-1) -ComputerName dc1,dc2
     
    .EXAMPLE
    Get events for two users within the last 24 hours from Domain Controller running the PDC role
    Get-ALHADFailedLogonAttemps -Identity 'user1','user2' -StartTime (Get-Date).AddDays(-1)

    .EXAMPLE
    Get events for users from pipeline input within the last 24 hours from Domain Controller running the PDC role
    Get-Content -Path C:\Temp\Userlist.txt | Get-ALHADFailedLogonAttemps -StartTime (Get-Date).AddDays(-1)

    .INPUTS
    Nothing

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADLockedOutUser.txt
    #>
   
    [CmdletBinding(DefaultParameterSetName = "default")]
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

        Write-Information -Message "Searching in domain                       : $DomainName" -InformationAction Continue
        Write-Information -Message "Checking security event log on cmputer(s) : $($Computername -join ';')" -InformationAction Continue
        Write-Information -Message "Search timeframe                          : $StartTime - $(Get-Date)" -InformationAction Continue
        Write-Information -Message "Running with credentials of user          : $CredentialsOfUser" -InformationAction Continue
        Write-Information -Message "Searching for username(s)                 : $($Identity -join ';')" -InformationAction Continue
    }
    
    process {
        if ($input) {
            $UserTotal = $Input.Count
        }

        foreach ($computer in $ComputerName) {
            $i = 0
            Write-Progress -Activity "Searching on computer $computer" -PercentComplete ($i / $ComputerTotal * 100) -Status "Progress ->" -CurrentOperation OuterLoop
            $i++

            foreach ($user in $Identity) {
                $j = 0
                Write-Progress -Activity "Searching on computer $computer" -PercentComplete ($j / $UserTotal * 100) -Status "Progress ->" -CurrentOperation InnerLoop
                $j++

                try {
                    Get-WinEvent -ComputerName $computer -FilterHashtable @{LogName = 'Security'; Id = 4740; StartTime = $StartTime } -Credential $Credential -ErrorAction SilentlyContinue `
                    | Where-Object { $_.Properties[0].Value -like "$user" } `
                    | Select-Object -Property TimeCreated, `
                    @{Name = 'UserName'; Expression = { $_.Properties[0].Value } }, `
                    @{Name = 'ClientName'; Expression = { $_.Properties[1].Value } }, `
                    @{Name = 'CurrentlyLocked'; Expression = { (Get-ADUser $_.Properties[0].Value -Properties LockedOut).LockedOut } }, `
                    @{Name = 'Computer'; Expression = { $computer } } `
                    | Sort-Object -Property Username, TimeCreated
                }
                catch {
                    Write-Error $_
                }
            }
        }
    }
    
    end {
        <#
        if ($($LockedOutUsers | Measure-Object).Count -eq 0) {
            Write-Information -Message "`n`nNo records found matching search criteria. Try extending the timeframe.`n" -InformationAction Continue
        }
        else {
            $LockedOutUsers
        }
        #>
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
