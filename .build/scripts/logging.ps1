Function Test-LogAreaEnabled{
    param($logging, $area)

    $result = $false

    if($VerbosePreference -eq "Continue"){
        $result = $true
    }

    $logging.split(',') | ForEach-Object {
        if($_ -eq $area -or $_ -eq "*"){
            $result = $true
        }
    }

    $result

}