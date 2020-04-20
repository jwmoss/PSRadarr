function Set-RadarrConfig {
    [CmdletBinding()]
    param (
        [string]
        $URL,

        [string]
        $API
    )

    $script:configuration = @{
        URL = $URL
        API = $API
    }    

    $script:configuration["RootFolder"] = (Invoke-RadarrRestMethod -Method "GET" -Endpoint "/rootfolder").Path      
    $script:configuration["Profiles"] = Invoke-RadarrRestMethod -Method "GET" -Endpoint "/profile"      

}

function Invoke-RadarrRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet(
            "GET",
            "POST"
            )]
        [string]
        $Method,

        [string]
        $Endpoint,

        [string]
        $Command
    )
    
    begin {
        $InvokeRestMethodHash = @{
            URI = $script:configuration.URL + $Endpoint
            Method = $Method
            Headers = @{
                'X-Api-Key' = $script:configuration.API
            }
        }
    }
    
    process {
        if ($PSBoundParameters.ContainsKey('Command')) {
            $InvokeRestMethodHash["URI"] = $script:configuration.URL + $Endpoint + $Command
        }

        Invoke-RestMethod @InvokeRestMethodHash 
    }
    
    end {
        
    }
}

function Get-RadarrMovie {
    [CmdletBinding()]
    param (
        [string]
        $ID
    )

    if ($PSBoundParameters.ContainsKey('ID')) {
        Invoke-RadarrRestMethod -Method "GET" -Endpoint "/movie/$ID"
    }
    else {
        Invoke-RadarrRestMethod -Method "GET" -Endpoint "/movie"
    }

}


function Find-RadarrMovie {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet(
            "Lookup",
            "TMDB",
            "IMDB"
            )]
        [string]
        $SearchMethod,

        [string]
        $SearchValue
    )

    switch ($SearchMethod) {
        "Lookup" {  

            ## Add %20 to spaces in the name
            $value = [uri]::EscapeDataString($SearchValue)

            ## Search for movie using the name
            Invoke-RadarrRestMethod -Method 'GET' -Endpoint '/movie/lookup' -Command "?term=$value"

        }
        "TMDB" {  

            ## Search for movie using TMDB ID
            Invoke-RadarrRestMethod -Method 'GET' -Endpoint '/movie/lookup/tmdb' -Command "?tmdbId=$SearchValue"

        }
        "IMDB" {  

            ## Search for movie using TMDB ID
            Invoke-RadarrRestMethod -Method 'GET' -Endpoint '/movie/lookup/imdb' -Command "?imdbId=$SearchValue"

        }
        Default {}
    }
}

function Get-RadarrRootFolder {
    [CmdletBinding()]
    param (
        
    )

    $script:configuration["RootFolder"] = (Invoke-RadarrRestMethod -Method "GET" -Endpoint "/rootfolder").Path      

    $script:configuration.RootFolder
}

function Get-RadarrSystemStatus {
    [CmdletBinding()]
    param (
        
    )
    
    Invoke-RadarrRestMethod -Method "GET" -Endpoint "/system/status"
}

function Get-RadarrRecommendations {
    [CmdletBinding()]
    param (
        
    )
    
    Invoke-RadarrRestMethod -Method "GET" -Endpoint "/movies/discover/recommendations"
}