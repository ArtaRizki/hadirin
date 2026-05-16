<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use Illuminate\Http\Request;

class LeaveController extends Controller
{
    public function index()
    {
        $leaves = Leave::with('user')->latest()->get();
        return view('leaves.index', compact('leaves'));
    }

    public function myLeaves()
    {
        $leaves = Leave::where('user_id', auth()->id())->latest()->get();
        return view('leaves.personal', compact('leaves'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required',
            'reason' => 'required',
            'lat_long' => 'required', // Ini adalah rentang tanggal di form
        ]);

        Leave::create([
            'user_id' => auth()->id(),
            'tenant_id' => auth()->user()->tenant_id,
            'type' => $request->type,
            'reason' => $request->reason,
            'lat_long' => $request->lat_long,
            'leave_status' => 'Menunggu Approval',
        ]);

        return redirect()->route('leaves.personal')->with('success', 'Permohonan izin berhasil dikirim.');
    }

    public function approve($id)
    {
        $leave = Leave::findOrFail($id);
        $leave->update(['leave_status' => 'Disetujui']);
        return back()->with('success', 'Leave approved.');
    }

    public function reject($id)
    {
        $leave = Leave::findOrFail($id);
        $leave->update(['leave_status' => 'Ditolak']);
        return back()->with('success', 'Leave rejected.');
    }
}
