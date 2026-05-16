@extends('layouts.app')

@section('title', 'Pengumuman')

@section('content')
<div class="content-view fade-in">
    <header style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 40px;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
                Pengumuman
            </h1>
            <p style="color: var(--text-muted); font-weight: 500">
                Kelola banner pengumuman untuk anggota instansi.
            </p>
        </div>
        <div style="display: flex; gap: 12px">
            <a href="{{ route('banners.create') }}" class="btn btn-primary" style="padding: 10px 20px; font-size: 0.9rem; text-decoration: none;">
            <i data-lucide="plus" style="width: 16px; height: 16px;"></i> Tambah Banner
        </a>
        </div>
    </header>

    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 24px;">
        @forelse($banners ?? [] as $banner)
        <div class="card glass" style="padding: 0; overflow: hidden; display: flex; flex-direction: column;">
            @if($banner->image_url)
                <div style="height: 180px; width: 100%; overflow: hidden;">
                    <img src="{{ $banner->image_url }}" alt="Banner" style="width: 100%; height: 100%; object-fit: cover;">
                </div>
            @else
                <div style="height: 180px; width: 100%; background: rgba(0,0,0,0.03); display: flex; align-items: center; justify-content: center;">
                    <i data-lucide="image" style="width: 48px; height: 48px; color: var(--text-muted); opacity: 0.3;"></i>
                </div>
            @endif
            
            <div style="padding: 24px; flex: 1; display: flex; flex-direction: column;">
                <h3 style="font-size: 1.1rem; font-weight: 800; margin-bottom: 12px; color: var(--text-main);">{{ $banner->title }}</h3>
                <div style="margin-bottom: 20px;">
                    @if($banner->status == 'Aktif')
                        <span class="badge-tipe" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">Aktif</span>
                    @else
                        <span class="badge-tipe" style="background: rgba(0,0,0,0.05); color: var(--text-muted);">Nonaktif</span>
                    @endif
                </div>
                
                <div style="display: flex; justify-content: space-between; margin-top: auto; gap: 10px;">
                    <button class="btn" style="flex: 1; padding: 10px; font-size: 0.85rem; background: rgba(0,0,0,0.05); color: var(--text-main);">
                        Edit
                    </button>
                    <form action="{{ route('banners.destroy', $banner->id) }}" method="POST" style="flex: 1;" onsubmit="return confirm('Hapus banner ini?')">
                        @csrf @method('DELETE')
                        <button type="submit" class="btn" style="width: 100%; padding: 10px; font-size: 0.85rem; background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                            Hapus
                        </button>
                    </form>
                </div>
            </div>
        </div>
        @empty
        <div style="grid-column: 1 / -1; text-align: center; color: var(--text-muted); padding: 60px;">
            <i data-lucide="megaphone" style="width: 48px; height: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
            <p>Belum ada pengumuman / banner.</p>
        </div>
        @endforelse
    </div>
</div>
@endsection
