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
                                              -DscResource "EXOSharedMailbox"
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
        $GlobalAdminAccount = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)

        Mock Invoke-ExoCommand {
            return Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $Arguments -NoNewScope
        }

        # Test contexts 
        Context -Name "Mailbox doesn't exist and it should" -Fixture {
            $testParams = @{
                DisplayName = "Test Shared Mailbox"
                PrimarySMTPAddress = "Testh@contoso.onmicrosoft.com"
                Ensure = "Present"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-Mailbox -MockWith { 
                return $null
            }

            Mock -CommandName New-Mailbox -MockWith {

            }

            Mock -CommandName Set-Mailbox -MockWith {

            }

            It "Should return absent from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Absent"
            }

            It "Should create the Shared Mailbox in the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "Mailbox already exists and it should" -Fixture {
            $testParams = @{
                DisplayName = "Test Shared Mailbox"
                PrimarySMTPAddress = "Test@contoso.onmicrosoft.com"
                Ensure = "Present"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-Mailbox -MockWith { 
                return @{
                    Identity = "Test Shared Mailbox"
                    RecipientTypeDetails = "SharedMailbox"
                    EmailAddresses = @("smtp:user@contoso.onmicrosoft.com", "SMTP:test@contoso.onmicrosoft.com")
                    PrimarySMTPAddress = "test@contoso.onmicrosoft.com"
                }
            }

            It "Should return Present from the Get method" {
                (Get-TargetResource @testParams).Ensure | Should Be "Present"
            }

            It "Should return True from the Test method" {
                { Test-TargetResource @testParams } | Should Be $True
            }
        }

        Context -Name "Alias is Contained in the PrimarySMTP Address" -Fixture {
            $testParams = @{
                DisplayName = "Test Shared Mailbox"
                PrimarySMTPAddress = "Test@contoso.onmicrosoft.com"
                Aliases = @("Test@contoso.onmicrosoft.com")
                Ensure = "Present"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            It "Should throw an error from the Set method" {
                { Set-TargetResource @testParams } | Should Throw "You cannot have the Aliases list contain the PrimarySMTPAddress"
            }
        }

        Context -Name "Mailbox exists but it should not" -Fixture {
            $testParams = @{
                DisplayName = "Test Shared Mailbox"
                PrimarySMTPAddress = "Test@contoso.onmicrosoft.com"
                Aliases = @("User1@contoso.onmicrosoft.com")
                Ensure = "Absent"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-Mailbox -MockWith { 
                return @{
                    Identity = "Test Shared Mailbox"
                    RecipientTypeDetails = "SharedMailbox"
                    EmailAddresses = @("smtp:user@contoso.onmicrosoft.com", "SMTP:test@contoso.onmicrosoft.com")
                    PrimarySMTPAddress = "test@contoso.onmicrosoft.com"
                }
            }

            Mock -CommandName Remove-Mailbox -MockWith {
                return $null
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
                Assert-MockCalled -CommandName Remove-Mailbox -Times 1
            }
        }

        Context -Name "Aliases are specified" -Fixture {
            $testParams = @{
                DisplayName = "Test Shared Mailbox"
                PrimarySMTPAddress = "Test@contoso.onmicrosoft.com"
                Aliases = @("User1@contoso.onmicrosoft.com")
                Ensure = "Present"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-Mailbox -MockWith { 
                return @{
                    Identity = "Test Shared Mailbox"
                    RecipientTypeDetails = "SharedMailbox"
                    EmailAddresses = @("smtp:user@contoso.onmicrosoft.com", "SMTP:test@contoso.onmicrosoft.com")
                    PrimarySMTPAddress = "test@contoso.onmicrosoft.com"
                }
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            $testParams = @{
                DisplayName = "Test Shared Mailbox"
                GlobalAdminAccount = $GlobalAdminAccount
            }

            Mock -CommandName Get-Mailbox -MockWith {
                return @{
                    Name = "Test Shared Mailbox"
                    DisplayName = "Test Shared Mailbox"
                    PrimarySMTPAddress = "Testh@contoso.onmicrosoft.com"
                }
            }

            It "Should Reverse Engineer resource from the Export method" {
                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
