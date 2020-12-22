Param (

    [Parameter(
        HelpMessage = "Internal ACR use by the demo team")]
    [string]$DemoTeamRegistry
    ,
    [Parameter(
        HelpMessage = "Internal ACR use by the demo team")]
    [string]$SitecoreRegistry = "scr.sitecore.com/"
    ,
    [Parameter(
        HelpMessage = "Demo version used in image tagging.")]
    [string]$IsolationMode = "hyperv"
    ,
    [Parameter(
        HelpMessage = "Base Module Version - used to refer to a specific build of the base images.")]
    [string]$WindowsVersion = "ltsc2019"
    ,
    [Parameter(
        HelpMessage = "Internal ACR use by the demo team")]
    [string]$SitecoreVersion = "10.0.1"
)

$ErrorActionPreference = "Stop";

Write-Host "Preparing your Sitecore Containers environment!" -ForegroundColor Green

################################################
# Retrieve and import SitecoreDockerTools module
################################################

# Check for Sitecore Gallery
Import-Module PowerShellGet
$SitecoreGallery = Get-PSRepository | Where-Object { $_.SourceLocation -eq "https://sitecore.myget.org/F/sc-powershell/api/v2" }
if (-not $SitecoreGallery) {
  Write-Host "Adding Sitecore PowerShell Gallery..." -ForegroundColor Green
  Register-PSRepository -Name SitecoreGallery -SourceLocation https://sitecore.myget.org/F/sc-powershell/api/v2 -InstallationPolicy Trusted
  $SitecoreGallery = Get-PSRepository -Name SitecoreGallery
}

#Install and Import SitecoreDockerTools
$dockerToolsVersion = "10.0.5"
Remove-Module SitecoreDockerTools -ErrorAction SilentlyContinue
if (-not (Get-InstalledModule -Name SitecoreDockerTools -RequiredVersion $dockerToolsVersion -ErrorAction SilentlyContinue)) {
  Write-Host "Installing SitecoreDockerTools..." -ForegroundColor Green
  Install-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion -Scope CurrentUser -Repository $SitecoreGallery.Name
}
Write-Host "Importing SitecoreDockerTools..." -ForegroundColor Green
Import-Module SitecoreDockerTools -RequiredVersion $dockerToolsVersion

Write-Host "Populating required demo team .env file values..." -ForegroundColor Green
if ([string]::IsNullOrEmpty($DemoTeamRegistry)) {
    # if it wasn't passed as a parameter, let's try to find it in environment
    $DemoTeamRegistry = $env:DEMO_TEAM_DOCKER_REGISTRY
    if ($null -eq $DemoTeamRegistry) {
        # Environment variable not found. Try to set it using demo team function.
        Set-DemoEnvironmentVariables
        refreshenv
    }
    # Retry
    $DemoTeamRegistry = $env:DEMO_TEAM_DOCKER_REGISTRY
    if ($null -eq $DemoTeamRegistry) {
        Write-Host "The DEMO_TEAM_DOCKER_REGISTRY environment variable is not set. Please:" -ForegroundColor Red
        Write-Host "  1. Ensure you are using the team's PowerShell profile." -ForegroundColor Red
        Write-Host "  2. From a new PowerShell window, re-run this command." -ForegroundColor Red
        throw
    }
}
$NanoserverVersion = $(if ($WindowsVersion -eq "ltsc2019") {"1809"} else {$WindowsVersion})
Set-DockerComposeEnvFileVariable "REGISTRY" -Value $DemoTeamRegistry
Set-DockerComposeEnvFileVariable "SITECORE_DOCKER_REGISTRY" -Value $SitecoreRegistry
Set-DockerComposeEnvFileVariable "WINDOWSSERVERCORE_VERSION" -Value $WindowsVersion
Set-DockerComposeEnvFileVariable "NANOSERVER_VERSION" -Value $NanoserverVersion
Set-DockerComposeEnvFileVariable "SITECORE_VERSION" -Value $SitecoreVersion
Set-DockerComposeEnvFileVariable "TOOLS_VERSION" -Value $SitecoreVersion
Set-DockerComposeEnvFileVariable "ISOLATION" -Value $IsolationMode

Write-Host "Done!" -ForegroundColor Green
