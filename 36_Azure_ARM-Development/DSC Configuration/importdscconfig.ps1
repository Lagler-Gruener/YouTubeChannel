Login-AzAccount

Import-AzAutomationDscConfiguration -SourcePath 'C:\Git\YouTubeChannel\36_ARM Templates (Powershell UserGroup)\DSC Configuration\deployiis.ps1' -ResourceGroupName 'rg-ARMTemplate-Demo' -AutomationAccountName 'armtemplatedemo' -Published -Force