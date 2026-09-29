# The bar's Network panel (Omarchy Quattro's shell/plugins/panels/network): the connection,
# a speed test with download and upload dials, the DNS provider, and the Wi-Fi networks.
# The panel is a Zebar widget; it reads the two files written here and asks for changes
# through menu.ahk:
#   netpanel.json   what `network-state` finds (the connection, DNS, Wi-Fi list)
#   speedtest.json  what `speedtest-run` is measuring right now

function Get-NetshValue([string]$Text, [string]$Key) {
    if ($Text -match "(?m)^\s*$Key\s*:\s*(.+?)\s*$") { return $Matches[1] }
    ''
}

# Latency to one address in ms, or $null.
function Get-PingMs([string]$Target) {
    if (-not $Target) { return $null }
    try {
        $r = Test-Connection -TargetName $Target -Count 1 -TimeoutSeconds 1 -ErrorAction Stop
        if ($r.Status -eq 'Success') { return [int]$r.Latency }
    } catch { }
    $null
}

function Update-NetPanelState {
    $s = [ordered]@{
        type = 'none'; iface = ''; ip = ''; gateway = ''; ssid = ''; signal = 0; band = ''
        dns = 'dhcp'; dnsServers = @(); wifiCapable = $false; wifiOn = $false; wifi = @()
        routerMs = $null; internetMs = $null; at = (Get-Date).ToString('s')
    }
    $wlan = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object { $_.PhysicalMediaType -match '802\.11' -or $_.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11' } | Select-Object -First 1
    if ($wlan) { $s.wifiCapable = $true; $s.wifiOn = $wlan.Status -ne 'Disabled' }

    $cfg = Get-NetIPConfiguration -ErrorAction SilentlyContinue |
        Where-Object { $_.NetAdapter.Status -eq 'Up' -and $_.IPv4DefaultGateway -and $_.InterfaceAlias -notmatch 'Tailscale|vEthernet|VMware|VirtualBox|WSL|Loopback' } |
        Select-Object -First 1
    if ($cfg) {
        $s.iface = $cfg.InterfaceAlias
        $s.ip = "$($cfg.IPv4Address[0].IPAddress)"
        $s.gateway = "$($cfg.IPv4DefaultGateway.NextHop)"
        $isWifi = $wlan -and $wlan.InterfaceIndex -eq $cfg.InterfaceIndex
        $s.type = if ($isWifi) { 'wifi' } else { 'ethernet' }
        $s.dnsServers = @((Get-DnsClientServerAddress -InterfaceIndex $cfg.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).ServerAddresses)
        # A static server list lives in the adapter's Tcpip key; without one, DHCP hands it out.
        $key = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($cfg.NetAdapter.InterfaceGuid)"
        $static = "$((Get-ItemProperty $key -Name NameServer -ErrorAction SilentlyContinue).NameServer)".Trim()
        if ($static) {
            $s.dns = if ($static -match '^1\.1\.1\.1|^1\.0\.0\.1') { 'cloudflare' } elseif ($static -match '^8\.8\.') { 'google' } else { 'custom' }
        }
        $s.routerMs = Get-PingMs $s.gateway
        $s.internetMs = Get-PingMs '1.1.1.1'
    }

    if ($wlan -and $s.wifiOn) {
        $if = (& netsh wlan show interfaces 2>$null) -join "`n"
        if ($s.type -eq 'wifi') {
            $s.ssid = Get-NetshValue $if 'SSID'
            $sig = Get-NetshValue $if 'Signal'
            if ($sig -match '(\d+)') { $s.signal = [int]$Matches[1] }
            $s.band = Get-NetshValue $if 'Band'
        }
        $profiles = @((& netsh wlan show profiles 2>$null) | ForEach-Object { if ($_ -match ':\s*(.+?)\s*$' -and $_ -match 'All User Profile') { $Matches[1] } })
        $nets = @{}
        $cur = $null
        foreach ($line in (& netsh wlan show networks mode=bssid 2>$null)) {
            if ($line -match '^SSID \d+ : (.*)$') {
                $cur = $Matches[1].Trim()
                if ($cur -and -not $nets.ContainsKey($cur)) { $nets[$cur] = @{ ssid = $cur; signal = 0; secured = $true } }
                elseif (-not $cur) { $cur = $null }
            } elseif ($cur -and $line -match 'Authentication\s*:\s*(.+)$') {
                $nets[$cur].secured = $Matches[1].Trim() -ne 'Open'
            } elseif ($cur -and $line -match 'Signal\s*:\s*(\d+)%') {
                $nets[$cur].signal = [Math]::Max($nets[$cur].signal, [int]$Matches[1])
            }
        }
        $s.wifi = @($nets.Values | Sort-Object { -$_.signal } | ForEach-Object {
                [ordered]@{ ssid = $_.ssid; signal = $_.signal; secured = $_.secured; known = ($profiles -contains $_.ssid); connected = ($_.ssid -eq $s.ssid) }
            })
    }
    Write-JsonAtomic (Join-Path $Pack 'netpanel.json') $s
    $s
}

# A reader never sees half a file: write beside it, then move it over.
function Write-JsonAtomic([string]$Path, $Object) {
    $tmp = "$Path.tmp"
    Write-Utf8 $tmp ($Object | ConvertTo-Json -Depth 8 -Compress)
    Move-Item -Force $tmp $Path
}

# Panel actions: connect <ssid>, radio (toggle Wi-Fi on/off), open (Windows' own list).
function Invoke-WifiAction([string]$What, [string]$Ssid) {
    switch ($What) {
        'connect' {
            $out = (& netsh wlan connect name="$Ssid" 2>&1) -join ' '
            if ($LASTEXITCODE -ne 0) { throw "could not join ${Ssid}: $out" }
        }
        'radio' {
            $a = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -match '802\.11' -or $_.InterfaceDescription -match 'Wi-?Fi|Wireless|802\.11' } | Select-Object -First 1
            if (-not $a) { throw 'no Wi-Fi adapter' }
            $verb = if ($a.Status -eq 'Disabled') { 'Enable' } else { 'Disable' }
            Invoke-Elevated "$verb-NetAdapter -Name '$($a.Name -replace "'", "''")' -Confirm:`$false"
        }
        default { throw "usage: winarchy wifi <connect <ssid>|radio>" }
    }
    [void](Update-NetPanelState)
}

# --- the speed test ------------------------------------------------------------------------
# Cloudflare's speed endpoints, several streams at once (one stream rarely fills a fast
# link). speedtest.json is rewritten every quarter second for the dials:
#   {"phase":"down|up|done|error","mbps":<now>,"down":<Mbps>,"up":<Mbps>,"secs":<n>}

$SpeedSeconds = 8
$SpeedStreams = 4

function Initialize-SpeedTypes {
    if ('WinarchyCounterStream' -as [type]) { return }
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Threading;
public class WinarchyCounterStream : Stream {
    public long Limit; public long Sent;
    public override bool CanRead { get { return true; } }
    public override bool CanSeek { get { return false; } }
    public override bool CanWrite { get { return false; } }
    public override long Length { get { throw new NotSupportedException(); } }
    public override long Position { get { throw new NotSupportedException(); } set { throw new NotSupportedException(); } }
    public override int Read(byte[] b, int o, int c) {
        long left = Limit - Interlocked.Read(ref Sent);
        if (left <= 0) return 0;
        int n = (int)Math.Min((long)c, left);
        Interlocked.Add(ref Sent, n);
        return n;
    }
    public override void Flush() { }
    public override long Seek(long o, SeekOrigin s) { throw new NotSupportedException(); }
    public override void SetLength(long v) { throw new NotSupportedException(); }
    public override void Write(byte[] b, int o, int c) { throw new NotSupportedException(); }
}
'@
}

function Invoke-SpeedRun {
    $mutex = [Threading.Mutex]::new($false, 'Local\winarchy-speedtest')
    if (-not $mutex.WaitOne(0)) { return }      # one run at a time (a second click is a no-op)
    $file = Join-Path $Pack 'speedtest.json'
    $st = [ordered]@{ phase = 'down'; mbps = 0; down = 0; up = 0; secs = 0 }
    $http = [Net.Http.HttpClient]::new()
    $http.Timeout = [TimeSpan]::FromSeconds(40)
    # Cloudflare answers 403 to a client that names nothing.
    $http.DefaultRequestHeaders.UserAgent.ParseAdd('Mozilla/5.0 (Windows NT 10.0; Win64; x64) winarchy-speedtest')
    $http.DefaultRequestHeaders.Referrer = [Uri]'https://speed.cloudflare.com/'
    $cts = [Threading.CancellationTokenSource]::new()
    try {
        Initialize-SpeedTypes
        Write-JsonAtomic $file $st

        # ---- download: N streams of Cloudflare's __down, refilled when one ends
        $url = 'https://speed.cloudflare.com/__down?bytes=100000000'
        $open = {
            $resp = $http.GetAsync($url, [Net.Http.HttpCompletionOption]::ResponseHeadersRead, $cts.Token).GetAwaiter().GetResult()
            $resp.EnsureSuccessStatusCode() | Out-Null
            $resp.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
        }
        $streams = @(1..$SpeedStreams | ForEach-Object { & $open })
        $bufs = @(1..$SpeedStreams | ForEach-Object { , ([byte[]]::new(65536)) })
        $tasks = @(0..($SpeedStreams - 1) | ForEach-Object { $streams[$_].ReadAsync($bufs[$_], 0, 65536, $cts.Token) })
        $total = 0L; $window = [Collections.Generic.Queue[object]]::new()
        $sw = [Diagnostics.Stopwatch]::StartNew(); $lastPut = 0.0; $warmBytes = 0L; $warmAt = 0.0
        while ($sw.Elapsed.TotalSeconds -lt $SpeedSeconds) {
            $i = [Threading.Tasks.Task]::WaitAny([Threading.Tasks.Task[]]$tasks, 250)
            if ($i -ge 0) {
                $n = $tasks[$i].Result
                if ($n -le 0) { $streams[$i].Dispose(); $streams[$i] = & $open } else { $total += $n }
                $tasks[$i] = $streams[$i].ReadAsync($bufs[$i], 0, 65536, $cts.Token)
            }
            $t = $sw.Elapsed.TotalSeconds
            if ($t -lt 1) { $warmBytes = $total; $warmAt = $t }     # the first second is ramp-up
            if ($t - $lastPut -ge 0.25) {
                $window.Enqueue(@($t, $total)); while ($window.Peek()[0] -lt $t - 1) { [void]$window.Dequeue() }
                $old = $window.Peek()
                $st.mbps = [Math]::Round((($total - $old[1]) * 8 / 1e6) / [Math]::Max(0.05, $t - $old[0]), 1)
                if ($t -gt 1) { $st.down = [Math]::Round((($total - $warmBytes) * 8 / 1e6) / ($t - $warmAt), 1) } else { $st.down = $st.mbps }
                $st.secs = [Math]::Round($t, 1)
                Write-JsonAtomic $file $st
                $lastPut = $t
            }
        }
        $cts.Cancel(); foreach ($x in $streams) { $x.Dispose() }
        $cts.Dispose(); $cts = [Threading.CancellationTokenSource]::new()

        # ---- upload: N POSTs of generated bytes to __up, counted as the client reads them
        $st.phase = 'up'; $st.mbps = 0; $st.secs = 0
        Write-JsonAtomic $file $st
        $bodies = [System.Collections.Generic.List[object]]::new()
        $posts = [System.Collections.Generic.List[object]]::new()
        $startPost = {
            $body = [WinarchyCounterStream]::new(); $body.Limit = 40MB
            $content = [Net.Http.StreamContent]::new($body)
            $content.Headers.ContentLength = $body.Limit
            $content.Headers.ContentType = [Net.Http.Headers.MediaTypeHeaderValue]::new('application/octet-stream')
            $bodies.Add($body); $posts.Add($http.PostAsync('https://speed.cloudflare.com/__up', $content, $cts.Token))
        }
        1..$SpeedStreams | ForEach-Object { & $startPost }
        $sw.Restart(); $lastPut = 0.0; $window.Clear(); $warmBytes = 0L; $warmAt = 0.0; $finished = 0
        $sent = { $sum = 0L; foreach ($b in $bodies) { $sum += $b.Sent }; $sum }
        while ($sw.Elapsed.TotalSeconds -lt $SpeedSeconds) {
            Start-Sleep -Milliseconds 100
            # Refill: a finished POST is replaced so the link stays busy for the whole window.
            for ($k = $finished; $k -lt $posts.Count; $k++) { if ($posts[$k].IsCompleted) { $finished++; & $startPost } }
            $t = $sw.Elapsed.TotalSeconds; $total = & $sent
            if ($t -lt 1) { $warmBytes = $total; $warmAt = $t }
            if ($t - $lastPut -ge 0.25) {
                $window.Enqueue(@($t, $total)); while ($window.Peek()[0] -lt $t - 1) { [void]$window.Dequeue() }
                $old = $window.Peek()
                $st.mbps = [Math]::Round((($total - $old[1]) * 8 / 1e6) / [Math]::Max(0.05, $t - $old[0]), 1)
                if ($t -gt 1) { $st.up = [Math]::Round((($total - $warmBytes) * 8 / 1e6) / ($t - $warmAt), 1) } else { $st.up = $st.mbps }
                $st.secs = [Math]::Round($t, 1)
                Write-JsonAtomic $file $st
                $lastPut = $t
            }
        }
        $cts.Cancel()
        $st.phase = 'done'; $st.mbps = 0
        Write-JsonAtomic $file $st
    } catch {
        $st.phase = 'error'; $st.error = $_.Exception.Message
        Write-JsonAtomic $file $st
        throw
    } finally {
        $http.Dispose()
        $mutex.ReleaseMutex(); $mutex.Dispose()
    }
}
