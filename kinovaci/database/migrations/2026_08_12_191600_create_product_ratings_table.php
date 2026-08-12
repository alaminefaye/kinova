<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_ratings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('stars'); // 1..5
            $table->timestamps();

            $table->unique(['user_id', 'product_id']);
        });

        Schema::table('products', function (Blueprint $table) {
            $table->unsignedInteger('ratings_count')->default(0)->after('rating');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn('ratings_count');
        });
        Schema::dropIfExists('product_ratings');
    }
};
