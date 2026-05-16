<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class AuthController extends Controller
{
    public function showLoginForm()
    {
        return view('auth.login');
    }

    public function login(Request $request)
    {
        $request->validate([
            'client_id' => 'required',
            'employee_id' => 'required',
            'password' => 'required',
        ]);

        $tenant = Tenant::find(strtoupper($request->client_id));
        if (!$tenant) {
            return back()->with('error', 'Kode Instansi tidak ditemukan.');
        }

        // Special super admin bypass (Optional, if you want this from GAS)
        if (strtoupper($request->employee_id) === 'ADMIN' && $request->password === 'HADIRIN_MASTER_2026_AHHH') {
            // Need to handle this cleanly. Maybe create a dummy user in session or 
            // ensure there is a super admin user in DB.
            // For now, let's rely on actual DB auth.
        }

        if (Auth::attempt([
            'tenant_id' => $tenant->id,
            'employee_id' => $request->employee_id,
            'password' => $request->password
        ])) {
            $request->session()->regenerate();
            
            // Allow admin and members (for testing/mobile view simulation)
            if (!in_array(Auth::user()->role, ['admin', 'superadmin', 'anggota'])) {
                Auth::logout();
                return back()->with('error', 'Hanya admin yang bisa mengakses web dashboard.');
            }

            return redirect()->intended('dashboard');
        }

        return back()->with('error', 'Kredensial tidak valid.');
    }

    public function logout(Request $request)
    {
        Auth::logout();
        $request->session()->invalidate();
        $request->session()->regenerateToken();
        return redirect('/login');
    }
}
