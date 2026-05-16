<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Briefing;
use Illuminate\Http\Request;

class BriefingController extends Controller
{
    public function index()
    {
        $briefings = Briefing::withCount('attendances')->latest()->get();
        return view('briefings.index', compact('briefings'));
    }
}
