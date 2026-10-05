# Omarchy's web apps: a site in its own Chromium --app window, with a launcher entry and,
# for some, a key. Here the launcher entry is a Start menu shortcut (so the Apps route and
# Flow Launcher find it), and the keys live in ahk/launchers.ahk, which starts the browser
# itself: no PowerShell in between, so a key opens the window at once.
#
# default/webapps.json holds the presets (Omarchy's URLs). Install > Web Apps adds one,
# Remove takes it out again, and uninstall treats them like the other apps you installed.

function Get-WebAppPresets {
    @((Read-Json (Join-Path $Code 'default\webapps.json') -AsHashtable).apps)
}

function Get-WebAppDir { Join-Path ([Environment]::GetFolderPath('Programs')) 'Winarchy Web Apps' }
function Get-WebAppIconDir { Join-Path $Data 'webapps' }

# Only Chromium browsers have --app windows. Firefox dropped its equivalent, and Edge can
# be removed in the EEA, so it is never assumed: the default browser when it is Chromium,
# else the first Chromium one found. $null: none at all (the site opens as a tab instead).
$WebAppBrowsers = 'chrome', 'msedge', 'brave', 'vivaldi', 'chromium', 'thorium'
function Find-WebAppBrowser($p) {
    $default = if ($p.browser) { $p.browser } else { (Find-Browser).exe }
    if ($default -and (Test-Path -LiteralPath $default) -and
        $WebAppBrowsers -contains [IO.Path]::GetFileNameWithoutExtension($default).ToLower()) { return $default }
    Find-First @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\Application\brave.exe",
        "$env:LOCALAPPDATA\Vivaldi\Application\vivaldi.exe",
        "$env:ProgramFiles\Vivaldi\Application\vivaldi.exe")
}

# The shortcut's own AppUserModelID. Without one, Start lists a shortcut to a browser under
# the browser's ID, so the menu's Apps route opened the plain browser instead of the site.
function Initialize-ShortcutNative {
    Add-NativeType Shortcut @'
[ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IPropertyStore {
    [PreserveSig] int GetCount(out uint count);
    [PreserveSig] int GetAt(uint index, out PropertyKey key);
    [PreserveSig] int GetValue(ref PropertyKey key, IntPtr value);
    [PreserveSig] int SetValue(ref PropertyKey key, IntPtr value);
    [PreserveSig] int Commit();
}
[StructLayout(LayoutKind.Sequential, Pack = 4)]
public struct PropertyKey { public Guid fmtid; public uint pid; }
[DllImport("shell32.dll", CharSet = CharSet.Unicode)]
static extern int SHGetPropertyStoreFromParsingName(string path, IntPtr bindCtx, int flags, ref Guid iid, [MarshalAs(UnmanagedType.Interface)] out IPropertyStore store);
[DllImport("ole32.dll")] static extern int PropVariantClear(IntPtr pv);
static PropertyKey AppId() { return new PropertyKey { fmtid = new Guid("9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3"), pid = 5 }; }
static IPropertyStore Open(string path, int flags) {
    Guid iid = typeof(IPropertyStore).GUID;
    IPropertyStore store;
    int hr = SHGetPropertyStoreFromParsingName(path, IntPtr.Zero, flags, ref iid, out store);
    if (hr != 0) Marshal.ThrowExceptionForHR(hr);
    return store;
}
public static void SetAppId(string path, string id) {
    IPropertyStore store = Open(path, 2);   // GPS_READWRITE
    IntPtr pv = Marshal.AllocCoTaskMem(24);
    try {
        for (int i = 0; i < 24; i++) Marshal.WriteByte(pv, i, 0);
        Marshal.WriteInt16(pv, 0, 31);        // VT_LPWSTR
        Marshal.WriteIntPtr(pv, 8, Marshal.StringToCoTaskMemUni(id));
        PropertyKey key = AppId();
        int hr = store.SetValue(ref key, pv);
        if (hr != 0) Marshal.ThrowExceptionForHR(hr);
        hr = store.Commit();
        if (hr != 0) Marshal.ThrowExceptionForHR(hr);
    } finally { PropVariantClear(pv); Marshal.FreeCoTaskMem(pv); Marshal.ReleaseComObject(store); }
}
public static string GetAppId(string path) {
    IPropertyStore store = Open(path, 0);
    IntPtr pv = Marshal.AllocCoTaskMem(24);
    try {
        for (int i = 0; i < 24; i++) Marshal.WriteByte(pv, i, 0);
        PropertyKey key = AppId();
        if (store.GetValue(ref key, pv) != 0 || Marshal.ReadInt16(pv, 0) != 31) return null;
        return Marshal.PtrToStringUni(Marshal.ReadIntPtr(pv, 8));
    } finally { PropVariantClear(pv); Marshal.FreeCoTaskMem(pv); Marshal.ReleaseComObject(store); }
}
'@
}

function Get-WebAppId([string]$key) { "Winarchy.WebApp.$($key -replace '[^A-Za-z0-9.-]', '-')" }

# A PNG wrapped in an .ico (Windows reads PNG icons since Vista), from the site's favicon.
# Best effort: offline or blocked, the shortcut keeps the browser's own icon.
function Save-WebAppIcon([string]$url, [string]$dest) {
    try {
        $site = ([Uri]$url).Host
        $tmp = "$dest.png"
        Invoke-WebRequest "https://www.google.com/s2/favicons?domain=$site&sz=128" -OutFile $tmp -TimeoutSec 15 -ErrorAction Stop
        $png = [IO.File]::ReadAllBytes($tmp)
        Remove-Item -LiteralPath $tmp -Force
        if ($png.Length -lt 8 -or $png[0] -ne 0x89 -or $png[1] -ne 0x50) { return $null }
        $w = [int]$png[19] + ([int]$png[18] -shl 8); $h = [int]$png[23] + ([int]$png[22] -shl 8)
        $ms = [IO.MemoryStream]::new()
        $bw = [IO.BinaryWriter]::new($ms)
        $bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]1)          # ICONDIR: 1 image
        $bw.Write([byte]($w -band 0xFF)); $bw.Write([byte]($h -band 0xFF))       # 0 = 256
        $bw.Write([byte]0); $bw.Write([byte]0); $bw.Write([uint16]1); $bw.Write([uint16]32)
        $bw.Write([uint32]$png.Length); $bw.Write([uint32]22)
        $bw.Write($png); $bw.Flush()
        New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
        [IO.File]::WriteAllBytes($dest, $ms.ToArray())
        $dest
    } catch { Log "web app icon for ${url}: $($_.Exception.Message) (keeps the browser's icon)"; $null }
}

