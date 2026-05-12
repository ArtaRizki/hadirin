<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Attendance;
use App\Models\User;
use Illuminate\Http\Request;
use Carbon\Carbon;

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
        ]);

        $tenant = $request->tenant;
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->firstOrFail();

        // Save as attendance entry with type 'Izin/Sakit/Cuti'
        Attendance::create([
            'tenant_id' => $tenant->id,
            'user_id' => $user->id,
            'type' => $request->tipe_izin,
            'timestamp' => Carbon::now(),
            'status' => $request->rentang_tanggal,
            'reason' => $request->alasan,
            'leave_status' => 'Pending',
            'is_valid' => true,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Sent']);
    }

    public function history(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'id_karyawan' => 'required',
        ]);

        $tenant = $request->tenant;
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->firstOrFail();

        $history = Attendance::where('user_id', $user->id)
                            ->whereIn('type', ['Izin', 'Sakit', 'Cuti'])
                            ->orderBy('timestamp', 'desc')
                            ->get();

        return response()->json($history);
    }
}
