<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $tenant = $request->input('tenant');
        $users = User::where('tenant_id', $tenant->id)->get()->map(function ($u) {
            return [
                'id' => $u->employee_id,
                'nama' => $u->name,
                'bagian' => $u->division ?? '-',
                'sudah_enroll' => $u->device_id !== null,
                'wajah_terdaftar' => $u->face_descriptor !== null,
                'no_hp' => $u->phone ?? '',
                'id_shift_default' => $u->role ?? 'Anggota',
            ];
        });
        return response()->json(['code' => 200, 'status' => 'success', 'message' => $users]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'id_karyawan_baru' => 'required',
            'nama_karyawan_baru' => 'required',
        ]);

        $tenant = $request->input('tenant');

        $user = User::create([
            'tenant_id' => $tenant->id,
            'employee_id' => $request->id_karyawan_baru,
            'name' => $request->nama_karyawan_baru,
            'division' => $request->divisi_baru ?? '-',
            'phone' => $request->no_hp ?? '',
            'role' => $request->id_shift ?? 'Anggota',
            'password' => Hash::make('123456'), // Default password
        ]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Anggota Ditambahkan.']);
    }

    public function destroy(Request $request, $employeeId)
    {
        $tenant = $request->input('tenant');
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $employeeId)->firstOrFail();
        $user->delete();

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Berhasil dihapus.']);
    }

    public function registerFace(Request $request)
    {
        $request->validate([
            'id_karyawan' => 'required',
            'face_descriptor' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->first();
        
        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'User not found.'], 404);
        }

        $user->update(['face_descriptor' => $request->face_descriptor]);

        return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Wajah terdaftar.']);
    }

    public function getFace(Request $request)
    {
        $request->validate([
            'id_karyawan' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'Not found.'], 404);
        }

        return response()->json(['code' => 200, 'status' => 'success', 'message' => $user->face_descriptor ?? '']);
    }

    public function resetDevice(Request $request)
    {
        $request->validate([
            'target_id_karyawan' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->target_id_karyawan)->first();

        if ($user) {
            $user->update(['device_id' => null]);
            return response()->json(['code' => 200, 'status' => 'success', 'message' => true]);
        }

        return response()->json(['code' => 404, 'status' => 'error', 'message' => false], 404);
    }

    public function uploadProfilePhoto(Request $request)
    {
        $request->validate([
            'id_karyawan' => 'required',
            'foto_base64' => 'required',
        ]);

        $tenant = $request->input('tenant');
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->first();

        if (!$user) {
            return response()->json(['code' => 404, 'status' => 'error', 'message' => 'User not found.'], 404);
        }

        try {
            $imgData  = base64_decode($request->foto_base64);
            $filename = 'profile_' . $user->employee_id . '_' . time() . '.jpg';
            $path     = 'profiles/' . $filename;
            Storage::disk('public')->put($path, $imgData);
            
            $user->update(['profile_photo_path' => Storage::url($path)]);
            
            return response()->json(['code' => 200, 'status' => 'success', 'message' => 'Foto profil berhasil diupload.']);
        } catch (\Exception $e) {
            return response()->json(['code' => 500, 'status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }
}
