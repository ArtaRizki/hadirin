<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Sample Admin
        \App\Models\User::create([
            'tenant_id' => 'SDIT-PALU',
            'employee_id' => 'ADMIN',
            'name' => 'Super Admin SDIT',
            'role' => 'superAdmin',
            'email' => 'admin@sdit-palu.com',
            'password' => \Illuminate\Support\Facades\Hash::make('HADIRIN_MASTER_2026_AHHH'),
        ]);

        // Sample User
        \App\Models\User::create([
            'tenant_id' => 'SDIT-PALU',
            'employee_id' => 'USR001',
            'name' => 'Ahmad Fauzi',
            'division' => 'Guru Kelas',
            'phone' => '081234567890',
            'role' => 'anggota',
            'email' => 'ahmad@sdit-palu.com',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
        ]);

        \App\Models\User::create([
            'tenant_id' => 'SMA-PGRI',
            'employee_id' => 'SMA001',
            'name' => 'Budi Santoso',
            'division' => 'TU',
            'role' => 'anggota',
            'email' => 'budi@sma-pgri.com',
            'password' => \Illuminate\Support\Facades\Hash::make('123456'),
        ]);
    }
}
