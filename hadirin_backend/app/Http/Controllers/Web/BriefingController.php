<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Briefing;
use Illuminate\Http\Request;

class BriefingController extends Controller
{
    public function index()
    {
        $briefings = Briefing::withCount('attendances')->latest()->get();
        return view('briefings.index', compact('briefings'));
    }

    public function personal()
    {
        $today = \Carbon\Carbon::today();
        
        $briefings = Briefing::where('tenant_id', auth()->user()->tenant_id)
            ->whereDate('scheduled_date', $today)
            ->with(['attendances' => function($q) {
                $q->where('user_id', auth()->id());
            }])
            ->get();

        return view('briefings.personal', compact('briefings'));
    }

    public function attend($id)
    {
        $briefing = Briefing::findOrFail($id);

        // Check if already attended
        $exists = \App\Models\BriefingAttendance::where('briefing_id', $id)
            ->where('user_id', auth()->id())
            ->exists();

        if ($exists) {
            return back()->with('error', 'Anda sudah melakukan presensi untuk rapat ini.');
        }

        \App\Models\BriefingAttendance::create([
            'briefing_id' => $id,
            'user_id' => auth()->id(),
            'status' => 'Hadir'
        ]);

        return back()->with('success', 'Presensi rapat berhasil disimpan!');
    }
}
