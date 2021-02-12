#region Assign Marketplace Permission to User

    $TenantID = "YourTenantID"

    Connect-AzAccount -UseDeviceAuthentication -Tenant $TenantID
    $marketplaceRole = "Marketplace Admin"
    $UsernameToAssignRoleFor = "User@domain.com"
    $MarketPlaceAdminRole = Get-AzRoleDefinition $marketplaceRole -Scope "/providers/Microsoft.Marketplace"
    New-AzRoleAssignment -SignInName $UsernameToAssignRoleFor -RoleDefinitionName $MarketPlaceAdminRole.Name -Scope "/providers/Microsoft.Marketplace"

#endregion