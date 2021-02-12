#region Assign Permission to User

    $TenantID = "c3e2ecf2-3901-4a7c-84c1-738e9594da6d"

    Connect-AzAccount -Tenant $TenantID
    $marketplaceRole= "Marketplace Admin"
    $UsernameToAssignRoleFor = "<UPN wher role should be assign>"
    $MarketPlaceAdminRole = Get-AzRoleDefinition $marketplaceRole
    New-AzRoleAssignment -SignInName $UsernameToAssignRoleFor `
                         -RoleDefinitionName $MarketPlaceAdminRole.Name `
                         -Scope "/providers/Microsoft.Marketplace"

#endregion