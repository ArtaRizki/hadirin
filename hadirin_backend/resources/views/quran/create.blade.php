@extends('layouts.app')

@section('title', 'Setoran Hafalan')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Input Setoran Hafalan
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Catat perkembangan hafalan siswa hari ini.
        </p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('quran.store') }}" method="POST">
            @csrf
            
            <div class="input-group">
                <label>Nama Siswa</label>
                <select name="student_nis" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Siswa --</option>
                    @foreach($students as $student)
                        <option value="{{ $student->nis }}">{{ $student->name }} ({{ $student->class }})</option>
                    @endforeach
                </select>
                @error('student_nis') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Jenis & Nama Surah</label>
                <select name="quran_master_id" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="">-- Pilih Materi --</option>
                    @foreach($masters as $master)
                        <option value="{{ $master->id }}">[{{ $master->type }}] {{ $master->name }}</option>
                    @endforeach
                </select>
            </div>

            <div class="input-group">
                <label>Halaman / Ayat</label>
                <input type="text" name="halaman_ayat" placeholder="Contoh: Ayat 1 - 10" value="{{ old('halaman_ayat') }}" />
            </div>

            <div class="input-group">
                <label>Nilai / Predikat</label>
                <select name="nilai" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    <option value="A (Sangat Lancar)">A (Sangat Lancar)</option>
                    <option value="B (Lancar)">B (Lancar)</option>
                    <option value="C (Kurang Lancar)">C (Kurang Lancar)</option>
                    <option value="D (Belum Lancar)">D (Belum Lancar)</option>
                </select>
            </div>

            <div class="input-group">
                <label>Keterangan Tambahan</label>
                <textarea name="keterangan" rows="3" placeholder="Catatan untuk siswa (opsional)"></textarea>
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <button type="submit" class="btn btn-primary" style="flex: 1; padding: 15px;">Simpan Setoran</button>
            </div>
        </form>
    </div>
</div>
@endsection
