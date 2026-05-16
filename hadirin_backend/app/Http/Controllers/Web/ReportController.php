<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function monthly(Request $request)
    {
        $month = $request->month ? \Carbon\Carbon::parse($request->month) : \Carbon\Carbon::today();
        
        $attendances = \App\Models\Attendance::where('tenant_id', auth()->user()->tenant_id)
            ->whereMonth('created_at', $month->month)
            ->whereYear('created_at', $month->year)
            ->with('user')
            ->latest()
            ->get();

        return view('reports.monthly', compact('attendances', 'month'));
    }
}
