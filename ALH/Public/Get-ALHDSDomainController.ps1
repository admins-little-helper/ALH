<#PSScriptInfo

.VERSION 1.0.1

.GUID e6e6b2bd-ffa8-4c53-a1fe-f383723729e1

.AUTHOR Dieter Koch

.COMPANYNAME

.COPYRIGHT (c) Dieter Koch

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

    1.0.1
    Changed type for parameter DomainName

#>


<#

.DESCRIPTION
 Function to query Active Directory Domain Controller based on DsGetDcName function
 https://docs.microsoft.com/en-us/windows/win32/api/dsgetdc/nf-dsgetdc-dsgetdcnamea

 Based on script from Jordan Borean (Jordan Borean (@jborean93) <jborean93@gmail.com>)
 https://gist.github.com/jborean93/6c3d8b64aa994c2676c6cc249bbf8833

 #>



function Get-ALHDSDomainController {
    <#
    .SYNOPSIS
    Locate a domain controller.

    .DESCRIPTION
    Locates a domain controller and returns the name and some additional information for about it.

    .PARAMETER DomainName
    The name of the Active Directory domain to search a DC for.

    .PARAMETER Server
    The name of the server to run the search from.

    .PARAMETER DomainGuid
    The GUID of the domain to find. This is used if the DC cannot be found by DomainName.

    .PARAMETER SiteName
    The name of the site where the DC should exist.

    .PARAMETER DirectoryServiceRequired
    Require the DC to support directory services.

    .PARAMETER DirectoryServicePreferred
    Prioritise DCs that support directory services over ones that do not.

    .PARAMETER GlobalCatalogRequired
    Require the DC to be a global catalog server for the forest of domains with this domain as the root.

    .PARAMETER PrimaryDCRequired
    Finds the DC that is the primary domain controller for the domain.

    .PARAMETER NoCache
    Forces cached information to be ignored.

    .PARAMETER UseCache
    Always use the cached information even when the function would normally refresh the data.

    .PARAMETER IpRequired
    The DC must have an IP address.

    .PARAMETER KdcRequired
    The DC must be a kerberos key distribution center.

    .PARAMETER TimeservRequired
    Requires the DC be currently running the Windows Time Service.

    .PARAMETER WritableRequired
    The DC must be writable and not a read only copy.

    .PARAMETER GoodTimeservPreferred
    Finds a DC that is a reliable time server.

    .PARAMETER AvoidSelf
    When calling from a domain controller, specified that the returned DC should not be the current host.

    .PARAMETER OnlyLdapNeeded
    Find a host that is an LDAP server and not necessarily a DC.

    .PARAMETER IsFlatName
    The -DomainName value is a flag name, e.g. DOMAIN. This cannot be combined with IsDnsName.

    .PARAMETER IsDnsName
    The -DomainName value is a DNS name, e.g. domain.com. This cannot be combined with IsFlagName.

    .PARAMETER TryNextClosestSite
    Attempt to find a DC in the same site but if nothing is found try the next closest site.

    .PARAMETER WebServiceRequired
    Requires the DC to be running the Active Directory web service.

    .PARAMETER Server2008OrLater
    DC must be running Windows Server 2008 or later.

    .PARAMETER Server2012OrLater
    DC must be running Windows Server 2012 or later.

    .PARAMETER Server2012R2OrLater
    DC must be running Windows Server 2012 R2 or later.

    .PARAMETER Server2016OrLater
    DC must be running Windows Server 2016 or later.

    .PARAMETER ReturnDnsName
    Returns the DNS names for Name and DomainName. This cannot be combined with ReturnFlatName.

    .PARAMETER ReturnFlatName
    Returns the flag name for Name and DOmain Name. This cannot be combined with ReturnDnsName.

    .EXAMPLE
    Get-ALHDSDomainController

    .INPUTS
    None

    .OUTPUTS
    Nothing

    .NOTES
    Author:     Dieter Koch
    Email:      diko@admins-little-helper.de

    .LINK
    https://github.com/admins-little-helper/ALH/blob/main/Help/Get-ALHDSDomainController.txt
    #>

    [CmdletBinding()]
    param (
        [String]
        $DomainName = (Get-CimInstance -ClassName "Win32_ComputerSystem").Domain,

        [String]
        $Server,

        [Nullable[Guid]]
        [AllowNull()]
        $DomainGuid = $null,

        [String]
        $SiteName,

        [Switch]
        $DirectoryServiceRequired,

        [Switch]
        $DirectoryServicePreferred,

        [Switch]
        $GlobalCatalogRequired,

        [Switch]
        $PrimaryDCRequired,

        [Switch]
        $NoCache,

        [Switch]
        $UseCache,

        [Switch]
        $IpRequired,

        [Switch]
        $KdcRequired,

        [Switch]
        $TimeservRequired,

        [Switch]
        $WritableRequired,

        [Switch]
        $GoodTimeservPreferred,

        [Switch]
        $AvoidSelf,

        [Switch]
        $OnlyLdapNeeded,

        [Switch]
        $IsFlatName,

        [Switch]
        $IsDnsName,

        [Switch]
        $TryNextClosestSite,

        [Switch]
        $WebServiceRequired,

        [Switch]
        $Server2008OrLater,

        [Switch]
        $Server2012OrLater,

        [Switch]
        $Server2012R2OrLater,

        [Switch]
        $Server2016OrLater,

        [Switch]
        $ReturnDnsName,

        [Switch]
        $ReturnFlatName
    )

    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace NetApi
{
    public class NativeHelpers
    {
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DOMAIN_CONTROLLER_INFOW
        {
            public string DomainControllerName;
            public string DomainControllerAddress;
            public DCAddressType DomainControllerAddressType;
            public Guid DomainGuid;
            public string DomainName;
            public string DnsForestName;
            public DCFlags Flags;
            public string DcSiteName;
            public string ClientSiteName;
        }
    }

    public class NativeMethods
    {
        [DllImport("NetApi32.dll", CharSet = CharSet.Unicode)]
        private static extern Int32 DsGetDcNameW(
            string ComputerName,
            string DomainName,
            IntPtr DomainGuid,
            string SiteName,
            GetDcFlags Flags,
            out IntPtr DomainControllerInfo);

        [DllImport("NetApi32.dll")]
        private static extern Int32 NetApiBufferFree(
            IntPtr Buffer);

        public static DCInfo DsGetDcName(string domainName, string computerName = null, string siteName = null,
            GetDcFlags flags = GetDcFlags.None, Guid? domainGuid = null)
        {
            IntPtr rawInfo;
            IntPtr domainGuidPtr = IntPtr.Zero;
            try
            {
                if (domainGuid != null)
                {
                    byte[] guidBytes = ((Guid)domainGuid).ToByteArray();
                    domainGuidPtr = Marshal.AllocHGlobal(guidBytes.Length);
                    Marshal.Copy(guidBytes, 0, domainGuidPtr, guidBytes.Length);
                }

                Int32 res = DsGetDcNameW(computerName, domainName, domainGuidPtr, siteName, flags, out rawInfo);
                if (res != 0)
                    throw new Win32Exception(res);
            }
            finally
            {
                if (domainGuidPtr != IntPtr.Zero)
                    Marshal.FreeHGlobal(domainGuidPtr);
            }

            try
            {
                var info = (NativeHelpers.DOMAIN_CONTROLLER_INFOW)Marshal.PtrToStructure(rawInfo,
                    typeof(NativeHelpers.DOMAIN_CONTROLLER_INFOW));

                return new DCInfo()
                {
                    Name = info.DomainControllerName,
                    Address = info.DomainControllerAddress,
                    AddressType = info.DomainControllerAddressType,
                    DomainGuid = info.DomainGuid,
                    DomainName = info.DomainName,
                    DnsForestName = info.DnsForestName,
                    Flags = info.Flags,
                    DcSiteName = info.DcSiteName,
                    ClientSiteName = info.ClientSiteName,
                };
            }
            finally
            {
                NetApiBufferFree(rawInfo);
            }
        }
    }

    public class DCInfo
    {
        public string Name { get; internal set; }
        public string Address { get; internal set; }
        public DCAddressType AddressType { get; internal set; }
        public Guid DomainGuid { get; internal set; }
        public string DomainName { get; internal set; }
        public string DnsForestName { get; internal set; }
        public DCFlags Flags { get; internal set; }
        public string DcSiteName { get; internal set; }
        public string ClientSiteName { get; internal set; }
    }

    public enum DCAddressType : uint
    {
        INetAddress = 1,
        NetbiosAddress = 2,
    }

    [Flags]
    public enum DCFlags : uint
    {
        Pdc = 0x00000001,
        Gc = 0x00000004,
        Ldap = 0x00000008,
        Ds = 0x00000010,
        Kdc = 0x00000020,
        Timeserv = 0x00000040,
        Closest = 0x00000080,
        Writable = 0x00000100,
        GoodTimeserv = 0x00000200,
        Ndnc = 0x00000400,
        SelectSecretDomain6 = 0x00000800,
        FullSecretDomain6 = 0x00001000,
        Ws = 0x00002000,
        Ds8 = 0x00004000,
        Ds9 = 0x00008000,
        Ds10 = 0x00010000,
        Ping = 0x000FFFFF,
        DnsController = 0x20000000,
        DnsDOmain = 0x40000000,
        DnsForest = 0x80000000,
    }

    [Flags]
    public enum GetDcFlags : uint
    {
        None = 0x00000000,
        ForceRediscovery = 0x00000001,
        DirectoryServiceRequired = 0x00000010,
        DirectoryServicePreferred = 0x00000020,
        GcServerRequired = 0x00000040,
        PdcRequired = 0x00000080,
        BackgroundOnly = 0x00000100,
        IpRequired = 0x00000200,
        KdcRequired = 0x00000400,
        TimeservRequired = 0x00000800,
        WritableRequired = 0x00001000,
        GoodTimeservPreferred = 0x00002000,
        AvoidSelf = 0x00004000,
        OnlyLdapNeeded = 0x00008000,
        IsFlatName = 0x00010000,
        IsDnsName = 0x00020000,
        TryNextClosestSite = 0x00040000,
        DirectoryService6Required = 0x00080000,
        WebServiceRequired = 0x00100000,
        DirectoryService8Required = 0x00200000,
        DirectoryService9Required = 0x00400000,
        DirectoryService10Required = 0x00800000,
        ReturnDnsName = 0x40000000,
        ReturnFlatName = 0x80000000,
    }
}
'@

    $ServerValue = if ($Server) { $Server } else { [NullString]::Value }
    $siteNameValue = if ($SiteName) { $SiteName } else { [NullString]::Value }
    [NetApi.GetDcFlags]$flags = [NetApi.GetDcFlags]::None

    if ($DirectoryServiceRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::DirectoryServiceRequired
    }

    if ($DirectoryServicePreferred) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::DirectoryServicePreferred
    }

    if ($GlobalCatalogRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::GcServerRequired
    }

    if ($PrimaryDCRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::PdcRequired
    }

    if ($NoCache) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::ForceRediscovery
    }

    if ($UseCache) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::BackgroundOnly
    }

    if ($IpRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::IpRequired
    }

    if ($KdcRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::KdcRequired
    }

    if ($TimeservRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::TimeservRequired
    }

    if ($WritableRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::WritableRequired
    }

    if ($GoodTimeservPreferred) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::GoodTimeservPreferred
    }

    if ($AvoidSelf) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::AvoidSelf
    }

    if ($OnlyLdapNeeded) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::OnlyLdapNeeded
    }

    if ($IsFlatName) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::IsFlatName
    }

    if ($IsDnsName) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::IsDnsName
    }

    if ($TryNextClosestSite) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::TryNextClosestSite
    }

    if ($WebServiceRequired) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::WebServiceRequired
    }

    if ($Server2008OrLater) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::DirectoryService6Required
    }

    if ($Server2012OrLater) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::DirectoryService8Required
    }

    if ($Server2012R2OrLater) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::DirectoryService9Required
    }

    if ($Server2016OrLater) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::DirectoryService10Required
    }

    if ($ReturnDnsName) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::ReturnDnsName
    }

    if ($ReturnFlatName) {
        $flags = [UInt32]$flags -bor [UInt32][NetApi.GetDcFlags]::ReturnFlatName
    }

    if ($IsDnsName -and $IsFlatName) {
        Write-Error -Message "Cannot specify IsDnsName and IsFlatName together" -Category InvalidArgument
        return
    }

    if ($ReturnDnsName -and $ReturnFlatName) {
        Write-Error -Message "Cannot specify ReturnDnsName and ReturnFlatName together" -Category InvalidArgument
        return
    }

    [NetApi.NativeMethods]::DsGetDcName(
        $DomainName,
        $ServerValue,
        $siteNameValue,
        $flags,
        $DomainGuid
    )
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
