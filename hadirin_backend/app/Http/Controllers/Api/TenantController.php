<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\Tenant;
use App\Models\OfficeConfig;

class TenantController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'client_id' => 'required|unique:tenants,id',
            'name' => 'required',
            'radius' => 'nullable|integer',
        ]);

        $tenant = Tenant::create([
            'id' => strtoupper($request->client_id),
            'name' => $request->name,
            'radius' => $request->radius ?: 100,
        ]);

        // Create default office config
        OfficeConfig::create([
            'tenant_id' => $tenant->id,
            'name' => $tenant->name . ' Office',
            'latitude' => 0,
            'longitude' => 0,
            'radius' => $tenant->radius,
            'start_checkin' => '05:00:00',
            'limit_checkin' => '07:30:00',
            'start_checkout' => '13:00:00',
        ]);

        return response()->json(['success' => true, 'message' => 'Tenant registered.', 'tenant' => $tenant]);
    }

    public function getConfig(Request $request)
    {
        $tenant = $request->tenant;
        $config = OfficeConfig::where('tenant_id', $tenant->id)->first();

        return response()->json([
            'code' => 200,
            'status' => 'success',
            'message' => [
                'nama' => $config->name,
                'lat' => $config->latitude,
                'lng' => $config->longitude,
                'radius' => $config->radius,
                'jam_masuk_mulai' => substr($config->start_checkin, 0, 5),
                'batas_jam_masuk' => substr($config->limit_checkin, 0, 5),
                'jam_pulang_mulai' => substr($config->start_checkout, 0, 5),
            ]
        ]);
    }

    public function getAyat(Request $request)
    {
        $tenant = $request->tenant;
        $verse = \App\Models\Verse::where('tenant_id', $tenant->id)->latest()->first();

        if ($verse) {
            return response()->json([
                'code' => 200,
                'status' => 'success',
                'message' => [
                    'ayat' => $verse->content,
                    'sumber' => $verse->reference,
                ]
            ]);
        }

        return response()->json([
            'code' => 200,
            'status' => 'success',
            'message' => [
                'ayat' => 'Maka sesungguhnya bersama kesulitan ada kemudahan.',
                'sumber' => 'QS. Al-Insyirah: 5',
            ]
        ]);
    }

    public function updateAyat(Request $request)
    {
        $request->validate([
            'ayat' => 'required',
            'sumber' => 'nullable',
        ]);

        $tenant = $request->tenant;

        \App\Models\Verse::create([
            'tenant_id' => $tenant->id,
            'content' => $request->ayat,
            'reference' => $request->sumber,
        ]);

        return response()->json([
            'code' => 200,
            'status' => 'success',
            'message' => 'Ayat pilihan berhasil diperbarui.'
        ]);
    }
}
