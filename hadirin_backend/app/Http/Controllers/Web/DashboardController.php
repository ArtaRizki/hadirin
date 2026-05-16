<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $tenant = auth()->user()->tenant;
        $today = now()->toDateString();

        $attendances = Attendance::with('user')
            ->where('tenant_id', $tenant->id)
            ->whereDate('created_at', $today)
            ->orderBy('created_at', 'desc')
            ->get();

        $stats = [
            'present' => $attendances->whereIn('status', ['Tepat Waktu', 'Terlambat'])->count(),
            'late' => $attendances->where('status', 'Terlambat')->count(),
            'leave' => $attendances->whereIn('type', ['Izin', 'Sakit', 'Cuti'])->count(),
        ];

        return view('dashboard', compact('attendances', 'stats'));
    }
}
