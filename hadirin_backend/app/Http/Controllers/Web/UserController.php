<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function index()
    {
        $users = User::all();
        return view('users.index', compact('users'));
    }

    public function enroll()
    {
        return view('users.enroll');
    }

    public function storeEnrollment(Request $request)
    {
        $request->validate([
            'face_descriptor' => 'required|string',
        ]);

        $user = auth()->user();
        $user->update([
            'face_descriptor' => $request->face_descriptor
        ]);

        return redirect()->route('dashboard')->with('success', 'Wajah berhasil didaftarkan! Anda sekarang bisa menggunakan fitur absensi wajah.');
    }

    public function resetDevice($id)
    {
        $user = User::findOrFail($id);
        $user->update([
            'device_id' => null,
            'face_descriptor' => null
        ]);

        return back()->with('success', 'Device and Face Data reset successfully.');
    }

    public function create()
    {
        return view('users.create');
    }

    public function store(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|unique:users,employee_id',
            'name' => 'required|string|max:255',
            'role' => 'required|string',
            'password' => 'required|string|min:6',
        ]);

        User::create([
            'tenant_id' => auth()->user()->tenant_id,
            'employee_id' => $request->employee_id,
            'name' => $request->name,
            'role' => $request->role,
            'password' => \Illuminate\Support\Facades\Hash::make($request->password),
        ]);

        return redirect()->route('users.index')->with('success', 'Anggota berhasil ditambahkan.');
    }

    public function edit($id)
    {
        $user = User::findOrFail($id);
        return view('users.edit', compact('user'));
    }

    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        $request->validate([
            'employee_id' => 'required|unique:users,employee_id,'.$id,
            'name' => 'required|string|max:255',
            'role' => 'required|string',
        ]);

        $data = [
            'employee_id' => $request->employee_id,
            'name' => $request->name,
            'role' => $request->role,
        ];

        if ($request->filled('password')) {
            $data['password'] = \Illuminate\Support\Facades\Hash::make($request->password);
        }

        $user->update($data);

        return redirect()->route('users.index')->with('success', 'Data anggota berhasil diperbarui.');
    }

    public function destroy($id)
    {
        $user = User::findOrFail($id);
        $user->delete();
        return redirect()->route('users.index')->with('success', 'Anggota berhasil dihapus.');
    }
}
