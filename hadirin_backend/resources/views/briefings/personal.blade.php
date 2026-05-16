@extends('layouts.app')

@section('title', 'Jadwal Rapat & Briefing')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Jadwal Rapat
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Daftar agenda rapat dan briefing hari ini. Silakan konfirmasi kehadiran Anda.
        </p>
    </header>

    <div class="card glass">
        @if($briefings->isEmpty())
            <div style="text-align: center; padding: 40px; color: var(--text-muted);">
                <i data-lucide="calendar-x" style="width: 48px; height: 48px; margin-bottom: 15px; opacity: 0.5;"></i>
                <h3>Tidak ada jadwal rapat hari ini.</h3>
            </div>
        @else
            <div style="display: grid; gap: 20px;">
                @foreach($briefings as $briefing)
                    <div style="padding: 20px; border-radius: 16px; border: 1px solid rgba(0,0,0,0.05); display: flex; justify-content: space-between; align-items: center; background: rgba(255,255,255,0.5);">
                        <div>
                            <h3 style="font-weight: 800; font-size: 1.2rem; margin-bottom: 5px;">{{ $briefing->title }}</h3>
                            <p style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 10px;">
                                <i data-lucide="clock" style="width: 14px; display: inline-block; vertical-align: middle;"></i> 
                                Pukul {{ \Carbon\Carbon::parse($briefing->scheduled_time)->format('H:i') }} WITA
                            </p>
                            @if($briefing->description)
                                <p style="font-size: 0.85rem; color: var(--text-main);">{{ $briefing->description }}</p>
                            @endif
                        </div>
                        
                        <div>
                            @php
                                $hasAttended = $briefing->attendances->contains('user_id', auth()->id());
                            @endphp

                            @if($hasAttended)
                                <span class="badge-tipe" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                                    <i data-lucide="check-circle" style="width: 16px; vertical-align: middle;"></i> Sudah Hadir
                                </span>
                            @else
                                <form action="{{ route('briefings.attend', $briefing->id) }}" method="POST">
                                    @csrf
                                    <button type="submit" class="btn btn-primary" style="padding: 10px 20px;">
                                        Konfirmasi Kehadiran
                                    </button>
                                </form>
                            @endif
                        </div>
                    </div>
                @endforeach
            </div>
        @endif
    </div>
</div>
@endsection
