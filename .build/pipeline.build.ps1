[CmdletBinding()]
param($artifactsPath, $Settings)

    try{
        push-location $artifactsPath
        if (-not $noLogo) {
            Write-BannerBuild
        }

        $global:ProgressPreference="SilentlyContinue"

        Install-ToolFromUrl "https://go.microsoft.com/fwlink/?linkid=2143820" -ToolPath "DatabaseProject"
        
    }
    catch {
        throw
    }
    finally 
    {
        Pop-Location
    }