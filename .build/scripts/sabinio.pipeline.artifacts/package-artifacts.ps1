
Function Clear-Artifacts{
    [CmdletBinding()]
     param ($destination)
 $destinationWildcard = (Join-Path $destination "*")

 if(Test-Path $destination){

     Write-Verbose "Copying artifacts, clearing existing path"
     Get-childItem $destinationWildcard -Exclude "_log" -Recurse | Remove-Item -Force -Recurse | Out-Null
     
 }
}
Function Copy-Artifacts{
 [CmdletBinding()]
 param(
     $source,
     $destination
 )
     
    Write-Host "Copying artifacts from: '$source' to '$destination'"
    
    $sourceWildcard = $source #(Join-Path $source "*")

    if (-not (Test-path $destination)) {$NewFolder = New-Item $destination -ItemType Directory -Force }

    Write-Verbose "Found items:"
    Get-ChildItem $sourceWildcard -recurse | %{Write-Verbose $_.FullName}
    Copy-Item -Path $sourceWildcard -Destination $destination -recurse -Force #| Out-Nul

    Write-Host "Copied Artifacts:"
    Get-ChildItem $destination -recurse | %{
        Write-Verbose $_.FullName
        if ($_.Directory ){
           $_.IsReadOnly=$true
        }
    }
    
}
function Publish-Artifacts{
[CmdletBinding(
    DefaultParameterSetName = 'multiple-paths'
)]
Param(
    [Parameter(            
        Mandatory = $true
    )]
    [string]$ArtifactsPath,

    [Parameter(
        ParameterSetName = 'multiple-paths',
        Mandatory = $true
    )]
    [Parameter()]
    [string[]]$PackagePaths,

    [Parameter(
        ParameterSetName = 'nameable-path',
        Mandatory = $true
    )]
    
    [string]
    $path,

    [Parameter(
        ParameterSetName = 'nameable-path',
        Mandatory = $true
    )]
    [Parameter(
        ParameterSetName = 'multiple-paths',
        Mandatory = $true
    )]
    [string]
    $name
)


switch($PSCmdlet.ParameterSetName){
    "multiple-paths"{
        if (-not $name ){
            $name = Split-Path -Path $_ -Leaf
        }
        Clear-Artifacts -destination (Join-Path $ArtifactsPath $name)

        $PackagePaths | ForEach-Object {            
            Copy-Artifacts -source $_  -destination (Join-Path $ArtifactsPath $name)
        }
        break
    }

    "nameable-path"{
        Clear-Artifacts -destination (Join-Path $ArtifactsPath $name)

        Copy-Artifacts -source $path -destination (Join-Path $ArtifactsPath $name)
        break;
    }
}
}