# The arguments a web app window is started with. Quoted: URLs carry & and ?.
function Get-WebAppArgs([string]$url) { "--app=`"$url`"" }

# One web app: the Start menu shortcut, journalled so uninstall and Remove take it out.
function Add-WebApp([string]$key, [string]$label, [string]$url, $p = (Get-Paths)) {
    if ($url -notmatch '^https?://') { $url = "https://$url" }
    $browser = Find-WebAppBrowser $p
    # Made again (a custom one renamed, or a new URL): the old one goes first. Before the
    # folder is made: taking out its last shortcut removes an empty folder.
    $old = Get-JournalEntry "webapp|$key"
    if ($old) { Remove-WebAppFiles $old; [void](Remove-JournalEntry "webapp|$key") }
    $dir = Get-WebAppDir
    New-Item -ItemType Directory -Force $dir | Out-Null
    $lnkPath = Join-Path $dir "$($label -replace '[\\/:*?"<>|]', '-').lnk"
    $icon = Save-WebAppIcon $url (Join-Path (Get-WebAppIconDir) "$key.ico")
    [void](Add-JournalEntry @{ kind = 'webapp'; key = "webapp|$key"; label = $label; path = $lnkPath; icon = $icon })
    $sh = New-Object -ComObject WScript.Shell
    $lnk = $sh.CreateShortcut($lnkPath)
    if ($browser) {
        $lnk.TargetPath = $browser
        $lnk.Arguments = Get-WebAppArgs $url
        $lnk.WorkingDirectory = Split-Path $browser
    } else {
        # No Chromium browser: the site in the default browser, as a tab.
        $lnk.TargetPath = Join-Path $env:SystemRoot 'explorer.exe'
        $lnk.Arguments = "`"$url`""
    }
    $lnk.Description = $label
    if ($icon) { $lnk.IconLocation = "$icon,0" }
    $lnk.Save()
    try { Initialize-ShortcutNative; [Winarchy.Shortcut]::SetAppId($lnkPath, (Get-WebAppId $key)) }
    catch { Log "web app ${label}: no AppUserModelID ($($_.Exception.Message)); Start may group it with the browser" }
    Log "web app $label -> $url$(if (-not $browser) { ' (no Chromium browser: opens as a tab)' })"
    $lnkPath
}

