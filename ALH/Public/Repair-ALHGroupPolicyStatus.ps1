<#PSScriptInfo

.VERSION 1.1.0

.GUID 15a0a82d-6d90-4f28-b2ff-32fe59cee3b5

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

1.1.0
Code cleaned up

#>


<#

.DESCRIPTION
Contains a function to repair corrupt group policy local store

#>


function Repair-ALHGroupPolicyStatus {
    <#
    .SYNOPSIS
    Function to repair corrupt group policy local store.
     
    .DESCRIPTION
    Function to repair corrupt group policy local store.
     
    .PARAMETER MachinePolicy
    Repair computer group policy.
     
    .PARAMETER ReportOnly
    Only report problems. If ommitted and problems are found, the script attemtps to repair it.
     
    .PARAMETER ComputerName
    Allows to specify remote computer name. By default it will run against the local computer.
     
    .PARAMETER Credential
    Specify credentials with necessary permissions to query the system event log on the given computer.
     
    .EXAMPLE
    Repair-ALHGroupPolicyStatus

    Run check for machine group policy and repair if issues are detected.

    .EXAMPLE
    Repair-ALHGroupPolicyStatus -Computer -ReportOnly -Verbose

    Run check for group policy and report only if issues are detected.

    .INPUTS
    Nothing

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Repair-ALHGroupPolicyStatus.txt
    #>
    
    [CmdletBinding()]
    param(
        [switch]
        $ReportOnly,

        [ValidateNotNullOrEmpty()]
        [string]
        $ComputerName = "$env:COMPUTERNAME",

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty
    )

    $GroupPolicyStatus = Test-ALHGroupPolicyStatus -ComputerName $ComputerName -Credential $Credential -ReturnDetails

    if ($GroupPolicyStatus -ne $false) {
        if ($ReportOnly.IsPresent) {
            Write-Verbose -Message "Group Policy status test indicates problem."
        }
        else {
            $RegistryPolFile = ($GroupPolicyStatus | Select-Object -Last 1 -Property FilePath).FilePath
            Write-Verbose -Message "Group Policy status test indicates problem. Trying to repair it."
            Write-Verbose -Message "Trying to remove file $RegistryPolFile on computer $ComputerName"
                
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                Remove-Item -Path $using:RegistryPolFile -Force
                Write-Verbose -Message "Running gpupdate /force..."
                Start-Process -FilePath "$env:SystemRoot\system32\gpupdate.exe" -ArgumentList "/force" -WindowStyle Hidden
            }
        }
    }
    else {
        Write-Verbose -Message "Group Policy status test indicates no problem."
    }

    Write-Verbose -Message "Done"
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
