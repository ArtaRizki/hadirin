@extends('layouts.app')

@section('title', 'Plotting Shift')

@section('extra_css')
<style>
    .plotting-container {
        overflow-x: auto;
        border-radius: 16px;
        border: 1px solid rgba(0,0,0,0.1);
    }
    .plotting-table {
        width: 100%;
        border-collapse: collapse;
        background: white;
    }
    .plotting-table th, .plotting-table td {
        border: 1px solid rgba(0,0,0,0.05);
        padding: 10px;
        text-align: center;
        min-width: 60px;
    }
    .plotting-table th:first-child, .plotting-table td:first-child {
        position: sticky;
        left: 0;
        background: white;
        z-index: 10;
        min-width: 200px;
        text-align: left;
        font-weight: 700;
    }
    .shift-select {
        width: 100%;
        padding: 5px;
        border-radius: 8px;
        border: 1px solid rgba(0,0,0,0.1);
        font-size: 0.75rem;
        cursor: pointer;
        background: rgba(0,0,0,0.02);
    }
    .shift-select:hover {
        background: white;
        border-color: var(--primary);
    }
    .is-weekend {
        background: rgba(239, 68, 68, 0.05) !important;
    }
    .is-today {
        background: rgba(59, 130, 246, 0.1) !important;
    }
</style>
@endsection

@section('content')
<div class="content-view fade-in">
    <header style="margin-bottom: 30px">
        <h1 style="font-size: 2.2rem; font-weight: 900; letter-spacing: -1px">Plotting Shift</h1>
        <p style="color: var(--text-muted); font-weight: 500">Atur jadwal shift harian anggota untuk bulan ini.</p>
    </header>

    <div class="card glass" style="margin-bottom: 20px; display: flex; align-items: center; justify-content: space-between;">
        <form action="{{ route('shifts.plotting') }}" method="GET" id="monthForm">
            <div style="display: flex; align-items: center; gap: 15px;">
                <label style="font-weight: 700;">Pilih Bulan:</label>
                <input type="month" name="month" value="{{ $month->format('Y-m') }}" onchange="document.getElementById('monthForm').submit()" 
                    style="padding: 10px 15px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.1); outline: none;" />
            </div>
        </form>
        <div style="font-size: 0.85rem; color: var(--text-muted);">
            <span style="display:inline-block; width:12px; height:12px; background:rgba(239, 68, 68, 0.1); margin-right:5px; vertical-align:middle; border-radius:3px;"></span> Weekend
            <span style="display:inline-block; width:12px; height:12px; background:rgba(59, 130, 246, 0.1); margin-left:15px; margin-right:5px; vertical-align:middle; border-radius:3px;"></span> Hari Ini
        </div>
    </div>

    <div class="card glass" style="padding: 0; overflow: hidden;">
        <div class="plotting-container">
            <table class="plotting-table">
                <thead>
                    <tr>
                        <th>Anggota</th>
                        @for($i = 1; $i <= $daysInMonth; $i++)
                            @php
                                $d = $month->copy()->day($i);
                                $isWeekend = $d->isWeekend();
                                $isToday = $d->isToday();
                            @endphp
                            <th class="{{ $isWeekend ? 'is-weekend' : '' }} {{ $isToday ? 'is-today' : '' }}">
                                <div style="font-size: 0.7rem; color: var(--text-muted);">{{ $d->isoFormat('ddd') }}</div>
                                <div>{{ $i }}</div>
                            </th>
                        @endfor
                    </tr>
                </thead>
                <tbody>
                    @foreach($users as $user)
                    <tr>
                        <td>
                            <div style="font-weight: 800;">{{ $user->name }}</div>
                            <div style="font-size: 0.7rem; color: var(--text-muted);">ID: {{ $user->employee_id }}</div>
                            <div style="font-size: 0.65rem; color: var(--primary); font-weight: 700;">Def: {{ $user->defaultShift->name ?? 'None' }}</div>
                        </td>
                        @for($i = 1; $i <= $daysInMonth; $i++)
                            @php
                                $d = $month->copy()->day($i);
                                $isWeekend = $d->isWeekend();
                                $isToday = $d->isToday();
                                $dateStr = $d->format('Y-m-d');
                                $plotted = isset($plottings[$user->id][$i]) ? $plottings[$user->id][$i][0] : null;
                                $currentShiftId = $plotted ? $plotted->shift_id : ($user->default_shift_id ?: '');
                            @endphp
                            <td class="{{ $isWeekend ? 'is-weekend' : '' }} {{ $isToday ? 'is-today' : '' }}">
                                <select class="shift-select" data-user="{{ $user->id }}" data-date="{{ $dateStr }}" onchange="savePlotting(this)">
                                    <option value="">Default</option>
                                    <option value="LIBUR" {{ $plotted === null && $user->default_shift_id === null ? 'selected' : '' }}>OFF</option>
                                    @foreach($shifts as $s)
                                        <option value="{{ $s->id }}" {{ $currentShiftId == $s->id ? 'selected' : '' }}>{{ $s->name }}</option>
                                    @endforeach
                                </select>
                            </td>
                        @endfor
                    </tr>
                    @endforeach
                </tbody>
            </table>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script>
function savePlotting(el) {
    const userId = el.dataset.user;
    const date = el.dataset.date;
    const shiftId = el.value;

    // Visual feedback
    el.style.opacity = '0.5';

    fetch('{{ route("shifts.plotting.save") }}', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'X-CSRF-TOKEN': '{{ csrf_token() }}'
        },
        body: JSON.stringify({
            user_id: userId,
            date: date,
            shift_id: shiftId
        })
    })
    .then(response => response.json())
    .then(data => {
        if(data.success) {
            el.style.borderColor = '#10b981'; // Green
        } else {
            el.style.borderColor = '#ef4444'; // Red
            alert('Gagal menyimpan plotting');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        el.style.borderColor = '#ef4444';
    })
    .finally(() => {
        el.style.opacity = '1';
        setTimeout(() => {
            el.style.borderColor = 'rgba(0,0,0,0.1)';
        }, 1000);
    });
}
</script>
@endsection
