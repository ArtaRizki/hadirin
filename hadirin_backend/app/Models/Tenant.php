<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Tenant extends Model
{
    protected $fillable = ['id', 'name', 'spreadsheet_id', 'drive_folder_id', 'radius', 'batas_jam_masuk'];
    public $incrementing = false;
    protected $keyType = 'string';

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function attendances()
    {
        return $this->hasMany(Attendance::class);
    }

    public function officeConfig()
    {
        return $this->hasOne(OfficeConfig::class);
    }

    public function activities()
    {
        return $this->hasMany(Activity::class);
    }

    public function banners()
    {
        return $this->hasMany(Banner::class);
    }

    public function ngajiGroups()
    {
        return $this->hasMany(NgajiGroup::class);
    }

    public function briefings()
    {
        return $this->hasMany(Briefing::class);
    }
}
