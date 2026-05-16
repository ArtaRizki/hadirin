<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\OfficeConfig;
use Illuminate\Http\Request;

class OfficeConfigController extends Controller
{
    public function index()
    {
        $config = OfficeConfig::first();
        return view('office-config.index', compact('config'));
    }

    public function updateLocation(Request $request)
    {
        $config = OfficeConfig::first();
        $config->update($request->only(['latitude', 'longitude', 'radius']));
        return back()->with('success', 'Location updated.');
    }

    public function updateTime(Request $request)
    {
        $config = OfficeConfig::first();
        $config->update($request->only(['start_checkin', 'limit_checkin', 'start_checkout']));
        return back()->with('success', 'Working hours updated.');
    }
}
