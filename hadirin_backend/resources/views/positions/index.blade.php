@extends('layouts.app')

@section('title', 'Manajemen Jabatan')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: flex-start;">
        <div>
            <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-main);">Manajemen Jabatan</h1>
            <p style="color: var(--text-muted);">Kelola daftar divisi atau jabatan di instansi Anda.</p>
        </div>
        <button onclick="openModal('modal-add-pos')" class="btn btn-primary">
            <i data-lucide="plus"></i> Tambah Jabatan
        </button>
    </header>

    <div class="card glass" style="max-width: 600px;">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Nama Jabatan / Divisi</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($positions as $item)
                    <tr>
                        <td data-label="Nama"><strong>{{ $item->name }}</strong></td>
                        <td data-label="Aksi">
                            <form action="{{ route('positions.destroy', $item->id) }}" method="POST" onsubmit="return confirm('Hapus jabatan ini?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn" style="color: #ef4444; padding: 8px;">
                                    <i data-lucide="trash-2"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="2" class="text-center">Belum ada jabatan yang ditambahkan.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal Add Position -->
<div id="modal-add-pos" class="modal">
    <div class="modal-content">
        <h2 style="margin-bottom: 20px;">Tambah Jabatan Baru</h2>
        <form action="{{ route('positions.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>Nama Jabatan</label>
                <input type="text" name="name" placeholder="Contoh: Guru Kelas, Staff TU, Kepala Sekolah" required>
            </div>
            <div style="display: flex; gap: 10px; margin-top: 20px;">
                <button type="button" onclick="closeModal('modal-add-pos')" class="btn" style="flex: 1; background: #f1f5f9;">Batal</button>
                <button type="submit" class="btn btn-primary" style="flex: 2;">Simpan</button>
            </div>
        </form>
    </div>
</div>
@endsection
