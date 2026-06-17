#Requires -RunAsAdministrator
param([switch]$Silent, [string[]]$ApplyOnly = @())

function Apply-InternetTweaks($selectedIds) {
    $ids = foreach ($i in $selectedIds) { $i.ToUpper().Trim() }

    # AUTOTUNE: AutoTuningLevel + ScalingHeuristics (lines 4-6 original)
    if ($ids -contains "AUTOTUNE") {
        echo "Set TCP settings"
        Set-NetTCPSetting -SettingName internet -AutoTuningLevel normal
        Set-NetTCPSetting -SettingName internet -ScalingHeuristics disabled
        netsh int tcp set supplemental internet congestionprovider=ctcp
    }

    # SCALING: MaxConnectionsPer{1_0}Server + ServiceProvider priorities (lines 13-20 original)
    if ($ids -contains "SCALING") {
        echo "Set registry values"
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER" /v explorer.exe /t REG_DWORD /d 20 /f
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER" /v iexplore.exe /t REG_DWORD /d 20 /f
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER" /v explorer.exe /t REG_DWORD /d 20 /f
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER" /v iexplore.exe /t REG_DWORD /d 20 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalPriority /t REG_DWORD /d 1 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v HostsPriority /t REG_DWORD /d 1 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v DnsPriority /t REG_DWORD /d 1 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v NetbtPriority /t REG_DWORD /d 1 /f
    }

    # THROTTLING: NetworkThrottlingIndex (line 23 original)
    if ($ids -contains "THROTTLING") {
        echo "Set registry values"
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f
    }

    # ALL (default): everything else that's not AUTOTUNE/SCALING/THROTTLING
    if ($ids -contains "ALL" -or $null -eq $selectedIds) {
        # Remaining registry tweaks (lines 21-22, 24-29 original)
        echo "Set registry values"
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 64 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d 1 /f
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v Size /t REG_DWORD /d 3 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\MemoryManagement" /v LargeSystemCache /t REG_DWORD /d 1 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65535 /f
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSMQ\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f

        # Additional TCP settings (lines 32-38 original)
        echo "Set additional TCP settings"
        Set-NetTCPSetting -SettingName internet -EcnCapability disabled
        Set-NetOffloadGlobalSetting -Chimney disabled
        Set-NetTCPSetting -SettingName internet -Timestamps disabled
        Set-NetTCPSetting -SettingName internet -MaxSynRetransmissions 2
        Set-NetTCPSetting -SettingName internet -NonSackRttResiliency disabled
        Set-NetTCPSetting -SettingName internet -InitialRto 2000
        Set-NetTCPSetting -SettingName internet -MinRto 300

        # MTU values (lines 41-43 original)
        echo "Set MTU values"
        netsh interface ipv4 set subinterface "Wi-Fi" mtu=1500 store=persistent
        netsh interface ipv6 set subinterface "Wi-Fi" mtu=1500 store=persistent
        netsh interface ipv4 set subinterface "Ethernet" mtu=1500 store=persistent
    }

    # NETRESET: network stack reset (from internetboosterPRO.bat)
    if ($ids -contains "NETRESET") {
        echo "Resetting TCP/IP stack..."
        netsh winsock reset
        netsh int ip reset
        ipconfig /release
        ipconfig /renew
        ipconfig /flushdns
        ipconfig /registerdns
    }
}

Import-Module NetTCPIP

if ($Silent -and $ApplyOnly.Count -gt 0) {
    Apply-InternetTweaks($ApplyOnly)
} elseif (-not $Silent) {
    Apply-InternetTweaks @()   # default: run all (null-checked in function)
}
# Silent + no selections => return silently
