<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Attendance;
use App\Models\User;
use App\Models\Tenant;
use App\Models\OfficeConfig;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    public function absen(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'id_karyawan' => 'required',
            'tipe_absen' => 'required', // Masuk, Pulang
            'lat_long' => 'required',
            'foto_base64' => 'nullable',
            'client_timestamp' => 'nullable',
        ]);

        $tenant = Tenant::findOrFail(strtoupper($request->client_id));
        $user = User::where('tenant_id', $tenant->id)
                    ->where('employee_id', $request->id_karyawan)
                    ->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'User tidak ditemukan.'], 404);
        }

        // 1. Geofencing
        $config = OfficeConfig::where('tenant_id', $tenant->id)->first();
        if ($config) {
            $coords = explode(',', $request->lat_long);
            $userLat = (float) trim($coords[0]);
            $userLng = (float) trim($coords[1]);

            $distance = $this->calculateDistance($config->latitude, $config->longitude, $userLat, $userLng);
            if ($distance > $config->radius) {
                return response()->json([
                    'code' => 403,
                    'status' => 'error',
                    'message' => "Anda berada di luar area kantor (" . round($distance) . "m dari titik). Radius absen: " . $config->radius . "m."
                ], 403);
            }
        }

        // 2. Time Validation (similar to GAS)
        $now = Carbon::now();
        if ($request->client_timestamp) {
            $diffMinutes = abs($now->timestamp * 1000 - $request->client_timestamp) / (1000 * 60);
            if ($diffMinutes > 5) {
                return response()->json([
                    'code' => 403,
                    'status' => 'error',
                    'message' => "Jam HP Anda tidak akurat (selisih " . round($diffMinutes) . " menit)."
                ], 403);
            }
        }

        // 3. Duplicate Check
        $today = $now->toDateString();
        $exists = Attendance::where('user_id', $user->id)
                            ->whereDate('timestamp', $today)
                            ->where('type', $request->tipe_absen)
                            ->where('leave_status', 'Approved') // Or similar check
                            ->exists();
        
        if ($exists) {
            return response()->json([
                'code' => 400,
                'status' => 'error',
                'message' => "Anda sudah melakukan absen " . $request->tipe_absen . " hari ini."
            ], 400);
        }

        // 4. Status (Late check)
        $status = 'Tepat Waktu';
        if ($request->tipe_absen === 'Masuk' && $config) {
            $limit = Carbon::createFromFormat('H:i:s', $config->limit_checkin);
            if ($now->greaterThan($limit)) {
                $status = 'Terlambat';
            }
        }

        // 5. Photo Storage (Placeholder for now)
        $photoUrl = 'No Photo';
        if ($request->foto_base64) {
            // Implement storage logic here
            $photoUrl = 'storage/photos/example.jpg'; 
        }

        // 6. Save Log
        Attendance::create([
            'tenant_id' => $tenant->id,
            'user_id' => $user->id,
            'type' => $request->tipe_absen,
            'timestamp' => $now,
            'lat_long' => $request->lat_long,
            'photo_url' => $photoUrl,
            'status' => $status,
            'is_valid' => true,
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Absen berhasil dicatat.']);
    }

    public function getHistory(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'id' => 'required',
        ]);

        $tenant = Tenant::findOrFail(strtoupper($request->client_id));
        $user = User::where('tenant_id', $tenant->id)
                    ->where('employee_id', $request->id)
                    ->first();

        if (!$user && $request->id !== 'admin') {
            return response()->json([]);
        }

        $query = Attendance::where('tenant_id', $tenant->id);
        if ($request->id !== 'admin') {
            $query->where('user_id', $user->id);
        }

        $history = $query->orderBy('timestamp', 'desc')
                        ->limit(50)
                        ->get()
                        ->map(function($item) {
                            return [
                                'waktu' => $item->timestamp,
                                'tipe' => $item->type,
                                'status' => $item->status,
                            ];
                        });

        return response()->json($history);
    }

    private function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $R = 6371000; // Earth radius in meters
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);
        $a = sin($dLat / 2) * sin($dLat / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($dLon / 2) * sin($dLon / 2);
        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $R * $c;
    }
}