function Remove-WebAppFiles($entry) {
    foreach ($f in $entry.path, $entry.icon) { if ($f) { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue } }
    $dir = Get-WebAppDir
    if ((Test-Path $dir) -and -not (Get-ChildItem $dir -Force)) { Remove-Item -LiteralPath $dir -Force -ErrorAction SilentlyContinue }
}

function Remove-WebAppByKey([string]$key) {
    $e = Get-JournalEntry "webapp|$key"
    if (-not $e) {
        # Made before web apps were journalled: find it by its preset's label.
        $preset = Get-WebAppPresets | Where-Object key -eq $key | Select-Object -First 1
        if (-not $preset) { throw "no web app '$key'" }
        $e = @{ path = Join-Path (Get-WebAppDir) "$($preset.label).lnk" }
    }
    Remove-WebAppFiles $e
    Remove-JournalEntry "webapp|$key"
    Log "web app $key removed"
}

function Test-WebApp([string]$key) {
    [bool](Get-AllJournalEntries | Where-Object { $_.key -eq "webapp|$key" -and (Test-Path -LiteralPath $_.path) })
}

# Install > Web App (custom): any site, named by you.
function New-WebApp([string]$Name, [string]$Url) {
    if (-not $Name) { $Name = Read-Host 'Name' }
    if (-not $Url) { $Url = Read-Host 'URL' }
    if (-not $Name) { throw 'a web app needs a name' }
    if (-not $Url) { throw 'a web app needs a URL' }
    $key = 'custom-' + ($Name.ToLower() -replace '[^a-z0-9]+', '-').Trim('-')
    $lnk = Add-WebApp $key $Name $Url
    Write-Host "Web app '$Name' is in the Start menu (Apps): $lnk"
}

function Remove-WebApp([string]$Name) {
    $mine = @(Get-AllJournalEntries | Where-Object { $_.kind -eq 'webapp' })
    if (-not $Name) {
        if (-not $mine) { Write-Host 'No web apps.'; return }
        $mine | ForEach-Object { Write-Host "  $($_.label)" }
        $Name = Read-Host 'Remove which one'
    }
    $e = $mine | Where-Object { $_.label -eq $Name -or $_.key -eq "webapp|$Name" } | Select-Object -First 1
    if ($e) { Remove-WebAppByKey ($e.key -replace '^webapp\|', '') }
    else {
        # One made by hand, or before web apps were journalled.
        Remove-Item -LiteralPath (Join-Path (Get-WebAppDir) "$Name.lnk") -Force
    }
    Write-Host "Removed web app '$Name'."
}

# generated/webapps.ini for ahk/launchers.ahk: the browser to start, and each preset's URL,
# key and whether it brings an open window back. UTF-16, like winarchy.ini.
function Write-WebAppIni($p) {
    $browser = Find-WebAppBrowser $p
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('[browser]'); $lines.Add("exe=$browser"); $lines.Add('')
    foreach ($a in Get-WebAppPresets) {
        $lines.Add("[$($a.key)]")
        $lines.Add("label=$($a.label)"); $lines.Add("url=$($a.url)")
        $lines.Add("hotkey=$($a.hotkey)"); $lines.Add("focus=$([int][bool]$a.focus)"); $lines.Add("title=$($a.title)")
        $lines.Add('')
    }
    New-Item -ItemType Directory -Force $Generated | Out-Null
    [IO.File]::WriteAllLines((Join-Path $Generated 'webapps.ini'), [string[]]$lines, [Text.UnicodeEncoding]::new($false, $true))
}

# The Install > Web Apps catalog group, one row per preset (lib/catalog.ps1). The blocks
# are made from text, not closures: a closure runs in a module of its own, which can't see
# the functions winarchy.ps1 dot-sources. Keys are [a-z0-9-], so they quote safely.
function Get-WebAppCatalogItems {
    foreach ($a in Get-WebAppPresets | Where-Object { $_.install -ne $false }) {
        $k = $a.key
        @{
            key = $k; label = $a.label; id = "webapp-$k"
            test = [scriptblock]::Create("Test-WebApp '$k'")
            install = [scriptblock]::Create("`$a = Get-WebAppPresets | Where-Object key -eq '$k'; [void](Add-WebApp '$k' `$a.label `$a.url)")
            remove = [scriptblock]::Create("Remove-WebAppByKey '$k'")
        }
    }
}
