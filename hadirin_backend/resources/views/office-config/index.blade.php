@extends('layouts.app')

@section('title', 'Setelan Kantor')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 40px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Setelan Kantor
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Atur lokasi geofencing dan jam kerja pegawai.
        </p>
    </header>

    <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 24px;">
        <!-- Form Geofencing -->
        <div class="card glass">
            <h3 style="font-weight: 800; margin-bottom: 24px; font-size: 1.2rem;">Geofencing (Lokasi & Radius)</h3>
            <form action="{{ route('office-config.updateLocation') }}" method="POST">
                @csrf
                <div class="input-group">
                    <label>Latitude</label>
                    <input type="text" name="latitude" value="{{ $config->latitude ?? '' }}" required />
                </div>
                <div class="input-group">
                    <label>Longitude</label>
                    <input type="text" name="longitude" value="{{ $config->longitude ?? '' }}" required />
                </div>
                <div class="input-group">
                    <label>Radius Absensi (Meter)</label>
                    <input type="number" name="radius" value="{{ $config->radius ?? 100 }}" required />
                    <small style="color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 6px; padding-left: 4px;">Jarak maksimal pegawai bisa melakukan absen dari titik kordinat.</small>
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                    Simpan Lokasi
                </button>
            </form>
        </div>

        <!-- Form Jam Kerja -->
        <div class="card glass">
            <h3 style="font-weight: 800; margin-bottom: 24px; font-size: 1.2rem;">Jam Kerja (WITA)</h3>
            <form action="{{ route('office-config.updateTime') }}" method="POST">
                @csrf
                <div class="input-group">
                    <label>Jam Mulai Absen Masuk</label>
                    <input type="time" name="start_checkin" value="{{ substr($config->start_checkin ?? '05:00', 0, 5) }}" required />
                </div>
                <div class="input-group">
                    <label>Batas Waktu Absen Masuk (Terlambat)</label>
                    <input type="time" name="limit_checkin" value="{{ substr($config->limit_checkin ?? '07:30', 0, 5) }}" required />
                    <small style="color: var(--text-muted); font-size: 0.75rem; display: block; margin-top: 6px; padding-left: 4px;">Lewat jam ini akan dihitung terlambat.</small>
                </div>
                <div class="input-group">
                    <label>Jam Mulai Absen Pulang</label>
                    <input type="time" name="start_checkout" value="{{ substr($config->start_checkout ?? '13:00', 0, 5) }}" required />
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 10px;">
                    Simpan Jam Kerja
                </button>
            </form>
        </div>
    </div>
</div>
@endsection
