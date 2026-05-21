<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Models\User;
use App\Models\OfficeConfig;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Create a dummy tenant
        $tenantId = 'SDIT-PALU';
        $tenant = Tenant::updateOrCreate(
            ['id' => $tenantId],
            [
                'name' => 'SDIT Al-Fahmi Palu',
                'radius' => 200,
                'batas_jam_masuk' => 7,
            ]
        );

        // 2. Create Office Config
        OfficeConfig::updateOrCreate(
            ['tenant_id' => $tenant->id],
            [
                'name' => 'Kampus Utama',
                'latitude' => -0.9115832,
                'longitude' => 119.8900044,
                'radius' => 200,
                'start_checkin' => '05:00:00',
                'limit_checkin' => '07:30:00',
                'start_checkout' => '13:00:00',
            ]
        );

        // 3. Create Admin
        User::updateOrCreate(
            ['employee_id' => 'ADMIN', 'tenant_id' => $tenant->id],
            [
                'name' => 'Super Admin',
                'role' => 'admin',
                'password' => Hash::make('HADIRIN_MASTER_2026_AHHH'),
            ]
        );

        // 4. Create dummy employee
        User::updateOrCreate(
            ['employee_id' => 'GURU-001', 'tenant_id' => $tenant->id],
            [
                'name' => 'Budi Santoso',
                'division' => 'Guru Kelas',
                'role' => 'anggota',
                'password' => Hash::make('123456'),
            ]
        );

        // 5. Create Quran Students (Siswa)
        \App\Models\QuranStudent::updateOrCreate(
            ['nis' => 'SISWA-001', 'tenant_id' => $tenant->id],
            ['name' => 'Ali bin Abi Thalib', 'class' => 'Kelas 1-A']
        );
        \App\Models\QuranStudent::updateOrCreate(
            ['nis' => 'SISWA-002', 'tenant_id' => $tenant->id],
            ['name' => 'Fathimah Az-Zahra', 'class' => 'Kelas 1-A']
        );
        \App\Models\QuranStudent::updateOrCreate(
            ['nis' => 'SISWA-003', 'tenant_id' => $tenant->id],
            ['name' => 'Umar bin Khattab', 'class' => 'Kelas 1-B']
        );
        \App\Models\QuranStudent::updateOrCreate(
            ['nis' => 'SISWA-004', 'tenant_id' => $tenant->id],
            ['name' => 'Aisyah binti Abu Bakar', 'class' => 'Kelas 1-B']
        );

        // 6. Create Quran Masters (Surah / Materi)
        \App\Models\QuranMaster::updateOrCreate(
            ['name' => 'Surah An-Naba', 'tenant_id' => $tenant->id],
            ['type' => 'Hafalan']
        );
        \App\Models\QuranMaster::updateOrCreate(
            ['name' => 'Surah An-Naziat', 'tenant_id' => $tenant->id],
            ['type' => 'Hafalan']
        );
        \App\Models\QuranMaster::updateOrCreate(
            ['name' => 'Surah Abasa', 'tenant_id' => $tenant->id],
            ['type' => 'Hafalan']
        );
        \App\Models\QuranMaster::updateOrCreate(
            ['name' => 'Surah At-Takwir', 'tenant_id' => $tenant->id],
            ['type' => 'Hafalan']
        );
        \App\Models\QuranMaster::updateOrCreate(
            ['name' => 'Surah Al-Infitar', 'tenant_id' => $tenant->id],
            ['type' => 'Hafalan']
        );

        // 7. Create Quran Halaqah Groups (Kelompok Ngaji)
        \App\Models\NgajiGroup::updateOrCreate(
            ['name' => 'Kelompok Abu Bakar', 'tenant_id' => $tenant->id]
        );
        \App\Models\NgajiGroup::updateOrCreate(
            ['name' => 'Kelompok Umar bin Khattab', 'tenant_id' => $tenant->id]
        );
        \App\Models\NgajiGroup::updateOrCreate(
            ['name' => 'Kelompok Utsman bin Affan', 'tenant_id' => $tenant->id]
        );
        \App\Models\NgajiGroup::updateOrCreate(
            ['name' => 'Kelompok Ali bin Abi Thalib', 'tenant_id' => $tenant->id]
        );

        // 8. Call ExcelSeeder if excel file exists
        $excelPath = base_path('sdit-palu.xlsx');
        $hasExcel = false;

        try {
            if (file_exists($excelPath)) {
                $hasExcel = true;
            } elseif (!ini_get('open_basedir')) {
                $parentPath = base_path('../sdit-palu.xlsx');
                if (file_exists($parentPath)) {
                    $excelPath = $parentPath;
                    $hasExcel = true;
                }
            }
        } catch (\Throwable $e) {
            $hasExcel = false;
        }

        if ($hasExcel) {
            $this->call(ExcelSeeder::class);
        }

        $this->command->info('Dummy data and Excel master records seeded successfully.');
    }
}
