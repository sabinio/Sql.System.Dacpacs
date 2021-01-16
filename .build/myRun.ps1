
#This allows for debugging of the build and deploy
push-location $PSScriptRoot

.\Pipeline-Tasks.ps1 -Install -TestModules


.\Pipeline-Tasks.ps1 -Install -Build -Package
pop-location