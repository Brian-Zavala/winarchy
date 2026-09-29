# The bar's Audio panel (Omarchy Quattro's shell/plugins/panels/audio): a master slider, the
# output picker and a mixer with one slider per app. The panel gets the devices and the master
# volume from Zebar's own audio provider; what Zebar cannot do is here, over Windows' Core
# Audio interfaces: switching the default device, and the per-app sessions.
#   audio.json   {"sessions":[{"pid":123,"name":"Spotify","volume":72,"muted":false}]}

# Compiled once and kept (Add-NativeType): the Audio panel asks every few seconds, and each
# ask is a new process.
function Initialize-CoreAudio {
    if ('WinarchyAudio' -as [type]) { return }
    Add-NativeType CoreAudio -TypeName WinarchyAudio -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;

public class WinarchyAudio {
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorCom { }
    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceEnumerator {
        [PreserveSig] int EnumAudioEndpoints(int flow, int mask, out IntPtr devices);
        [PreserveSig] int GetDefaultAudioEndpoint(int flow, int role, out IMMDevice device);
    }
    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDevice {
        [PreserveSig] int Activate(ref Guid iid, int ctx, IntPtr p, [MarshalAs(UnmanagedType.IUnknown)] out object o);
        [PreserveSig] int OpenPropertyStore(int access, out IntPtr store);
        [PreserveSig] int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
    }
    [ComImport, Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionManager2 {
        [PreserveSig] int GetAudioSessionControl(IntPtr g, int f, out IntPtr c);
        [PreserveSig] int GetSimpleAudioVolume(IntPtr g, int f, out IntPtr v);
        [PreserveSig] int GetSessionEnumerator(out IAudioSessionEnumerator e);
    }
    [ComImport, Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionEnumerator {
        [PreserveSig] int GetCount(out int n);
        [PreserveSig] int GetSession(int i, out IAudioSessionControl2 s);
    }
    [ComImport, Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionControl2 {
        [PreserveSig] int GetState(out int s);
        [PreserveSig] int GetDisplayName([MarshalAs(UnmanagedType.LPWStr)] out string n);
        [PreserveSig] int SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string n, IntPtr c);
        [PreserveSig] int GetIconPath([MarshalAs(UnmanagedType.LPWStr)] out string p);
        [PreserveSig] int SetIconPath([MarshalAs(UnmanagedType.LPWStr)] string p, IntPtr c);
        [PreserveSig] int GetGroupingParam(out Guid g);
        [PreserveSig] int SetGroupingParam(ref Guid g, IntPtr c);
        [PreserveSig] int RegisterAudioSessionNotification(IntPtr n);
        [PreserveSig] int UnregisterAudioSessionNotification(IntPtr n);
        [PreserveSig] int GetSessionIdentifier([MarshalAs(UnmanagedType.LPWStr)] out string i);
        [PreserveSig] int GetSessionInstanceIdentifier([MarshalAs(UnmanagedType.LPWStr)] out string i);
        [PreserveSig] int GetProcessId(out uint pid);
        [PreserveSig] int IsSystemSoundsSession();
        [PreserveSig] int SetDuckingPreference(bool optOut);
    }
    [ComImport, Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface ISimpleAudioVolume {
        [PreserveSig] int SetMasterVolume(float level, ref Guid ctx);
        [PreserveSig] int GetMasterVolume(out float level);
        [PreserveSig] int SetMute(bool mute, ref Guid ctx);
        [PreserveSig] int GetMute(out bool mute);
    }
    [ComImport, Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9")] class PolicyConfigCom { }
    [ComImport, Guid("F8679F50-850A-41CF-9C72-430F290290C8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IPolicyConfig {
        [PreserveSig] int GetMixFormat(IntPtr n, IntPtr f);
        [PreserveSig] int GetDeviceFormat(IntPtr n, int d, IntPtr f);
        [PreserveSig] int ResetDeviceFormat(IntPtr n);
        [PreserveSig] int SetDeviceFormat(IntPtr n, IntPtr e, IntPtr m);
        [PreserveSig] int GetProcessingPeriod(IntPtr n, int d, IntPtr p, IntPtr m);
        [PreserveSig] int SetProcessingPeriod(IntPtr n, IntPtr p);
        [PreserveSig] int GetShareMode(IntPtr n, IntPtr m);
        [PreserveSig] int SetShareMode(IntPtr n, IntPtr m);
        [PreserveSig] int GetPropertyValue(IntPtr n, int b, IntPtr k, IntPtr v);
        [PreserveSig] int SetPropertyValue(IntPtr n, int b, IntPtr k, IntPtr v);
        [PreserveSig] int SetDefaultEndpoint([MarshalAs(UnmanagedType.LPWStr)] string id, int role);
        [PreserveSig] int SetEndpointVisibility(IntPtr n, int v);
    }

    public class Session { public uint Pid; public string Name; public int Volume; public bool Muted; public ISimpleAudioVolume Vol; }

    static Guid IID_Mgr = new Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F");

    // Every app with an audio session on the default playback device.
    public static List<Session> Sessions() {
        var list = new List<Session>();
        var en = (IMMDeviceEnumerator)new MMDeviceEnumeratorCom();
        IMMDevice dev;
        if (en.GetDefaultAudioEndpoint(0, 1, out dev) != 0) return list;
        object o; Guid iid = IID_Mgr;
        if (dev.Activate(ref iid, 23, IntPtr.Zero, out o) != 0) return list;
        var mgr = (IAudioSessionManager2)o;
        IAudioSessionEnumerator se;
        if (mgr.GetSessionEnumerator(out se) != 0) return list;
        int n; se.GetCount(out n);
        for (int i = 0; i < n; i++) {
            IAudioSessionControl2 c;
            if (se.GetSession(i, out c) != 0) continue;
            uint pid; c.GetProcessId(out pid);
            if (c.IsSystemSoundsSession() == 0) continue;      // S_OK = the "System sounds" session
            var v = (ISimpleAudioVolume)c;
            float lvl; bool mute; v.GetMasterVolume(out lvl); v.GetMute(out mute);
            string name = "";
            try {
                var p = Process.GetProcessById((int)pid);
                name = !string.IsNullOrEmpty(p.MainWindowTitle) && p.ProcessName.Length < 24 ? p.ProcessName : p.ProcessName;
            } catch { name = "pid " + pid; }
            list.Add(new Session { Pid = pid, Name = name, Volume = (int)Math.Round(lvl * 100), Muted = mute, Vol = v });
        }
        return list;
    }

    // Volume 0-100 (or -1) and mute (1 mute, 0 unmute, -1 leave) for every session of a process.
    public static int SetApp(uint pid, int volume, int mute) {
        int hit = 0; Guid ctx = Guid.Empty;
        foreach (var s in Sessions()) {
            if (s.Pid != pid) continue;
            if (volume >= 0) s.Vol.SetMasterVolume(Math.Max(0, Math.Min(100, volume)) / 100f, ref ctx);
            if (mute >= 0) s.Vol.SetMute(mute == 1, ref ctx);
            hit++;
        }
        return hit;
    }

    // The default playback device's endpoint id ("{0.0.0.00000000}.{guid}"), or null.
    public static string DefaultId() {
        var en = (IMMDeviceEnumerator)new MMDeviceEnumeratorCom();
        IMMDevice dev; string id;
        if (en.GetDefaultAudioEndpoint(0, 1, out dev) != 0 || dev.GetId(out id) != 0) return null;
        return id;
    }

    // Make an endpoint the default for every role (what the Sound settings' "Set as default" does).
    public static void SetDefault(string id) {
        var pc = (IPolicyConfig)new PolicyConfigCom();
        for (int role = 0; role < 3; role++) {
            int hr = pc.SetDefaultEndpoint(id, role);
            if (hr != 0) throw new InvalidOperationException("SetDefaultEndpoint failed: 0x" + hr.ToString("X"));
        }
    }
}
'@
}

function Update-AudioState {
    Initialize-CoreAudio
    $sessions = @([WinarchyAudio]::Sessions() | Sort-Object Name | ForEach-Object {
            [ordered]@{ pid = [int]$_.Pid; name = $_.Name; volume = $_.Volume; muted = $_.Muted }
        })
    Write-JsonAtomic (Join-Path $Pack 'audio.json') ([ordered]@{ sessions = $sessions; at = (Get-Date).ToString('s') })
}

# The playback devices that are plugged in and on, as endpoint ids with their names, in a
# fixed order. Windows keeps them under MMDevices; DeviceState 1 = active.
function Get-AudioOutputs {
    $root = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
    @(Get-ChildItem $root -ErrorAction SilentlyContinue | ForEach-Object {
            if ((Get-ItemProperty $_.PSPath -Name DeviceState -ErrorAction SilentlyContinue).DeviceState -ne 1) { return }
            # PKEY_Device_DeviceDesc ("Speakers") and PKEY_DeviceInterface_FriendlyName ("Realtek Audio").
            $props = Get-ItemProperty (Join-Path $_.PSPath 'Properties') -ErrorAction SilentlyContinue
            $desc = $props.'{a45c254e-df1c-4efd-8020-67d146a850e0},2'
            $iface = $props.'{b3f8fa53-0004-438e-9003-51a46e139bfc},6'
            [pscustomobject]@{ id = "{0.0.0.00000000}.$($_.PSChildName)".ToLower(); name = $(if ($iface) { "$desc ($iface)" } else { "$desc" }) }
        } | Sort-Object id)
}

# Omarchy's Shift + Mute (omarchy-audio-output-switch): the next playback device becomes the default.
function Switch-AudioOutput {
    $outs = @(Get-AudioOutputs)
    if ($outs.Count -lt 2) { return $(if ($outs) { $outs[0].name } else { '' }) }
    $cur = "$([WinarchyAudio]::DefaultId())".ToLower()
    $i = [array]::IndexOf(@($outs.id), $cur)
    $next = $outs[($i + 1) % $outs.Count]
    [WinarchyAudio]::SetDefault($next.id)
    $next.name
}

function Invoke-AudioAction([string]$What, [string]$A, [string]$B) {
    Initialize-CoreAudio
    switch ($What) {
        'sessions' { }
        'app-volume' { [void][WinarchyAudio]::SetApp([uint32]$A, [int]$B, -1) }
        'app-mute' { [void][WinarchyAudio]::SetApp([uint32]$A, -1, [int]$B) }
        'default' { [WinarchyAudio]::SetDefault($A) }
        # The name goes where winarchy.ahk reads it for its OSD.
        'next-output' { Write-Utf8 (Join-Path $Generated 'audio-output.txt') (Switch-AudioOutput) }
        default { throw 'usage: winarchy audio <sessions|app-volume <pid> <0-100>|app-mute <pid> <0|1>|default <device id>|next-output>' }
    }
    Update-AudioState
}
