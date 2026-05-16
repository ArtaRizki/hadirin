@extends('layouts.app')

@section('title', 'Tambah Pengumuman')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Tambah Pengumuman Baru
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Upload gambar banner untuk ditampilkan di aplikasi anggota.
        </p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('banners.store') }}" method="POST" enctype="multipart/form-data">
            @csrf
            <div class="input-group">
                <label>Judul / Keterangan</label>
                <input type="text" name="title" required placeholder="Contoh: Libur Lebaran" value="{{ old('title') }}" />
                @error('title') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Gambar Banner</label>
                <input type="file" name="image" required accept="image/*" style="width: 100%; padding: 10px; background: rgba(0,0,0,0.02); border-radius: 12px; border: 1px dashed rgba(0,0,0,0.2);" />
                <small style="color: var(--text-muted);">Maksimal 2MB. Format: JPG, PNG.</small>
                @error('image') <br><span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Status</label>
                <select name="is_active" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="1">Aktif (Tampilkan)</option>
                    <option value="0">Draft (Sembunyikan)</option>
                </select>
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">Upload Banner</button>
                <a href="{{ route('banners.index') }}" class="btn" style="padding: 15px; background: rgba(0,0,0,0.05); color: var(--text-main); text-decoration: none; text-align: center;">Batal</a>
            </div>
        </form>
    </div>
</div>
@endsection
