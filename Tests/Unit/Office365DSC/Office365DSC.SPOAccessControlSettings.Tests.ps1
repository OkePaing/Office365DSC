[CmdletBinding()]
param(
    [Parameter()]
    [string] 
    $CmdletModule = (Join-Path -Path $PSScriptRoot `
            -ChildPath "..\Stubs\Office365.psm1" `
            -Resolve)
)

Import-Module -Name (Join-Path -Path $PSScriptRoot `
        -ChildPath "..\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-O365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "SPOAccessControlSettings"

Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock -CommandName Test-PnPOnlineConnection -MockWith {

        }

        # Test contexts 
        Context -Name "PNP AccessControl settings are not configured" -Fixture {
            $testParams = @{
                CentralAdminUrl              = "https://o365dsc1-admin.sharepoint.com"
                GlobalAdminAccount           = $GlobalAdminAccount
                IsSingleInstance             = "Yes"
                DisplayStartASiteOption      = $false
                StartASiteFormUrl            = "https://o365dsc1.sharepoint.com"
                IPAddressEnforcement         = $false
                #IPAddressAllowList           = "" #would generate an error while writing this resource
                IPAddressWACTokenLifetime    = 15
                CommentsOnSitePagesDisabled  = $false
                SocialBarOnSitePagesDisabled = $false
                DisallowInfectedFileDownload = $false
                ExternalServicesEnabled      = $true
                EmailAttestationRequired     = $false
                EmailAttestationReAuthDays   = 30
            }

            Mock -CommandName Set-PnPTenant -MockWith {
                return @{
                    DisplayStartASiteOption      = $false
                    StartASiteFormUrl            = "https://o365dsc1.sharepoint.com"
                    IPAddressEnforcement         = $false
                    #IPAddressAllowList           = "" #would generate an error while writing this resource
                    IPAddressWACTokenLifetime    = 15
                    CommentsOnSitePagesDisabled  = $false
                    SocialBarOnSitePagesDisabled = $false
                    DisallowInfectedFileDownload = $false
                    ExternalServicesEnabled      = $true
                    EmailAttestationRequired     = $false
                    EmailAttestationReAuthDays   = 30
                }
            }

            Mock -CommandName Get-PnPTenant -MockWith {
                return @{
                    DisplayStartASiteOption      = $true
                    StartASiteFormUrl            = "https://o365dsc1.sharepoint.com"
                    IPAddressEnforcement         = $false
                    #IPAddressAllowList           = "" #would generate an error while writing this resource
                    IPAddressWACTokenLifetime    = 20
                    CommentsOnSitePagesDisabled  = $true
                    SocialBarOnSitePagesDisabled = $false
                    DisallowInfectedFileDownload = $false
                    ExternalServicesEnabled      = $true
                    EmailAttestationRequired     = $false
                    EmailAttestationReAuthDays   = 29
                }
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Sets the tenant AccessControl settings in Set method" {
                set-TargetResource @testParams
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                CentralAdminUrl              = "https://o365dsc1-admin.sharepoint.com"
                GlobalAdminAccount           = $GlobalAdminAccount
                IsSingleInstance             = "Yes"
            }

            Mock -CommandName Get-PnPTenant -MockWith {
                return @{
                    CentralAdminUrl              = "https://o365dsc1-admin.sharepoint.com"
                    GlobalAdminAccount           = $GlobalAdminAccount
                    DisplayStartASiteOption      = $false
                    StartASiteFormUrl            = "https://o365dsc1.sharepoint.com"
                    IPAddressEnforcement         = $false
                    #IPAddressAllowList           = "" #would generate an error while writing this resource
                    IPAddressWACTokenLifetime    = 15
                    CommentsOnSitePagesDisabled  = $false
                    SocialBarOnSitePagesDisabled = $false
                    DisallowInfectedFileDownload = $false
                    ExternalServicesEnabled      = $true
                    EmailAttestationRequired     = $false
                    EmailAttestationReAuthDays   = 30
                }
            }

            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }#inmodulescope
}#describe

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope