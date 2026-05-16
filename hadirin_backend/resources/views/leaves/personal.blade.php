@extends('layouts.app')

@section('title', 'Ajukan Izin')

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 40px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">
            Ajukan Izin
        </h1>
        <p style="color: var(--text-muted); font-weight: 500">
            Formulir pengajuan izin, sakit, atau cuti.
        </p>
    </header>

    <div style="display: grid; grid-template-columns: 1fr 1.5fr; gap: 30px;">
        <!-- Form Section -->
        <div class="card glass">
            <h3 style="font-weight: 800; margin-bottom: 24px;">Form Pengajuan</h3>
            <form action="{{ route('leaves.store') }}" method="POST">
                @csrf
                <div class="input-group">
                    <label>Tipe Izin</label>
                    <select name="type" required style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;">
                        <option value="Izin">Izin</option>
                        <option value="Sakit">Sakit</option>
                        <option value="Cuti">Cuti</option>
                    </select>
                </div>
                <div class="input-group">
                    <label>Rentang Tanggal</label>
                    <input type="text" name="lat_long" placeholder="Contoh: 12 Mei - 14 Mei 2026" required />
                </div>
                <div class="input-group">
                    <label>Alasan</label>
                    <textarea name="reason" rows="4" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none; font-family: inherit;" placeholder="Jelaskan alasan Anda..." required></textarea>
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%; padding: 15px; margin-top: 10px;">
                    Kirim Pengajuan
                </button>
            </form>
        </div>

        <!-- History Section -->
        <div class="card glass">
            <h3 style="font-weight: 800; margin-bottom: 24px;">Status Pengajuan Terakhir</h3>
            <div class="table-container">
                <table>
                    <thead>
                        <tr>
                            <th>Tanggal</th>
                            <th>Tipe</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($leaves as $leave)
                        <tr>
                            <td>{{ $leave->lat_long }}</td>
                            <td><span class="badge-tipe">{{ $leave->type }}</span></td>
                            <td>
                                @php
                                    $color = '#f59e0b';
                                    if($leave->leave_status == 'Disetujui') $color = '#10b981';
                                    if($leave->leave_status == 'Ditolak') $color = '#ef4444';
                                @endphp
                                <span style="font-weight: 800; color: {{ $color }}">
                                    {{ strtoupper($leave->leave_status) }}
                                </span>
                            </td>
                        </tr>
                        @empty
                        <tr><td colspan="3" style="text-align: center; color: var(--text-muted); padding: 40px;">Belum ada pengajuan.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
