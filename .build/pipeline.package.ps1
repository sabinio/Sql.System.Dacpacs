[CmdletBinding()]
param($settings, $ArtifactsPath)

    if (-not $noLogo) { Write-BannerPackage }

    . "$PSScriptroot/scripts/sabinio.pipeline.artifacts/package-artifacts.ps1"        

    push-location $rootPath

    try{
        write-Verbose "Writing artifacts to $ArtifactsPath"

        $DatabaseProjectVSIX= ([System.IO.Path]::Combine($ArtifactsPath,"DatabaseProject","extension","BuildDirectory","SystemDacpacs","*"))
        Publish-Artifacts -artifactsPath  $artifactsPath -PackagePaths $DatabaseProjectVSIX,"*.nuspec"         -name "SystemDacPacs" -verbose:$VerbosePreference

        &$env:nugetPath pack (join-path $artifactsPath "SystemDacPacs")  -outputDirectory  (join-path $artifactsPath "sabinio.Sql.System.Dacpacs") -version $settings.FullVersion
    }
    catch{
        Throw
    }
    finally{
        Pop-Location
    }