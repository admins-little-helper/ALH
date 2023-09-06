<#PSScriptInfo

.VERSION 1.0.2

.GUID 31231287-50ef-41f6-a780-411712bee2fe

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
    Initial Release

    1.0.1
    - Extended LastRunInfo
    - Improved data processing

    1.0.2
    - Fixed issue with clientrequestid.
#>


<#

.DESCRIPTION
Contains a function to retrieve IPs and URLs used by Microsoft 365 services.

Microsoft documentation about Microsoft 365 IP Web service and how to use it:
https://docs.microsoft.com/en-us/microsoft-365/enterprise/microsoft-365-ip-web-service?view=o365-worldwide

#>


function Get-ALHOffice365IPAndUrl {
    <#
    .SYNOPSIS
    Retrieves IPs and URLs used by Microsoft 365 services.

    .DESCRIPTION
    The 'Get-ALHOffice365IPAndUrl' function retrieves IPs and URLs used by the Microsoft 365 services by the Microsoft REST API.
    It allows to filter the output for example to only URLs, not IPs or only for certain services like Exchange. The data retrieved is stored
    in a local cache file to limit the number of queries against the webservice.

    .PARAMETER Instance
    Specifies the Office 365 Instance name. Choose from one of the valid values: 'Worldwide', 'USGovDoD', 'USGovGCCHigh', 'China', 'Germany'.
    Defaults to 'Worldwide'

    .PARAMETER ServiceArea
    Specifies the Office 365 service area. Choose from one of the valid values: 'All', 'Common', 'Exchange', 'SharePoint', 'Skype'.
    Defaults to 'All'

    .PARAMETER Category
    Specifies the Office 365 connectivity category for a service endpoint set. Choose from one of the valid values: 'All', 'Optimize', 'Allow', 'Default'.
    Defaults to 'All'

    .PARAMETER Required
    Specify $true to retrieve only endpoint sets marked required. Specify $false for optional endpoint sets.
    If ommited, all endpoint sets are retrieved.

    .PARAMETER ExpressRoute
    Specify $true to retrieve only endpoint sets routed over ExpressRoute.
    Specify $false to retrieve only endpoint sets NOT routed over ExpressRoute
    If ommited, all endpoint sets are retrieved.

    .PARAMETER TenantName
    A Office 365 tenant name. The web service takes the provided name and inserts it in parts of URLs that include the tenant name.
    If no tenant name is provided, those parts of URLs have the wildcard character (*).

    .PARAMETER OutputType
    Specifies which endpoint sets should be returned by the function. Valid values are 'All', 'IPv4', 'IPv6', 'URLs'.

    .PARAMETER OutputPath
    Specifies the folder path to the local cache file. The function will create at least two files.
    One file contains the client id required for the webservice and the version number of the last retrieved IP and URL list.
    This allows to take data from the offlien file instead of querying the webservice, in case no update is available there.
    If ommited, these files are stored in user's temp directory ($env:TEMP).

    .PARAMETER Force
    If specified, data is always retrieved from the web service instead of a local cache file.

    .EXAMPLE
    Get-ALHOffice365IPAndUrl

    Retrieve all endpoint sets for all service areas and all categories in the 'Worldwide' Instance

    .EXAMPLE
    Get-ALHOffice365IPAndUrl -ServiceArea Exchange

    Retrieve all endpoint sets for Exchange and all categories in the 'Worldwide' Instance

    .EXAMPLE
    Get-ALHOffice365IPAndUrl -ServiceArea SharePoint -Required

    Retrieve only required endpoint sets for SharePoint and all categories in the 'Worldwide' Instance

    .EXAMPLE
    Get-ALHOffice365IPAndUrl -ServiceArea SharePoint -Required -OutputType IPv4 -Force

    Retrieve only IPv4 endpoint sets for Skype and all categories in the 'USGovDoD' Instance and ignore any local cache file (if exist)

    .INPUTS
    Nothing

    .OUTPUTS
    PSCustomObject

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHOffice365IPAndUrl.txt
    #>

    [CmdletBinding()]
    param (
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Worldwide', 'USGovDoD', 'USGovGCCHigh', 'China', 'Germany')]
        [string[]]
        $Instance = 'Worldwide',

        [ValidateNotNullOrEmpty()]
        [ValidateSet('All', 'Common', 'Exchange', 'SharePoint', 'Skype')]
        [string[]]
        $ServiceArea = 'All',

        [ValidateSet('All', 'Optimize', 'Allow', 'Default')]
        [string[]]
        $Category = 'All',

        [boolean]
        $Required,

        [boolean]
        $ExpressRoute,

        [string]
        $TenantName,

        [ValidateSet('All', 'IPv4', 'IPv6', 'URLs')]
        [string[]]
        $OutputType = 'All',

        [ValidateScript({ (Get-Item -Path $_ -ErrorAction SilentlyContinue).PSIsContainer })]
        [string]
        $OutputPath = "$env:TEMP",

        [switch]
        $Force
    )

    if (Test-Path -Path $OutputPath) {
        $LastRunInfoFile = "$OutputPath\Office365IPsandUrls.json"
        Write-Verbose -Message "Trying to read last run info from $LastRunInfoFile"

        if (Test-Path -Path $LastRunInfoFile) {
            $LastRunInfo = Get-Content -Path $LastRunInfoFile -Encoding utf8 | ConvertFrom-Json
        }
        else {
            Write-Verbose -Message "No file from previous run found. Starting from scratch and retrieving data from Webservice."
        }
    }
    else {
        Write-Error -Message "Output path does not exist is is not accessible. Can not continue." -ErrorAction Stop
        break
    }

    if ($null -eq $LastRunInfo) {
        $LastRunInfo = [PSCustomObject]@{
            LastRun            = Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'
            LastUpdateFromWeb  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'
            LastVersionFromWeb = '0000000000'
            Instance           = $Instance
            ClientRequestID    = (New-Guid).Guid
        }
    }
    else {
        $LastRunInfo.LastRun = Get-Date -Format 'yyyy-MM-dd HH:mm:ss:fff'
        $LastRunInfo.Instance = $Instance
    }

    Write-Verbose -Message "LastRun           : $($LastRunInfo.LastRun)"
    Write-Verbose -Message "LastUpdateFromWeb : $($LastRunInfo.LastUpdateFromWeb)"
    Write-Verbose -Message "LastVersionFromWeb: $($LastRunInfo.LastVersionFromWeb)"
    Write-Verbose -Message "Instance          : $($LastRunInfo.Instance)"
    Write-Verbose -Message "ClientRequestID   : $($LastRunInfo.ClientRequestID)"

    foreach ($SingleInstance in $Instance) {
        $BaseURI = 'https://endpoints.office.com'
        $VersionRequestURI = $BaseURI + '/version/' + $SingleInstance + '?clientRequestId=' + $LastRunInfo.ClientRequestID
        $EndpointRequestURI = $BaseURI + '/endpoints/' + $SingleInstance + '?clientRequestId=' + $LastRunInfo.ClientRequestID

        Write-Verbose -Message "Trying to get version number of latest version from Webservice for Instance '$SingleInstance'..."

        try {
            $VersionParams = @{
                Uri    = $VersionRequestURI
                Method = 'Get'
            }

            $LatestVersionOnWeb = Invoke-RestMethod @VersionParams
        }
        catch {
            Write-Verbose -Message "Unable to retrieve the Office 365 Endpoint version information."
            $_
            break
        }

        Write-Verbose -Message "Last version locally                    : $($LastRunInfo.LastVersionFromWeb)"
        Write-Verbose -Message "Latest version available from Webservice: $($LatestVersionOnWeb.latest)"

        if ($TenantName) {
            Write-Verbose -Message "Parameter '-Tenant' specified, appending value to request URI"
            $EndpointRequestURI = $EndpointRequestURI + "&TenantName=$TenantName"
            $EndpointsFile = "$OutputPath\Office365Endpoints-$SingleInstance-$TenantName-$($LatestVersionOnWeb.latest).json"
        }
        else {
            $EndpointsFile = "$OutputPath\Office365Endpoints-$SingleInstance-$($LatestVersionOnWeb.latest).json"
        }

        $EndpointsFileExists = Test-Path -Path $EndpointsFile -PathType Leaf -ErrorAction SilentlyContinue
        $RetrieveDataFromWeb = $false

        if ($LatestVersionOnWeb.latest -ne $LastRunInfo.LastVersionFromWeb) {
            Write-Verbose -Message "Version on Webservice is newer than local cache file from previous run."
            $RetrieveDataFromWeb = $true
        }

        if (-not $EndpointsFileExists) {
            Write-Verbose -Message "Endpoints file does not exist."
            $RetrieveDataFromWeb = $true
        }

        if ($Force.IsPresent) {
            Write-Verbose -Message "Parameter '-Force' specified."
            $RetrieveDataFromWeb = $true
        }

        if ($RetrieveDataFromWeb) {
            Write-Verbose -Message "Will retrieve data from Webservice."
            Write-Verbose -Message "Requesting the following URI: $EndpointRequestURI"

            try {
                $EndpointsParams = @{
                    Uri    = $EndpointRequestURI
                    Method = 'Get'
                }
                $Endpoints = Invoke-RestMethod @EndpointsParams
            }
            catch {
                Write-Verbose -Message 'Unable to retrieve the Office 365 Endpoint information.'
                $_
                break
            }

            if ($Endpoints) {
                try {
                    $Endpoints | ConvertTo-Json | Out-File -FilePath $EndpointsFile -Encoding utf8 -Force
                }
                catch {
                    Write-Verbose -Message $_
                    Write-Error -Message "Unable to write output file: $EndpointsFile" -ErrorAction Stop
                    break
                }
            }

            $LastRunInfo.LastVersionFromWeb = $LatestVersionOnWeb.latest

            try {
                $LastRunInfo | ConvertTo-Json | Out-File -FilePath $LastRunInfoFile -Encoding utf8 -Force
            }
            catch {
                Write-Verbose -Message "Unable to write output file: $LastRunInfoFile"
                $_
                break
            }
        }
        else {
            Write-Verbose -Message "Latest version on Webservice is the same as the local content. Using local content."
            $Endpoints = Get-Content -Path $EndpointsFile -Encoding utf8 | ConvertFrom-Json
        }

        if ($ServiceArea -ne 'All') {
            Write-Verbose -Message "Parameter '-ServiceArea' specified - filtering output for ServiceArea: $ServiceArea"
            $Endpoints = $Endpoints.where({ $_.ServiceArea -in $ServiceArea })
        }

        if ($Category -ne 'All') {
            Write-Verbose -Message "Parameter '-Category' specified - Filtering output for Category: $Category"
            $Endpoints = $Endpoints.where({ $_.Category -in $Category })
        }

        if ($OutputType -ne 'All') {
            Write-Verbose -Message "Parameter 'OutputType' specified with value $OutputType"

            if ($OutputType -eq 'IPv4') {
                Write-Verbose -Message "Removing endpoints with URLs and IPv6 addresses from output"
                $EndPoints = foreach ($EndPoint in $Endpoints) {
                    if ($EndPoint.PSObject.Properties.Name -contains "ips" ) {
                        $EndPoint.IPs = $EndPoint.IPs.Where({ $_ -like "*.*" })
                        $EndPoint
                    }
                }
            }

            if ($OutputType -eq 'IPv6') {
                Write-Verbose -Message "Removing endpoints with URLs and IPv4 addresses from output"
                $EndPoints = foreach ($EndPoint in $Endpoints) {
                    if ($EndPoint.PSObject.Properties.Name -contains "ips" ) {
                        $EndPoint.IPs = $EndPoint.IPs.Where({ $_ -like "*:*" })
                        $EndPoint
                    }
                }
            }

            if ($OutputType -eq 'URLs') {
                Write-Verbose -Message "Removing endpoitns with IP addresses from output"
                $EndPoints = foreach ($EndPoint in $Endpoints) {
                    if ($EndPoint.PSObject.Properties.Name -contains "urls" ) {
                        $EndPoint
                    }
                }
            }
        }

        if ($PSBoundParameters.ContainsKey("Required")) {
            Write-Verbose -Message "Parameter '-Required' specified, filtering output for endpoint sets where required is set to: $Required"
            $Endpoints = $Endpoints.Where({ $_.Required -eq $Required })
        }

        if ($PSBoundParameters.ContainsKey("ExpressRoute")) {
            Write-Verbose -Message "Parameter 'ExpressRoute' specified, filtering output for endpoint sets where ExpressRoute is set to: $ExpressRoute"
            $Endpoints = $Endpoints.Where({ $_.ExpressRoute -eq $ExpressRoute })
        }

        Write-Verbose -Message "Done"
        $Endpoints
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
