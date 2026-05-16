@extends('layouts.app')

@section('title', 'Kritik & Saran')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px;">
        <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-main);">Kritik & Saran</h1>
        <p style="color: var(--text-muted);">Sampaikan masukan Anda untuk kemajuan sekolah.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('feedback.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>Jenis Masukan</label>
                <select name="type" required>
                    <option value="Kritik">Kritik</option>
                    <option value="Saran">Saran</option>
                </select>
            </div>

            <div class="input-group">
                <label>Isi Pesan</label>
                <textarea name="content" rows="6" placeholder="Tuliskan masukan Anda di sini..." required></textarea>
            </div>

            <div style="margin-top: 20px;">
                <button type="submit" class="btn btn-primary" style="width: 100%;">
                    <i data-lucide="send"></i> Kirim Masukan
                </button>
            </div>
        </form>
    </div>
</div>
@endsection
