<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Web\AuthController;
use App\Http\Controllers\Web\DashboardController;
use App\Http\Controllers\Web\AttendanceController;
use App\Http\Controllers\Web\UserController;
use App\Http\Controllers\Web\LeaveController;
use App\Http\Controllers\Web\ActivityController;
use App\Http\Controllers\Web\ReportController;
use App\Http\Controllers\Web\OfficeConfigController;
use App\Http\Controllers\Web\BannerController;

Route::get('/', function () {
    return redirect()->route('login');
});

Route::get('/login', [AuthController::class, 'showLoginForm'])->name('login')->middleware('guest');
Route::post('/login', [AuthController::class, 'login']);
Route::post('/logout', [AuthController::class, 'logout'])->name('logout');

Route::middleware(['auth'])->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    
    // Attendances
    Route::get('/attendances', [AttendanceController::class, 'index'])->name('attendances.index');
    Route::get('/attendances/create', [AttendanceController::class, 'create'])->name('attendances.create');
    Route::post('/attendances/storeWeb', [AttendanceController::class, 'storeWeb'])->name('attendances.storeWeb');
    Route::get('/my-history', [AttendanceController::class, 'myHistory'])->name('attendances.history');
    
    // Users
    Route::get('/users', [UserController::class, 'index'])->name('users.index');
    Route::get('/users/create', [UserController::class, 'create'])->name('users.create');
    Route::post('/users', [UserController::class, 'store'])->name('users.store');
    Route::get('/users/{id}/edit', [UserController::class, 'edit'])->name('users.edit');
    Route::put('/users/{id}', [UserController::class, 'update'])->name('users.update');
    Route::delete('/users/{id}', [UserController::class, 'destroy'])->name('users.destroy');
    Route::get('/users/enroll', [UserController::class, 'enroll'])->name('users.enroll');
    Route::post('/users/enroll', [UserController::class, 'storeEnrollment'])->name('users.storeEnrollment');
    Route::post('/users/{id}/reset-device', [UserController::class, 'resetDevice'])->name('users.resetDevice');
    
    // Leaves
    Route::get('/leaves', [LeaveController::class, 'index'])->name('leaves.index');
    Route::get('/my-leaves', [LeaveController::class, 'myLeaves'])->name('leaves.personal');
    Route::post('/leaves', [LeaveController::class, 'store'])->name('leaves.store');
    Route::post('/leaves/{id}/approve', [LeaveController::class, 'approve'])->name('leaves.approve');
    Route::post('/leaves/{id}/reject', [LeaveController::class, 'reject'])->name('leaves.reject');
    
    // Activities
    Route::get('/activities', [ActivityController::class, 'index'])->name('activities.index');
    
    // Reports
    Route::get('/reports/monthly', [ReportController::class, 'monthly'])->name('reports.monthly');
    
    // Office Config
    Route::get('/office-config', [OfficeConfigController::class, 'index'])->name('office-config.index');
    Route::post('/office-config/location', [OfficeConfigController::class, 'updateLocation'])->name('office-config.updateLocation');
    Route::post('/office-config/time', [OfficeConfigController::class, 'updateTime'])->name('office-config.updateTime');
    
    // Banners
    Route::get('/banners', [BannerController::class, 'index'])->name('banners.index');
    Route::get('/banners/create', [BannerController::class, 'create'])->name('banners.create');
    Route::post('/banners', [BannerController::class, 'store'])->name('banners.store');
    Route::delete('/banners/{id}', [BannerController::class, 'destroy'])->name('banners.destroy');

    // Fitur Keagamaan & Rapat
    Route::get('/quran', [\App\Http\Controllers\Web\QuranController::class, 'index'])->name('quran.index');
    Route::get('/ngaji', [\App\Http\Controllers\Web\NgajiController::class, 'index'])->name('ngaji.index');
    Route::get('/briefings', [\App\Http\Controllers\Web\BriefingController::class, 'index'])->name('briefings.index');
});
