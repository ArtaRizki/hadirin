<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Verse;
use Illuminate\Http\Request;

class VerseController extends Controller
{
    public function index()
    {
        $verses = Verse::where('tenant_id', auth()->user()->tenant_id)->latest()->get();
        return view('verses.index', compact('verses'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'content' => 'required',
            'reference' => 'nullable',
        ]);

        Verse::create([
            'tenant_id' => auth()->user()->tenant_id,
            'content' => $request->content,
            'reference' => $request->reference,
        ]);

        return redirect()->route('verses.index')->with('success', 'Ayat/Kutipan berhasil ditambahkan.');
    }

    public function destroy($id)
    {
        $verse = Verse::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $verse->delete();
        return redirect()->route('verses.index')->with('success', 'Ayat berhasil dihapus.');
    }
}
