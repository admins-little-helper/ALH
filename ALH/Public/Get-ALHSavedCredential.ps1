<#PSScriptInfo

.VERSION 1.2.0

.GUID 899d0d26-7c9e-4356-a846-bb1f6ee7b579

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
Cleaned up code

1.2.0
Fixed issue with variable names.
Added validatescript for parameter 'Path'.
Added parameter -AsJSon.
Added parameter -FilePath.
Redesign and code cleanup.

#>


<#

.DESCRIPTION
 Contains a function to retrieve credentials from a text file which were saved there as securestring.

#>


function Get-ALHSavedCredential {
    <# 
    .SYNOPSIS
    Retrieve saved credentials (username and secure string password) from a text file.
    
    .DESCRIPTION
    Retrieve saved credentials (username and secure string password) from files.
    
    .PARAMETER Path
    Path to search in for credential files.

    .PARAMETER FileNamePrefix
    Filename prefix to use for credential files.
    
    .PARAMETER AsJson
    If specified, the output will be saved in a json file, instead of a text file.

    .EXAMPLE
    Get-ALHSavedCredential -Path C:\Admin\Credentials -FileNamePrefix "CredForApp1"

    Get credentials for App1 from text files (one for username, another for the password).

    .EXAMPLE
    Get-ALHSavedCredential -FilePath C:\Admin\Credentials\MyCredentials.json

    Get credentials from a JSON file.

    .INPUTS
    Nothing

    .OUTPUTS
    PSCredential

    .NOTES
    Author: Dieter Koch
    Email: diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHSavedCredential.txt
    #>

    [OutputType([PSCredential])]
    [CmdletBinding(DefaultParameterSetName = "default")]
    param
    (
        [Parameter(Mandatory, ParameterSetName = "Path")]
        [ValidateScript({
                # Check if the given path is valid.
                if (-not (Test-Path -Path $_) ) {
                    throw "Folder does not exist."
                }
                # Check if the given path is a directory.
                if (-not (Test-Path -Path $_ -PathType Container) ) {
                    throw "The Path argument must be a folder. File paths are not allowed."
                }
                return $true 
            })]
        [System.IO.FileInfo]
        $Path,

        [Parameter(Mandatory, ParameterSetName = "FilePath")]
        [ValidateScript({
                # Check if the given path is valid.
                if (-not (Test-Path -Path $_) ) {
                    throw "File or folder does not exist."
                }
                # Check if the given path is a file.
                if (Test-Path -Path $_ -PathType Container) {
                    throw "The Path argument must be a file. The given path is a folder."
                }
                # Check if the given file is not a json file.
                if ( -not ([IO.Path]::GetExtension($_) -eq ".json")) {
                    throw "The Path argument must be a file. The given path is a folder."
                }
                return $true 
            })]
        [System.IO.FileInfo]
        $FilePath,

        [Parameter(ParameterSetName = "Path")]
        [ValidateNotNull()]
        [String]
        $FileNamePrefix,

        [Parameter(ParameterSetName = "Path")]
        [Switch]
        $AsJson
    )

    if ($PSCmdlet.ParameterSetName -eq "FilePath") {
        $FullPathFilCredential = $FilePath
        [switch]$AsJson = $true
    }
    
    if ($AsJson.IsPresent) {
        if ($PSCmdlet.ParameterSetName -eq "Path") {
            $FullPathFilCredential = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Credential.json"
        }
        $FileList = @($FullPathFilCredential)
    }
    else {
        $FullPathFileIdentity = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Identity.txt"
        $FullPathFileSecret = Join-Path -Path $Path -ChildPath "$($FileNamePrefix)_Secret.txt"
        $FileList = @($FullPathFileIdentity, $FullPathFileSecret)
    }

    $IsFileMissing = $false
    foreach ($File in $FileList) {
        if (-not (Test-Path -Path $File)) {
            Write-Error -Message "File not found or accessible. FullPath: $File"
            $IsFileMissing = $true
        }
    }

    if (-not ($IsFileMissing)) {
        if ($AsJson.IsPresent) {
            $MyCredentialObject = Get-Content -Path $FullPathFilCredential -Encoding UTF8 | ConvertFrom-Json
            $Credentials = New-Object System.Management.Automation.PSCredential ($MyCredentialObject.Username, $($MyCredentialObject.Password | ConvertTo-SecureString))
        }
        else {
            Write-Verbose -Message "Reading file content of $FullPathFileIdentity"
            $Identity = Get-Content "$FullPathFileIdentity"
    
            Write-Verbose -Message "Reading file content of $FullPathFileSecret"
            $Secret = Get-Content "$FullPathFileSecret" | ConvertTo-SecureString
            $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Identity, $Secret)
        }
        
        return $Credentials
    }
    else {
        return $null
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
