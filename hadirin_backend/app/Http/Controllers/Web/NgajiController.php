<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\NgajiLog;
use Illuminate\Http\Request;

class NgajiController extends Controller
{
    public function index()
    {
        $logs = NgajiLog::with(['user', 'group'])->latest()->get();
        return view('ngaji.index', compact('logs'));
    }

    public function create()
    {
        $groups = \App\Models\NgajiGroup::where('tenant_id', auth()->user()->tenant_id)->get();
        return view('ngaji.create', compact('groups'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'ngaji_group_id' => 'required',
            'status' => 'required|string',
            'location' => 'nullable|string',
            'materi' => 'nullable|string',
        ]);

        NgajiLog::create([
            'tenant_id' => auth()->user()->tenant_id,
            'user_id' => auth()->id(),
            'ngaji_group_id' => $request->ngaji_group_id,
            'status' => $request->status,
            'location' => $request->location,
            'materi' => $request->materi,
        ]);

        return redirect()->route('dashboard')->with('success', 'Presensi Halaqah berhasil disimpan!');
    }
}
