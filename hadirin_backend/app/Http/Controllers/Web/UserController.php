<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Position;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    public function index()
    {
        $users = User::where('tenant_id', auth()->user()->tenant_id)->orderBy('name')->get();
        return view('users.index', compact('users'));
    }

    public function create()
    {
        $positions = Position::where('tenant_id', auth()->user()->tenant_id)->get();
        return view('users.create', compact('positions'));
    }

    public function store(Request $request)
    {
        $request->validate([
            'employee_id' => 'required|string|max:255',
            'name' => 'required|string|max:255',
            'password' => 'required|string|min:6',
            'role' => 'required|in:admin,anggota',
            'division' => 'nullable|string'
        ]);

        // Check if employee_id exists for this tenant
        if (User::where('tenant_id', auth()->user()->tenant_id)->where('employee_id', $request->employee_id)->exists()) {
            return back()->withErrors(['employee_id' => 'ID Anggota sudah terdaftar.'])->withInput();
        }

        User::create([
            'tenant_id' => auth()->user()->tenant_id,
            'employee_id' => $request->employee_id,
            'name' => $request->name,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'division' => $request->division,
            'email' => strtolower($request->employee_id) . '@' . strtolower(auth()->user()->tenant_id) . '.local',
        ]);

        return redirect()->route('users.index')->with('success', 'Anggota berhasil ditambahkan.');
    }

    public function edit(string $id)
    {
        $user = User::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $positions = Position::where('tenant_id', auth()->user()->tenant_id)->get();
        return view('users.edit', compact('user', 'positions'));
    }

    public function update(Request $request, string $id)
    {
        $user = User::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);

        $request->validate([
            'employee_id' => 'required|string|max:255',
            'name' => 'required|string|max:255',
            'role' => 'required|in:admin,anggota',
            'division' => 'nullable|string'
        ]);

        // Check if employee_id exists for another user in this tenant
        $exists = User::where('tenant_id', auth()->user()->tenant_id)
            ->where('employee_id', $request->employee_id)
            ->where('id', '!=', $id)
            ->exists();

        if ($exists) {
            return back()->withErrors(['employee_id' => 'ID Anggota sudah terdaftar.'])->withInput();
        }

        $user->update([
            'employee_id' => $request->employee_id,
            'name' => $request->name,
            'role' => $request->role,
            'division' => $request->division,
            'email' => strtolower($request->employee_id) . '@' . strtolower(auth()->user()->tenant_id) . '.local',
        ]);

        if ($request->filled('password')) {
            $user->update(['password' => Hash::make($request->password)]);
        }

        return redirect()->route('users.index')->with('success', 'Data anggota berhasil diperbarui.');
    }

    public function destroy(string $id)
    {
        $user = User::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        
        // Prevent self deletion
        if ($user->id === auth()->id()) {
            return back()->with('error', 'Anda tidak dapat menghapus akun Anda sendiri.');
        }

        $user->delete();
        return redirect()->route('users.index')->with('success', 'Anggota berhasil dihapus.');
    }

    public function resetDevice(string $id)
    {
        $user = User::where('tenant_id', auth()->user()->tenant_id)->findOrFail($id);
        $user->update(['device_id' => null]);

        return back()->with('success', 'Perangkat ' . $user->name . ' berhasil di-reset.');
    }

    public function enroll()
    {
        return view('users.enroll');
    }

    public function storeEnrollment(Request $request)
    {
        $request->validate([
            'face_descriptor' => 'required|string'
        ]);

        /** @var \App\Models\User $user */
        $user = auth()->user();
        $user->update([
            'face_descriptor' => $request->face_descriptor
        ]);

        return redirect()->route('dashboard')->with('success', 'Wajah berhasil didaftarkan!');
    }
}
