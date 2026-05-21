<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\QuranLog;
use Illuminate\Http\Request;

class QuranController extends Controller
{
    public function index()
    {
        $logs = QuranLog::with(['user', 'quranMaster'])->where('tenant_id', auth()->user()->tenant_id)->latest()->get();
        return view('quran.index', compact('logs'));
    }

    public function create()
    {
        $students = \App\Models\QuranStudent::where('tenant_id', auth()->user()->tenant_id)->get();
        $masters = \App\Models\QuranMaster::where('tenant_id', auth()->user()->tenant_id)->get();
        return view('quran.create', compact('students', 'masters'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'student_nis'    => 'required',
            'quran_master_id'=> 'required',
            'halaman_ayat'   => 'nullable|string',
            'nilai'          => 'nullable|string',
            'keterangan'     => 'nullable|string',
        ]);

        QuranLog::create([
            'tenant_id'      => auth()->user()->tenant_id,
            'user_id'        => auth()->id(),
            'student_nis'    => $request->student_nis,
            'quran_master_id'=> $request->quran_master_id,
            'halaman_ayat'   => $request->halaman_ayat,
            'nilai'          => $request->nilai,
            'keterangan'     => $request->keterangan,
        ]);

        return redirect()->route('quran.index')->with('success', 'Setoran hafalan berhasil disimpan!');
    }

    public function edit($id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('quran.index')->with('error', 'Akses ditolak.');
        }
        $log      = QuranLog::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $students = \App\Models\QuranStudent::where('tenant_id', auth()->user()->tenant_id)->get();
        $masters  = \App\Models\QuranMaster::where('tenant_id', auth()->user()->tenant_id)->get();
        return view('quran.edit', compact('log', 'students', 'masters'));
    }

    public function update(Request $request, $id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('quran.index')->with('error', 'Akses ditolak.');
        }
        $log = QuranLog::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $request->validate([
            'student_nis'    => 'required',
            'quran_master_id'=> 'required',
            'halaman_ayat'   => 'nullable|string',
            'nilai'          => 'nullable|string',
            'keterangan'     => 'nullable|string',
        ]);
        $log->update($request->only(['student_nis', 'quran_master_id', 'halaman_ayat', 'nilai', 'keterangan']));
        return redirect()->route('quran.index')->with('success', 'Data setoran berhasil diperbarui!');
    }

    public function destroy($id)
    {
        if (auth()->user()->role != 'admin' && auth()->user()->role != 'superadmin') {
            return redirect()->route('quran.index')->with('error', 'Akses ditolak.');
        }
        $log = QuranLog::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $log->delete();
        return redirect()->route('quran.index')->with('success', 'Data setoran berhasil dihapus!');
    }
}
