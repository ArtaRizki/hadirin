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
        Schema::table('users', function (Blueprint $table) {
            $table->string('tenant_id')->after('id');
            $table->string('employee_id')->after('tenant_id');
            $table->string('division')->nullable()->after('name');
            $table->string('device_id')->nullable()->after('division');
            $table->text('face_descriptor')->nullable()->after('device_id');
            $table->string('phone')->nullable()->after('face_descriptor');
            $table->string('role')->default('anggota')->after('phone');
            $table->string('profile_photo_path')->nullable()->after('role');
            
            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
            $table->unique(['tenant_id', 'employee_id']);
            $table->unique(['tenant_id', 'email']); // Optional, if they use email
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['tenant_id']);
            $table->dropColumn(['tenant_id', 'employee_id', 'division', 'device_id', 'face_descriptor', 'phone', 'role', 'profile_photo_path']);
        });
    }
};
