<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Position;
use Illuminate\Http\Request;

class PositionController extends Controller
{
    public function index()
    {
        $positions = Position::where('tenant_id', auth()->user()->tenant_id)->get();
        return view('positions.index', compact('positions'));
    }

    public function store(Request $request)
    {
        $request->validate(['name' => 'required']);

        Position::create([
            'tenant_id' => auth()->user()->tenant_id,
            'name' => $request->name,
        ]);

        return redirect()->route('positions.index')->with('success', 'Jabatan berhasil ditambahkan.');
    }

    public function destroy($id)
    {
        $position = Position::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $position->delete();
        return redirect()->route('positions.index')->with('success', 'Jabatan berhasil dihapus.');
    }
}
