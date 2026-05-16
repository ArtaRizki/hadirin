<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\NgajiLog;
use Illuminate\Http\Request;

class NgajiController extends Controller
{
    public function index()
    {
        $logs = NgajiLog::with(['user', 'group'])->latest()->get();
        return view('ngaji.index', compact('logs'));
    }
}
