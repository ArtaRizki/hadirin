<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('quran_masters', function (Blueprint $table) {
            $table->id();
            $table->string('tenant_id');
            $table->string('type'); // Hafalan, Murojaah, Tilawah, dll
            $table->string('name'); // nama materi/surah
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
        });

        Schema::create('quran_students', function (Blueprint $table) {
            $table->id();
            $table->string('tenant_id');
            $table->string('nis')->unique();
            $table->string('name');
            $table->string('class')->nullable();
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
        });

        Schema::create('quran_logs', function (Blueprint $table) {
            $table->id();
            $table->string('tenant_id');
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // guru
            $table->string('student_nis');
            $table->foreignId('quran_master_id')->constrained()->onDelete('cascade');
            $table->string('halaman_ayat')->nullable();
            $table->string('nilai')->nullable();
            $table->text('keterangan')->nullable();
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('quran_logs');
        Schema::dropIfExists('quran_students');
        Schema::dropIfExists('quran_masters');
    }
};
