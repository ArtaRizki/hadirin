<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('briefings', function (Blueprint $table) {
            $table->id();
            $table->string('tenant_id');
            $table->string('title');
            $table->date('scheduled_date');
            $table->time('scheduled_time');
            $table->text('description')->nullable();
            $table->timestamps();

            $table->foreign('tenant_id')->references('id')->on('tenants')->onDelete('cascade');
        });

        Schema::create('briefing_attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('briefing_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('status')->default('Hadir'); // Hadir, Tidak Hadir
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('briefing_attendances');
        Schema::dropIfExists('briefings');
    }
};
