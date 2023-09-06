<#PSScriptInfo

.VERSION 1.2.0

.GUID f3d1fbcd-1063-4e97-b7ae-a03ddbec9827

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
Cleaned up code.

1.1.1
Fixed issue: Wrong paramter name for Out-File

1.2.0
Redesign and code cleanup.

1.2.1
Fixed issue when creating $Path failes.

#>


<#

.DESCRIPTION
Contains a function to store credentials in as secure string in a text file.

#>


function Set-ALHSavedCredential {
    <#
    .SYNOPSIS
    Saves credentials (username and password as secure string) in a text file.

    .DESCRIPTION
    Saves credentials (username and password as secure string) in a text file.

    .PARAMETER Path
    Folder in wich the credential files are stored.

    .PARAMETER FileNamePrefix
    Filename prefix to use for credential files.

    .PARAMETER Credential
    PSCredential object with username and password.

    .PARAMETER Identity
    Username for credentials.

    .PARAMETER Secret
    SecureString representing the password.

    .PARAMETER Force
    If specified, existing files will be overwritten.

    .PARAMETER AsJson
    If specified, the output will be saved in a json file, instead of a text file.

    .EXAMPLE
    Set-ALHSavedCredential -Path C:\Admin\Credentials -FileNamePrefix "CredsForApp1" -Identity "MyUserName"

    Save credentials for App1. The script will prompt for the password and hide typed characters.

    .EXAMPLE
    Set-ALHSavedCredential -Path C:\Admin\Credentials -FileNamePrefix "CredsForApp1" -Identity "MyUserName" -AsJson

    Save credentials for App1 in a single JSON file. The script will prompt for the password and hide typed characters.

    .EXAMPLE
    Set-ALHSavedCredential -Path C:\Admin\Credentials -FileNamePrefix "CredsForApp1" -Credential (Get-Credential) -AsJson

    Save credentials for App1 in a single JSON file. Username and password will be requested.

    .INPUTS
    Nothing

    .OUTPUTS
    Object

    .NOTES
    Author: Dieter Koch
    Email: diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Set-ALHSavedCredential.txt
    #>

    [OutputType([PSCredential])]
    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = "default")]
    param
    (
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [System.IO.FileInfo]
        $Path,

        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [String]
        $FileNamePrefix,

        [Parameter(Mandatory, ParameterSetName = "PSCredential")]
        [ValidateNotNull()]
        [PSCredential]
        $Credential,

        [Parameter(Mandatory, ParameterSetName = "IdentitySecret")]
        [ValidateNotNull()]
        [String]
        $Identity,

        [Parameter(Mandatory, ParameterSetName = "IdentitySecret")]
        [ValidateNotNull()]
        [SecureString]
        $Secret,

        [Switch]
        $Force,

        [Switch]
        $AsJson
    )

    if ($PSCmdlet.ParameterSetName -eq "IdentitySecret") {
        $Credential = New-Object System.Management.Automation.PSCredential ($Identity, $Secret)
    }

    Write-Verbose -Message "Checking if path and filename already exist."
    if (Test-Path -Path $Path -ErrorAction SilentlyContinue) {
        Write-Verbose -Message "Path exists and is accessible."

        $FullPathFileIdentity = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Identity.txt"
        $FullPathFileSecret = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Secret.txt"
        $FullPathFilCredential = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Credential.json"

        $FileList = @($FullPathFileIdentity, $FullPathFileSecret, $FullPathFilCredential)
        foreach ($File in $FileList) {
            if (Test-Path -Path $File) {
                if ($Force.IsPresent) {
                    Write-Warning -Message "File already exists and will be overwritten: [$File]"
                }
                else {
                    Write-Warning -Message "File already exists. Stopping here. To overwrite existing file use parameter '-Force': [$File]"
                    return $null
                }
            }
        }
    }
    else {
        Write-Verbose -Message "Path does not exist, trying to create it."

        try {
            $null = New-Item -Path $Path -ItemType Directory -Force -ErrorAction Stop
        }
        catch {
            Write-Error -Message "Error creating path [$Path]."
            return $null
        }
    }

    if ($AsJson.IsPresent) {
        [PSCustomObject]$MyCredentialObject = @{
            Username = $Credential.UserName
            Password = $Credential.Password | ConvertFrom-SecureString
        }

        Write-Verbose -Message "Saving credential to json file."
        $MyCredentialObject | ConvertTo-Json | Out-File -FilePath $FullPathFilCredential -Force -Encoding utf8
    }
    else {
        Write-Verbose -Message "Saving identity value to file."
        $Credential.UserName | Out-File -FilePath "$FullPathFileIdentity" -Force -Encoding utf8

        Write-Verbose -Message "Saving secret value to file."
        $Credential.Password | ConvertFrom-SecureString | Out-File -FilePath "$FullPathFileSecret" -Force -Encoding utf8
    }

    Write-Verbose -Message "Returning saved credentials."
    $GetSavedCredentialParams = @{
        Path           = $Path
        FileNamePrefix = $FileNamePrefix
    }
    if ($AsJson.IsPresent) { $GetSavedCredentialParams.AsJson = $true }
    $SavedCredential = Get-ALHSavedCredential @GetSavedCredentialParams
    return $SavedCredential
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
