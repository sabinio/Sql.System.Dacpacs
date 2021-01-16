[CmdletBinding()]
param($WorkingPath)

$ProgressPreference = 'SilentlyContinue' 
$Global:ProgressPreference = 'SilentlyContinue' #Needed for expand archive to supress progress

function Repair-PSModulePath {

    if ($PSVersionTable.PsEdition -eq "Core") {
        $mydocsPath = [IO.Path]::Combine([environment]::GetFolderPath("MyDocuments"), "PowerShell", "Modules")
    }
    else {
        $mydocsPath = [IO.Path]::Combine([environment]::GetFolderPath("MyDocuments"), "WindowsPowerShell", "Modules")
    }

    If ("$($env:PSModulePath)".Split([IO.Path]::PathSeparator) -notcontains $mydocsPath) {
        Write-Verbose "Adding LocalModule folder to PSModulePath"
        $env:PSModulePath = "$mydocsPath$([IO.Path]::PathSeparator)$($env:PSModulePath)"
    }
}
try {
    
    if (Get-PSRepository PowershellGalleryTest  -ErrorAction SilentlyContinue) { Unregister-PSRepository PowershellGalleryTest }

	if (-not (Test-path $workingPath)){
	    Write-Verbose "Creating $workingPath"
	    New-Item $workingPath -ItemType Directory -Force | Out-Null
	}
	$PackagePath = Resolve-Path $workingPath

	Write-Verbose "Installing tools to $PackagePath "

    Repair-PSModulePath -Verbose:$VerbosePreference
$LatestVersion = (Find-Module Pipeline.Tools -Repository "PSGallery").Version
Write-Host "Getting Pipeline.Tools module $LatestVersion"


if (-not ((get-module Pipeline.Tools -ListAvailable).Version -eq $LatestVersion)) {
    Write-Host "Installing Pipeline.Tools module $LatestVersion"
    Install-Module Pipeline.Tools -Scope CurrentUser -RequiredVersion $LatestVersion -Force -Repository PSGallery -Verbose:$VerbosePreference -SkipPublisherCheck -AllowClobber -ErrorAction "Stop"
}
if (-not ((get-module Pipeline.Tools -Verbose:$VerbosePreference).Version -eq $LatestVersion)){
    Write-Host "Importing Pipeline.Tools module  $LatestVersion"
    get-module Pipeline.Tools |remove-module #remove any versions not loaded  
    Import-Module Pipeline.Tools -RequiredVersion $LatestVersion -Verbose:$VerbosePreference -ErrorAction "Stop"
}
    push-location $PackagePath

    Install-Nuget ([IO.Path]::Combine($PackagePath, "Nuget", "nuget.exe")) -Verbose:$VerbosePreference

    $packages = @()#  @{package = "Microsoft.SqlServer.DacFx"; subpath = "\lib\netstandard2.0"; version = "150.4982.1-preview";env="DacFxPath","SQLDBExtensionsRefPath","SqlServerRedistPath" } `
    $packages | ForEach-Object { Install-ToolsPackageFromNuget -PackagePath . -Verbose:$VerbosePreference @_}

  Pop-Location
  
    $modules = @{Module = "Pipeline.Config"; Version = "0.2.44"; Repository = "PSGallery" }
    $modules | ForEach-Object { Install-PsModuleFast @_ -Verbose:$VerbosePreference }

    Write-Host "Modules loaded "

}
catch {
    Throw $_
}
