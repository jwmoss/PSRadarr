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
        $Command,

        [PSObject]
        $Body
    )
    
    begin {
        $InvokeRestMethodHash = @{
            URI     = $script:configuration.URL + $Endpoint
            Method  = $Method
            Headers = @{
                'X-Api-Key' = $script:configuration.API
            }
        }
    }
    
    process {
        if ($PSBoundParameters.ContainsKey('Command')) {
            $InvokeRestMethodHash["URI"] = $script:configuration.URL + $Endpoint + $Command
        }

        if ($PSBoundParameters.ContainsKey('Command') -and ($PSBoundParameters.ContainsKey('Body'))) {
            $InvokeRestMethodHash["URI"] = $script:configuration.URL + $Endpoint + $Command
            $InvokeRestMethodHash["Body"] = $Body
        }

        if ($PSBoundParameters.ContainsKey('Body')) {
            $InvokeRestMethodHash["Body"] = $Body
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
            "Name",
            "TMDB",
            "IMDB"
        )]
        [string]
        $SearchMethod,

        [string]
        $SearchValue
    )

    switch ($SearchMethod) {
        "Name" {  

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
        Default { }
    }
}

function Get-RadarrProfile {
    [CmdletBinding()]
    param (
        
    )
    
    $script:configuration.Profiles

}

function Add-RadarrMovie {
    [CmdletBinding()]
    param (
        [PSObject]
        $SearchResults,

        [string]
        $ProfileID,

        [switch]
        $Monitored,

        [switch]
        $SearchForMovie
    )

    $CoverImage = $SearchResults.covertype | Where-Object { $_ -eq "Poster" }

    ## Add a movie from non4K to 4K
    $params = @{
        title            = $SearchResults.title
        qualityProfileId = $ProfileID
        titleSlug        = $SearchResults.titleslug  
        images           = @(
            @{
                covertype = $CoverImage.covertype
                url       = $CoverImage.url
            }
        )
        tmdbId           = $SearchResults.tmdbid
        profileId        = $ProfileID
        year             = $SearchResults.year
        rootfolderpath   = Get-RadarrRootFolder
        monitored        = $true
        addoptions       = @{
            searchForMovie = $true
        }
    } | ConvertTo-Json

    Invoke-RadarrRestMethod -Method "POST" -Endpoint "/movie" -Body $Params

}

function Get-RadarrRootFolder {
    [CmdletBinding()]
    param (
        
    )

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

function Sync-RadarrInstance {
    [CmdletBinding()]
    param (
        [PSObject]
        $Source,

        [PSObject]
        $Destination,

        [string]
        $DestinationProfileID,

        [int]
        $Max,

        [switch]
        $Monitored,

        [switch]
        $SearchForMovie
    )

    ## Loop through each movie in the source library
    
    if (-not $PSBoundParameters.ContainsKey('Max')) {
        foreach ($movie in $Source) {
            #Write-Verbose "Processing $($movie.Title)"
            ## If the movie in source library is not in the destination library, do stuff
            if ($movie.tmdbid -notin $Destination.tmdbid) {
                Write-Verbose "Adding $($movie.Title) to destination library"
                ## If you want to monitor and search for the movie
                if ($PSBoundParameters.ContainsKey('Monitored') -and ($PSBoundParameters.ContainsKey('SearchForMovie'))) {
                    Write-Verbose "Adding $($movie.Title) to Destination Library, searching and monitoring it."
                    Add-RadarrMovie -SearchResults $movie -ProfileID $DestinationProfileID -Monitored -SearchForMovie
                } 
                
                ## If you want to monitor the movie
                if ($PSBoundParameters.ContainsKey('Monitored')) {
                    Write-Verbose "Adding $($movie.Title) to Destination Library, and monitoring it."
                    Add-RadarrMovie -SearchResults $movie -ProfileID $DestinationProfileID -Monitored
                }       
                
                ## If you want to search for the movie
                if ($PSBoundParameters.ContainsKey('SearchForMovie')) {
                    Write-Verbose "Adding $($movie.Title) to Destination Library, and searching for the movie."
                    Add-RadarrMovie -SearchResults $movie -ProfileID $DestinationProfileID -SearchForMovie
                }   
            }   
        }  
    }

    if ($PSBoundParameters.ContainsKey('Max')) {
        Write-Verbose -Message "Processing the first $Max"
        foreach ($movie in $Source[0..$Max]) {
            Write-Verbose "Processing $($movie.Title)"
            ## If the movie in source library is not in the destination library, do stuff
            if ($movie.tmdbid -notin $Destination.tmdbid) {
                Write-Verbose "Adding $($movie.Title) to destination library"
                ## If you want to monitor and search for the movie
                if ($PSBoundParameters.ContainsKey('Monitored') -and ($PSBoundParameters.ContainsKey('SearchForMovie'))) {
                    Write-Verbose "Adding $($movie.Title) to Destination Library, searching and monitoring it."
                    Add-RadarrMovie -SearchResults $movie -ProfileID $DestinationProfileID -Monitored -SearchForMovie
                } 
                
                ## If you want to monitor the movie
                if ($PSBoundParameters.ContainsKey('Monitored')) {
                    Write-Verbose "Adding $($movie.Title) to Destination Library, and monitoring it."
                    Add-RadarrMovie -SearchResults $movie -ProfileID $DestinationProfileID -Monitored
                }       
                
                ## If you want to search for the movie
                if ($PSBoundParameters.ContainsKey('SearchForMovie')) {
                    Write-Verbose "Adding $($movie.Title) to Destination Library, and searching for the movie."
                    Add-RadarrMovie -SearchResults $movie -ProfileID $DestinationProfileID -SearchForMovie
                }   
            }   
        }
    }
}