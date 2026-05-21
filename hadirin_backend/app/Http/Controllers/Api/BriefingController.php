<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Briefing;
use App\Models\BriefingAttendance;
use App\Models\User;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\Storage;

class BriefingController extends Controller
{
    public function storeAttendance(Request $request)
    {
        $request->validate([
            'id_karyawan'      => 'required',
            'status_kehadiran' => 'nullable',
            'catatan'          => 'nullable',
            'foto_base64'      => 'nullable',
        ]);

        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)
            ->where('employee_id', $request->id_karyawan)
            ->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'Karyawan tidak ditemukan.'], 404);
        }

        // Find or create today's briefing session
        $today = Carbon::today();
        $briefing = Briefing::where('tenant_id', $tenant->id)
            ->whereDate('scheduled_date', $today)
            ->first();

        if (!$briefing) {
            $briefing = Briefing::create([
                'tenant_id'      => $tenant->id,
                'title'          => 'Briefing Harian ' . $today->format('d-m-Y'),
                'speaker_name'   => 'Koordinator',
                'scheduled_date' => $today,
                'scheduled_time' => Carbon::now()->format('H:i:s'),
                'description'    => 'Sesi briefing harian otomatis.',
            ]);
        }

        // Check if attendance already exists
        $exists = BriefingAttendance::where('briefing_id', $briefing->id)
            ->where('user_id', $user->id)
            ->first();

        if ($exists) {
            return response()->json(['code' => 400, 'status' => 'error', 'message' => 'Anda sudah melakukan presensi briefing hari ini.'], 400);
        }

        $fotoUrl = '';
        if ($request->foto_base64 && strlen($request->foto_base64) > 0) {
            try {
                $imgData = base64_decode($request->foto_base64);
                $filename = 'briefing_' . $user->employee_id . '_' . now()->format('YmdHis') . '.jpg';
                $path = 'briefing/' . $filename;
                Storage::disk('public')->put($path, $imgData);
                $fotoUrl = Storage::url($path);
            } catch (\Exception $e) {
                // Return fallback error or ignore
            }
        }

        BriefingAttendance::create([
            'briefing_id' => $briefing->id,
            'user_id'     => $user->id,
            'status'      => $request->status_kehadiran ?? 'Hadir',
            'foto'        => $fotoUrl,
            'catatan'     => $request->catatan,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Presensi briefing berhasil disimpan.']);
    }

    public function getAttendances(Request $request)
    {
        $tenant  = $request->input('tenant');
        $idKaryawan = $request->input('id_karyawan');
        $isAdmin = $request->input('is_admin', false);

        $query = BriefingAttendance::with(['briefing', 'user'])
            ->whereHas('briefing', function ($q) use ($tenant) {
                $q->where('tenant_id', $tenant->id);
            })
            ->orderBy('created_at', 'desc');

        if (!$isAdmin && $idKaryawan && $idKaryawan !== 'SEMUA') {
            $user = User::where('tenant_id', $tenant->id)
                ->where('employee_id', $idKaryawan)
                ->first();
            if ($user) {
                $query->where('user_id', $user->id);
            }
        }

        $attendances = $query->get()->map(function ($att) {
            return [
                'id'               => $att->id,
                'id_karyawan'      => $att->user->employee_id ?? '-',
                'nama_karyawan'    => $att->user->name ?? '-',
                'status_kehadiran' => $att->status,
                'foto'             => $att->foto,
                'catatan'          => $att->catatan,
                'waktu'            => $att->created_at->format('Y-m-d H:i:s'),
                'tanggal'          => $att->briefing->scheduled_date->format('Y-m-d'),
            ];
        });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $attendances]);
    }

    public function updateAttendance(Request $request)
    {
        $request->validate([
            'id'               => 'required|exists:briefing_attendances,id',
            'status_kehadiran' => 'required',
            'catatan'          => 'nullable',
            'foto_base64'      => 'nullable',
        ]);

        $tenant = $request->input('tenant');
        $att = BriefingAttendance::whereHas('briefing', function ($q) use ($tenant) {
            $q->where('tenant_id', $tenant->id);
        })->findOrFail($request->id);

        $fotoUrl = $att->foto;
        if ($request->foto_base64 && strlen($request->foto_base64) > 0) {
            try {
                // Delete old photo if exists
                if ($att->foto) {
                    $oldPath = str_replace('/storage/', '', $att->foto);
                    Storage::disk('public')->delete($oldPath);
                }

                $imgData = base64_decode($request->foto_base64);
                $filename = 'briefing_' . $att->user->employee_id . '_' . now()->format('YmdHis') . '.jpg';
                $path = 'briefing/' . $filename;
                Storage::disk('public')->put($path, $imgData);
                $fotoUrl = Storage::url($path);
            } catch (\Exception $e) {
                // Ignore photo save error or use old photo
            }
        }

        $att->update([
            'status'  => $request->status_kehadiran,
            'foto'    => $fotoUrl,
            'catatan' => $request->catatan,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Presensi briefing berhasil diperbarui.']);
    }

    public function destroyAttendance(Request $request)
    {
        $request->validate([
            'id' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $att = BriefingAttendance::whereHas('briefing', function ($q) use ($tenant) {
            $q->where('tenant_id', $tenant->id);
        })->findOrFail($request->id);

        // Delete photo if exists
        if ($att->foto) {
            try {
                $path = str_replace('/storage/', '', $att->foto);
                Storage::disk('public')->delete($path);
            } catch (\Exception $e) {
                // Ignore delete error
            }
        }

        $att->delete();

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Presensi briefing berhasil dihapus.']);
    }
}
