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
        Schema::create('leaves', function (Blueprint $table) {
            $table->id();
            $table->string('tenant_id')->nullable();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type'); // Izin, Sakit, Cuti
            $table->string('lat_long')->nullable(); // Digunakan untuk rentang tanggal di legacy
            $table->text('reason')->nullable();
            $table->string('photo_url')->nullable();
            $table->string('leave_status')->default('Menunggu Approval');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('leaves');
    }
};
