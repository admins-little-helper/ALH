<#PSScriptInfo

.VERSION 1.0.0

.GUID dc7e6c37-6124-43d7-9b42-a3db5d26afe5

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
Contains a function that allows to move an element within an array.

#>

function Move-ALHElementInArray {
    <#
    .SYNOPSIS
        A PowerShell function to move an element within an array.

    .DESCRIPTION
        A PowerShell function to move an element within an array.

    .PARAMETER Array
        The array in which to move an element to another position.

    .PARAMETER ElementNumberToMove
        The number of the element to move. Remember to start counting at 0!

	.PARAMETER NewElementNumber
        The postition at which the element should be moved to within the array. Remember to start counting at 0!

	.EXAMPLE
        Move-ALHElementInArray -Array @(0,1,2,3,4,5,6,7,8,9) -ElementNumberToMove 2 -NewElementNumber 4

        This will move element number 2 (the 3rd element) to position 4 (the 5th element). The result will the following array:
        @(0,1,3,2,4,5,6,7,8,9)

    .INPUTS
        Nothing

    .OUTPUTS
        Nothing

    .NOTES
        Author:     Dieter Koch
        Email:      diko@admins-little-helper.de

    .LINK
        https://github.com/admins-little-helper/ALH/blob/main/Help/Move-ALHElementInArray.txt
    #>

    [CmdletBinding()]
    param (
        [array]
        $Array,

        [int32]
        $ElementNumberToMove,

        [int32]
        $NewElementNumber
    )

    $StopWatch = [System.Diagnostics.Stopwatch]::startnew()

    if ($ElementNumberToMove -gt $Array.count) {
        Write-Warning -Message "The given element number is greater than the number of elements in the array. Can not continue."
    }
    elseif ($ElementNumberToMove -eq $NewElementNumber) {
        Write-Warning -Message "The given element number and the new element number are equal. There is nothing to do."
    }
    else {
        $ElementToMove = $Array[$ElementNumberToMove]

        if ($ElementNumberToMove -gt $NewElementNumber) {
            $ElementBlock1 = $Array[0 ..(([math]::Min($ElementNumberToMove, $NewElementNumber)) - 1)]
            $ElementBlock2 = $Array[([math]::Min($ElementNumberToMove, $NewElementNumber)) ..(([math]::Max($ElementNumberToMove, $NewElementNumber)) - 1)]
            $ElementBlock3 = $Array[(([math]::Max($ElementNumberToMove, $NewElementNumber)) + 1) .. ($Array.Count - 1)]
            [array]$NewArray = $ElementBlock1 + $ElementToMove + $ElementBlock2 + $ElementBlock3
        }
        else {
            $ElementBlock1 = $Array[0 ..(([math]::Min($ElementNumberToMove, $NewElementNumber)) - 1)]
            $ElementBlock2 = $Array[(([math]::Min($ElementNumberToMove, $NewElementNumber)) + 1) ..([math]::Max($ElementNumberToMove, $NewElementNumber))]
            $ElementBlock3 = $Array[(([math]::Max($ElementNumberToMove, $NewElementNumber)) + 1) .. ($Array.Count - 1)]
            [array]$NewArray = $ElementBlock1 + $ElementBlock2 + $ElementToMove + $ElementBlock3
        }

        $StopWatch.Stop()
        Write-Information -MessageData "Elapsed time: [$($StopWatch.Elapsed)]" -InformationAction Continue
        $NewArray
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
