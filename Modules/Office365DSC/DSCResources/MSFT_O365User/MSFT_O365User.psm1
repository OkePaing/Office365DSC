function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserPrincipalName,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $FirstName,

        [Parameter()]
        [System.String]
        $LastName,

        [Parameter()]
        [System.String]
        $UsageLocation,

        [Parameter()]
        [System.String[]]
        $LicenseAssignment,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.String]
        $City,

        [Parameter()]
        [System.String]
        $Country,

        [Parameter()]
        [System.String]
        $Department,

        [Parameter()]
        [System.String]
        $Fax,

        [Parameter()]
        [System.String]
        $MobilePhone,

        [Parameter()]
        [System.String]
        $Office,

        [Parameter()]
        [System.Boolean]
        $PasswordNeverExpires = $false,

        [Parameter()]
        [System.String]
        $PhoneNumber,

        [Parameter()]
        [System.String]
        $PostalCode,

        [Parameter()]
        [System.String]
        $PreferredDataLocation,

        [Parameter()]
        [System.String]
        $PreferredLanguage,

        [Parameter()]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        $StreetAddress,

        [Parameter()]
        [System.String]
        $Title,

        [Parameter()]
        [ValidateSet("Guest", "Member", "Other", "Viral")]
        [System.String]
        $UserType,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Test-O365ServiceConnection -GlobalAdminAccount $GlobalAdminAccount

    $nullReturn = @{
        UserPrincipalName = $null
        DisplayName = $null
        FirstName = $null
        LastName = $null
        UsageLocation = $null
        LicenseAssignment = $null
        Password = $null
        GlobalAdminAccount = $GlobalAdminAccount
        Ensure = "Absent"
    }

    try
    {
        Write-Verbose -Message "Getting Office 365 User $UserPrincipalName"
        $user = Get-AzureADUser | Where-Object {$_.UserPrincipalName -eq $UserPrincipalName}
        if (!$user)
        {
            Write-Verbose "The specified User doesn't already exist."
            return $nullReturn
        }

        Write-Verbose "Found User $($UserPrincipalName)"
        $currentLicenseAssignment = @()
        foreach($license in ($user | Get-AzureADUserLicenseDetail))
        {
            [array]$currentLicenseAssignment += $license.SkuPartNumber.ToString()
        }

        $passwordNeverExpires = $user.PasswordPolicies
        if ($null -eq $passwordNeverExpires -or $passwordNeverExpires -eq "None")
        {
            $passwordNeverExpires = $true
        }
        return @{
            UserPrincipalName = $user.UserPrincipalName
            DisplayName = $user.DisplayName
            GivenName = $user.GivenName
            Surname = $user.Surname
            UsageLocation = $user.UsageLocation
            LicenseAssignment = $currentLicenseAssignment
            Password = $Password
            City = $user.City
            Country = $user.Country
            Department = $user.Department
            Fax = $user.Fax
            Mobile = $user.Mobile
            Office = $user.Office
            PasswordNeverExpires = $passwordNeverExpires
            TelephoneNumber = $user.TelephoneNumber
            PostalCode = $user.PostalCode
            PreferredDataLocation = $user.PreferredDataLocation
            PreferredLanguage = $user.PreferredLanguage
            State = $user.State
            StreetAddress = $user.StreetAddress
            JobTitle = $user.JobTitle
            UserType = $user.UserType
            GlobalAdminAccount = $GlobalAdminAccount
            Ensure = "Present"
        }
    }
    catch
    {
        Write-Verbose "The specified User doesn't already exist."
        return $nullReturn
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserPrincipalName,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $FirstName,

        [Parameter()]
        [System.String]
        $LastName,

        [Parameter()]
        [System.String]
        $UsageLocation,

        [Parameter()]
        [System.String[]]
        $LicenseAssignment,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.String]
        $City,

        [Parameter()]
        [System.String]
        $Country,

        [Parameter()]
        [System.String]
        $Department,

        [Parameter()]
        [System.String]
        $Fax,

        [Parameter()]
        [System.String]
        $MobilePhone,

        [Parameter()]
        [System.String]
        $Office,

        [Parameter()]
        [System.Boolean]
        $PasswordNeverExpires = $false,

        [Parameter()]
        [System.String]
        $PhoneNumber,

        [Parameter()]
        [System.String]
        $PostalCode,

        [Parameter()]
        [System.String]
        $PreferredDataLocation,

        [Parameter()]
        [System.String]
        $PreferredLanguage,

        [Parameter()]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        $StreetAddress,

        [Parameter()]
        [System.String]
        $Title,

        [Parameter()]
        [ValidateSet("Guest", "Member", "Other", "Viral")]
        [System.String]
        $UserType,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Test-O365ServiceConnection -GlobalAdminAccount $GlobalAdminAccount

    $user = Get-TargetResource @PSBoundParameters
    $CurrentParameters = $PSBoundParameters
    $CurrentParameters.Remove("Ensure")
    $CurrentParameters.Remove("GlobalAdminAccount")
    $newLicenseAssignment = $LicenseAssignment

    if ($user.UserPrincipalName)
    {
        Write-Verbose "Comparing License Assignment for user $UserPrincipalName"
        $diff = Compare-Object -ReferenceObject $user.LicenseAssignment -DifferenceObject $newLicenseAssignment
        $CurrentParameters.Remove("LicenseAssignment")
        if($Password)
        {
            $CurrentParameters.Remove("Password")
        }
        $CurrentParameters.Remove("LicenseAssignment")
        if ($diff.InputObject)
        {
            Write-Verbose "Detected a change in license assignment for user $UserPrincipalName"
            Write-Verbose "Current License Assignment is $($user.LicenseAssignment)"
            Write-Verbose "New License Assignment is $($newLicenseAssignment)"
            $licensesToRemove = @()
            $licensesToAdd = @()
            foreach($difference in $diff)
            {
                if ($difference.SideIndicator -eq "<=")
                {
                    $licensesToRemove += $difference.InputObject
                }
                elseif ($difference.SideIndicator -eq "=>")
                {
                    $licensesToAdd += $difference.InputObject
                }
            }
            Write-Verbose "Updating License Assignment"
            Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $licensesToAdd -RemoveLicenses $licensesToRemove
        }
        Write-Verbose -Message "Updating Office 365 User $UserPrincipalName Information"
        $user = Set-MsolUser @CurrentParameters
    }
    else
    {
        Write-Verbose -Message "Creating Office 365 User $UserPrincipalName"
        $user = New-MsolUser @CurrentParameters
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserPrincipalName,

        [Parameter()]
        [System.String]
        $DisplayName,

        [Parameter()]
        [System.String]
        $FirstName,

        [Parameter()]
        [System.String]
        $LastName,

        [Parameter()]
        [System.String]
        $UsageLocation,

        [Parameter()]
        [System.String[]]
        $LicenseAssignment,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $Password,

        [Parameter()]
        [System.String]
        $City,

        [Parameter()]
        [System.String]
        $Country,

        [Parameter()]
        [System.String]
        $Department,

        [Parameter()]
        [System.String]
        $Fax,

        [Parameter()]
        [System.String]
        $MobilePhone,

        [Parameter()]
        [System.String]
        $Office,

        [Parameter()]
        [System.Boolean]
        $PasswordNeverExpires = $false,

        [Parameter()]
        [System.String]
        $PhoneNumber,

        [Parameter()]
        [System.String]
        $PostalCode,

        [Parameter()]
        [System.String]
        $PreferredDataLocation,

        [Parameter()]
        [System.String]
        $PreferredLanguage,

        [Parameter()]
        [System.String]
        $State,

        [Parameter()]
        [System.String]
        $StreetAddress,

        [Parameter()]
        [System.String]
        $Title,

        [Parameter()]
        [ValidateSet("Guest", "Member", "Other", "Viral")]
        [System.String]
        $UserType,

        [Parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = "Present",

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )

    Write-Verbose -Message "Testing Office 365 User $UserPrincipalName"
    $CurrentValues = Get-TargetResource @PSBoundParameters
    $result = Test-Office365DSCParameterState -CurrentValues $CurrentValues `
                                           -DesiredValues $PSBoundParameters `
                                           -ValuesToCheck @("Ensure", `
                                                            "UserPrincipalName", `
                                                            "LicenseAssignment", `
                                                            "UsageLocation", `
                                                            "FirstName", `
                                                            "LastName", `
                                                            "DisplayName", `
                                                            "City", `
                                                            "Country", `
                                                            "Department", `
                                                            "Fax", `
                                                            "MobilePhone", `
                                                            "Office", `
                                                            "PasswordNeverExpires", `
                                                            "PhoneNumber", `
                                                            "PostalCode", `
                                                            "PreferredDataLocation", `
                                                            "PreferredLanguage", `
                                                            "State", `
                                                            "StreetAddress", `
                                                            "Title", `
                                                            "UserType")
    Write-Verbose "Testing User $UserPrincipalName result was $result"
    return $result
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $UserPrincipalName,

        [Parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount
    )
    $result = Get-TargetResource @PSBoundParameters
    $content = ""
    if ($null -ne $result.UserPrincipalName)
    {
        $result.Password = Resolve-Credentials -UserName $GlobalAdminAccount.UserName
        $result.GlobalAdminAccount = Resolve-Credentials -UserName $GlobalAdminAccount.UserName
        $modulePath = $PSScriptRoot + "\MSFT_O365User.psm1"
        $content = "        O365User " + (New-GUID).ToString() + "`r`n"
        $content += "        {`r`n"
        $currentDSCBlock = Get-DSCBlock -Params $result -ModulePath $modulePath -UseGetTargetResource
        $content += Convert-DSCStringParamToVariable -DSCBlock $currentDSCBlock -ParameterName "GlobalAdminAccount"
        $content += "        }`r`n"
    }
    return $content
}

Export-ModuleMember -Function *-TargetResource
