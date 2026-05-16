@extends('layouts.app')

@section('title', 'Laporan Kehadiran')

@section('content')
<div class="content-view fade-in">
    <header style="display: flex; justify-content: space-between; align-items: flex-end; margin-bottom: 40px;">
        <div>
            <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
                Laporan Kehadiran
            </h1>
            <p style="color: var(--text-muted); font-weight: 500">
                Unduh ringkasan absensi per bulan.
            </p>
        </div>
        <div style="display: flex; gap: 12px">
            <button class="btn btn-primary" onclick="alert('Fitur download Excel akan segera diimplementasikan.')">
                <i data-lucide="download"></i> Download Excel
            </button>
        </div>
    </header>

    <div class="card glass" style="margin-bottom: 30px;">
        <form action="{{ route('reports.monthly') }}" method="GET" style="display: flex; gap: 20px; align-items: flex-end;">
            <div style="flex: 1;">
                <label style="display: block; font-size: 0.8rem; font-weight: 700; color: var(--text-muted); margin-bottom: 8px;">Bulan</label>
                <select name="month" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    @for($i=1; $i<=12; $i++)
                        <option value="{{ $i }}" {{ request('month', now()->month) == $i ? 'selected' : '' }}>
                            {{ date('F', mktime(0, 0, 0, $i, 10)) }}
                        </option>
                    @endfor
                </select>
            </div>
            <div style="flex: 1;">
                <label style="display: block; font-size: 0.8rem; font-weight: 700; color: var(--text-muted); margin-bottom: 8px;">Tahun</label>
                <select name="year" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                    @for($i=now()->year; $i>=2023; $i--)
                        <option value="{{ $i }}" {{ request('year', now()->year) == $i ? 'selected' : '' }}>{{ $i }}</option>
                    @endfor
                </select>
            </div>
            <div>
                <button type="submit" class="btn btn-primary" style="padding: 12px 24px;">Tampilkan</button>
            </div>
        </form>
    </div>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th rowspan="2" style="border-bottom: 2px solid #f1f5f9; vertical-align: middle;">Nama Pegawai</th>
                        <th colspan="4" style="text-align: center; border-bottom: 1px solid #e2e8f0;">Ringkasan</th>
                    </tr>
                    <tr>
                        <th style="color: #10b981; text-align: center;">Hadir</th>
                        <th style="color: #f59e0b; text-align: center;">Terlambat</th>
                        <th style="color: #3b82f6; text-align: center;">Izin/Sakit</th>
                        <th style="color: #ef4444; text-align: center;">Alpha</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($report ?? [] as $row)
                    <tr>
                        <td style="font-weight: 600;">
                            {{ $row['nama'] }}<br>
                            <span style="font-size: 0.75rem; color: var(--text-muted); font-weight: 500;">{{ $row['id'] }}</span>
                        </td>
                        <td style="text-align: center; font-weight: 800; color: #10b981;">{{ $row['hadir'] }}</td>
                        <td style="text-align: center; font-weight: 800; color: #f59e0b;">{{ $row['terlambat'] }}</td>
                        <td style="text-align: center; font-weight: 800; color: #3b82f6;">{{ $row['izin'] + $row['sakit'] + $row['cuti'] }}</td>
                        <td style="text-align: center; font-weight: 800; color: #ef4444;">{{ $row['alpha'] ?? 0 }}</td>
                    </tr>
                    @empty
                    <tr><td colspan="5" style="text-align: center; color: var(--text-muted); padding: 40px;">Data tidak ditemukan untuk bulan tersebut.</td></tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
