<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Attendance;
use Illuminate\Http\Request;
use Carbon\Carbon;

class ReportController extends Controller
{
    public function monthly(Request $request)
    {
        $month = $request->month ? Carbon::parse($request->month) : Carbon::today();
        
        $attendances = Attendance::where('tenant_id', auth()->user()->tenant_id)
            ->whereMonth('created_at', $month->month)
            ->whereYear('created_at', $month->year)
            ->with('user')
            ->latest()
            ->get();

        return view('reports.monthly', compact('attendances', 'month'));
    }

    public function export(Request $request)
    {
        $monthStr = $request->month ?? Carbon::today()->format('Y-m');
        $month = Carbon::parse($monthStr);
        $tenantId = auth()->user()->tenant_id;

        $attendances = Attendance::where('tenant_id', $tenantId)
            ->whereMonth('created_at', $month->month)
            ->whereYear('created_at', $month->year)
            ->with('user')
            ->orderBy('created_at', 'asc')
            ->get();

        $fileName = "Rekap_Absensi_" . $month->format('F_Y') . ".csv";
        
        $headers = array(
            "Content-type"        => "text/csv",
            "Content-Disposition" => "attachment; filename=$fileName",
            "Pragma"              => "no-cache",
            "Cache-Control"       => "must-revalidate, post-check=0, pre-check=0",
            "Expires"             => "0"
        );

        $columns = array('Tanggal', 'Jam', 'ID Anggota', 'Nama', 'Tipe', 'Status', 'Titik Koordinat');

        $callback = function() use($attendances, $columns) {
            $file = fopen('php://output', 'w');
            fputcsv($file, $columns);

            foreach ($attendances as $att) {
                fputcsv($file, array(
                    $att->created_at->format('d/m/Y'),
                    $att->created_at->format('H:i:s'),
                    $att->user->employee_id,
                    $att->user->name,
                    $att->type,
                    $att->status,
                    $att->lat_long
                ));
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
