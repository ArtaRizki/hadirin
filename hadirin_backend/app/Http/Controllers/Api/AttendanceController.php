<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use App\Models\OfficeConfig;
use App\Models\User;
use App\Models\Tenant;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class AttendanceController extends Controller
{
    public function absen(Request $request)
    {
        $request->validate([
            'client_id'        => 'required',
            'id_karyawan'      => 'required',
            'tipe_absen'       => 'required',
            'lat_long'         => 'required',
            'foto_base64'      => 'nullable',
            'client_timestamp' => 'nullable',
        ]);

        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)
            ->where('employee_id', $request->id_karyawan)
            ->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'User tidak ditemukan.'], 404);
        }

        // 1. Geofencing
        $config = OfficeConfig::where('tenant_id', $tenant->id)->first();
        if ($config && $config->latitude != 0 && $config->longitude != 0) {
            $coords  = explode(',', $request->lat_long);
            $userLat = (float) trim($coords[0]);
            $userLng = (float) trim($coords[1] ?? 0);
            $distance = $this->calculateDistance($config->latitude, $config->longitude, $userLat, $userLng);
            if ($distance > $config->radius) {
                $jarakTeks  = $distance >= 1000 ? number_format($distance / 1000, 2) . ' km' : round($distance) . ' m';
                $radiusTeks = $config->radius >= 1000 ? number_format($config->radius / 1000, 2) . ' km' : $config->radius . ' m';
                return response()->json([
                    'code'    => 403,
                    'status'  => 'error',
                    'message' => "Anda berada di luar area kantor ({$jarakTeks} dari titik). Radius absen: {$radiusTeks}.",
                ], 403);
            }
        }

        // 2. Validasi waktu (maks. 5 menit selisih server)
        $now = Carbon::now();
        if ($request->client_timestamp) {
            $diffMinutes = abs($now->timestamp * 1000 - $request->client_timestamp) / (1000 * 60);
            if ($diffMinutes > 5) {
                return response()->json([
                    'code'    => 403,
                    'status'  => 'error',
                    'message' => "Jam HP tidak akurat (selisih " . round($diffMinutes) . " menit). Aktifkan 'Tanggal & Waktu Otomatis'.",
                ], 403);
            }
        }

        // 3. Duplikat check
        $today  = $now->toDateString();
        $exists = Attendance::where('user_id', $user->id)
            ->whereDate('created_at', $today)
            ->where('type', $request->tipe_absen)
            ->where('leave_status', 'Approved')
            ->exists();

        if ($exists) {
            return response()->json([
                'code'    => 400,
                'status'  => 'error',
                'message' => "Anda sudah absen {$request->tipe_absen} hari ini.",
            ], 400);
        }

        // 4. Status terlambat
        $status = 'Tepat Waktu';
        if ($request->tipe_absen === 'Masuk' && $config && $config->limit_checkin) {
            $limit = Carbon::createFromFormat('H:i:s', $config->limit_checkin);
            if ($now->greaterThan($limit)) {
                $status = 'Terlambat';
            }
        }

        // 5. Foto (base64 → storage)
        $photoUrl = 'No Photo';
        if ($request->foto_base64 && strlen($request->foto_base64) > 0) {
            try {
                $imgData  = base64_decode($request->foto_base64);
                $filename = 'absen_' . $user->employee_id . '_' . $now->format('YmdHis') . '.jpg';
                $path     = 'photos/' . $filename;
                Storage::disk('public')->put($path, $imgData);
                $photoUrl = Storage::url($path);
            } catch (\Exception $e) {
                $photoUrl = 'Error: ' . $e->getMessage();
            }
        }

        // 6. Simpan
        Attendance::create([
            'tenant_id'    => $tenant->id,
            'user_id'      => $user->id,
            'type'         => $request->tipe_absen,
            'lat_long'     => $request->lat_long,
            'photo_url'    => $photoUrl,
            'status'       => $status,
            'is_valid'     => true,
            'leave_status' => 'Approved',
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Absen berhasil dicatat.']);
    }

    public function getHistory(Request $request)
    {
        $request->validate(['client_id' => 'required', 'id' => 'required']);

        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id)->first();

        if (!$user && $request->id !== 'admin') {
            return response()->json([]);
        }

        $query = Attendance::where('tenant_id', $tenant->id);
        if ($request->id !== 'admin') {
            $query->where('user_id', $user->id);
        }

        $history = $query->orderBy('created_at', 'desc')
            ->limit(50)
            ->get()
            ->map(function ($item) {
                return [
                    'waktu'      => $item->created_at->format('Y-m-d H:i:s'),
                    'tipe'       => $item->type,
                    'lat_long'   => $item->lat_long,
                    'foto'       => $item->photo_url,
                    'biometrik'  => $item->is_valid ? 'Valid' : 'Invalid',
                    'status'     => $item->status,
                ];
            });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $history]);
    }

    public function cekStatusHariIni(Request $request)
    {
        $tenant = $request->input('tenant');
        $user   = User::where('tenant_id', $tenant->id)
            ->where('employee_id', $request->id_karyawan)
            ->first();

        if (!$user) {
            return response()->json(['code' => 200, 'status' => 'success', 'message' => false]);
        }

        $hadir = Attendance::where('user_id', $user->id)
            ->whereDate('created_at', now()->toDateString())
            ->where('leave_status', 'Approved')
            ->exists();

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $hadir]);
    }

    public function dashboardStats(Request $request)
    {
        $tenant = $request->input('tenant');
        $today  = now()->toDateString();

        $records = Attendance::where('tenant_id', $tenant->id)
            ->whereDate('created_at', $today)
            ->get();

        $present = $records->whereIn('status', ['Tepat Waktu', 'Terlambat'])->count();
        $late    = $records->where('status', 'Terlambat')->count();
        $leave   = $records->whereIn('type', ['Izin', 'Sakit', 'Cuti'])->count();

        // Trend 7 hari
        $trendLabels = [];
        $trendValues = [];
        for ($d = 6; $d >= 0; $d--) {
            $date = now()->subDays($d)->toDateString();
            $trendLabels[] = now()->subDays($d)->format('d M');
            $trendValues[] = Attendance::where('tenant_id', $tenant->id)
                ->whereDate('created_at', $date)
                ->whereIn('status', ['Tepat Waktu', 'Terlambat'])
                ->count();
        }

        return response()->json([
            'present'      => $present,
            'leave'        => $leave,
            'late'         => $late,
            'trendLabels'  => $trendLabels,
            'trendValues'  => $trendValues,
        ]);
    }

    public function monthlyReport(Request $request)
    {
        $tenant = $request->input('tenant');
        $month  = $request->input('bulan', now()->month);
        $year   = $request->input('tahun', now()->year);

        $users = User::where('tenant_id', $tenant->id)->get();
        $report = [];

        foreach ($users as $user) {
            $records = Attendance::where('user_id', $user->id)
                ->whereMonth('created_at', $month)
                ->whereYear('created_at', $year)
                ->get();

            $report[] = [
                'id'       => $user->employee_id,
                'nama'     => $user->name,
                'hadir'    => $records->whereIn('status', ['Tepat Waktu', 'Terlambat'])->count(),
                'terlambat'=> $records->where('status', 'Terlambat')->count(),
                'izin'     => $records->where('type', 'Izin')->count(),
                'sakit'    => $records->where('type', 'Sakit')->count(),
                'cuti'     => $records->where('type', 'Cuti')->count(),
            ];
        }

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $report]);
    }

    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $R    = 6371000;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a    = sin($dLat / 2) * sin($dLat / 2) +
                cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
                sin($dLon / 2) * sin($dLon / 2);
        $c    = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $R * $c;
    }
}
