<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Carbon\Carbon;

class AttendanceController extends Controller
{
    public function index(Request $request)
    {
        $date = $request->get('date', Carbon::today()->toDateString());
        $attendances = Attendance::with('user')
            ->whereDate('created_at', $date)
            ->latest()
            ->paginate(20);

        $stats = [
            'present' => Attendance::whereDate('created_at', $date)->where('type', 'Masuk')->where('status', 'Tepat Waktu')->count(),
            'late' => Attendance::whereDate('created_at', $date)->where('type', 'Masuk')->where('status', 'Terlambat')->count(),
            'leave' => 0, // Placeholder for now
        ];

        return view('attendances.index', compact('attendances', 'stats'));
    }

    public function myHistory()
    {
        $attendances = Attendance::where('user_id', auth()->id())
            ->latest()
            ->paginate(20);

        return view('attendances.history', compact('attendances'));
    }

    public function create(Request $request)
    {
        // Must have type
        if (!in_array($request->type, ['Masuk', 'Pulang'])) {
            return redirect()->route('dashboard')->with('error', 'Tipe absen tidak valid.');
        }

        // Validate if already checked in/out today
        $today = Carbon::today();
        $existing = Attendance::where('user_id', auth()->id())
            ->whereDate('created_at', $today)
            ->where('type', $request->type)
            ->first();

        if ($existing) {
            return redirect()->route('dashboard')->with('error', 'Anda sudah melakukan Absen ' . $request->type . ' hari ini.');
        }

        return view('attendances.create');
    }

    public function storeWeb(Request $request)
    {
        $request->validate([
            'type' => 'required',
            'lat_long' => 'required',
            'photo' => 'required'
        ]);

        // 1. Geofencing Validation
        $config = \App\Models\OfficeConfig::where('tenant_id', auth()->user()->tenant_id)->first();
        if ($config) {
            $userLoc = explode(',', $request->lat_long);
            $userLat = $userLoc[0];
            $userLon = $userLoc[1];

            $theta = $userLon - $config->longitude;
            $dist = sin(deg2rad($userLat)) * sin(deg2rad($config->latitude)) +  cos(deg2rad($userLat)) * cos(deg2rad($config->latitude)) * cos(deg2rad($theta));
            $dist = acos($dist);
            $dist = rad2deg($dist);
            $miles = $dist * 60 * 1.1515;
            $distanceInMeters = $miles * 1609.344;

            if ($distanceInMeters > $config->radius) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda berada di luar radius kantor (' . round($distanceInMeters) . 'm). Silakan mendekat ke lokasi.'
                ], 422);
            }
        }

        // 2. Determine Status (Tepat Waktu / Terlambat) based on OfficeConfig
        $status = 'Tepat Waktu';
        $now = \Carbon\Carbon::now(); // FORCE SERVER TIME
        
        if ($request->type === 'Masuk') {
            if ($config) {
                $limit = \Carbon\Carbon::createFromFormat('H:i:s', $config->limit_checkin);
                
                if ($now->greaterThan($limit)) {
                    $status = 'Terlambat';
                }
            }
        }

        // 3. Save Image
        $imageName = time() . '_' . auth()->id() . '.jpg';
        \Illuminate\Support\Facades\Storage::disk('public')->put('attendances/' . $imageName, base64_decode($request->photo));
        $photoUrl = '/storage/attendances/' . $imageName;

        // 4. Create Attendance
        Attendance::create([
            'tenant_id' => auth()->user()->tenant_id,
            'user_id' => auth()->id(),
            'type' => $request->type,
            'status' => $status,
            'lat_long' => $request->lat_long,
            'photo_url' => $photoUrl,
            'notes' => 'Via Web'
        ]);

        return redirect()->route('dashboard')->with('success', 'Absen ' . $request->type . ' berhasil disimpan!');
    }
}
