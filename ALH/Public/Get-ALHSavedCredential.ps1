<#PSScriptInfo

.VERSION 1.1.0

.GUID 899d0d26-7c9e-4356-a846-bb1f6ee7b579

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) 2021-2023 Dieter Koch

.TAGS

.LICENSEURI  https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
1.0.0
Initial release

1.1.0
Cleaned up code

#>


<#

.DESCRIPTION
 Contains a function to retrieve credentials in a secure way.

#>


function Get-ALHSavedCredential {
    <# 
    .SYNOPSIS
    Retrieve saved credentials (username and secure string password) from files.
    
    .DESCRIPTION
    Retrieve saved credentials (username and secure string password) from files.
    
    .PARAMETER Path
    Path to search in for credential files.

    .PARAMETER FileNamePrefix
    Filename prefix to use for credential files.

    .EXAMPLE
    Get-ALHSavedCredential -Path C:\Admin\Credentials -FileNamePrefix "CredForApp1"

    Get credentials for App1.

    .INPUTS
    Nothing

    .OUTPUTS
    PSCredential

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHSavedCredential.txt
    #>
    
    param
    (                     
        [parameter(Mandatory)]
        [ValidateNotNull()]
        [String]
        $Path,

        [parameter(Mandatory)]
        [ValidateNotNull()]
        [String]
        $FileNamePrefix
    )
    
    Write-Verbose -Message "Checking if path and filename exist"
    if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "Path exists and is accessable"
            
        $FullPathFileIdentity = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Identity.txt"
        $FullPathFileSecret = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Secret.txt"

        if (-not (Test-Path -Path $FullPathFileIdentity)) {
            Write-Error -Message "Identity file not found or accessable. FullPath: FullPathFileIdentity"
            $FullPathFileIdentity = $null
        }

        if (-not (Test-Path -Path $FullPathFileSecret)) {
            Write-Error -Message "Secret file not found or accessable. FullPath: FullPathFileSecret"
            $FullPathFileSecret = $null
        }
    }
    else {
        Write-Error -Message "Path does not exist. Stopping here."
        Write-Error -Message "$Path"
        return $null
    }

    if (-not ($null -eq $FullPathFileIdentity -or $null -eq $FullPathFileSecret)) {
        Write-Verbose -Message "Reading file content of $FullPathFileIdentity"
        $Identity = Get-Content "$FullPathFileIdentity"
        Write-Verbose -Message "Reading file content of $FullPathFileSecret"
        $Secret = Get-Content "$FullPathFileSecret" | ConvertTo-SecureString
            
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Identity, $Secret)
        return $Credentials
    }
    else {
        return $null
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
    