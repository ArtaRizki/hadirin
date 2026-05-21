<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Leave;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Auth;

class LeaveController extends Controller
{
    public function index()
    {
        $leaves = Leave::with('user')->latest()->get();
        return view('leaves.index', compact('leaves'));
    }

    public function myLeaves()
    {
        $leaves = Leave::where('user_id', Auth::id())->latest()->get();
        return view('leaves.personal', compact('leaves'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required',
            'reason' => 'required',
            'lat_long' => 'required', // Ini adalah rentang tanggal di form
            'attachment' => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:2048',
        ]);

        /** @var \App\Models\User $user */
        $user = Auth::user();

        $photoUrl = '';
        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $empId = $user->employee_id ?: $user->id;
            $filename = 'lampiran_' . $empId . '_' . now()->format('YmdHis') . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('lampiran', $filename, 'public');
            $photoUrl = Storage::url($path);
        }

        Leave::create([
            'user_id' => $user->id,
            'tenant_id' => $user->tenant_id,
            'type' => $request->type,
            'reason' => $request->reason,
            'lat_long' => $request->lat_long,
            'photo_url' => $photoUrl,
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
