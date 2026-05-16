<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Banner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class BannerController extends Controller
{
    public function index(Request $request)
    {
        $tenant  = $request->input('tenant');
        $banners = Banner::where('tenant_id', $tenant->id)
            ->where('status', 'Aktif')
            ->get()
            ->map(function ($b) {
                return [
                    'id_banner'   => $b->id,
                    'judul'       => $b->title,
                    'url_gambar'  => $b->image_url,
                ];
            });

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $banners]);
    }

    public function store(Request $request)
    {
        $request->validate(['judul' => 'required']);
        $tenant   = $request->input('tenant');
        $imageUrl = null;

        if ($request->hasFile('gambar')) {
            $path     = $request->file('gambar')->store('banners', 'public');
            $imageUrl = Storage::url($path);
        } elseif ($request->url_gambar) {
            $imageUrl = $request->url_gambar;
        }

        Banner::create([
            'tenant_id' => $tenant->id,
            'title'     => $request->judul,
            'image_url' => $imageUrl,
            'status'    => 'Aktif',
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Banner ditambahkan.']);
    }

    public function update(Request $request, $id)
    {
        $banner = Banner::findOrFail($id);
        $banner->update([
            'title'  => $request->judul ?? $banner->title,
            'status' => $request->status ?? $banner->status,
        ]);
        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Banner diperbarui.']);
    }

    public function destroy($id)
    {
        Banner::findOrFail($id)->delete();
        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Banner dihapus.']);
    }
}
