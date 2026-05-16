<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\QuranLog;
use Illuminate\Http\Request;

class QuranController extends Controller
{
    public function index()
    {
        $logs = QuranLog::with(['teacher', 'student', 'master'])->latest()->get();
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
            'student_nis' => 'required',
            'quran_master_id' => 'required',
            'halaman_ayat' => 'nullable|string',
            'nilai' => 'nullable|string',
            'keterangan' => 'nullable|string'
        ]);

        QuranLog::create([
            'tenant_id' => auth()->user()->tenant_id,
            'user_id' => auth()->id(),
            'student_nis' => $request->student_nis,
            'quran_master_id' => $request->quran_master_id,
            'halaman_ayat' => $request->halaman_ayat,
            'nilai' => $request->nilai,
            'keterangan' => $request->keterangan
        ]);

        return redirect()->route('dashboard')->with('success', 'Setoran hafalan berhasil disimpan!');
    }
}
