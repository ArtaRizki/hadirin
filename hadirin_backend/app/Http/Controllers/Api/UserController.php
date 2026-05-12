<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Models\User;
use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $tenant = $request->tenant;
        return response()->json($tenant->users);
    }

    public function store(Request $request)
    {
        $request->validate([
            'id_karyawan' => 'required',
            'nama' => 'required',
            'divisi' => 'nullable',
            'no_hp' => 'nullable',
            'role' => 'nullable',
        ]);

        $tenant = $request->tenant;

        $user = User::create([
            'tenant_id' => $tenant->id,
            'employee_id' => $request->id_karyawan,
            'name' => $request->nama,
            'division' => $request->divisi,
            'phone' => $request->no_hp,
            'role' => $request->role ?: 'anggota',
            'password' => Hash::make('123456'), // Default password
        ]);

        return response()->json(['success' => true, 'message' => 'Member added.', 'user' => $user]);
    }

    public function destroy(Request $request, $employeeId)
    {
        $tenant = $request->tenant;
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $employeeId)->firstOrFail();
        $user->delete();

        return response()->json(['success' => true, 'message' => 'Member deleted.']);
    }

    public function registerFace(Request $request)
    {
        $request->validate([
            'id_karyawan' => 'required',
            'descriptor' => 'required',
        ]);

        $tenant = $request->tenant;
        $user = User::where('tenant_id', $tenant->id)->where('employee_id', $request->id_karyawan)->firstOrFail();
        $user->update(['face_descriptor' => $request->descriptor]);

        return response()->json(['success' => true, 'message' => 'Face registered successfully.']);
    }
}
