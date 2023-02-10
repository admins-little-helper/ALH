<#PSScriptInfo

.VERSION 1.1.0

.GUID f3d1fbcd-1063-4e97-b7ae-a03ddbec9827 

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
Cleaned up code.

#>


<#

.DESCRIPTION
Contains a function to store credentials in a secure way.

#>


function Set-ALHSavedCredential {
    <# 
    .SYNOPSIS
    Saves credentials (username and password as secure string) in text files.
    
    .DESCRIPTION
    Saves credentials (username and password as secure string) in text files.
    
    .PARAMETER Path
    Folder in wich the credential files are stored.

    .PARAMETER FileNamePrefix
    Filename prefix to use for credential files.

    .PARAMETER Identity
    Username for credentials.

    .PARAMETER Secret
    SecureString representing the password.

    .PARAMETER Force
    Overwrite existing files. Default is set to $false.

    .EXAMPLE
    Set-ALHSavedCredential -Path C:\Admin\Credentials -FileNamePrefix "CredsForApp1" -Identity "MyUserName"

    Save credentials for App1. The script will prompt for the password and hide typed characters.

    .INPUTS
    Nothing

    .OUTPUTS
    Object

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Set-ALHSavedCredential.txt
    #>
    
    [CmdletBinding(SupportsShouldProcess)]

    param
    (                     
        [parameter(Mandatory)]
        [ValidateNotNull()]
        [String]
        $Path,

        [parameter(Mandatory)]
        [ValidateNotNull()]
        [String]
        $FileNamePrefix,

        [parameter(Mandatory)]
        [ValidateNotNull()]
        [String]
        $Identity,

        [parameter(Mandatory)]
        [ValidateNotNull()]
        [SecureString]
        $Secret,

        [Boolean]
        $Force = $false
    )
    
    Write-Verbose -Message "Checking if path and filename already exist"
    if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "Path exists and is accessable"
            
        $FullPathFileIdentity = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Identity.txt"
        $FullPathFileSecret = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Secret.txt"

        if (Test-Path -Path $FullPathFileIdentity) {
            if ($Force) {
                Write-Verbose -Message "File to store identity already exists, file will be overwritten"
            }
            else {
                Write-Output "File to store identity already exists. Stopping here. To overwrite existing file use -Force parameter with value $true"
                Write-Output "$FullPathFileIdentity"
                return $null
            }
        }

        if (Test-Path -Path $FullPathFileSecret) {
            if ($Force) {
                Write-Verbose -Message "File to store secret already exists, file will be overwritten"
            }
            else {
                Write-Output "File to store secret already exists. Stopping here. To overwrite existing file use -Force parameter with value $true"
                Write-Output "$FullPathFileSecret"
                return $null
            }
        }
    }
    else {
        Write-Verbose -Message "Path does not exist, trying to create it"
            
        try {
            New-Item -Path $Path -ItemType Directory -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Error -Message "Error creating path $Path. Stopping here."
            return $null
        }
    }

    Write-Verbose -Message "Saving identity value to file"
    $Identity | Out-File -Path "$FullPathFileIdentity" -Force 
    Write-Verbose -Message "Saving secret value to file"
    $Secret | ConvertFrom-SecureString | Out-File -Path "$FullPathFileSecret" -Force 
    return Get-ALHSavedCredential -Path $Path -FileNamePrefix $FileNamePrefix

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
    