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
            <form action="{{ route('leaves.store') }}" method="POST" enctype="multipart/form-data">
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
                    <input type="text" id="date_range" name="lat_long" placeholder="Contoh: 12 Mei - 14 Mei 2026" required />
                </div>
                <div class="input-group">
                    <label>Alasan</label>
                    <textarea name="reason" rows="4" style="width: 100%; padding: 12px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none; font-family: inherit;" placeholder="Jelaskan alasan Anda..." required></textarea>
                </div>
                
                <!-- Premium Attachment Input -->
                <div class="input-group" style="margin-bottom: 20px;">
                    <label style="display: block; font-weight: 700; margin-bottom: 8px; color: var(--text-main);">Lampiran / Dokumen Pendukung (Opsional)</label>
                    <div style="position: relative; display: flex; align-items: center; justify-content: center; border: 2px dashed rgba(0,0,0,0.1); padding: 20px; border-radius: 12px; text-align: center; cursor: pointer; transition: all 0.3s ease; background: rgba(0,0,0,0.01);" onmouseover="this.style.borderColor='var(--primary)'; this.style.background='rgba(22, 163, 74, 0.02)'" onmouseout="this.style.borderColor='rgba(0,0,0,0.1)'; this.style.background='rgba(0,0,0,0.01)'">
                        <input type="file" name="attachment" accept="image/*,application/pdf" style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; opacity: 0; cursor: pointer;" onchange="document.getElementById('file-chosen').textContent = this.files[0] ? this.files[0].name : 'Pilih file atau seret ke sini'" />
                        <div>
                            <i data-lucide="upload-cloud" style="width: 32px; height: 32px; color: var(--text-muted); margin-bottom: 8px;"></i>
                            <div id="file-chosen" style="font-size: 0.85rem; font-weight: 600; color: var(--text-main);">Pilih file (JPG, PNG, PDF)</div>
                            <div style="font-size: 0.75rem; color: var(--text-muted); margin-top: 4px;">Maksimal 2 MB</div>
                        </div>
                    </div>
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
                            <th>Lampiran</th>
                            <th>Status</th>
                        </tr>
                    </thead>
                    <tbody>
                        @forelse($leaves as $leave)
                        <tr>
                            <td>{{ $leave->lat_long }}</td>
                            <td><span class="badge-tipe">{{ $leave->type }}</span></td>
                            <td>
                                @if($leave->photo_url && $leave->photo_url != 'No Photo' && !str_starts_with($leave->photo_url, 'Error'))
                                <a href="{{ $leave->photo_url }}" target="_blank" style="font-size: 0.75rem; color: var(--primary); font-weight: 700; text-decoration: none; display: flex; align-items: center; gap: 4px;">
                                    <i data-lucide="file-text" style="width: 14px; height: 14px;"></i> Lihat
                                </a>
                                @else
                                <span style="color: var(--text-muted); font-size: 0.75rem;">-</span>
                                @endif
                            </td>
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
                        <tr><td colspan="4" style="text-align: center; color: var(--text-muted); padding: 40px;">Belum ada pengajuan.</td></tr>
                        @endforelse
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection

@push('styles')
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/flatpickr/dist/flatpickr.min.css">
<style>
    .flatpickr-calendar {
        font-family: 'Inter', sans-serif;
        border-radius: 12px;
        box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        border: none;
    }
</style>
@endpush

@push('scripts')
<script src="https://cdn.jsdelivr.net/npm/flatpickr"></script>
<script src="https://npmcdn.com/flatpickr/dist/l10n/id.js"></script>
<script>
    document.addEventListener("DOMContentLoaded", function() {
        flatpickr("#date_range", {
            mode: "range",
            dateFormat: "d M Y",
            locale: "id",
            minDate: "today",
            disableMobile: "true"
        });
    });
</script>
@endpush
