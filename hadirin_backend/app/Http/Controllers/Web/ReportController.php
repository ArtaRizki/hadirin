<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class ReportController extends Controller
{
    public function monthly()
    {
        $report = []; // Placeholder for now
        return view('reports.monthly', compact('report'));
    }
}
