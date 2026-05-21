@extends('layouts.app')

@section('title', 'Edit Briefing')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Edit Briefing / Rapat</h1>
        <p style="color: var(--text-muted); font-weight: 500">Perbarui informasi jadwal rapat.</p>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <form action="{{ route('briefings.update', $briefing->id) }}" method="POST">
            @csrf @method('PUT')

            <div class="input-group">
                <label>Judul / Agenda Rapat</label>
                <input type="text" name="title" value="{{ old('title', $briefing->title) }}" placeholder="Cth: Briefing Pagi Senin" required />
                @error('title') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Pemateri / PIC</label>
                <input type="text" name="speaker_name" value="{{ old('speaker_name', $briefing->speaker_name) }}" placeholder="Nama pemateri atau penanggung jawab" required />
                @error('speaker_name') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Tanggal Pelaksanaan</label>
                <input type="date" name="scheduled_date" value="{{ old('scheduled_date', $briefing->scheduled_date->format('Y-m-d')) }}" required />
                @error('scheduled_date') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Jam Pelaksanaan</label>
                <input type="time" name="scheduled_time" value="{{ old('scheduled_time', $briefing->scheduled_time) }}" required />
                @error('scheduled_time') <span style="color: red; font-size: 0.8rem;">{{ $message }}</span> @enderror
            </div>

            <div class="input-group">
                <label>Deskripsi (Opsional)</label>
                <textarea name="description" rows="3" placeholder="Catatan atau agenda rinci...">{{ old('description', $briefing->description) }}</textarea>
            </div>

            <div style="display: flex; gap: 15px; margin-top: 30px;">
                <a href="{{ route('briefings.index') }}" class="btn" style="flex: 1; padding: 15px; text-align: center;">Batal</a>
                <button type="submit" class="btn btn-primary" style="flex: 2; padding: 15px;">Simpan Perubahan</button>
            </div>
        </form>
    </div>
</div>
@endsection
