<?php

namespace App\Filament\Resources\OfficeConfigResource\Pages;

use App\Filament\Resources\OfficeConfigResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListOfficeConfigs extends ListRecords
{
    protected static string $resource = OfficeConfigResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
