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
                'latitude' => -0.8917, // Dummy coords
                'longitude' => 119.8707,
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

        $this->command->info('Dummy data seeded successfully.');
    }
}
