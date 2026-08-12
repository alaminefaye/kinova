<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Email optionnel pour les clients (admin garde un email).
        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable()->change();
        });

        // Index unique téléphone (plusieurs NULL autorisés selon le moteur SQL).
        $driver = Schema::getConnection()->getDriverName();
        if ($driver === 'mysql') {
            $exists = collect(DB::select("SHOW INDEX FROM users WHERE Key_name = 'users_phone_unique'"))->isNotEmpty();
            if (! $exists) {
                Schema::table('users', function (Blueprint $table) {
                    $table->unique('phone');
                });
            }
        } else {
            Schema::table('users', function (Blueprint $table) {
                $table->unique('phone');
            });
        }
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['phone']);
        });

        // Remettre un email factice pour éviter l'échec NOT NULL.
        DB::table('users')->whereNull('email')->update([
            'email' => DB::raw("CONCAT('user-', id, '@kinova.local')"),
        ]);

        Schema::table('users', function (Blueprint $table) {
            $table->string('email')->nullable(false)->change();
        });
    }
};
