@extends('layouts.app')

@section('title', 'Daftar Masukan')

@section('content')
<div class="content-view">
    <header style="margin-bottom: 30px;">
        <h1 style="font-size: 2rem; font-weight: 800; color: var(--text-main);">Lihat Masukan</h1>
        <p style="color: var(--text-muted);">Daftar kritik dan saran dari guru/staff.</p>
    </header>

    <div class="card glass">
        <div class="table-container">
            <table>
                <thead>
                    <tr>
                        <th>Tanggal</th>
                        <th>Pengirim</th>
                        <th>Tipe</th>
                        <th>Isi Masukan</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($feedbacks as $item)
                    <tr>
                        <td data-label="Tanggal">{{ $item->created_at->format('d/m/Y H:i') }}</td>
                        <td data-label="Pengirim">
                            <strong>{{ $item->user->name }}</strong><br>
                            <small>{{ $item->user->employee_id }}</small>
                        </td>
                        <td data-label="Tipe">
                            <span class="badge-tipe {{ $item->type == 'Kritik' ? 'badge-danger' : 'badge-success' }}">
                                {{ $item->type }}
                            </span>
                        </td>
                        <td data-label="Isi Masukan">
                            <div style="max-width: 400px; white-space: normal; line-height: 1.5;">
                                {{ $item->content }}
                            </div>
                        </td>
                    </tr>
                    @empty
                    <tr>
                        <td colspan="4" class="text-center">Belum ada masukan yang masuk.</td>
                    </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection
