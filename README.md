# PSRadarr

PowerShell wrapper around Radarr API with PowerShell 7

## Example

```PowerShell
Import-Module ./path/to/PSRadarr.psm1

Set-RadarrConfig -URL "http://radarrnon4k:port/api" -API $env:non4kapi

$non4kmovies = Get-RadarrMovie

Set-RadarrConfig -URL "http://radarr4k:port/api" -API $env:4kapi

$4kmovies = Get-RadarrMovie  

Write-host "$($4kmovies.count) 4K Movies" -ForegroundColor Green
Write-host "$($non4kmovies.count) Movies" -ForegroundColor Green
Write-Host (('Movie Sync Status: {0:p0}') -f $($4kmovies.count / $non4kmovies.count)) -ForegroundColor Green

Sync-RadarrInstance -Source $non4kmovies -Destination $4kmovies -DestinationProfileID "4KProfileReplaceme" -Monitored -SearchForMovie
```
