<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable([
    'title',
    'tag',
    'image_url',
    'cta_label',
    'link_type',
    'link_value',
    'is_active',
    'sort_order',
])]
class HeroSlide extends Model
{
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}
