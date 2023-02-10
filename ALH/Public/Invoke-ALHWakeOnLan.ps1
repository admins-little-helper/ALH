<#PSScriptInfo

.VERSION 1.0.2

.GUID 5cbd7525-1d02-41ab-93f3-b78f276a4cf6

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

    1.0.1
    Fixed issue with WolProxy in case a hostname is specified instead of an ip address.
    Changed behaviour to disallow -Wait parameter together with -WolProxy parameter as it makes no sense to have this together.

    1.0.2
    Fixed count of attempts

#>


<#

.DESCRIPTION
 Function to send wake on lan magic packet.

 Basic idea about how to send a magic packet based on: 
 https://www.pdq.com/blog/wake-on-lan-wol-magic-packet-powershell/

#>


function Invoke-ALHWakeOnLan {
    <#
    .SYNOPSIS
    Function to send wake on lan magic packet.

    .DESCRIPTION
    This function sends a magic packet (WoL / Wake-On-Lan) to wake up one ore multiple systems specified
    by their MAC address.

    .PARAMETER MacAddress
    String. One or more strings specifying the target MAC address to wake up.

    .PARAMETER WolProxy
    String. IP address or hostname of a system that acts as Wake-On-Lan proxy and forwards the
    magic packet. Used in scenarios where you want to wake a host in a different subnet.
    Can not be combined with parameter Wait.

    .PARAMETER Wait
    Switch. If specified, the function checks if the system comes up and waits for about 40 seconds per system.
    Can not be combined with parameter WolProxy.

    .EXAMPLE
    Invoke-ALHWakeOnLan -MacAddress "00:11:22:33:44:55"

    Send magic packet to wake up host with MAC address '00:11:22:33:44:55'
    
    .EXAMPLE
    Invoke-ALHWakeOnLan -MacAddress "00:11:22:33:44:55" -Wait -Verbose

    Send magic packet to wake up host with MAC address '00:11:22:33:44:55' and wait until it is up or timeout is reached.

    .EXAMPLE
    Invoke-ALHWakeOnLan -MacAddress "00:11:22:33:44:55" -WolProxy 10.255.255.255

    Send magic packet to wake up host with MAC address '00:11:22:33:44:55' and use WolProxy 10.255.255.255.
    
    .EXAMPLE
    Invoke-ALHWakeOnLan -MacAddress '00:11:22:33:44:55', '66:77:88:99:AA:BB'

    Send magic packet to wake up hosts with MAC address '00:11:22:33:44:55' and '66:77:88:99:AA:BB'

    .INPUTS
    String

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Invoke-ALHWakeOnLan.txt
    #>

    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $MacAddress,

        [Parameter(ParameterSetName = "WolProxy")]
        [ValidateNotNullOrEmpty()]
        [string]
        $WolProxy,

        [Parameter(ParameterSetName = "NoWolProxy")]
        [switch]
        $Wait
    )
    
    begin {
        if ([string]::IsNullOrEmpty($WolProxy)) {
            $WolProxyTargetIP = [System.Net.IPAddress]::Broadcast
        }
        else {
            if ($WolProxy -as [System.Net.IPAddress]) {
                Write-Verbose -Message "Specified Wake-On-Lan proxy seems to be an IP address"
                $WolProxyTargetIP = ($WolProxy -as [System.Net.IPAddress]).IpAddressTostring
            }
            else {
                try {
                    Write-Verbose -Message "Trying to resolve the specified Wake-On-Lan proxy address in DNS"
                    $WolProxyTargetIP = ([System.Net.Dns]::GetHostByName($WolProxy)).AddressList[0].IPAddressToString
                }
                catch {
                    Write-Warning -Message "Wake-On-Lan proxy hostname '$WolProxy' could not be resolved to an IP address."
                    break
                }
            }        
        }

        if ([string]::IsNullOrEmpty($WolProxyTargetIP)) {
            Write-Error -Message "Unable to correctly define target address for Wake-On-Lan. Aborting."
            break
        }
    }

    process {
        foreach ($Target in $MacAddress) {
            Write-Information -Message "Trying to wake up system with MAC address: '$Target'..." -InformationAction Continue
            $MacByteArray = $MacAddress -split "[:-]" | ForEach-Object { [Byte] "0x$_" }
            [Byte[]] $MagicPacket = (, 0xFF * 6) + ($MacByteArray * 16)

            $UdpClient = New-Object System.Net.Sockets.UdpClient

            Write-Verbose -Message "Sending magic packet to address '$WolProxyTargetIP'"
            $UdpClient.Connect($WolProxyTargetIP, 7)
            $null = $UdpClient.Send($MagicPacket, $MagicPacket.Length)
            $UdpClient.Close()

            if ($Wait.IsPresent) {
                $MaxAttempts = 20
                Write-Information -Message "Checking if host with MAC address '$Target' comes up..." -InformationAction Continue

                for ($i = 1; $i -lt $MaxAttempts; $i++) {
                    Write-Verbose -Message "Attempt #$i of $MaxAttempts"

                    $ArpRecord = Get-NetNeighbor -LinkLayerAddress $Target -ErrorAction SilentlyContinue
                    if ($null -ne $ArpRecord) {
                        Write-Verbose -Message "Found record in ARP table for MAC address '$Target' with IP address '$($ArpRecord.IPAddress)'"
                        Write-Verbose -Message "Trying to resolve ip to hostname"
                        $DnsRecord = [System.Net.Dns]::GetHostByAddress($ArpRecord.IPAddress)

                        if ($null -ne $DnsRecord) {
                            Write-Information -Message "DNS record found for IP '$($ArpRecord.IPAddress)' --> '$($DnsRecord.HostName)'" -InformationAction Continue
                        }
                        else {
                            Write-Warning -Message "No DNS record found for IP '$($ArpRecord.IPAddress)'"
                        }

                        if (Test-Connection -TargetName $ArpRecord.IPAddress -Ping -Count 1 -Quiet) {
                            Write-Information -Message "Host repsonds to ping on IP address '$($ArpRecord.IPAddress)'" -InformationAction Continue
                        }
                        else {
                            Write-Warning -Message "Host does NOT (yet) respond to ping on IP address '$($ArpRecord.IPAddress)'"
                        }

                        break
                    }
                    else {
                        Write-Verbose -Message "No ARP record found. Waiting 2 seconds before retrying"

                        if ($i -eq $MaxAttempts -or $i -eq $($MaxAttempts - 1)) {
                            Write-Warning -Message "Reached maximum number of attempts. No success so far. Giving up."
                        }
                    }
                    
                    Start-Sleep -Seconds 2
                } 
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
