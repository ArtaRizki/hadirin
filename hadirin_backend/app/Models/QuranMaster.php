<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class QuranMaster extends Model
{
    protected $fillable = ['tenant_id', 'type', 'name'];

    public function tenant()
    {
        return $this->belongsTo(Tenant::class);
    }
}
