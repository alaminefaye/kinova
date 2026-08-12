<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('address')->nullable()->after('phone');
            $table->string('city')->nullable()->after('address');
            $table->unsignedInteger('loyalty_points')->default(0)->after('city');
            $table->string('vip_tier')->default('standard')->after('loyalty_points'); // standard|silver|gold|vip
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['address', 'city', 'loyalty_points', 'vip_tier']);
        });
    }
};
