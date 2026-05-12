<?php

namespace App\Filament\Widgets;

use App\Models\Attendance;
use Filament\Widgets\ChartWidget;
use Illuminate\Support\Facades\DB;

class AttendanceChart extends ChartWidget
{
    public static function canView(): bool
    {
        return \Filament\Facades\Filament::getCurrentPanel()?->getId() === 'admin';
    }

    protected static ?string $heading = 'Tren Kehadiran (7 Hari Terakhir)';

    protected function getData(): array
    {
        $data = Attendance::select(DB::raw('date(created_at) as date'), DB::raw('count(*) as aggregate'))
            ->where('type', 'Masuk')
            ->where('created_at', '>=', now()->subDays(7))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return [
            'datasets' => [
                [
                    'label' => 'Total Kehadiran',
                    'data' => $data->pluck('aggregate')->toArray(),
                    'fill' => 'start',
                ],
            ],
            'labels' => $data->pluck('date')->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
