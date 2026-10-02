<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'reference',
    'user_id',
    'customer_name',
    'customer_phone',
    'customer_email',
    'is_delivery',
    'address',
    'city',
    'latitude',
    'longitude',
    'delivery_details',
    'payment_method',
    'payment_status',
    'paid_at',
    'delivered_at',
    'status',
    'tracking_number',
    'carrier',
    'subtotal',
    'shipping',
    'total',
    'notes',
])]
class Order extends Model
{
    protected $appends = [
        'invoice_number',
        'invoice_status',
        'invoice_url',
        'maps_url',
    ];

    protected function casts(): array
    {
        return [
            'is_delivery' => 'boolean',
            'latitude' => 'float',
            'longitude' => 'float',
            'subtotal' => 'decimal:2',
            'shipping' => 'decimal:2',
            'total' => 'decimal:2',
            'paid_at' => 'datetime',
            'delivered_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function getInvoiceNumberAttribute(): string
    {
        return 'FAC-'.$this->reference;
    }

    /**
     * provisional : commande passée, pas encore livrée et payée
     * confirmed   : colis livré et payé
     * cancelled   : commande annulée
     */
    public function getInvoiceStatusAttribute(): string
    {
        if ($this->status === 'cancelled') {
            return 'cancelled';
        }

        return ($this->status === 'delivered' && $this->payment_status === 'paid')
            ? 'confirmed'
            : 'provisional';
    }

    public function invoiceToken(): string
    {
        return substr(hash_hmac('sha256', 'invoice:'.$this->reference, (string) config('app.key')), 0, 32);
    }

    public function getInvoiceUrlAttribute(): ?string
    {
        if (! $this->reference) {
            return null;
        }

        return url("/facture/{$this->reference}?t=".$this->invoiceToken());
    }

    public function getMapsUrlAttribute(): ?string
    {
        if ($this->latitude === null || $this->longitude === null) {
            return null;
        }

        return "https://www.google.com/maps/search/?api=1&query={$this->latitude},{$this->longitude}";
    }
}
