@extends('layouts.app')

@section('title', 'Tambah Kegiatan')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 40px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Tambah Kegiatan</h1>
        <p style="color: var(--text-muted); font-weight: 500">Buat jadwal kegiatan baru untuk instansi Anda.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('activities.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>Nama Kegiatan</label>
                <input type="text" name="name" required placeholder="Cth: Rapat Guru Bulanan" />
            </div>
            <div class="input-group">
                <label>Tipe Kegiatan</label>
                <select name="type" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="Rapat">Rapat</option>
                    <option value="Upacara">Upacara</option>
                    <option value="Briefing">Briefing</option>
                    <option value="Lainnya">Lainnya</option>
                </select>
            </div>
            <div class="input-group">
                <label>Waktu Kegiatan</label>
                <input type="datetime-local" name="scheduled_at" required />
            </div>
            <div class="input-group">
                <label>Deskripsi (Opsional)</label>
                <textarea name="description" rows="4" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;"></textarea>
            </div>
            
            <div style="display: flex; gap: 12px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1;">Simpan Kegiatan</button>
                <a href="{{ route('activities.index') }}" class="btn" style="flex: 1; text-align: center; background: rgba(0,0,0,0.05); text-decoration: none;">Batal</a>
            </div>
        </form>
    </div>
</div>
@endsection
