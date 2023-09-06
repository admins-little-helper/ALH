<#PSScriptInfo

.VERSION 1.0.17

.GUID aaad0933-beef-40ea-b916-5dfc9b1e85ea

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
    Initial release.

    1.0.1
    Added verbose information on time taken for rule processing.

    1.0.2
    Updated footer to show a list of excluded objects.

    1.0.3
    Added 'Server' parameter to be able to specify a domain controller to query.

    1.0.4
    Added 'Credential' paramet to be able to specify different credentials for querying AD.

    1.0.5
    Fixed module dependency.

    1.0.6
    Fixed issue in applying credentials correctly.

    1.0.7
    Corrected domain name output if executed in current user context.

    1.0.8
    Added verbose output for elapsed time at program start.
    Changed query for object classes in used in rules to only look at enabled rules.

    1.0.9
    Fixed issue with getting objectClasses for enabled rules.
    Fixed text replacement for Title, Subtitle, Infotext and footer.

    1.0.10
    Fixed issue in calculating filter string for Get-ADObject.

    1.0.11
    Added code to support Get-ALHADObject.

    1.0.12
    Fixed issue with calculated value for LDAPFilter.

    1.0.13
    Added check for attributes to query.

    1.0.14
    Fixed issue #42: Make parameters more dynamic for Get-ALHAD* and Get-AD*.

    1.0.15
    Changed handling of ServerName parameter.

    1.0.16
    Fixed issue #40 - Allow to specify multiple rules files.

    1.0.17
    Fixed issue with SearchBase when ActiveDirectory Module is used.

    1.1.0
    Added paramter '-FilePath' to directly store the output in a html file.
    Corrected names of dependent functions.

#>


<#

.DESCRIPTION
 Contains function to run rules to identify discrepancies in Active Directory.

#>


