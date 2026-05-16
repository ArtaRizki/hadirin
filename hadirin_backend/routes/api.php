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

// Tenant-specific routes (via middleware)
Route::middleware([\App\Http\Middleware\TenantMiddleware::class])->group(function () {
    Route::post('/enroll-device', [AuthController::class, 'enrollDevice']);
    
    // Attendance
    Route::post('/absen', [AttendanceController::class, 'absen']);
    Route::post('/history', [AttendanceController::class, 'getHistory']);
    Route::post('/cek-status-hari-ini', [AttendanceController::class, 'cekStatusHariIni']);
    Route::post('/dashboard-stats', [AttendanceController::class, 'dashboardStats']);
    Route::post('/monthly-report', [AttendanceController::class, 'monthlyReport']);
    
    // Config
    Route::get('/office-config', [TenantController::class, 'getConfig']);
    Route::post('/office-config', [TenantController::class, 'getConfig']); // mobile legacy app support
    
    // Member management
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users', [UserController::class, 'index']); // mobile support
    Route::post('/add-karyawan', [UserController::class, 'store']);
    Route::delete('/users/{employeeId}', [UserController::class, 'destroy']);
    Route::post('/delete-karyawan', [UserController::class, 'destroy']); // mobile support
    Route::post('/register-face', [UserController::class, 'registerFace']);
    Route::post('/get-face', [UserController::class, 'getFace']);
    Route::post('/reset-device', [UserController::class, 'resetDevice']);
    Route::post('/upload-profile-photo', [UserController::class, 'uploadProfilePhoto']);

    // Activities
    Route::post('/get-jadwal-kegiatan', [ActivityController::class, 'index']);
    Route::post('/add-jadwal-kegiatan', [ActivityController::class, 'store']);
    Route::post('/edit-jadwal-kegiatan', [ActivityController::class, 'edit']);
    Route::post('/absen-kegiatan', [ActivityController::class, 'absen']);

    // Leaves
    Route::post('/ajukan-izin', [LeaveController::class, 'store']);
    Route::post('/get-leave-history', [LeaveController::class, 'history']);
    Route::post('/get-all-approvals', [LeaveController::class, 'approvals']);
    Route::post('/update-leave-status', [LeaveController::class, 'updateStatus']);

    // Ngaji Logs
    Route::post('/get-kelompok-ngaji', [NgajiController::class, 'groups']);
    Route::post('/add-kelompok-ngaji', [NgajiController::class, 'storeGroup']);
    Route::post('/submit-laporan-ngaji', [NgajiController::class, 'storeLog']);
    Route::post('/get-laporan-ngaji', [NgajiController::class, 'getLogs']);
    
    // Banners
    Route::post('/get-banners', [BannerController::class, 'index']);
    Route::post('/add-banner', [BannerController::class, 'store']);
    Route::post('/edit-banner/{id}', [BannerController::class, 'update']);
    Route::post('/delete-banner/{id}', [BannerController::class, 'destroy']);
});
