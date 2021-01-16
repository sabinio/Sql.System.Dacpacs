[CmdletBinding()]
param (
    [Switch] $Install,
    [Switch] $Build,
    [switch] $Package,
    [switch] $noLogo,
    [string] $environment = $env:environment,
    [string] $rootPath = $env:rootpath,
    [string] $artifactsPath = $env:artifactspath,
    [string] $verboseLogging = "", #"Install,Build,Package,DeployInfra,Deploy,Config,Module,*",
    [parameter(ValueFromRemainingArguments = $true)]
    $parameterOverrides
)
$global:ErrorActionPreference = "Stop"
$ErrorActionPreference = "Stop"

push-location $PSScriptroot
Set-StrictMode -Version 1.0
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    if ([string]::IsNullOrEmpty($environment)) {
        $environment = 'localdev'
    }
    if ([string]::IsNullOrEmpty($rootPath)) { $rootPath = join-path $PSScriptroot ".." | Resolve-Path };
    if ([string]::IsNullOrEmpty($artifactsPath)) { $artifactsPath = join-path $rootPath "artifacts" };
    [string] $outPath = join-path $rootPath "out";

    . $PSScriptroot/scripts/logging.ps1

    Write-Host "Processing with "
    Write-Host "   Root path       = $rootpath"
    Write-Host "   Artifacts path  = $artifactsPath"
    Write-Host "   Out path        = $outPath"
    Write-Host "   PSScriptroot    = $PSScriptroot"

    if ($Install) { 
		$InstallVerbose = (Test-LogAreaEnabled -logging $verboseLogging -area "install")
        Write-Host "##[command]./pipeline.install-tools.ps1 -workingPath $(join-path $artifactsPath "tools") -verbose:$InstallVerbose"
		Write-Host "##[group]Install"
		./pipeline.install-tools.ps1  -workingPath (join-path $artifactsPath "tools") -verbose:$InstallVerbose
		Write-Host "##[endgroup]"
    }
	
	Write-Host "##[group]Settings"
    $settings = (Get-ProjectSettings -environment $environment -ConfigRootPath (join-path $PSScriptroot "config") -verbose:(Test-LogAreaEnabled -logging $verboseLogging -area "config") -overrides $parameterOverrides) 
    write-host ("##vso[build.updatebuildnumber] {0}.{1}" -f $settings.ProjectName, $settings.FullVersion)
	write-host ("##vso[task.setvariable variable=ProjectName;]{0}" -f $settings.ProjectName)

	Write-Host ($settings | Convertto-json)
	#Write-Host (Get-ChildItem env: | out-string)
	Write-Host "##[endgroup]"

    if ($Build) {     
		Write-Host "##[group]Build"
		./pipeline.build.ps1  -settings $settings -artifactsPath $artifactsPath -verbose:(Test-LogAreaEnabled -logging $verboseLogging -area "build")
		Write-Host "##[endgroup]"
    }

    if ($Package) {
        ./pipeline.package.ps1  -settings $settings -ArtifactsPath $artifactsPath -verbose:(Test-LogAreaEnabled -logging $verboseLogging -area "package")
    }
    else {
        Write-Verbose "-package switch not set - skipping..."
    }

    pop-location
}

catch {
    
    $errorRecord = $_
    # This provides the vs code friendly links to the position the error occurs 
    Write-Host -ForegroundColor Red "$ErrorRecord $($ErrorRecord.InvocationInfo.PositionMessage)"

    if ($ErrorRecord.Exception) {
        Write-Host -ForegroundColor Red $ErrorRecord.Exception
    }

    if ((Get-Member -InputObject $ErrorRecord -Name ScriptStackTrace) -ne $null) {
        #PS 3.0 has a stack trace on the ErrorRecord; if we have it, use it & skip the manual stack trace below
        Write-Host -ForegroundColor Red $ErrorRecord.ScriptStackTrace
    }
    else {

        Get-PSCallStack | Select -Skip 1 | % {
            Write-Host -ForegroundColor Yellow -NoNewLine "! "
            Write-Host -ForegroundColor Red $_.Command $_.Location $(if ($_.Arguments.Length -le 80) { $_.Arguments })
        }
    }  

    Throw "An error has occurred"
} 
finally
{
    pop-location
}
