<?php

namespace App\Filament\Resources;

use App\Filament\Resources\OfficeConfigResource\Pages;
use App\Models\OfficeConfig;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class OfficeConfigResource extends Resource
{
    protected static ?string $model = OfficeConfig::class;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';

    public static function shouldRegisterNavigation(): bool
    {
        return \Filament\Facades\Filament::getCurrentPanel()?->getId() === 'admin';
    }

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Section::make('Informasi Kantor')
                    ->schema([
                        Forms\Components\Select::make('tenant_id')
                            ->relationship('tenant', 'name')
                            ->required()
                            ->searchable(),
                        Forms\Components\TextInput::make('name')
                            ->label('Nama Cabang/Kantor')
                            ->required(),
                    ])->columns(2),

                Forms\Components\Section::make('Geofencing & Lokasi')
                    ->description('Tentukan koordinat dan radius jangkauan absensi.')
                    ->schema([
                        Forms\Components\TextInput::make('latitude')
                            ->required()
                            ->numeric(),
                        Forms\Components\TextInput::make('longitude')
                            ->required()
                            ->numeric(),
                        Forms\Components\TextInput::make('radius')
                            ->label('Radius (Meter)')
                            ->required()
                            ->numeric()
                            ->prefix('m'),
                    ])->columns(3),

                Forms\Components\Section::make('Pengaturan Waktu Kerja')
                    ->schema([
                        Forms\Components\TimePicker::make('start_checkin')
                            ->label('Jam Mulai Masuk')
                            ->required(),
                        Forms\Components\TimePicker::make('limit_checkin')
                            ->label('Batas Jam Masuk')
                            ->required(),
                        Forms\Components\TimePicker::make('start_checkout')
                            ->label('Jam Mulai Pulang')
                            ->required(),
                    ])->columns(3),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('tenant.name')
                    ->label('Instansi')
                    ->searchable(),
                Tables\Columns\TextColumn::make('name')
                    ->label('Kantor')
                    ->searchable(),
                Tables\Columns\TextColumn::make('latitude')
                    ->sortable(),
                Tables\Columns\TextColumn::make('longitude')
                    ->sortable(),
                Tables\Columns\TextColumn::make('radius')
                    ->label('Radius')
                    ->suffix(' m')
                    ->sortable(),
                Tables\Columns\TextColumn::make('start_checkin')
                    ->label('Masuk'),
                Tables\Columns\TextColumn::make('start_checkout')
                    ->label('Pulang'),
            ])
            ->filters([])
            ->actions([
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListOfficeConfigs::route('/'),
            'create' => Pages\CreateOfficeConfig::route('/create'),
            'edit' => Pages\EditOfficeConfig::route('/{record}/edit'),
        ];
    }
}
