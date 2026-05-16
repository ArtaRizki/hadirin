<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NgajiGroup;
use App\Models\NgajiLog;
use App\Models\User;
use Illuminate\Http\Request;

class NgajiController extends Controller
{
    public function groups(Request $request)
    {
        $tenant = $request->input('tenant');
        $groups = NgajiGroup::where('tenant_id', $tenant->id)->get()->pluck('name');
        return response()->json(['code' => 200, 'status' => 'success', 'message' => $groups]);
    }

    public function storeGroup(Request $request)
    {
        $request->validate(['nama_kelompok' => 'required']);
        $tenant = $request->input('tenant');

        NgajiGroup::create([
            'tenant_id' => $tenant->id,
            'name'      => $request->nama_kelompok,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Kelompok berhasil ditambahkan.']);
    }

    public function storeLog(Request $request)
    {
        $request->validate([
            'id_guru'          => 'required',
            'nama_kelompok'    => 'required',
        ]);

        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)
            ->where('employee_id', $request->id_guru)
            ->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'Guru tidak ditemukan.'], 404);
        }

        $group = NgajiGroup::where('tenant_id', $tenant->id)
            ->where('name', $request->nama_kelompok)
            ->first();

        NgajiLog::create([
            'tenant_id'       => $tenant->id,
            'user_id'         => $user->id,
            'ngaji_group_id'  => $group ? $group->id : null,
            'location'        => $request->lokasi,
            'materi'          => $request->materi_keterangan,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Laporan pengajian tersimpan.']);
    }

    public function getLogs(Request $request)
    {
        $tenant  = $request->input('tenant');
        $idGuru  = $request->input('id_guru');

        $query = NgajiLog::with(['user', 'group'])
            ->where('tenant_id', $tenant->id)
            ->orderBy('created_at', 'desc');

        if ($idGuru && $idGuru !== 'SEMUA') {
            $user = User::where('tenant_id', $tenant->id)
                ->where('employee_id', $idGuru)
                ->first();
            if ($user) {
                $query->where('user_id', $user->id);
            }
        }

        $logs = $query->get()->map(function ($log) {
            return [
                'waktu'    => $log->created_at->format('Y-m-d H:i:s'),
                'id_guru'  => $log->user->employee_id ?? '-',
                'kelompok' => $log->group->name ?? '-',
                'lokasi'   => $log->location,
                'materi'   => $log->materi,
            ];
        });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $logs]);
    }
}
