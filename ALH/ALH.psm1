
#region ActiveDirectory preparation
# Prevent the Active Directory from creating the AD: drive. This dramatically improves performance when importing the ALH module
# https://techibee.com/active-directory/loading-activedirectory-powershell-module-without-default-ad-drive/2372
$Env:ADPS_LoadDefaultDrive = 0
#endregion


#Get public and private function definition files.
$PublicScripts = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$PrivateScripts = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
foreach ($ScriptToImport in @($PrivateScripts + $PublicScripts)) {
    try {
        Write-Verbose -Message "Importing script $($ScriptToImport.FullName)"
        . $ScriptToImport.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($ScriptToImport.FullName): $_"
    }
}

Export-ModuleMember -Function $PublicScripts.Basename -Alias *
