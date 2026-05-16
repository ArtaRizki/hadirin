<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Http\Request;

class BannerController extends Controller
{
    public function index()
    {
        $banners = Banner::where('tenant_id', auth()->user()->tenant_id)->latest()->get();
        return view('banners.index', compact('banners'));
    }

    public function create()
    {
        return view('banners.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'title' => 'required|string|max:255',
            'image' => 'required|image|max:2048', // max 2MB
        ]);

        $imagePath = $request->file('image')->store('banners', 'public');

        Banner::create([
            'tenant_id' => auth()->user()->tenant_id,
            'title' => $request->title,
            'image_url' => '/storage/' . $imagePath,
            'is_active' => $request->has('is_active') ? $request->is_active : true,
        ]);

        return redirect()->route('banners.index')->with('success', 'Pengumuman berhasil ditambahkan.');
    }

    public function destroy($id)
    {
        $banner = Banner::findOrFail($id);
        
        // Optionally delete image from storage
        $path = str_replace('/storage/', '', $banner->image_url);
        \Illuminate\Support\Facades\Storage::disk('public')->delete($path);
        
        $banner->delete();
        
        return back()->with('success', 'Banner deleted successfully.');
    }
}
