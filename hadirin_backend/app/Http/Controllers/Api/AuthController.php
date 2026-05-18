<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\User;
use App\Models\Tenant;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'id' => 'required', // employee_id
            'pin' => 'nullable', // or password
        ]);

        $tenant = Tenant::findOrFail(strtoupper($request->client_id));
        $user = User::where('tenant_id', $tenant->id)
                    ->where('employee_id', $request->id)
                    ->first();

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'ID Anggota tidak ditemukan.'], 404);
        }

        // Handle super admin login logic if needed
        if ($request->id === 'ADMIN' && $request->pin === config('app.super_admin_password')) {
            $token = $user->createToken('admin-token')->plainTextToken;
            return response()->json([
                'success' => true,
                'token' => $token,
                'user' => $user
            ]);
        }

        // Logic for regular users (you might want to add PIN check here if implemented in migration)
        // For now, let's just return the user if found, similar to GAS logic
        
        $token = $user->createToken('user-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'token' => $token,
            'user' => [
                'id' => $user->employee_id,
                'nama' => $user->name,
                'role' => $user->role,
                'clientId' => $user->tenant_id,
                'faceWeb' => $user->face_descriptor,
            ]
        ]);
    }

    public function verifySuperAdmin(Request $request)
    {
        $request->validate([
            'password' => 'required'
        ]);

        // Matches the "super admin" hardcoded password from previous configuration
        if ($request->password === 'HADIRIN_MASTER_2026_AHHH') {
            return response()->json([
                'code' => 200,
                'status' => 'success',
                'message' => 'Super Admin Verified'
            ]);
        }

        return response()->json(['code' => 401, 'status' => 'error', 'message' => 'Password Super Admin salah'], 401);
    }

    public function enrollDevice(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'id_karyawan' => 'required',
            'device_id' => 'required',
        ]);

        $tenant = Tenant::findOrFail(strtoupper($request->client_id));
        $user = User::where('tenant_id', $tenant->id)
                    ->where('employee_id', $request->id_karyawan)
                    ->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'User tidak ditemukan.'], 404);
        }

        if ($user->device_id === null || $user->device_id === $request->device_id) {
            if ($user->device_id === null) {
                $user->update(['device_id' => $request->device_id]);
            }

            return response()->json([
                'code' => 200,
                'status' => 'success',
                'message' => [
                    'nama_karyawan' => $user->name,
                    'client_id' => $user->tenant_id,
                    'divisi' => $user->division,
                    'no_hp' => $user->phone,
                    'role_akses' => $user->role,
                    'profile_photo' => $user->profile_photo_path,
                ]
            ]);
        }

        return response()->json(['code' => 403, 'status' => 'error', 'message' => 'Device ID tidak cocok.'], 403);
    }
}
