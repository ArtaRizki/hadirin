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
    Route::get('/activities/create', [ActivityController::class, 'create'])->name('activities.create');
    Route::post('/activities', [ActivityController::class, 'store'])->name('activities.store');
    Route::get('/activities/{id}/edit', [ActivityController::class, 'edit'])->name('activities.edit');
    Route::put('/activities/{id}', [ActivityController::class, 'update'])->name('activities.update');
    Route::delete('/activities/{id}', [ActivityController::class, 'destroy'])->name('activities.destroy');
    
    // Reports
    Route::get('/reports/monthly', [ReportController::class, 'monthly'])->name('reports.monthly');
    Route::get('/reports/export', [ReportController::class, 'export'])->name('reports.export');
    
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
    Route::get('/quran/create', [\App\Http\Controllers\Web\QuranController::class, 'create'])->name('quran.create');
    Route::post('/quran', [\App\Http\Controllers\Web\QuranController::class, 'store'])->name('quran.store');
    
    Route::get('/ngaji', [\App\Http\Controllers\Web\NgajiController::class, 'index'])->name('ngaji.index');
    Route::get('/ngaji/create', [\App\Http\Controllers\Web\NgajiController::class, 'create'])->name('ngaji.create');
    Route::post('/ngaji', [\App\Http\Controllers\Web\NgajiController::class, 'store'])->name('ngaji.store');
    
    Route::get('/briefings', [\App\Http\Controllers\Web\BriefingController::class, 'index'])->name('briefings.index');
    Route::get('/briefings/personal', [\App\Http\Controllers\Web\BriefingController::class, 'personal'])->name('briefings.personal');
    Route::post('/briefings/{id}/attend', [\App\Http\Controllers\Web\BriefingController::class, 'attend'])->name('briefings.attend');

    // Feedback
    Route::get('/feedback', [\App\Http\Controllers\Web\FeedbackController::class, 'index'])->name('feedback.index');
    Route::get('/feedback/create', [\App\Http\Controllers\Web\FeedbackController::class, 'create'])->name('feedback.create');
    Route::post('/feedback', [\App\Http\Controllers\Web\FeedbackController::class, 'store'])->name('feedback.store');

    // Manajemen Jabatan
    Route::get('/positions', [\App\Http\Controllers\Web\PositionController::class, 'index'])->name('positions.index');
    Route::post('/positions', [\App\Http\Controllers\Web\PositionController::class, 'store'])->name('positions.store');
    Route::delete('/positions/{id}', [\App\Http\Controllers\Web\PositionController::class, 'destroy'])->name('positions.destroy');

    // Kelola Ayat
    Route::get('/verses', [\App\Http\Controllers\Web\VerseController::class, 'index'])->name('verses.index');
    Route::post('/verses', [\App\Http\Controllers\Web\VerseController::class, 'store'])->name('verses.store');
    Route::delete('/verses/{id}', [\App\Http\Controllers\Web\VerseController::class, 'destroy'])->name('verses.destroy');
});

// Route Sementara untuk Migrasi Database di InfinityFree (Hapus jika sudah selesai)
Route::get('/run-migrate', function() {
    try {
        if (request()->query('fresh') === '1') {
            \Illuminate\Support\Facades\Artisan::call('migrate:fresh', ['--force' => true]);
            return "Migration (Fresh) successful!";
        }
        \Illuminate\Support\Facades\Artisan::call('migrate', ['--force' => true]);
        return "Migration successful!";
    } catch (\Exception $e) {
        return "Error: " . $e->getMessage();
    }
});

Route::get('/run-seed', function() {
    try {
        \Illuminate\Support\Facades\Artisan::call('db:seed', ['--force' => true]);
        return "Seeding successful!";
    } catch (\Exception $e) {
        return "Error: " . $e->getMessage();
    }
});

Route::get('/run-link', function() {
    try {
        \Illuminate\Support\Facades\Artisan::call('storage:link');
        return "Storage link created!";
    } catch (\Exception $e) {
        return "Error: " . $e->getMessage();
    }
});

