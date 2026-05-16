<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\User;
use App\Models\Leave;
use App\Models\Feedback;
use App\Models\Verse;
use Carbon\Carbon;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index()
    {
        $user = auth()->user();
        $tenantId = $user->tenant_id;
        $today = Carbon::today('Asia/Makassar');

        // Stats for cards
        $stats = [
            'present' => Attendance::where('tenant_id', $tenantId)->whereDate('date', $today)->where('status', 'Hadir')->count(),
            'late' => Attendance::where('tenant_id', $tenantId)->whereDate('date', $today)->where('is_late', true)->count(),
            'leave' => Attendance::where('tenant_id', $tenantId)->whereDate('date', $today)->whereIn('status', ['Izin', 'Sakit'])->count(),
        ];

        // Verse of the Day
        $verse = Verse::where('tenant_id', $tenantId)->inRandomOrder()->first();

        // Admin Specific Data
        $adminData = [];
        if ($user->role == 'admin' || $user->role == 'superadmin') {
            $adminData = [
                'pending_leaves' => Leave::where('tenant_id', $tenantId)->where('status', 'pending')->count(),
                'new_feedback' => Feedback::where('tenant_id', $tenantId)->whereDate('created_at', '>', Carbon::now()->subDays(3))->count(),
                'recent_attendances' => Attendance::where('tenant_id', $tenantId)->with('user')->latest()->take(5)->get(),
            ];
        }

        return view('dashboard', compact('stats', 'verse', 'adminData'));
    }
}
