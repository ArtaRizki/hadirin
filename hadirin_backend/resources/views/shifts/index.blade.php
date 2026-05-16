@extends('layouts.app')

@section('title', 'Master Shift')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: center">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Master Shift</h1>
            <p style="color: var(--text-muted); font-weight: 500">Definisikan jam kerja instansi Anda.</p>
        </div>
        <button class="btn btn-primary" onclick="document.getElementById('modal-add').style.display='flex'">
            <i data-lucide="plus"></i> Tambah Shift
        </button>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Nama Shift</th>
                        <th>Jam Masuk</th>
                        <th>Jam Pulang</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($shifts as $shift)
                    <tr>
                        <td style="font-weight: 600;">{{ $shift->name }}</td>
                        <td>{{ \Carbon\Carbon::parse($shift->start_time)->format('H:i') }}</td>
                        <td>{{ \Carbon\Carbon::parse($shift->end_time)->format('H:i') }}</td>
                        <td>
                            <form action="{{ route('shifts.master.destroy', $shift->id) }}" method="POST" onsubmit="return confirm('Hapus shift ini?')">
                                @csrf
                                @method('DELETE')
                                <button type="submit" class="btn" style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 6px 12px; font-size: 0.8rem; border: none; cursor: pointer;">Hapus</button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" style="text-align: center; padding: 40px; color: var(--text-muted)">Belum ada data shift.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal Add -->
<div id="modal-add" style="display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 1000; align-items: center; justify-content: center; backdrop-filter: blur(4px);">
    <div class="card glass" style="width: 400px; padding: 30px;">
        <h2 style="margin-bottom: 20px;">Tambah Master Shift</h2>
        <form action="{{ route('shifts.master.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>Nama Shift</label>
                <input type="text" name="name" required placeholder="Cth: Pagi / Normal" />
            </div>
            <div class="input-group">
                <label>Jam Masuk</label>
                <input type="time" name="start_time" required />
            </div>
            <div class="input-group">
                <label>Jam Pulang</label>
                <input type="time" name="end_time" required />
            </div>
            <div style="display: flex; gap: 10px; margin-top: 20px;">
                <button type="submit" class="btn btn-primary" style="flex: 1">Simpan</button>
                <button type="button" class="btn" style="flex: 1; background: rgba(0,0,0,0.05)" onclick="document.getElementById('modal-add').style.display='none'">Batal</button>
            </div>
        </form>
    </div>
</div>
@endsection
