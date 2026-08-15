<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->json('sizes')->nullable()->after('gallery');
            $table->json('colors')->nullable()->after('sizes');
        });

        Schema::table('order_items', function (Blueprint $table) {
            $table->string('selected_size')->nullable()->after('quantity');
            $table->string('selected_color')->nullable()->after('selected_size');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn(['sizes', 'colors']);
        });

        Schema::table('order_items', function (Blueprint $table) {
            $table->dropColumn(['selected_size', 'selected_color']);
        });
    }
};
