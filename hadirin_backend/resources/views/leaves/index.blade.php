@extends('layouts.app')

@section('title', 'Persetujuan Izin')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 40px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Persetujuan Izin
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Proses pengajuan izin, sakit, dan cuti.
        </p>
    </header>

    <div style="display: grid; grid-template-columns: repeat(auto-fill, minmax(350px, 1fr)); gap: 24px;">
        @forelse($leaves as $leave)
        <div class="card glass" style="padding: 24px;">
            <div style="display: flex; justify-content: space-between; margin-bottom: 15px;">
                <div style="display: flex; align-items: center; gap: 12px;">
                    <div style="width: 40px; height: 40px; border-radius: 50%; background: var(--primary-gradient); color: white; display: flex; align-items: center; justify-content: center;">
                        <i data-lucide="user"></i>
                    </div>
                    <div>
                        <div style="font-weight: 800; color: var(--text-main);">{{ $leave->user->name ?? '-' }}</div>
                        <div style="font-size: 0.75rem; color: var(--text-muted); font-weight: 600;">{{ $leave->created_at->format('d M Y H:i') }}</div>
                    </div>
                </div>
                <span class="badge-tipe" style="background: rgba(245, 158, 11, 0.1); color: #f59e0b;">{{ $leave->type }}</span>
            </div>
            
            <div style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 8px;">
                <strong>Waktu:</strong> {{ $leave->lat_long ?? '-' }}
            </div>
            <div style="font-size: 0.85rem; color: var(--text-muted); margin-bottom: 15px; padding: 12px; background: rgba(0,0,0,0.02); border-radius: 8px;">
                {{ $leave->reason }}
            </div>
            
            @if($leave->photo_url && $leave->photo_url != 'No Photo' && !str_starts_with($leave->photo_url, 'Error'))
            <div style="margin-bottom: 15px;">
                <a href="{{ $leave->photo_url }}" target="_blank" style="font-size: 0.8rem; color: var(--primary); font-weight: 600; text-decoration: none; display: flex; align-items: center; gap: 6px;">
                    <i data-lucide="image" style="width: 14px;"></i> Lihat Lampiran
                </a>
            </div>
            @endif

            @if($leave->leave_status == 'Menunggu Approval')
            <div style="display: flex; gap: 10px; margin-top: auto;">
                <form action="{{ route('leaves.reject', $leave->id) }}" method="POST" style="flex: 1;">
                    @csrf
                    <button type="submit" class="btn" style="width: 100%; background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 10px;">
                        <i data-lucide="x"></i> Tolak
                    </button>
                </form>
                <form action="{{ route('leaves.approve', $leave->id) }}" method="POST" style="flex: 1;">
                    @csrf
                    <button type="submit" class="btn btn-primary" style="width: 100%; padding: 10px;">
                        <i data-lucide="check"></i> Setujui
                    </button>
                </form>
            </div>
            @else
                <div style="text-align: center; padding: 10px; font-weight: 700; border-radius: 8px; background: {{ $leave->leave_status == 'Disetujui' ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)' }}; color: {{ $leave->leave_status == 'Disetujui' ? '#10b981' : '#ef4444' }};">
                    {{ $leave->leave_status }}
                </div>
            @endif
        </div>
        @empty
        <div style="grid-column: 1 / -1; text-align: center; color: var(--text-muted); padding: 60px;">
            <i data-lucide="check-circle" style="width: 48px; height: 48px; margin-bottom: 16px; opacity: 0.5;"></i>
            <p>Tidak ada pengajuan yang menunggu persetujuan.</p>
        </div>
        @endforelse
    </div>
</div>
@endsection
