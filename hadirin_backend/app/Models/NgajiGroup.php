<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class NgajiGroup extends Model
{
    protected $fillable = ['tenant_id', 'name'];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }

    public function logs()
    {
        return $this->hasMany(NgajiLog::class);
    }
}
