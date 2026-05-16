<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Activity;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ActivityController extends Controller
{
    public function index()
    {
        $activities = Activity::where('tenant_id', auth()->user()->tenant_id)->latest('scheduled_at')->get();
        return view('activities.index', compact('activities'));
    }

    public function create()
    {
        return view('activities.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'type' => 'required',
            'scheduled_at' => 'required|date',
            'description' => 'nullable',
        ]);

        Activity::create([
            'id' => 'KEG-' . time(),
            'tenant_id' => auth()->user()->tenant_id,
            'name' => $request->name,
            'type' => $request->type,
            'scheduled_at' => $request->scheduled_at,
            'description' => $request->description,
            'created_by' => auth()->id(),
        ]);

        return redirect()->route('activities.index')->with('success', 'Kegiatan berhasil ditambahkan.');
    }

    public function edit($id)
    {
        $activity = Activity::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        return view('activities.edit', compact('activity'));
    }

    public function update(Request $request, $id)
    {
        $activity = Activity::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        
        $request->validate([
            'name' => 'required',
            'type' => 'required',
            'scheduled_at' => 'required|date',
            'description' => 'nullable',
        ]);

        $activity->update($request->only(['name', 'type', 'scheduled_at', 'description']));

        return redirect()->route('activities.index')->with('success', 'Kegiatan berhasil diperbarui.');
    }

    public function destroy($id)
    {
        $activity = Activity::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $activity->delete();
        return redirect()->route('activities.index')->with('success', 'Kegiatan berhasil dihapus.');
    }
}
