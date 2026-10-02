<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->boolean('is_delivery')->default(true)->after('customer_email');
            $table->decimal('latitude', 10, 7)->nullable()->after('city');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->text('delivery_details')->nullable()->after('longitude');
            $table->string('payment_status')->default('unpaid')->after('payment_method'); // unpaid|paid
            $table->timestamp('paid_at')->nullable()->after('payment_status');
            $table->timestamp('delivered_at')->nullable()->after('paid_at');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'is_delivery',
                'latitude',
                'longitude',
                'delivery_details',
                'payment_status',
                'paid_at',
                'delivered_at',
            ]);
        });
    }
};
