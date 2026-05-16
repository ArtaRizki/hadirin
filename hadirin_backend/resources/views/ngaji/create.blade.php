@extends('layouts.app')

@section('title', 'Presensi Halaqah')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Presensi Halaqah (Ngaji)
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Konfirmasi kehadiran pada kelompok halaqah Anda hari ini.
        </p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('ngaji.store') }}" method="POST">
            @csrf
            
            <div class="input-group">
                <label>Kelompok Halaqah</label>
                <select name="ngaji_group_id" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Kelompok --</option>
                    @foreach($groups as $group)
                        <option value="{{ $group->id }}">{{ $group->group_name }}</option>
                    @endforeach
                </select>
                @error('ngaji_group_id') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Status Kehadiran</label>
                <select name="status" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="Hadir">Hadir</option>
                    <option value="Izin">Izin</option>
                    <option value="Sakit">Sakit</option>
                    <option value="Alpha">Alpha</option>
                </select>
            </div>

            <div class="input-group">
                <label>Lokasi / Keterangan</label>
                <input type="text" name="location" placeholder="Cth: Masjid Sekolah / Izin ke luar kota" value="{{ old('location') }}" />
            </div>

            <div class="input-group">
                <label>Materi / Pencapaian (Opsional)</label>
                <textarea name="materi" rows="3" placeholder="Apa yang dibahas hari ini?"></textarea>
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">Simpan Presensi</button>
            </div>
        </form>
    </div>
</div>
@endsection
