# Definizione della funzione di sistema per svuotare la RAM
$code = @"
using System;
using System.Runtime.InteropServices;
public class MemoryCleaner {
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr hwProc);
}
"@
Add-Type -TypeDefinition $code -Language CSharp

# Lista dei processi da pulire (Aggiungi qui altri nomi se serve)
# Nota: "brave" è il nome del processo, anche se vedi "Brave Browser"
$targets = @("Vesktop", "Discord", "Spotify", "WhatsApp", "brave")

Write-Host "Inizio pulizia RAM per: $targets"

foreach ($target in $targets) {
    # Cerca tutti i processi con quel nome (es. tutte le schede di Brave)
    Get-Process -Name $target -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            # Tenta di svuotare la memoria
            $result = [MemoryCleaner]::EmptyWorkingSet($_.Handle)
        } catch {
            # Ignora errori (es. accesso negato o processo chiuso)
        }
    }
}