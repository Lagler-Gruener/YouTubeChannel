Configuration deployiis
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node WebServerConfig
    {
        WindowsFeature WebServer
        {
            Ensure  = 'Present'
            Name    = 'Web-Server'
        }

        WindowsFeature InstallDotNet
        {
            Ensure  = 'Present'
            Name    = 'Web-Asp-Net45'
            DependsOn = '[WindowsFeature]WebServer'
        }

        Script DisableFirewall 
        {
            GetScript = {
                @{
                    GetScript = $GetScript
                    SetScript = $SetScript
                    TestScript = $TestScript
                    Result = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                }
            }

            SetScript = {
                Set-NetFirewallProfile -All -Enabled False -Verbose
            }

            TestScript = {
                $Status = -not('True' -in (Get-NetFirewallProfile -All).Enabled)
                $Status -eq $True
            }
        }
    }
}