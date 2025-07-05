
```markdown
# Modifiche Configurazioni di Ottimizzazione Internet

Questo documento elenca le modifiche applicate dagli script di ottimizzazione per le due modalità disponibili.

## ⚙️ Modifiche Comuni a Entrambe le Modalità

### 🔧 Impostazioni TCP/IP di Base
- `AutoTuningLevel`: normal
- `ScalingHeuristics`: disabled
- `CongestionProvider`: impostato dinamicamente in base all'OS
- `ReceiveSegmentCoalescing`: enabled
- `ReceiveSideScaling`: enabled

### 🧹 Pulizia e Ottimizzazione Sistema
- Creazione punto di ripristino pre-modifiche
- Pulizia cache DNS
- Ottimizzazione priorità processo: `Win32PrioritySeparation` = 26 (balanced) o 38 (gaming)

### 🔄 Modifiche al Registro di Sistema
```registry
[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters]
"MaxUserPort"=dword:0000ffff
"TcpTimedWaitDelay"=dword:0000001e

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters]
"Size"=dword:00000003

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\MemoryManagement]
"LargeSystemCache"=dword:00000001
```

## 🎮 Modalità Gaming (Low-Latency)

### 🚀 Impostazioni Performance Estreme
- **Algoritmo Congestione**: `DCTCP` (Data Center TCP)
- **Parametri TCP Aggressivi**:
  - `InitialRto`: 300ms
  - `MinRto`: 50ms
  - `InitialCongestionWindow`: 16 pacchetti
- **Disabilitazione Ottimizzazioni DANNOSE**:
  - Receive Segment Coalescing (RSC): disabled
  - Energy Efficient Ethernet: disabled

### ⚡ Ottimizzazione Hardware
```powershell
# Disabilita moderazione interrupt
Set-NetAdapterAdvancedProperty -DisplayName "Interrupt Moderation" -DisplayValue "Disabled"

# Riduce buffer di ricezione
Set-NetAdapterAdvancedProperty -DisplayName "Receive Buffers" -DisplayValue 512
```

### 🎯 Priorità Traffico Gaming
```registry
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games]
"GPU Priority"=dword:00000008
"Priority"=dword:00000001

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"NetworkThrottlingIndex"=dword:ffffffff
"SystemResponsiveness"=dword:00000000
```

### ⚙️ Impostazioni Avanzate
- **MTU**: 1472 (ottimizzato per gaming)
- **Schema Alimentazione**: "Ultimate Performance"
- **IPv6**: disabilitato su interfacce fisiche

## 🌐 Modalità Generale (High-Performance)

### 📶 Impostazioni per Stabilità e Throughput
- **Algoritmo Congestione**:
  - Windows 10 2004+: `BBR2`
  - Versioni precedenti: `CTCP`
- **Parametri TCP Bilanciati**:
  - `InitialRto`: 1000ms
  - `MinRto`: 150ms
  - `InitialCongestionWindow`: 10 pacchetti

### 📊 Ottimizzazione Multimediale
```registry
[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"NetworkThrottlingIndex"=dword:0000000a
"SystemResponsiveness"=dword:00000014
```

### ⚖️ Impostazioni Bilanciate
- **MTU**: 1500 (standard)
- **Schema Alimentazione**: "Bilanciato"
- **QoS**: 
  ```registry
  [HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Psched]
  "NonBestEffortLimit"=dword:00000040
  ```

## 🔄 Differenze Chiave tra le Modalità

| Impostazione               | Gaming Mode          | General Mode         |
|----------------------------|----------------------|----------------------|
| **Algoritmo Congestione**  | DCTCP                | BBR2/CTCP            |
| **Priorità Traffico**      | Massima (8)          | Standard             |
| **RTO Iniziale**           | 300ms                | 1000ms               |
| **Buffer Ricezione**       | 512 (ridotto)        | Default              |
| **Interrupt Moderation**   | Disabilitato         | Abilitato            |
| **Energy Efficient Eth**   | Disabilitato         | Abilitato            |
| **MTU**                    | 1472                 | 1500                 |
| **System Responsiveness**  | 0 (massimo)          | 20 (bilanciato)      |

## ⚠️ Note Importanti
1. Alcune modifiche richiedono il riavvio del sistema
2. L'MTU ottimale può variare in base alla connessione ISP
3. DCTCP richiede Windows 10 v1709 o superiore
4. BBR2 richiede Windows 10 v2004 o superiore

> **Disclaimer**: Queste ottimizzazioni sono state testate su Windows 10/11. Alcune impostazioni potrebbero non essere applicabili su versioni precedenti del sistema operativo.
```

Questo documento fornisce una panoramica completa delle modifiche applicate dalle due configurazioni. Il file può essere aggiornato man mano che vengono apportati miglioramenti agli script di ottimizzazione.