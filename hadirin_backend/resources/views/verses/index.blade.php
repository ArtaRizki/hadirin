@extends('layouts.app')

@section('title', 'Kelola Ayat')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px; display: flex; justify-content: space-between; align-items: flex-start;">
        <div>
            <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-main);">Kelola Ayat</h1>
            <p style="color: var(--text-muted);">Atur kutipan harian yang tampil di dashboard.</p>
        </div>
        <button onclick="openModal('modal-add-verse')" class="btn btn-primary">
            <i data-lucide="plus"></i> Tambah Ayat
        </button>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Isi Kutipan / Ayat</th>
                        <th>Referensi</th>
                        <th>Aksi</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($verses as $item)
                    <tr>
                        <td data-label="Isi">
                            <div style="font-style: italic; max-width: 500px; white-space: normal;">
                                "{{ $item->content }}"
                            </div>
                        </td>
                        <td data-label="Referensi"><strong>{{ $item->reference }}</strong></td>
                        <td data-label="Aksi">
                            <form action="{{ route('verses.destroy', $item->id) }}" method="POST" onsubmit="return confirm('Hapus ayat ini?')">
                                @csrf @method('DELETE')
                                <button type="submit" class="btn" style="color: #ef4444; padding: 8px;">
                                    <i data-lucide="trash-2"></i>
                                </button>
                            </form>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="3" class="text-center">Belum ada ayat yang ditambahkan.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>

<!-- Modal Add Verse -->
<div id="modal-add-verse" class="modal">
    <div class="modal-content">
        <h2 style="margin-bottom: 20px;">Tambah Ayat Harian</h2>
        <form action="{{ route('verses.store') }}" method="POST">
            @csrf
            <div class="input-group">
                <label>Isi Ayat / Kutipan</label>
                <textarea name="content" rows="4" placeholder="Masukkan teks ayat..." required></textarea>
            </div>
            <div class="input-group">
                <label>Referensi (Opsional)</label>
                <input type="text" name="reference" placeholder="Contoh: Al-Baqarah: 255">
            </div>
            <div style="display: flex; gap: 10px; margin-top: 20px;">
                <button type="button" onclick="closeModal('modal-add-verse')" class="btn" style="flex: 1; background: #f1f5f9;">Batal</button>
                <button type="submit" class="btn btn-primary" style="flex: 2;">Simpan</button>
            </div>
        </form>
    </div>
</div>
@endsection
