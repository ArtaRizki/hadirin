<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Briefing;
use App\Models\BriefingAttendance;
use Illuminate\Http\Request;

class BriefingController extends Controller
{
    public function index()
    {
        $briefings = Briefing::where('tenant_id', auth()->user()->tenant_id)
            ->withCount('attendances')->latest()->get();
        return view('briefings.index', compact('briefings'));
    }

    public function create()
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('briefings.index')->with('error', 'Akses ditolak.');
        }
        return view('briefings.create');
    }

    public function store(Request $request)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('briefings.index')->with('error', 'Akses ditolak.');
        }
        $request->validate([
            'title'          => 'required|string|max:255',
            'speaker_name'   => 'required|string|max:255',
            'scheduled_date' => 'required|date',
            'scheduled_time' => 'required',
            'description'    => 'nullable|string',
        ]);

        Briefing::create([
            'tenant_id'      => auth()->user()->tenant_id,
            'title'          => $request->title,
            'speaker_name'   => $request->speaker_name,
            'scheduled_date' => $request->scheduled_date,
            'scheduled_time' => $request->scheduled_time,
            'description'    => $request->description,
        ]);

        return redirect()->route('briefings.index')->with('success', 'Jadwal Briefing berhasil dibuat!');
    }

    public function edit($id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('briefings.index')->with('error', 'Akses ditolak.');
        }
        $briefing = Briefing::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        return view('briefings.edit', compact('briefing'));
    }

    public function update(Request $request, $id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('briefings.index')->with('error', 'Akses ditolak.');
        }
        $briefing = Briefing::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $request->validate([
            'title'          => 'required|string|max:255',
            'speaker_name'   => 'required|string|max:255',
            'scheduled_date' => 'required|date',
            'scheduled_time' => 'required',
            'description'    => 'nullable|string',
        ]);
        $briefing->update($request->only(['title', 'speaker_name', 'scheduled_date', 'scheduled_time', 'description']));
        return redirect()->route('briefings.index')->with('success', 'Data Briefing berhasil diperbarui!');
    }

    public function destroy($id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('briefings.index')->with('error', 'Akses ditolak.');
        }
        $briefing = Briefing::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $briefing->attendances()->delete();
        $briefing->delete();
        return redirect()->route('briefings.index')->with('success', 'Data Briefing berhasil dihapus!');
    }

    public function personal()
    {
        $today    = \Carbon\Carbon::today();
        $briefings = Briefing::where('tenant_id', auth()->user()->tenant_id)
            ->whereDate('scheduled_date', $today)
            ->with(['attendances' => function ($q) {
                $q->where('user_id', auth()->id());
            }])->get();
        return view('briefings.personal', compact('briefings'));
    }

    public function attend($id)
    {
        $briefing = Briefing::findOrFail($id);
        $exists = BriefingAttendance::where('briefing_id', $id)
            ->where('user_id', auth()->id())->exists();

        if ($exists) {
            return back()->with('error', 'Anda sudah melakukan presensi untuk rapat ini.');
        }

        BriefingAttendance::create([
            'briefing_id' => $id,
            'user_id'     => auth()->id(),
            'status'      => 'Hadir',
        ]);

        return back()->with('success', 'Presensi rapat berhasil disimpan!');
    }
}
