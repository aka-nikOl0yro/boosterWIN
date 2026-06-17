# 1. Chiude i processi WebView2 attivi per sbloccare i file di cache
# da NON avviare troppo spesso
Get-Process msedgewebview2 -ErrorAction SilentlyContinue | Stop-Process -Force

# 2. Definisce il percorso dei dati locali dell'utente
$localAppData = $env:LOCALAPPDATA

# 3. Cerca le cartelle EBWebView e pulisce le sottocartelle di cache
Write-Host "Ricerca e pulizia cache WebView2 in corso..." -ForegroundColor Cyan

Get-ChildItem -Path $localAppData -Recurse -Filter "EBWebView" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $cachePaths = @(
        "$($_.FullName)\Default\Cache", 
        "$($_.FullName)\Default\Code Cache", 
        "$($_.FullName)\Default\GPUCache"
    )
    
    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Pulita: $path" -ForegroundColor Green
        }
    }
}
Write-Host "Pulizia completata!" -ForegroundColor Cyan