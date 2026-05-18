<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\TenantController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ActivityController;
use App\Http\Controllers\Api\LeaveController;
use App\Http\Controllers\Api\NgajiController;
use App\Http\Controllers\Api\BannerController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/tenant/register', [TenantController::class, 'register']);
Route::post('/verify_super_admin', [AuthController::class, 'verifySuperAdmin']);

// Tenant-specific routes (via middleware)
// Nama rute disamakan dengan 'action' yang dikirimkan oleh aplikasi Flutter (menggunakan underscore)
Route::middleware([\App\Http\Middleware\TenantMiddleware::class])->group(function () {
    Route::post('/enroll_device', [AuthController::class, 'enrollDevice']);
    
    // Attendance
    Route::post('/absen', [AttendanceController::class, 'absen']);
    Route::post('/get_history', [AttendanceController::class, 'getHistory']);
    Route::post('/cek_status_hari_ini', [AttendanceController::class, 'cekStatusHariIni']);
    Route::post('/dashboard_stats', [AttendanceController::class, 'dashboardStats']);
    Route::post('/monthly_report', [AttendanceController::class, 'monthlyReport']);
    
    // Config
    Route::get('/get_office_config', [TenantController::class, 'getConfig']);
    Route::post('/get_office_config', [TenantController::class, 'getConfig']); // mobile legacy app support
    
    // Member management
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/get_all_karyawan', [UserController::class, 'index']); // mobile support
    Route::post('/add_karyawan', [UserController::class, 'store']);
    Route::post('/delete_karyawan', [UserController::class, 'destroy']); // mobile support
    Route::post('/register_face', [UserController::class, 'registerFace']);
    Route::post('/get_face', [UserController::class, 'getFace']);
    Route::post('/reset_device', [UserController::class, 'resetDevice']);
    Route::post('/upload_profile_photo', [UserController::class, 'uploadProfilePhoto']);

    // Activities
    Route::post('/get_jadwal_kegiatan', [ActivityController::class, 'index']);
    Route::post('/add_jadwal_kegiatan', [ActivityController::class, 'store']);
    Route::post('/edit_jadwal_kegiatan', [ActivityController::class, 'edit']);
    Route::post('/absen_kegiatan', [ActivityController::class, 'absen']);

    // Leaves
    Route::post('/ajukan_izin', [LeaveController::class, 'store']);
    Route::post('/get_leave_history', [LeaveController::class, 'history']);
    Route::post('/get_all_approvals', [LeaveController::class, 'approvals']);
    Route::post('/update_leave_status', [LeaveController::class, 'updateStatus']);

    // Ngaji Logs
    Route::post('/get_kelompok_ngaji', [NgajiController::class, 'groups']);
    Route::post('/add_kelompok_ngaji', [NgajiController::class, 'storeGroup']);
    Route::post('/submit_laporan_ngaji', [NgajiController::class, 'storeLog']);
    Route::post('/get_laporan_ngaji', [NgajiController::class, 'getLogs']);
    
    // Banners
    Route::post('/get_banners', [BannerController::class, 'index']);
    Route::post('/add_banner', [BannerController::class, 'store']);
    Route::post('/edit_banner/{id}', [BannerController::class, 'update']);
    Route::post('/delete_banner/{id}', [BannerController::class, 'destroy']);

    // Stats & Ayat (New Parity)
    Route::post('/get_enhanced_stats', [AttendanceController::class, 'enhancedStats']);
    Route::post('/get_employee_stats', [AttendanceController::class, 'employeeStats']);
    Route::post('/get_ayat_pilihan', [TenantController::class, 'getAyat']);
});
