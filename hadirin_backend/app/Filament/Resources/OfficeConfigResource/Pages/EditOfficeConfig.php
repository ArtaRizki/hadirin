<?php

namespace App\Filament\Resources\OfficeConfigResource\Pages;

use App\Filament\Resources\OfficeConfigResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditOfficeConfig extends EditRecord
{
    protected static string $resource = OfficeConfigResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
