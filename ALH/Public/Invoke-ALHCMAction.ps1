<#PSScriptInfo

.VERSION 1.1.0

.GUID ec7fd3c0-abc2-43cf-a062-cfeea14f9378

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
Made script accept values for paramter ComputerName from pipeline.

#>


<#

.DESCRIPTION
Contains a function to trigger Configuration Manager tasks

#>


$CMScheduleActions = @{
    "Hardware Inventory"                                = "{00000000-0000-0000-0000-000000000001}"
    "Software Inventory"                                = "{00000000-0000-0000-0000-000000000002}"
    "Data Discovery Record"                             = "{00000000-0000-0000-0000-000000000003}"
    "File Collection"                                   = "{00000000-0000-0000-0000-000000000010}"
    "IDMIF Collection"                                  = "{00000000-0000-0000-0000-000000000011}"
    "Client Machine Authentication"                     = "{00000000-0000-0000-0000-000000000012}"
    "Machine Policy Assignments Request"                = "{00000000-0000-0000-0000-000000000021}"
    "Machine Policy Evaluation"                         = "{00000000-0000-0000-0000-000000000022}"
    "Refresh Default MP Task"                           = "{00000000-0000-0000-0000-000000000023}"
    "Location Service Refresh Locations Task"           = "{00000000-0000-0000-0000-000000000024}"
    "Location Service Timeout Refresh Task"             = "{00000000-0000-0000-0000-000000000025}"
    "Policy Agent Request Assignment (User)"            = "{00000000-0000-0000-0000-000000000026}"
    "Policy Agent Evaluate Assignment (User)"           = "{00000000-0000-0000-0000-000000000027}"
    "Software Metering Generating Usage Report"         = "{00000000-0000-0000-0000-000000000031}"
    "Source Update Message"                             = "{00000000-0000-0000-0000-000000000032}"
    "Clearing proxy settings cache"                     = "{00000000-0000-0000-0000-000000000037}"
    "Machine Policy Agent Cleanup"                      = "{00000000-0000-0000-0000-000000000040}"
    "User Policy Agent Cleanup"                         = "{00000000-0000-0000-0000-000000000041}"
    "Policy Agent Validate Machine Policy - Assignment" = "{00000000-0000-0000-0000-000000000042}"
    "Policy Agent Validate User Policy - Assignment"    = "{00000000-0000-0000-0000-000000000043}"
    "Retrying/Refreshing certificates in AD on MP"      = "{00000000-0000-0000-0000-000000000051}"
    "Peer DP Status reporting"                          = "{00000000-0000-0000-0000-000000000061}"
    "Peer DP Pending package check schedule"            = "{00000000-0000-0000-0000-000000000062}"
    "SUM Updates install schedule"                      = "{00000000-0000-0000-0000-000000000063}"
    "Hardware Inventory Collection Cycle"               = "{00000000-0000-0000-0000-000000000101}"
    "Software Inventory Collection Cycle"               = "{00000000-0000-0000-0000-000000000102}"
    "Discovery Data Collection Cycle"                   = "{00000000-0000-0000-0000-000000000103}"
    "File Collection Cycle"                             = "{00000000-0000-0000-0000-000000000104}"
    "IDMIF Collection Cycle"                            = "{00000000-0000-0000-0000-000000000105}"
    "Software Metering Usage Report Cycle"              = "{00000000-0000-0000-0000-000000000106}"
    "Windows Installer Source List Update Cycle"        = "{00000000-0000-0000-0000-000000000107}"
    "Software Updates Assignments Evaluation Cycle"     = "{00000000-0000-0000-0000-000000000108}"
    "Branch Distribution Point Maintenance Task"        = "{00000000-0000-0000-0000-000000000109}"
    "Send Unsent State Message"                         = "{00000000-0000-0000-0000-000000000111}"
    "State System policy cache cleanout"                = "{00000000-0000-0000-0000-000000000112}"
    "Scan by Update Source"                             = "{00000000-0000-0000-0000-000000000113}"
    "Update Store Policy"                               = "{00000000-0000-0000-0000-000000000114}"
    "State system policy bulk send high"                = "{00000000-0000-0000-0000-000000000115}"
    "State system policy bulk send low"                 = "{00000000-0000-0000-0000-000000000116}"
    "Application manager policy action"                 = "{00000000-0000-0000-0000-000000000121}"
    "Application manager user policy action"            = "{00000000-0000-0000-0000-000000000122}"
    "Application manager global evaluation action"      = "{00000000-0000-0000-0000-000000000123}"
    "Power management start summarizer"                 = "{00000000-0000-0000-0000-000000000131}"
    "Endpoint deployment reevaluate"                    = "{00000000-0000-0000-0000-000000000221}"
    "Endpoint AM policy reevaluate"                     = "{00000000-0000-0000-0000-000000000222}"
    "External event detection"                          = "{00000000-0000-0000-0000-000000000223}"
}


