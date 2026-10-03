<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'image_url',
    'is_active',
])]
class Announcement extends Model
{
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'views_count' => 'integer',
        ];
    }
}
