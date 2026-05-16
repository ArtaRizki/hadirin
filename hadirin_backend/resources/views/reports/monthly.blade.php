@extends('layouts.app')

@section('title', 'Laporan Bulanan')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 40px; display: flex; justify-content: space-between; align-items: center;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Laporan Absensi</h1>
            <p style="color: var(--text-muted); font-weight: 500">Rekapitulasi kehadiran anggota per bulan.</p>
        </div>
        <div style="display: flex; gap: 12px; align-items: center;">
            <form action="{{ route('reports.monthly') }}" method="GET" id="monthForm">
                <input type="month" name="month" value="{{ $month->format('Y-m') }}" onchange="document.getElementById('monthForm').submit()" 
                    style="padding: 10px 16px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none; font-weight: 600;" />
            </form>
            <a href="{{ route('reports.export', ['month' => $month->format('Y-m')]) }}" class="btn" style="background: #10b981; color: white; text-decoration: none; display: flex; align-items: center; gap: 8px;">
                <i data-lucide="file-spreadsheet"></i> Download Excel
            </a>
            <button class="btn" onclick="window.print()" style="background: var(--text-main); color: white; display: flex; align-items: center; gap: 8px;">
                <i data-lucide="printer"></i> Cetak
            </button>
        </div>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Waktu</th>
                        <th>ID Anggota</th>
                        <th>Nama Anggota</th>
                        <th>Tipe</th>
                        <th>Status</th>
                        <th>Lampiran</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($attendances as $attendance)
                    <tr>
                        <td>{{ $attendance->created_at->format('d/m/Y H:i') }}</td>
                        <td style="font-weight: 600;">{{ $attendance->user->employee_id }}</td>
                        <td>{{ $attendance->user->name }}</td>
                        <td><span class="badge-tipe">{{ $attendance->type }}</span></td>
                        <td>
                            @if($attendance->status == 'Tepat Waktu')
                                <span style="color: #10b981; font-weight: 700;">{{ $attendance->status }}</span>
                            @else
                                <span style="color: #ef4444; font-weight: 700;">{{ $attendance->status }}</span>
                            @endif
                        </td>
                        <td>
                            @if($attendance->image_url)
                                <a href="{{ asset('storage/' . $attendance->image_url) }}" target="_blank" style="color: var(--primary); font-size: 0.8rem; font-weight: 600;">Lihat Foto</a>
                            @else
                                -
                            @endif
                        </td>
                    </tr>
                    @empty
                    <tr><td colspan="6" style="text-align: center; color: var(--text-muted); padding: 40px;">Tidak ada data absensi untuk bulan ini.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
