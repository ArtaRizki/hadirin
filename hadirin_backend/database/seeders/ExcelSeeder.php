<?php

namespace Database\Seeders;

use App\Models\Tenant;
use App\Models\User;
use App\Models\OfficeConfig;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use PhpOffice\PhpSpreadsheet\IOFactory;

class ExcelSeeder extends Seeder
{
    public function run(): void
    {
        $filePath = 'd:/INFORMATICS/FREELANCE/hadirin/sdit-palu.xlsx';
        $spreadsheet = IOFactory::load($filePath);

        // 1. Seed Tenant & Office Config
        $configSheet = $spreadsheet->getSheetByName('Config_Kantor');
        $configData = $configSheet->toArray();
        $row1 = $configData[1];

        $tenantId = 'SDIT-PALU';
        $tenant = Tenant::updateOrCreate(
            ['id' => $tenantId],
            ['name' => 'SDIT Al-Fahmi Palu', 'radius' => (int)$row1[3]]
        );

        OfficeConfig::updateOrCreate(
            ['tenant_id' => $tenant->id],
            [
                'name' => 'Kantor Utama',
                'latitude' => $row1[1],
                'longitude' => $row1[2],
                'radius' => (int)$row1[3],
                'start_checkin' => $row1[4] ?: '05:00',
                'limit_checkin' => $row1[5] ?: '07:15',
                'start_checkout' => $row1[6] ?: '14:30',
            ]
        );

        // 2. Seed Users
        $userSheet = $spreadsheet->getSheetByName('Master_Karyawan');
        $userData = $userSheet->toArray();

        foreach ($userData as $index => $row) {
            if ($index == 0 || !array_filter($row)) continue;

            User::updateOrCreate(
                ['tenant_id' => $tenant->id, 'employee_id' => $row[0]],
                [
                    'name' => $row[1],
                    'division' => $row[2],
                    'device_id' => $row[3],
                    'face_descriptor' => $row[4],
                    'phone' => $row[5],
                    'role' => $row[6] ?: 'anggota',
                    'password' => Hash::make('123456'), // Default
                ]
            );
        }
    }
}
