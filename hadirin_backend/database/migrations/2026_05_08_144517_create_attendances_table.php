<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('attendances', function (Blueprint $table) {
            $table->id();
            $table->string('tenant_id');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type'); // Masuk, Pulang, Izin, Sakit, Cuti
            $table->timestamp('timestamp')->useCurrent();
            $table->string('lat_long')->nullable();
            $table->string('photo_url')->nullable();
            $table->string('status')->nullable(); // Tepat Waktu, Terlambat, etc.
            $table->boolean('is_valid')->default(true);
            $table->text('reason')->nullable(); // for leaves
            $table->string('leave_status')->default('Pending'); // Approved, Pending, Rejected
            $table->string('substitute_teacher')->nullable();
            $table->timestamps();
            
            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attendances');
    }
};
