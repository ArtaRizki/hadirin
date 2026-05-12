<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OfficeConfig extends Model
{
    protected $fillable = [
        'tenant_id',
        'name',
        'latitude',
        'longitude',
        'radius',
        'start_checkin',
        'limit_checkin',
        'start_checkout',
    ];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