function Invoke-ALHCMAction {
    <#
    .SYNOPSIS
        Runs ConfigMgr Actions like hardware inventory, policy refresh etc.

    .DESCRIPTION
        Runs ConfigMgr Actions like hardware inventory, policy refresh etc.

    .PARAMETER ComputerName
        Name of a remote computer. If no name is sepcified, the command runs agains the local computer.
        Multiple Names can be specified as comma separated strings.

    .PARAMETER Credential
        Credentials that will be used for remote system.

    .EXAMPLE
        Invoke Hardware Inventory and Machine Policy Evaluation tasks on computer Computer1 and Computer2
        $Result = Invoke-ALHCMAction -ComputerName Computer1, Computer2 -Action 'Hardware Inventory', 'Machine Policy Evaluation' -Credential $CredentialForRemote  -Verbose
        $Result

    .INPUTS
        System.String

    .OUTPUTS
        Nothing

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Invoke-ALHCMAction.txt
    #>

    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, HelpMessage = 'Enter one or more computer names')]
        [string[]]
        $ComputerName,

        [parameter(Mandatory = $true)]
        [pscredential]
        $Credential
    )

    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'Action'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet
        $arrSet = $CMScheduleActions.keys
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string[]], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    begin {
        # Bind the parameter to a friendly variable
        $Action = $PsBoundParameters[$ParameterName]

        Write-Verbose -Message "Running the following actions for all specified computers: "
        $Action | ForEach-Object { Write-Verbose -Message "--> $_" }

        Write-Verbose -Message "Computers specified:  "
        $ComputerName | ForEach-Object { Write-Verbose -Message "  --> $_" }
    }

    process {
        foreach ($computer in $ComputerName) {
            Write-Verbose -Message "Checkig if system is reachable via WSMAN --> $($computer.ToUpper())"

            if (Test-WSMan -ComputerName $computer -Authentication Kerberos -Credential $Credential -ErrorAction SilentlyContinue) {
                $IsConfigMgrInstalled = $null
                Write-Verbose -Message "Checking if ConifgMgr Client is installed on sytem $($computer.ToUpper())"
                $IsConfigMgrInstalled = Get-CimClass -ComputerName $computer -ClassName SMS_CLIENT -Namespace ROOT\ccm

                if ($null -ne $IsConfigMgrInstalled) {
                    try {
                        foreach ($ActionToRun in $Action) {
                            Write-Verbose -Message "Triggering action on $($computer.ToUpper()) --> $ActionToRun --> $($CMScheduleActions."$ActionToRun")"

                            $ActionString = "$($CMScheduleActions."$ActionToRun")"

                            Invoke-Command -ComputerName $computer { Invoke-CimMethod -Namespace ROOT\ccm -Class SMS_CLIENT -Name TriggerSchedule -Arguments @{sScheduleID = $using:ActionString } } -Credential $Credential
                        }
                    }
                    catch {
                        $_
                    }
                }
            }
            else {
                Write-Verbose "System not reachable via WSMAN - SKIPPING --> $($computer.ToUpper())"
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
