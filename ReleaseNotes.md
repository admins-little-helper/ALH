# Release notes

[README.md](./README.md)

## Version 2.3.0 (2023-09-06)

* Fixed PSScriptAnalyzer rule violations in all functions.
* Get-ALHADFailedLogonAttempt: Renamed function to fix rule violation 'PSUseSingularNouns'.
* Get-ALHOffice365IPAndUrl: Renamed function to fix rule violation 'PSUseSingularNouns'.
* Get-ALHOffice365IPAndUrl: Fixed issue with clientrequestid.
* Get-ALHOffice365SkuId: Renamed function to fix rule violation 'PSUseSingularNouns'.
* Get-ALHScriptSetting: Renamed function to fix rule violation 'PSUseSingularNouns'.
* Invoke-ALHCMAction: Renamed function to fix rule violation 'PSUseSingularNouns'.
* Added function: 'Move-ALHElementInArray'.
* Get-ALHOffice365UpdateStatus: Added parameter 'UpdateChannel' to limit the information returned to a single channel.
* Get-ALHOffice365UpdateStatus: Added some additional (unofficial!) channel name-ffn mappings.

## Version 2.2.1 (2023-03-24)

* Set-ALHSavedCredentials: Fixed issue when creating $Path failes.
* Get-ALHOffice365UpdateStatus: Changed output to include 'UpdatedTimeUtc' and removed 'FFN'.

## Version 2.2.0 (2023-03-23)

* Fixed typos in some functions.
* Set-ALHSavedCredentials: Redesign and code cleanup.
* Get-ALHSavedCredentials: Redesign and code cleanup.
* Stop-ALHService: Changed message output.
* Stop-ALHService: Changed how the -KillDegraded switch works. When specified, only service where status is 'degraded' will be stopped. Normally running processes are not touched.
* Added function 'Get-ALHOffice365UpdateStatus'

## Version 2.1.1 (2023-03-23)

* Function 'Stop-ALHService': Fixed issue in correctly determining service status and service state.

## Version 2.1.0 (2023-03-22)

* Added function 'Get-ALHADDiscrepancy'
* Added function 'Get-ALHDSDomainController'
* Added function 'Stop-ALHService'

## Version 2.0.5 (2023-02-22)

* Set-ALHSavedCredential: Fixed issue: Wrong paramter name for Out-File.
* Get-ALHADBitlockerRecoveryKey: Fixed issue in returning computer name.

## Version 2.0.4 (2023-02-16)

* Fixed issue in calling Set-ALHCellColor in functions 'Out-ALHHtml' and 'Out-ALHHtmlReport'.

## Version 2.0.3 (2023-02-13)

* Added help to function 'Out-ALHHtml'.
* Changed output of PasswordExpirationTime in function 'Get-ALHADLapsPwd' to a human readable format.
* Updated help files.

## Version 2.0.2 (2023-02-11)

* Added missing help files to project.
* Fixed order of loading module functions.

## Version 2.0.1 (2023-02-10)

* Corrected project page link in README.md.
* Removed unused help files.

## Version 2.0.0 (2023-02-09)

* Initial public release.
