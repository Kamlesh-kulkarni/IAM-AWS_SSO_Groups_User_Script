# Connect to Azure AD
Connect-AzureAD

# Enterprise App Name
$appName = "AWS XL - SSO"

# Get the Service Principal for the app
$servicePrincipal = Get-AzureADServicePrincipal -Filter "displayName eq '$appName'"

if ($null -eq $servicePrincipal) {
    Write-Error "Enterprise Application '$appName' not found."
    exit
}

# Get all role assignments
$assignments = Get-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId

# Result array
$result = @()

foreach ($assignment in $assignments) {
    # Get the assigned principal (User or Group)
    $principal = Get-AzureADObjectByObjectId -ObjectId $assignment.PrincipalId

    # Get the role name
    $appRole = $servicePrincipal.AppRoles | Where-Object { $_.Id -eq $assignment.AppRoleId }
    $roleName = if ($appRole) { $appRole.DisplayName } else { "No Role Assigned" }

    # Prepare user list
    $userDetails = @()

    if ($principal.ObjectType -eq "Group") {
        # Get group members
        $members = Get-AzureADGroupMember -ObjectId $principal.ObjectId -All $true

        foreach ($member in $members) {
            if ($member.ObjectType -eq "User") {
                $userDetails += "$($member.DisplayName) <$($member.Mail)>"
            }
        }
    }
    elseif ($principal.ObjectType -eq "User") {
        $userDetails += "$($principal.DisplayName) <$($principal.Mail)>"
    }

    # Join user info
    $membersString = $userDetails -join ", "

    # Add to result
    $obj = [PSCustomObject]@{
        DisplayName = $principal.DisplayName
        ObjectType  = $principal.ObjectType
        RoleName    = $roleName
        Members     = $membersString
    }

    $result += $obj
}

# Export to Excel (no output to screen)
$excelPath = ".\AWS XL - SSO Users.xlsx"
$result | Export-Excel -Path $excelPath -AutoSize -BoldTopRow -Title "AWS XL - SSO Users" -WorksheetName "AWS_XL_SSO_Users"
