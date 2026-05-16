<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\QuranLog;
use Illuminate\Http\Request;

class QuranController extends Controller
{
    public function index()
    {
        $logs = QuranLog::with(['teacher', 'student', 'master'])->latest()->get();
        return view('quran.index', compact('logs'));
    }
}
