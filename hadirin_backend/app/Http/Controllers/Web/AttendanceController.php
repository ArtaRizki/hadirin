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

        // Time-fencing: cek apakah sudah waktunya absen (timezone WITA / Asia/Makassar)
        $config = \App\Models\OfficeConfig::where('tenant_id', auth()->user()->tenant_id)->first();
        if ($config) {
            $now = Carbon::now('Asia/Makassar');
            $currentMinutes = ($now->hour * 60) + $now->minute;

            if ($request->type === 'Masuk') {
                $startCheckin = $this->timeToMinutes($config->start_checkin ?? '04:00');
                $startCheckout = $this->timeToMinutes($config->start_checkout ?? '13:00');

                if ($currentMinutes < $startCheckin || $currentMinutes >= $startCheckout) {
                    $startStr = $config->start_checkin ?? '04:00';
                    $endStr = $config->start_checkout ?? '13:00';
                    return redirect()->route('dashboard')->with('error', "Absen Masuk hanya tersedia pukul {$startStr} - {$endStr} WITA.");
                }
            } else {
                // Pulang
                $startCheckout = $this->timeToMinutes($config->start_checkout ?? '13:00');

                if ($currentMinutes < $startCheckout) {
                    $checkoutStr = $config->start_checkout ?? '13:00';
                    return redirect()->route('dashboard')->with('error', "Absen Pulang baru dibuka mulai pukul {$checkoutStr} WITA.");
                }
            }
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

    /**
     * Convert time string (H:i or H:i:s) to total minutes since midnight.
     */
    private function timeToMinutes(?string $time): int
    {
        if (!$time) return 0;
        $parts = explode(':', $time);
        return (int)$parts[0] * 60 + (int)($parts[1] ?? 0);
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
            $userLat = trim($userLoc[0]);
            $userLon = trim($userLoc[1]);

            $theta = $userLon - $config->longitude;
            $dist = sin(deg2rad($userLat)) * sin(deg2rad($config->latitude)) +  cos(deg2rad($userLat)) * cos(deg2rad($config->latitude)) * cos(deg2rad($theta));
            $dist = acos($dist);
            $dist = rad2deg($dist);
            $miles = $dist * 60 * 1.1515;
            $distanceInMeters = $miles * 1609.344;

            if ($distanceInMeters > $config->radius) {
                return redirect()->back()->with('error', 'Anda berada di luar radius kantor (' . round($distanceInMeters) . 'm). Silakan mendekat ke lokasi.');
            }
        }

        // 2. Determine Status (Tepat Waktu / Terlambat) based on OfficeConfig
        $status = 'Tepat Waktu';
        $now = \Carbon\Carbon::now('Asia/Makassar');
        
        if ($request->type === 'Masuk') {
            if ($config && $config->limit_checkin) {
                try {
                    // Handle both H:i and H:i:s formats
                    $limitStr = $config->limit_checkin;
                    if (substr_count($limitStr, ':') === 1) {
                        $limitStr .= ':00';
                    }
                    $limit = \Carbon\Carbon::createFromFormat('H:i:s', $limitStr);
                    
                    if ($now->greaterThan($limit)) {
                        $status = 'Terlambat';
                    }
                } catch (\Exception $e) {
                    // If parsing fails, default to Tepat Waktu
                    \Log::warning('Failed to parse limit_checkin: ' . $config->limit_checkin);
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
        ]);

        return redirect()->route('dashboard')->with('success', 'Absen ' . $request->type . ' berhasil disimpan!');
    }
}
