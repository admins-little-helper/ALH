<#PSScriptInfo

.VERSION 1.0.0

.GUID 1e36743f-dda9-44ae-bd9e-c102836f945d

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

#>


<#

.DESCRIPTION
 Contains a function to download and export the current list of Office 365 SKU Ids from the official Microsoft Download page.

#>

function Get-ALHOffice365SkuId {
    <#
    .SYNOPSIS
    Function to download and export the current list of Office 365 SKU Ids from the official Microsoft Download page.

    .DESCRIPTION
    The 'Get-ALHOffice365SkuId' function downloads and exports the current list of Office 365 SKU Ids from the official Microsoft Download page.
    The function either returns an an array of PSCustomObjects containing all Office 365 SKU Ids, or exports the list
    to either a json or CSV file on a given path.

    .PARAMETER OutFile
    The file path to either a CSV or JSON file to which the results are exported.

    .PARAMETER Force
    Only has effect if parameter -OutFile is specified. Forces file overwrite if a the specified file already exists.

    .PARAMETER Force
    Only has effect if parameter -OutFile is specified. If specified, the result will be saved to the specified filename and return to the console.

    .EXAMPLE
    Get-ALHOffice365SkuId

    Gets a list of Office365 SKU Ids.

    .EXAMPLE
    Get-ALHOffice365SkuId -OutFile 'C:\Temp\Office365SkuIds.csv'

    Gets a list of Office365 SKU Ids and save the result to a CSV file.

    .EXAMPLE
    Get-ALHOffice365SkuId -OutFile 'C:\Temp\Office365SkuIds.json' -PassThru

    Gets a list of Office365 SKU Ids and save the result to a JSON file and also shows it on the console.

    .EXAMPLE
    Get-ALHOffice365SkuId -OutFile 'C:\Temp\Office365SkuIds.json' -Force -PassThrough

    Get a list of Office365 SKU Ids and save the result to a JSON file, overwrite if it already exists and also shows the results on the console.

    .INPUTS
    Nothing

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHOffice365SkuId.txt
    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(ParameterSetName = 'OutFile')]
        [ValidateScript({
                # Check if the given path is valid.
                if (-not (Test-Path -Path $_ -IsValid) ) {
                    throw "File or folder does not exist"
                }
                # Check if the extension of the given file matches the supported file extensions.
                if ($_ -notmatch "(\.csv|\.json)") {
                    throw "The file specified in the OutFile parameter must be one of these types: .csv, .json"
                }
                return $true
            })]
        [string]
        $OutFile,

        [Parameter(ParameterSetName = 'OutFile')]
        [switch]
        $Force,

        [Parameter(ParameterSetName = 'OutFile')]
        [switch]
        $PassThru
    )

    # If the 'OutFile' parameter was specified and the file already exits and the 'Force' parameter was not specfied
    # the script stops here because the result could not be saved.
    if ((-not ([string]::IsNullOrEmpty($OutFile))) -and (Test-Path -Path $OutFile) -and (-not ($Force.IsPresent))) {
        Write-Warning -Message "The file '$OutFile' already exists. Specify the -Force paramter if you want to overwrite it or specify a different filename."
    }
    else {
        # https://docs.microsoft.com/en-us/azure/active-directory/enterprise-users/licensing-service-plan-reference
        $SkuIdDownloadLink = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"

        $TempFile = New-TemporaryFile

        try {
            Write-Verbose -Message "Trying to download file from '$SkuIdDownloadLink'."
            $InvokeWebRequestParams = @{
                Uri     = $SkuIdDownloadLink
                Method  = 'Get'
                OutFile = $TempFile
            }

            Invoke-WebRequest @InvokeWebRequestParams
            Write-Verbose -Message "File downloaded to '$TempFile'."
        }
        catch {
            $_
        }

        $O365SkuIdDataCsv = Import-Csv -Path $TempFile -Delimiter ',' -Encoding utf8
        Write-Verbose -Message "Number of records found in file: $(($O365SkuIdDataCsv | Measure-Object).Count)"

        if ([string]::IsNullOrEmpty($OutFile)) {
            Write-Verbose -Message "Deleting temporary file: '$TempFile'."
            Remove-Item -Path $TempFile -Force

            $O365SkuIdDataCsv
        }
        else {
            switch ($OutFile.Substring($OutFile.LastIndexOf('.'))) {
                '.csv' {
                    Write-Verbose -Message "Exporting results to CSV file: '$OutFile'."
                    Move-Item -Path $TempFile -Destination $OutFile -Force:$Force.IsPresent
                }
                '.json' {
                    Write-Verbose -Message "Exporting results to JSON file: '$OutFile'."
                    $O365SkuIdDataCsv | ConvertTo-Json | Out-File -FilePath $OutFile -Encoding utf8 -NoClobber:(-not ($Force.IsPresent))

                    Write-Verbose -Message "Deleting temporary file: '$TempFile'."
                    Remove-Item -Path $TempFile -Force
                }
                default {
                    # This part should never be reached.
                    Write-Error -Message "Invalid file type specified. Supported file types are '.csv' or '.json'."
                    break
                }
            }

            if ($PassThru.IsPresent) {
                Write-Verbose -Message "Parameter '-PassThru' specified - returning results also to console."
                $O365SkuIdDataCsv
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
