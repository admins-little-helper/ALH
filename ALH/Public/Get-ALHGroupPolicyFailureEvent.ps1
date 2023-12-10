<#PSScriptInfo

.VERSION 1.1.0

.GUID 29c961ad-ed17-4bd5-8ded-985a3ce68d5f

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
- Initial release

1.1.0
Made script accept values for paramter ComputerName from pipeline.

#>


<#

.DESCRIPTION
 Contains a function to query system eventlog for event id 1096 which indicates problems in applying computer group policy.

#>


function Get-ALHGroupPolicyFailureEvent {
    <#
    .SYNOPSIS
        Function to query system eventlog for event id 1096 which indicates problems in applying computer group policy.

    .DESCRIPTION
        The function 'Get-ALHGroupPolicyFailureEvent' queries the system eventlog for event id 1096 which indicates problems in applying computer group policy.
        The function can query one or multiple computers for one, multiple or any user in a given timeframe.

    .PARAMETER StartTime
        The datetime to start searching from. If ommited, it's set for the last two hours.

    .PARAMETER ComputerName
        Optional. One or more computernames to search for. If ommited, the script tries to get the domain controller
        with the PDC emulator role for the current domain or the domain specified with the -DomainName parameter.

    .PARAMETER Credential
        Optional. Credentials used to query the event log. If ommited, the credentials of the user running the script are used.

    .EXAMPLE
        Get-ALHGroupPolicyFailureEvent
        This will run the query on the local computer and show the results.

    .EXAMPLE
        Get-ALHGroupPolicyFailureEvent -StartTime (Get-Date).AddHours(-24) -ComputerName COMPUTER01
        This will run the query on computer 'COMPUTER01' and searching all events in the last 24 hours.

    .INPUTS
        System.String for parameter 'ComputerName'

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHGroupPolicyFailureEvent.txt
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [datetime]$StartTime = (Get-Date).AddHours(-2),

        [Parameter(ValueFromPipeline, HelpMessage = 'Enter one or more computer names')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    begin {
        # Note: This will only count objects if the computer names are given by parameter.
        # In case the input comes from the pipeline, it will always be 1.
        # For more information see https://stackoverflow.com/questions/67529017/powershell-is-there-a-way-to-get-the-total-count-of-objects-piped-into-a-functi
        $ComputerCountTotal = $ComputerName.Count
    }

    process {
        foreach ($SingleComputer in $ComputerName) {
            Write-Verbose -Message "Querying computer: '$SingleComputer'"
            $i = 0
            Write-Progress -Activity "Querying computer: '$SingleComputer'" -PercentComplete ($i / $ComputerCountTotal * 100) -Status "Progress ->" -CurrentOperation OuterLoop
            $i++

            try {
                $GetWinEventParams = @{
                    ComputerName    = $SingleComputer
                    FilterHashtable = @{
                        LogName   = 'System'
                        Id        = 1096
                        StartTime = $StartTime
                    }
                    Credential      = $Credential
                    ErrorAction     = 'SilentlyContinue'
                }

                $Events1096 = Get-WinEvent @GetWinEventParams
                $EventsFoundCount = ($Events1096 | Measure-Object).Count

                Write-Verbose -Message "Number events found: $EventsFoundCount"

                if ($EventsFoundCount -gt 0) {
                    foreach ($Event in $EventsFoundCount) {
                        $Result = @{
                            TimeCreated                  = $Event.TimeCreated
                            EventID                      = 1096
                            SupportInfo1                 = $Event.Properties[0].Value
                            SupportInfo2                 = $Event.Properties[1].Value
                            ProcessingMode               = $Event.Properties[2].Value
                            ProcessingTimeInMilliseconds = $Event.Properties[3].Value
                            ErrorCode                    = $Event.Properties[4].Value
                            ErrorDescription             = $Event.Properties[5].Value
                            DCName                       = $Event.Properties[6].Value
                            GPOCNName                    = $Event.Properties[7].Value
                            FilePath                     = $Event.Properties[8].Value
                            Computer                     = $SingleComputer
                        }

                        $Result
                    }
                }
            }
            catch [System.Exception] {
                if ($_.FullyQualifiedErrorID -eq 'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand') {
                    Write-Information -MessageData "No events returned in search" -InformationAction Continue
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
