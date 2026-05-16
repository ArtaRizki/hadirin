<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use App\Models\ActivityAttendance;
use App\Models\User;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ActivityController extends Controller
{
    public function index(Request $request)
    {
        $tenant = $request->input('tenant');
        $activities = Activity::where('tenant_id', $tenant->id)
            ->orderBy('scheduled_at', 'desc')
            ->get()
            ->map(function ($a) {
                return [
                    'id_kegiatan'   => $a->id,
                    'nama_kegiatan' => $a->name,
                    'tipe'          => $a->type,
                    'tanggal_waktu' => $a->scheduled_at
                        ? Carbon::parse($a->scheduled_at)->format('Y-m-d H:i:s')
                        : null,
                    'deskripsi'     => $a->description,
                ];
            });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $activities]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'nama_kegiatan' => 'required',
            'tipe'          => 'required',
            'tanggal_waktu' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)
            ->where('employee_id', $request->id_admin)
            ->first();

        $activity = Activity::create([
            'id'           => 'KEG-' . time(),
            'tenant_id'    => $tenant->id,
            'name'         => $request->nama_kegiatan,
            'type'         => $request->tipe,
            'scheduled_at' => $request->tanggal_waktu,
            'description'  => $request->deskripsi,
            'created_by'   => $user ? $user->id : 1,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Jadwal berhasil ditambahkan.']);
    }

    public function edit(Request $request, $id)
    {
        $activity = Activity::findOrFail($id);

        if ($request->nama_kegiatan) $activity->name         = $request->nama_kegiatan;
        if ($request->tipe)          $activity->type         = $request->tipe;
        if ($request->tanggal_waktu) $activity->scheduled_at = $request->tanggal_waktu;
        if ($request->deskripsi)     $activity->description  = $request->deskripsi;
        $activity->save();

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Berhasil.']);
    }

    public function absen(Request $request)
    {
        $request->validate([
            'id_kegiatan'     => 'required',
            'id_karyawan'     => 'required',
            'status_kehadiran'=> 'nullable',
        ]);

        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)
            ->where('employee_id', $request->id_karyawan)
            ->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'User tidak ditemukan.'], 404);
        }

        ActivityAttendance::create([
            'activity_id' => $request->id_kegiatan,
            'user_id'     => $user->id,
            'status'      => $request->status_kehadiran ?? $request->status ?? 'Hadir',
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Absen kegiatan tersimpan.']);
    }
}
