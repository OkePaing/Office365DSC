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
                                                -DscResource "SPOSite"

Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock -CommandName Test-SPOServiceConnection -MockWith {

        }

        # Test contexts 
        Context -Name "When the site doesn't already exist" -Fixture {
            $testParams = @{
                Url = "https://contoso.com/sites/TestSite"
                Owner = "testuser@contoso.com"
                StorageQuota = 1000
                CentralAdminUrl = "https://contoso-admin.sharepoint.com"
                GlobalAdminAccount = $GlobalAdminAccount
                Ensure= "Present"
            }

            Mock -CommandName New-SPOSite -MockWith { 
                return @{Url = $null}
            }

            Mock -CommandName Get-SPOSite -MockWith { 
                return $null
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent" 
            }

            It "Should return false from the Test method" {
                Test-TargetResource @testParams | Should Be $false
            }

            It "Creates the site collection in the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "The site already exists" -Fixture {
            $testParams = @{
                Url = "https://contoso.com/sites/TestSite"
                Owner = "testuser@contoso.com"
                StorageQuota = 1000
                CentralAdminUrl = "https://contoso-admin.sharepoint.com"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-SPOSite -MockWith { 
                return @{
                    Url = "https://contoso.com/sites/TestSite"
                    Ensure = "Present"
                }
            }
            
            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present" 
            }

            It "Should return true from the Test method" {
                Test-TargetResource @testParams | Should Be $true
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                Url = "https://contoso.com/sites/TestSite"
                CentralAdminUrl = "https://contoso-admin.sharepoint.com"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-SPOSite -MockWith { 
                return @{
                    Url = "https://contoso.com/sites/TestSite"
                    Ensure = "Present"
                }
            }

            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
