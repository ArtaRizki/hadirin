<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Feedback;
use Illuminate\Http\Request;

class FeedbackController extends Controller
{
    public function index()
    {
        $feedbacks = Feedback::where('tenant_id', auth()->user()->tenant_id)->with('user')->latest()->get();
        return view('feedback.index', compact('feedbacks'));
    }

    public function create()
    {
        return view('feedback.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'type' => 'required|in:Kritik,Saran',
            'content' => 'required',
        ]);

        Feedback::create([
            'tenant_id' => auth()->user()->tenant_id,
            'user_id' => auth()->id(),
            'type' => $request->type,
            'content' => $request->content,
        ]);

        return redirect()->route('dashboard')->with('success', 'Masukan Anda telah terkirim. Terima kasih!');
    }
}