function Get-ALHADDiscrepancy {
    <#
    .SYNOPSIS
    Function to run rules to identify discrepancies in Active Directory.

    .DESCRIPTION
    The function 'Get-ALHADDiscrepancy' queries Active Directory and used some customizable rules to detect any discrepancies or inconsistencies in the attribute values.

    .PARAMETER ScriptSettingsFile
    Filepath to the script settings file in JSON format.

    .PARAMETER RulesFile
    Filepath to one or more rules files in JSON format.

    .PARAMETER UseActiveDirectoryModule
    If specified, this function is using the ActiveDirecotry PowerShell module to query Active Directory objects.
    If omitted this function used the Get-ALHADObject function from the ALH module to query Active Directory.

    .PARAMETER FilePath
    Filepath to the output html report file.

    .EXAMPLE
    Get-ALHADDiscrepancy

    .EXAMPLE
    Get-ALHADDiscrepancy -ScriptSettingsFile 'C:\Admin\ADRulesSettings.json' -RulesFile 'C:\Admin\ADRules.json'

    .INPUTS
    None

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHADDiscrepancy.txt
    #>

    [CmdletBinding()]
    param(
        [ValidateScript({ Test-Path -Path $_ -ErrorAction SilentlyContinue })]
        [string]
        $ScriptSettingsFile,

        [ValidateScript({ foreach ($file in $_) { Test-Path -Path $_ -ErrorAction SilentlyContinue } })]
        [string[]]
        $RulesFile,

        [string]
        [ValidateNotNullOrEmpty()]
        $DomainName = (Get-CimInstance -ClassName "Win32_ComputerSystem").Domain,

        [string]
        $Server,

        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,

        [switch]
        $UseActiveDirectoryModule,

        [ValidateScript({
                # Check if the given path is valid.
                if ((Test-Path -Path $_) ) {
                    throw "File already exists. Can not overwrite."
                }
                # Check if the extension of the given file matches the supported file extensions.
                if ($_ -notmatch "(\.htm|\.html)") {
                    throw "The file specified in the InputFile parameter must be one of these types: .htm, .html"
                }
                return $true
            })]
        [Parameter(Mandatory)]
        [string]
        $FilePath
    )

    $StopWatch = [System.Diagnostics.Stopwatch]::new()
    $StopWatch.Start()
    Write-Verbose -Message "Elapsed time since program start: $($StopWatch.Elapsed)"

    if ([string]::IsNullOrEmpty($ScriptSettingsFile)) {
        Write-Error -Message "No script settings file specified. Please specify a valid path to an input settings file."
        break
    }
    else {
        $ScriptSettings = Get-ALHScriptSetting -Path "$ScriptSettingsFile"
    }

    if ($null -eq $RulesFile -or $RulesFile.Count -eq 0) {
        Write-Error -Message "No AD Rules file specified. Please specify a valid path to a rules file."
        break
    }
    else {
        [Array]$AllRulesJson = foreach ($File in $RulesFile) {
            Get-Content -Path "$File" -Encoding UTF8 | ConvertFrom-Json
        }

        $ADRules = [PSCustomObject]@{
            AttributesToQuery = $null
            RuleSets          = $null
        }

        $ADRules.RuleSets = foreach ($RuleSet in $AllRulesJson.RuleSets) {
            $RuleSet
        }
        $ADRules.AttributesToQuery = foreach ($Attribute in $AllRulesJson.AttributesToQuery) {
            $Attribute
        }
        $ADRules.AttributesToQuery = $ADRules.AttributesToQuery | Select-Object -Unique
    }

    Write-Verbose -Message "Identify which objectClasses are specified in all enabled rules and querying AD objects."

    # Setting parameters for Get-ALHAD* and Get-AD* cmdlets
    $CommonParams = @{}
    $GetALHADDomainControllerParams = @{}
    $GetALHADAttributesParams = @{}
    $GetADObjectParams = @{}

    if (-not ([string]::IsNullOrEmpty($DomainName))) {
        $CommonParams.DomainName = $DomainName
        $GetALHADDomainControllerParams.DomainName = $DomainName

        if ($UseActiveDirectoryModule.IsPresent) {
            Write-Verbose -Message "Setting SearchBase based on specified DomainName: '$DomainName'"
            if ($null -ne $Credential.UserName -and $null -ne $Credential.Password) {
                try {
                    $DomainConnection = [adsi]::new("LDAP://$DomainName", $Credential.UserName, $($Credential.GetNetworkCredential().Password))
                }
                catch {
                    $_
                }
            }
            else {
                try {
                    $DomainConnection = [adsi]::new("LDAP://$DomainName")
                }
                catch {
                    $_
                }
            }

            if ($DomainConnection.distinguishedName) {
                $SearchBase = $DomainConnection.distinguishedName[0]
                $DomainConnection.Dispose()
            }
            else {
                $_
                Write-Error -Message "Could not connect to domain '$DomainName'"
                break
            }

            $GetADObjectParams.SearchBase = $SearchBase
        }
    }
    if (-not ([string]::IsNullOrEmpty($Server))) {
        $CommonParams.Server = $Server
        $GetALHADDomainControllerParams.Server = $Server
        $GetALHADAttributesParams.Server = $Server
        $GetADObjectParams.Server = $Server
    }
    if ($null -ne $Credential.UserName -and $null -ne $Credential.Password) {
        $CommonParams.Credential = $Credential
        $GetALHADAttributesParams.Credential = $Credential
        $GetADObjectParams.Credential = $Credential
    }

    if ([string]::IsNullOrEmpty($Server)) {
        Write-Verbose -Message "No Servername specified, checking if one is needed."

        if ( $UseActiveDirectoryModule ) {
            if ($DomainName -ne $((Get-CimInstance -ClassName "Win32_ComputerSystem").Domain)) {
                Write-Verbose -Message "Running query aginst foreign domain - need to detect domain controller for query."
                $Server = "$((Get-ADDomainController -Discover -ForceDiscover -NextClosestSite @CommonParams).HostName)"
                $CommonParams.Server = $Server
            }
            else {
                Write-Verbose -Message "Running query against current user's domain - no need to detect servername."
            }
        }
        else {
            Write-Verbose -Message "Detecting server to query for Get-ALHAD* cmdlets."
            $Server = "$((Get-ALHADDomainController @GetALHADDomainControllerParams).Name.Substring(2))"
            $CommonParams.Server = $Server
        }
    }

    if (-not ([string]::IsNullOrEmpty($Server))) {
        Write-Verbose -Message "Running query against domain controller '$Server'"
    }

    if ($UseActiveDirectoryModule) {
        if ([bool](Get-Module -Name ActiveDirectory -ListAvailable)) {
            if (-not [bool](Get-Module -Name ActiveDirectory)) {
                Import-Module -Name ActiveDirectory
            }
        }
        else {
            Write-Warning -Message "Module 'ActiveDirectory' not found. Falling back to ALH integrated method."
            Remove-Variable -Name $UseActiveDirectoryModule
        }
    }

    if ($UseActiveDirectoryModule.IsPresent) {
        [array]$ObjectClassesToQuery = (($ADRules.RuleSets | Where-Object { $_.Enabled -eq $true }).objectClass | Select-Object -Unique).where({ $_ -eq 'user' -or $_ -eq 'computer' -or $_ -eq 'group' -or $_ -eq 'organizationalUnit' })

        if ($ObjectClassesToQuery -contains '*') {
            [string]$ObjectClassQueryString = "objectClass -eq '*'"
        }
        else {
            [string]$ObjectClassQueryString = $(foreach ($ObjectClassToQuery in $ObjectClassesToQuery | Where-Object { $_ -ne '*' }) { "objectClass -eq `"$ObjectClassToQuery`"" }) -join " -or "
        }
    }
    else {
        [array]$ObjectClassesToQuery = (($ADRules.RuleSets | Where-Object { $_.Enabled -eq $true }).objectClass | Select-Object -Unique).where({ $_ -eq 'user' -or $_ -eq 'computer' -or $_ -eq 'group' -or $_ -eq 'organizationalUnit' })

        if ($ObjectClassesToQuery -contains '*') {
            [string]$ObjectClassQueryString = "(&(objectClass=*))"
        }
        else {
            [string]$ObjectClassQueryString = $(foreach ($ObjectClassToQuery in $ObjectClassesToQuery | Where-Object { $_ -ne '*' }) {
                    "(objectClass=$ObjectClassToQuery)"
                })
            $ObjectClassQueryString = '(| ' + $ObjectClassQueryString + ')'
        }
    }

    Write-Verbose -Message "ObjectClass filter string for Get-ADObject/Get-ALHADObject: '$ObjectClassQueryString'"

    Write-Verbose -Message "Elapsed time since program start - prepared AD Query: $($StopWatch.Elapsed)"

    if ($UseActiveDirectoryModule.IsPresent) {
        Write-Verbose -Message "Getting list of attributes to query from rule file."
        [array]$AttributesToQuery = $ADRules.AttributesToQuery

        Write-Verbose -Message "Checking attributes existing in current domain for each object class."

        $AttributesInAdSchema = foreach ($class in $ObjectClassesToQuery) {
            Get-ALHDSAttribute -ClassName $class @CommonParams
        }

        [array]$AttributesToQueryVerified = foreach ($attribute in $AttributesToQuery) {
            if ($AttributesInAdSchema -contains $attribute) { $attribute }
        }

        if ($null -eq $AttributesToQueryVerified -or $AttributesToQueryVerified.Count -eq 0) {
            [array]$AttributesToQueryVerified = @(, '*')
        }
    }
    else {
        Write-Verbose -Message "AttributesToQuery from rules file ignored, because it's not needed for Get-ALHADObject."
    }

    if ($UseActiveDirectoryModule.IsPresent) {
        [array]$ADObjectsRaw = Get-ADObject -Filter $ObjectClassQueryString -Property $AttributesToQueryVerified @GetADObjectParams
    }
    else {
        [array]$ADObjectsRaw = Get-ALHADObject -LDAPFilter $ObjectClassQueryString @CommonParams
    }

    Write-Verbose -Message "Elapsed time since program start - executed AD Query : $($StopWatch.Elapsed)"

    [array]$ADObjects = foreach ($ADObj in $ADObjectsRaw) {
        $ParentOU = { $($($this.DistinguishedName -split ",") | Select-Object -Skip 1 | ForEach-Object { if ( $_ -notmatch "\\" -and $_ -match "=") { $_ } }) -join "," }
        $Enabled = { (-not $(Test-ALHADUserAccountControl -UacFlagToCheck ACCOUNTDISABLE -UacValue $this.userAccountControl )) }
        $ADObj | Add-Member -MemberType ScriptProperty -Name "c_ParentOu" -Value $ParentOU -Force
        $ADObj | Add-Member -MemberType ScriptProperty -Name "c_Enabled" -Value $Enabled -Force
        $ADObj
    }

    Write-Verbose -Message "Elapsed time since program start - added calculated attributes : $($StopWatch.Elapsed)"

    $TotalResults = foreach ($RuleSet in $ADRules.RuleSets | Where-Object { $_.Enabled -eq $true } | Sort-Object -Property objectClass, Name) {
        Write-Information -MessageData "$($Ruleset.Name)" -InformationAction Continue
        Write-Verbose -Message "Elapsed time since program start - started rule processing: $($StopWatch.Elapsed)"

        [string]$RuleSetFilterString = foreach ($Rule in $RuleSet.Rules) {
            $RuleFilterString = $null
            $CalculatedValue = $Rule.Values
            if ($Rule.Values -is [string]) {
                if ($Rule.Values -eq "true") { $CalculatedValue = '$true' }
                elseif ($Rule.Values -eq "false") { $CalculatedValue = '$false' }
                elseif ($Rule.Values.Length -ge 2) {
                    if ($Rule.Values.Substring(0, 2) -eq '$(') {
                        $CalculatedValue = $([scriptblock]::Create($Rule.Values)).Invoke()
                    }
                }
            }
            elseif ($Rule.Values -is [array]) {
                [string]$CalculatedValue = "@($($Rule.Values -join ', '))"
            }

            if (-not [string]::IsNullOrEmpty($Rule.AttributeValueCompute)) {
                $RuleAttribute = "$($Rule.AttributeValueCompute)"
            }
            else {
                $RuleAttribute = "`$_.$($Rule.Attribute)"
            }

            [string]$RuleFilterString = "($RuleAttribute $($Rule.Operator) $CalculatedValue)"
            if ($Rule.RuleConnector) { $RuleFilterString = $RuleFilterString + " $($Rule.RuleConnector) " }

            $RuleFilterString
        }

        Write-Verbose -Message "Elapsed time since program start - created rule set filter string: $($StopWatch.Elapsed)"
        Write-Verbose -Message "RulesetFilterString: '$RuleSetFilterString'"
        $RuleSetFilter = $null
        if ($UseActiveDirectoryModule.IsPresent) {
            [string]$RuleSetFilterComplete = "`$_.objectClass -like '$($RuleSet.ObjectClass)' -and ($($RuleSetFilterString -join ''))"
        }
        else {
            [string]$RuleSetFilterComplete = "`$_.ALHobjectClass -like '$($RuleSet.ObjectClass)' -and ($($RuleSetFilterString -join ''))"
        }

        $RuleSetFilter = [scriptblock]::Create($RuleSetFilterComplete)
        $RuleSet | Add-Member -Name "RuleSetFilter" -MemberType NoteProperty -Value $RuleSetFilter

        Write-Verbose -Message "Elapsed time since program start - created rule set filter scriptblock: $($StopWatch.Elapsed)"

        $RuleResult = $null

        # In case the current rule has an 'ExcludeFromRuleCheck' attribute, it will be handled here.
        if ( $(Get-Member -InputObject $RuleSet).Name.Contains("ExcludeFromRuleCheck") ) {
            Write-Verbose -Message "Rule has excludes defined. Removing excluded items from check."
            $ADObjectsToWorkWith = foreach ($ADObj in $ADObjects) {
                foreach ($ExcludedItem in $RuleSet.ExcludeFromRuleCheck) {
                    if ($ADObj.name -ne $ExcludedItem) {
                        $ADObj
                    }
                }
            }
        }
        else {
            $ADObjectsToWorkWith = $ADObjects
        }

        Write-Verbose -Message "Elapsed time since program start - started applying ruleset filter scriptblock: $($StopWatch.Elapsed)"
        [array]$RuleResult = foreach ($obj in $ADObjectsToWorkWith | Where-Object $RuleSetFilter) {
            if ($(Get-Member -InputObject $RuleSet).Name.Contains("ExcludeFromRuleCheck")) {
                if ($obj.Name -in $ruleset.ExcludeFromRuleCheck ) {
                    $obj
                }
            }
            else {
                $obj
            }
        }
        Write-Verbose -Message "Elapsed time since program start - finished applying ruleset filter scriptblock: $($StopWatch.Elapsed)"

        $RuleSet | Add-Member -Name "RuleSetResult" -MemberType NoteProperty -Value $RuleResult
        $RuleSet
        Write-Verbose -Message "Elapsed time since program start - processed rule: $($StopWatch.Elapsed)"

        $OutALHHtmlProperties = @{
            'Title'     = "$($RuleSet.Name)"
            'SubTitle'  = "$($RuleSet.Description)"
            'InfoText'  = "PowerShell filter string for this rule: `r`n `r`n $($Ruleset.RuleSetFilter)"
            'Footer'    = "# objects part of AD query: $(($ADObjectsToWorkWith          | Measure-Object).Count) `
                           # objects found:            $(($RuleResult                   | Measure-Object).Count) `
                           # objects excluded:         $(($RuleSet.ExcludeFromRuleCheck | Measure-Object).Count) `
                           exclusion list:             $($RuleSet.ExcludeFromRuleCheck -join '; ')  `
                           "
            'AddSort'   = $true
            'AddFilter' = $true
        }

        if ($(Get-Member -InputObject $RuleSet).Name.Contains("ReportSettings")) {
            if ($(Get-Member -InputObject $RuleSet.ReportSettings).Name.Contains("AttributesToShow")) {
                Write-Verbose -Message "Set attributes to show based on rule"
                [hashtable]$AttributesToShow = @{
                    Property = foreach ($attribute in $RuleSet.ReportSettings.AttributesToShow) {
                        if ($attribute -is [PSCustomObject]) {
                            $TempHashtable = @{}
                            $attribute.PSObject.Properties | ForEach-Object {
                                $TempHashtable[$_.Name] = $_.Value
                            }

                            $TempHashtable.Expression = [scriptblock]::create($TempHashtable.Expression)
                            $TempHashtable
                        }
                        else {
                            $attribute
                        }
                    }
                }
            }

            if ($(Get-Member -InputObject $RuleSet.ReportSettings).Name.Contains("OutHtmlProperties")) {
                if ($(Get-Member -InputObject $RuleSet.ReportSettings.OutHtmlProperties).Name.Contains("CellFormat")) {
                    $OutALHHtmlProperties.CellFormat = $RuleSet.ReportSettings.OutHtmlProperties.CellFormat
                    $OutHtmlProperties.CellFormat = $RuleSet.ReportSettings.OutHtmlProperties.CellFormat
                }
            }
        }

        if ($null -eq $AttributesToShow) {
            Write-Verbose -Message "Set default attributes to show"
            [hashtable]$AttributesToShow = @{
                Property = "Name", "DistinguishedName", "ObjectGUID", "ObjectClass"
            }
        }

        if ($(Get-Member -InputObject $RuleSet).Name.Contains("ReportSettings")) {
            if ($(Get-Member -InputObject $RuleSet.ReportSettings).Name.Contains("AttributesToSortBy")) {
                Write-Verbose -Message "Set attributes to sort by based on rule"
                [array]$AttributesToSortBy = $RuleSet.ReportSettings.AttributesToSortBy
            }
        }

        if ($null -eq $AttributesToSortBy) {
            Write-Verbose -Message "Set default attributes to sort by"
            [array]$AttributesToSortBy = "Name"
        }

        $HtmlReport = $null
        $HtmlReport = Out-ALHHtmlReport -Data $($RuleResult | Sort-Object -Property $AttributesToSortBy | Select-Object @AttributesToShow ) @OutALHHtmlProperties
        $RuleSet | Add-Member -Name "HtmlReport" -MemberType NoteProperty -Value $HtmlReport
    }

    $OutALHHtmlDocProperties = @{}
    $ScriptSettings.HtmlProperties.PSObject.Properties | ForEach-Object { $OutALHHtmlDocProperties[$_.Name] = $_.Value }

    if ([string]::IsNullOrEmpty($OutALHHtmlDocProperties.Title)) {
        Write-Verbose -Message "Replace empty HTML document 'Title' with default text from this module"
        $OutALHHtmlDocProperties.Title = $OutALHHtmlDocProperties.Title -replace "(\[default\])", "AD Discrepancies based on rules in '$RulesFile'"
    }

    if ([string]::IsNullOrEmpty($OutALHHtmlDocProperties.SubTitle)) {
        Write-Verbose -Message "Replace empty HTML document 'Subtitle' with default text from this module"
        $OutALHHtmlDocProperties.SubTitle = $OutALHHtmlDocProperties.SubTitle -replace "(\[default\])", "AD Discrepancies based on rules in '$RulesFile'"
    }

    if ($OutALHHtmlDocProperties.InfoText -match "(\[default\])") {
        Write-Verbose -Message "Replace HTML document 'InfoText' value '[default]' with default text from this module"
        $OutALHHtmlDocProperties.InfoText = $OutALHHtmlDocProperties.InfoText -replace "(\[default\])", "AD Discrepancies based on rules in '$RulesFile'"
    }

    if ($OutALHHtmlDocProperties.Footer -match "(\[default\])") {
        Write-Verbose -Message "Replace HTML document 'Footer' value '[default]' with default text from this module"
        $OutALHHtmlDocProperties.Footer = $OutALHHtmlDocProperties.Footer -replace "(\[default\])", "# rules processed: $(($ADRules.RuleSets | Where-Object { $_.Enabled -eq $true } | Measure-Object).Count) / # total rules defined: $(($ADRules.RuleSets | Measure-Object).Count)"
    }

    $HtmlDocString = Out-ALHHtmlDoc -HtmlReport ($TotalResults.HtmlReport) @OutALHHtmlDocProperties
    $StopWatch.Stop()
    Write-Verbose -Message "Elapsed time total: $($StopWatch.Elapsed)"

    $HtmlDocString | Out-File -FilePath $FilePath -Encoding utf8
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
