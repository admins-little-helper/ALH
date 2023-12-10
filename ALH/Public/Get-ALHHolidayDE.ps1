<#PSScriptInfo

.VERSION 1.0.0

.GUID 847cdbda-0861-4a0a-9e51-7882ed75c359

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) Dieter Koch

.TAGS Holiday Germany

.LICENSEURI https://github.com/admins-little-helper/ALH/blob/main/LICENSE

.PROJECTURI https://github.com/admins-little-helper/ALH

.ICONURI

.EXTERNALMODULEDEPENDENCIES EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
    1.0.0
    Initial release

#>


<#

.DESCRIPTION
Contains function to retrieve public holidays for Germany using the public API 'https://feiertage-api.de/api/'.

.LINK
https://github.com/admins-little-helper/ALH

.LINK
https://feiertage-api.de/api/

#>


function Get-ALHHolidayDE {
    <#
    .SYNOPSIS
        Retrieves public holidays for Germany.

    .DESCRIPTION
        Retrieves public holidays for Germany using the free API 'https://feiertage-api.de/api/'

    .PARAMETER Year
        The year (format 'yyyy') to retrieve public holidays for. If ommited, the current date's year will be used.

    .PARAMETER Country
        The country code for any of the 16 German country or "NATIONAL" for nationwide public holidays (same is if the parameter is omitted).

    .PARAMETER ShowWeekDay
        If specified, the output is formatted with an additional column 'Weekday' showing the day of the week of the public holiday's date.

    .EXAMPLE
        Get-ALHHolidayDE

        Get public holidays in the current year and for all German countries.

    .EXAMPLE
        Get-ALHHolidayDE -Year 2024

        Get public holidays in 2024.

    .EXAMPLE
        Get-ALHHolidayDE -Year $(Get-Date -Date (Get-Date).AddYears(+1) -Format 'yyyy')

        Get public holiday for next year.

    .EXAMPLE
        Get-ALHHolidayDE -Year 2023 -Country 'BW'

        Get public holiday in 2023 for the country Baden-Wuerttemberg (BW)

    .EXAMPLE
        Get-ALHHolidayDE -ShowWeekDay

        Get public holiday in the current year and show the day of the week in the output.

    .INPUTS
        System.String

    .OUTPUTS
        PSCustomObject

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHHolidayDE.txt

    .LINK
        https://feiertage-api.de/api/
    #>

    [Cmdletbinding()]
    [OutputType([PSCustomObject])]
    param (
        [int]
        $Year,

        [Parameter(ValueFromPipeline)]
        [ValidateSet("NATIONAL", "BW", "BY", "BE", "BB", "HB", "HH", "HE", "MV", "NI", "NW", "RP", "SL", "SN", "ST", "SH", "TH")]
        [string[]]
        $Country,

        [switch]
        $ShowWeekDay
    )

    begin {
        $ApiUri = 'https://feiertage-api.de/api/'

        $InvokeRestMethodParams = @{
            Method = 'Get'
            Uri    = $ApiUri
            Body   = @{}
        }

        if ([string]::IsNullOrEmpty($Year)) {
            Write-Verbose -Message "No year specified. Getting year of current date."
            $Year = Get-Date -Format yyyy
        }

        if (-not ([string]::IsNullOrEmpty($Year))) {
            $InvokeRestMethodParams.Body.jahr = $Year
        }

        if ($DataOnly.IsPresent) {
            Write-Warning -Message "Parameter 'nur_daten' will return ALL holiday - independent of any specified country!"
            $InvokeRestMethodParams.Body.nur_daten = 1
        }
    }

    process {
        try {
            if ([string]::IsNullOrEmpty($Country)) {
                # Retrieve the list of holidays for all countries from the API.
                $Result = Invoke-RestMethod @InvokeRestMethodParams
            }
            else {
                # Retrieve the lis of holiday for the specified countries from the API.
                # Then construct a PSCustomObject that has the same format as the 'AllCountries' response.
                $Result = [PSCustomObject]@{}
                foreach ($CountryElement in $Country) {
                    Write-Verbose -Message "Getting data for country '$CountryElement'"
                    $InvokeRestMethodParams.Body.nur_land = $CountryElement

                    $Result | Add-Member -Name $CountryElement -MemberType NoteProperty -Value $null
                    $Result.$CountryElement = Invoke-RestMethod @InvokeRestMethodParams
                }
            }

            # Change the way the resulting object is formatted.
            # Instead of objects by country, create an array by date containing each holiday.
            # This will result in a long list (for example 190 records for the year 2023) because there is a record for each holiday and for each country.
            # For example 'Neujahrstag' will show up 17 times (16 countries + 'NATIONAL').
            $ResultByDate = foreach ($Country in $Result.PSObject.Properties.Name) {
                foreach ($Holiday in $Result.$Country.PSObject.Properties.Name) {
                    # Create a record for each holiday in each country having the date, the name, the country and - if there is one - the remark.
                    $HolidayRecord = [PSCustomObject]@{
                        Date    = Get-Date -Date $($Result.$Country.$Holiday.datum)
                        Name    = $Holiday
                        Country = $Country[0]
                        Remark  = if (-not [string]::IsNullOrEmpty($Result.$Country.$Holiday.hinweis)) { "$($Country[0]): $($Result.$Country.$Holiday.hinweis)" -replace "`t", "" } else { $null }
                    }

                    # Add our custom type name so that the format gets applied.
                    if ($ShowWeekDay.IsPresent) {
                        # In case the 'ShowWeekDay' parameter was specified, set the type and therefore format to use the LongDate format.
                        $HolidayRecord.PSObject.TypeNames.Insert(0, "ALHHolidayDELongDate")
                    }
                    else {
                        # Otherwise the default type and format is selected (which is Short Date format).
                        $HolidayRecord.PSObject.TypeNames.Insert(0, "ALHHolidayDE")
                    }

                    $HolidayRecord
                }
            }


            # Now create a hash table and put the records from the array in it.
            # Here we acutally remove duplicates by date and combine the country and remark values into a single field.
            # The goal is to have a shorter list where each holiday shows up only once.
            $ResultByDateHT = @{}
            foreach ($Record in $ResultByDate) {
                if ($ResultByDateHT.ContainsKey($Record.Date)) {
                    # In case the hashtable already has a record for the date, we don't need to add the full record.
                    # Instead we only need to add country and remark, but it depends on...
                    if ($ResultByDateHT[$Record.Date].Country -eq "NATIONAL") {
                        # ... the country that is already in the list. In case it's a national holiday, we don't need to add every of the 16 German countries.
                        # But we need to add the remark that might exist for some of the 16 countries because in those remarks the rules and exceptions are explained.
                        if ($ResultByDateHT[$Record.Date].Remark.Length -gt 0) {
                            # In case the remark field for the holiday date in the hashtable already contains something, we need to add a delimiter and the remark of the current record.
                            if ($Record.Remark.Length -gt 0) {
                                $ResultByDateHT[$Record.Date].Remark += "`n`n" + $Record.Remark
                            }
                        }
                        else {
                            # In case the remark field for the holiday date in the hashtable is an empty string, we simply add the current records remark.
                            $ResultByDateHT[$Record.Date].Remark = $Record.Remark
                        }
                    }
                    # In case the current records country name is 'NATIONAL' we can use it to overwrite whatever country name is already in the hashtable for the same date.
                    elseif ($Record.Country -eq "NATIONAL") {
                        $ResultByDateHT[$Record.Date].Country = $Record.Country
                        # But also here, we need to check the remark and apply the same rule as above. Either add a delimiter and the current record's remark to an existing value,
                        # or simply set the current record's remark if there is nothing.
                        if ($ResultByDateHT[$Record.Date].Remark.Length -gt 0) {
                            if ($Record.Remark.Length -gt 0) {
                                $ResultByDateHT[$Record.Date].Remark += "`n`n" + $Record.Remark
                            }
                        }
                        else {
                            $ResultByDateHT[$Record.Date].Remark = $Record.Remark
                        }
                    }
                    else {
                        # We end up in this block in case the hashtable's record is not 'NATIONAL' and the current record's country is also not 'NATIONAL'.
                        # Then we need to add the current record's country name to the list of countries in the hashtable for that date.
                        $ResultByDateHT[$Record.Date].Country += ";" + $Record.Country

                        # And the same procedure again for the remark...
                        if ($ResultByDateHT[$Record.Date].Remark.Length -gt 0) {
                            if ($Record.Remark.Length -gt 0) {
                                $ResultByDateHT[$Record.Date].Remark += "`n`n" + $Record.Remark
                            }
                        }
                        else {
                            $ResultByDateHT[$Record.Date].Remark = $Record.Remark
                        }
                    }
                }
                else {
                    # There is no record in the hashtable for the given date. So we add the full record to the hashtable.
                    $ResultByDateHT[$Record.Date] = $Record
                }
            }

            # And finally create an array again out of the hashtable because it's nicer in the output.
            $FinalResult = foreach ($Element in $ResultByDateHT.GetEnumerator()) {
                $Element.Value
            }

            # Return the final result.
            $FinalResult | Sort-Object -Property Date
        }
        catch [Microsoft.PowerShell.Commands.HttpResponseException] {
            switch ( $_.Exception.Response.StatusCode.value__ ) {
                400 {
                    Write-Error -Message "Bad Request."
                }
                401 {
                    Write-Error -Message "Unauthorized."
                }
                403 {
                    Write-Error -Message "Authorization failed. Please supply a valid ApiKey."
                }
                404 {
                    Write-Error -Message "Not found."
                }
                413 {
                    Write-Error -Message "Payload too large."
                }
                414 {
                    Write-Error -Message "URI too long."
                }
                429 {
                    Write-Error -Message "Too many requests. Please wait and resend your request."
                }
                429 {
                    Write-Error -Message "Quota exceeded."
                }
                500 {
                    Write-Error -Message "Internal Server error."
                }
                503 {
                    Write-Error -Message "Resource currently unavailable. Try again later."
                }
                504 {
                    Write-Error -Message "Service unavailable."
                }
                529 {
                    Write-Error -Message "Too many requests. Please wait and resend your request."
                }
                default {
                    $_
                }
            }
        }
        catch {
            Write-Verbose -Message "An unknown error occured."
            $_
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
