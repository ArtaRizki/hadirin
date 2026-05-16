<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class LeaveController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'id_karyawan' => 'required',
            'tipe_izin' => 'required',
            'rentang_tanggal' => 'required',
            'alasan' => 'nullable',
            'foto_base64' => 'nullable',
            'guru_pengganti' => 'nullable',
            'is_admin' => 'nullable|boolean',
        ]);

        $tenant = $request->input('tenant');
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->firstOrFail();

        $fotoUrl = '';
        if ($request->foto_base64 && strlen($request->foto_base64) > 0) {
            try {
                $imgData = base64_decode($request->foto_base64);
                $filename = 'lampiran_' . $user->employee_id . '_' . now()->format('YmdHis') . '.jpg';
                $path = 'lampiran/' . $filename;
                Storage::disk('public')->put($path, $imgData);
                $fotoUrl = Storage::url($path);
            } catch (\Exception $e) {
                $fotoUrl = 'Error GDrive: ' . $e->getMessage();
            }
        }

        Attendance::create([
            'tenant_id' => $tenant->id,
            'user_id' => $user->id,
            'type' => $request->tipe_izin,
            'timestamp' => Carbon::now(),
            'lat_long' => $request->rentang_tanggal, // using lat_long to store rentang tanggal like in legacy
            'photo_url' => $fotoUrl,
            'status' => 'Valid',
            'reason' => $request->alasan,
            'leave_status' => $request->is_admin ? 'Disetujui' : 'Menunggu Approval',
            'substitute_teacher' => $request->guru_pengganti ?? '-',
            'is_valid' => true,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Sent']);
    }

    public function history(Request $request)
    {
        $request->validate([
            'id_karyawan' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $isAdmin = $request->input('is_admin', false);
        
        $query = Attendance::with('user')
            ->where('tenant_id', $tenant->id)
            ->whereIn('type', ['Izin', 'Sakit', 'Cuti'])
            ->orderBy('created_at', 'desc');

        if (!$isAdmin) {
            $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->first();
            if ($user) {
                $query->where('user_id', $user->id);
            }
        }

        $history = $query->get()->map(function ($item) {
            return [
                'waktu_pengajuan' => $item->created_at->format('Y-m-d H:i:s'),
                'id_karyawan' => $item->user->employee_id ?? '-',
                'nama' => $item->user->name ?? '-',
                'no_hp' => $item->user->phone ?? '',
                'tipe' => $item->type,
                'rentang' => $item->lat_long, // using lat_long for rentang date mapping legacy
                'foto' => $item->photo_url,
                'alasan' => $item->reason,
                'status' => $item->leave_status,
                'guru_pengganti' => $item->substitute_teacher ?? '-',
            ];
        });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $history]);
    }

    public function approvals(Request $request)
    {
        $tenant = $request->input('tenant');
        
        $approvals = Attendance::with('user')
            ->where('tenant_id', $tenant->id)
            ->whereIn('type', ['Izin', 'Sakit', 'Cuti'])
            ->where('leave_status', 'Menunggu Approval')
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($item) {
                return [
                    'waktu_pengajuan' => $item->created_at->format('Y-m-d H:i:s'),
                    'id_karyawan' => $item->user->employee_id ?? '-',
                    'nama' => $item->user->name ?? '-',
                    'no_hp' => $item->user->phone ?? '',
                    'tipe' => $item->type,
                    'rentang' => $item->lat_long, // mapping legacy
                    'foto' => $item->photo_url,
                    'alasan' => $item->reason,
                    'guru_pengganti' => $item->substitute_teacher ?? '-',
                    'row_index' => $item->id, // Use ID as row_index mapping
                ];
            });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $approvals]);
    }

    public function updateStatus(Request $request)
    {
        $request->validate([
            'row_index' => 'required', // This is attendance ID
            'new_status' => 'required'
        ]);

        $tenant = $request->input('tenant');
        $attendance = Attendance::where('tenant_id', $tenant->id)->where('id', $request->row_index)->first();

        if ($attendance) {
            $attendance->update(['leave_status' => $request->new_status]);
            return response()->json(['code' => 200, 'status' => 'success', 'message' => true]);
        }

        return response()->json(['code' => 404, 'status' => 'error', 'message' => false], 404);
    }
}
