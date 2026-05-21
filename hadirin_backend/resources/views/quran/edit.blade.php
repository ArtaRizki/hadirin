@extends('layouts.app')

@section('title', 'Edit Setoran Hafalan')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Edit Setoran Hafalan</h1>
        <p style="color: var(--text-muted); font-weight: 500">Perbarui data setoran hafalan guru.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('quran.update', $log->id) }}" method="POST">
            @csrf @method('PUT')

            <div class="input-group">
                <label>Nama Guru</label>
                <select name="student_nis" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Guru --</option>
                    @foreach($students as $student)
                        <option value="{{ $student->nis }}" {{ $log->student_nis == $student->nis ? 'selected' : '' }}>{{ $student->name }} ({{ $student->class }})</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Jenis & Nama Surah</label>
                <select name="quran_master_id" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Materi --</option>
                    @foreach($masters as $master)
                        <option value="{{ $master->id }}" {{ $log->quran_master_id == $master->id ? 'selected' : '' }}>[{{ $master->type }}] {{ $master->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Halaman / Ayat</label>
                <input type="text" name="halaman_ayat" value="{{ old('halaman_ayat', $log->halaman_ayat) }}" placeholder="Contoh: Ayat 1 - 10" />
            </div>

            <div class="input-group">
                <label>Nilai / Predikat</label>
                <select name="nilai" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    @foreach(['A (Sangat Lancar)', 'B (Lancar)', 'C (Kurang Lancar)', 'D (Belum Lancar)'] as $n)
                        <option value="{{ $n }}" {{ $log->nilai == $n ? 'selected' : '' }}>{{ $n }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Keterangan Tambahan</label>
                <textarea name="keterangan" rows="3" placeholder="Catatan (opsional)">{{ old('keterangan', $log->keterangan) }}</textarea>
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <a href="{{ route('quran.index') }}" class="btn" style="flex: 1; padding: 15px; text-align: center;">Batal</a>
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 15px;">Simpan Perubahan</button>
            </div>
        </form>
    </div>
</div>
@endsection
