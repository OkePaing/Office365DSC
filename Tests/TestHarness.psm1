function Invoke-TestHarness
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $TestResultsFile,

        [Parameter()]
        [System.String]
        $DscTestsPath,

        [Parameter()]
        [Switch]
        $IgnoreCodeCoverage
    )
    

    Write-Verbose -Message 'Commencing all Office365DSC tests'

    $repoDir = Join-Path -Path $PSScriptRoot -ChildPath '..\' -Resolve

    $testCoverageFiles = @()
    if ($IgnoreCodeCoverage.IsPresent -eq $false)
    {
        Get-ChildItem -Path "$repoDir\modules\Office365DSC\DSCResources\**\*.psm1" -Recurse | ForEach-Object {
            if ($_.FullName -notlike '*\DSCResource.Tests\*') 
            {
                $testCoverageFiles += $_.FullName
            }
        }
    }

    $testResultSettings = @{}
    if ([String]::IsNullOrEmpty($TestResultsFile) -eq $false) 
    {
        $testResultSettings.Add('OutputFormat', 'NUnitXml' )
        $testResultSettings.Add('OutputFile', $TestResultsFile)
    }
    Import-Module Microsoft.Online.SharePoint.PowerShell -Force
    Import-Module MSOnline
    Import-Module -Name "$repoDir\modules\Office365DSC\Office365DSC.psd1"
    $testsToRun = @()

    # Run Unit Tests
    $versionsPath = Join-Path -Path $repoDir -ChildPath "\Tests\Unit\Stubs\"
    $versionsToTest = (Get-ChildItem -Path $versionsPath).Name
    # Import the first stub found so that there is a base module loaded before the tests start
    $firstVersion = $versionsToTest | Select-Object -First 1
    $firstStub = Join-Path -Path $repoDir `
                           -ChildPath "\Tests\Unit\Stubs\Office365.psm1"
    Import-Module $firstStub -WarningAction SilentlyContinue

    $versionsToTest | ForEach-Object -Process {
        $stubPath = Join-Path -Path $repoDir `
                              -ChildPath "\Tests\Unit\Stubs\Office365.psm1"
        $testsToRun += @(@{
            'Path' = (Join-Path -Path $repoDir -ChildPath "\Tests\Unit")
            'Parameters' = @{
                'CmdletModule' = $stubPath
            }
        })
    }

    # DSC Common Tests
    if ($PSBoundParameters.ContainsKey('DscTestsPath') -eq $true)
    {
        $getChildItemParameters = @{
            Path = $DscTestsPath
            Recurse = $true
            Filter = '*.Tests.ps1'
        }

        # Get all tests '*.Tests.ps1'.
        $commonTestFiles = Get-ChildItem @getChildItemParameters

        # Remove DscResource.Tests unit tests.
        $commonTestFiles = $commonTestFiles | Where-Object -FilterScript {
            $_.FullName -notmatch 'DSCResource.Tests\\Tests'
        }

        $testsToRun += @( $commonTestFiles.FullName )
    }

    if ($IgnoreCodeCoverage.IsPresent -eq $false)
    {
        $testResultSettings.Add('CodeCoverage', $testCoverageFiles)
    }

    $results = Invoke-Pester -Script $testsToRun -PassThru @testResultSettings

    return $results
}
