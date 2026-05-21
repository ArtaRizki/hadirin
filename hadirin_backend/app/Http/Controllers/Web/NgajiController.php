<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\NgajiLog;
use App\Models\NgajiGroup;
use App\Models\User;
use Illuminate\Http\Request;

class NgajiController extends Controller
{
    public function index()
    {
        $logs = NgajiLog::with(['user', 'group'])->where('tenant_id', auth()->user()->tenant_id)->latest()->get();
        return view('ngaji.index', compact('logs'));
    }

    public function create()
    {
        $groups = NgajiGroup::where('tenant_id', auth()->user()->tenant_id)->get();
        $users  = User::where('tenant_id', auth()->user()->tenant_id)->orderBy('name')->get();
        return view('ngaji.create', compact('groups', 'users'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'ngaji_group_id' => 'required',
            'status'         => 'required|string',
            'location'       => 'nullable|string',
            'materi'         => 'nullable|string',
        ]);

        NgajiLog::create([
            'tenant_id'      => auth()->user()->tenant_id,
            'user_id'        => $request->user_id ?? auth()->id(),
            'ngaji_group_id' => $request->ngaji_group_id,
            'status'         => $request->status,
            'location'       => $request->location,
            'materi'         => $request->materi,
        ]);

        return redirect()->route('ngaji.index')->with('success', 'Presensi Halaqah berhasil disimpan!');
    }

    public function edit($id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('ngaji.index')->with('error', 'Akses ditolak.');
        }
        $log    = NgajiLog::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $groups = NgajiGroup::where('tenant_id', auth()->user()->tenant_id)->get();
        $users  = User::where('tenant_id', auth()->user()->tenant_id)->orderBy('name')->get();
        return view('ngaji.edit', compact('log', 'groups', 'users'));
    }

    public function update(Request $request, $id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('ngaji.index')->with('error', 'Akses ditolak.');
        }
        $log = NgajiLog::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $request->validate([
            'ngaji_group_id' => 'required',
            'status'         => 'required|string',
            'location'       => 'nullable|string',
            'materi'         => 'nullable|string',
        ]);
        $log->update($request->only(['user_id', 'ngaji_group_id', 'status', 'location', 'materi']));
        return redirect()->route('ngaji.index')->with('success', 'Data Halaqah berhasil diperbarui!');
    }

    public function destroy($id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('ngaji.index')->with('error', 'Akses ditolak.');
        }
        $log = NgajiLog::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $log->delete();
        return redirect()->route('ngaji.index')->with('success', 'Data Halaqah berhasil dihapus!');
    }
}
