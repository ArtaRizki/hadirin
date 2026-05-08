use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\TenantController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/tenant/register', [TenantController::class, 'register']);

// Tenant-specific routes (via middleware)
Route::middleware(['tenant'])->group(function () {
    Route::post('/enroll-device', [AuthController::class, 'enrollDevice']);
    Route::post('/absen', [AttendanceController::class, 'absen']);
    Route::post('/history', [AttendanceController::class, 'getHistory']);
    Route::get('/office-config', [TenantController::class, 'getConfig']);
    
    // Member management
    Route::get('/users', [UserController::class, 'index']);
    Route::post('/users', [UserController::class, 'store']);
    Route::delete('/users/{employeeId}', [UserController::class, 'destroy']);
    Route::post('/register-face', [UserController::class, 'registerFace']);

    // Activities
    Route::get('/activities', [\App\Http\Controllers\Api\ActivityController::class, 'index']);
    Route::post('/activities', [\App\Http\Controllers\Api\ActivityController::class, 'store']);
    Route::post('/activities/absen', [\App\Http\Controllers\Api\ActivityController::class, 'absen']);

    // Leaves
    Route::post('/leaves', [\App\Http\Controllers\Api\LeaveController::class, 'store']);
    Route::get('/leaves/history', [\App\Http\Controllers\Api\LeaveController::class, 'history']);

    // Ngaji Logs
    Route::get('/ngaji/groups', [\App\Http\Controllers\Api\NgajiController::class, 'groups']);
    Route::post('/ngaji/groups', [\App\Http\Controllers\Api\NgajiController::class, 'storeGroup']);
    Route::post('/ngaji/logs', [\App\Http\Controllers\Api\NgajiController::class, 'storeLog']);
});

// Authenticated routes (optional for now, can be added as needed)
Route::middleware('auth:sanctum')->group(function () {
    //
});
