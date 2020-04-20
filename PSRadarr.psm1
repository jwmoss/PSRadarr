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
            URI = $script:configuration.URL
            Method = $Method
            Headers = @{
                'X-Api-Key' = $script:configuration.API
            }
        }
    }
    
    process {
        if ($PSBoundParameters.ContainsKey('Command')) {
            $InvokeRestMethodHash.Update("URI", $script:configuration.URL + $Endpoint + $Command)
        }
        
        Invoke-RestMethod @InvokeRestMethodHash 
    }
    
    end {
        
    }
}