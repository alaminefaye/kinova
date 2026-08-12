<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Dashboard SPA (Vue) — served by Laravel
|--------------------------------------------------------------------------
| API routes live in routes/api.php (prefix /api).
| Everything else is handled by the Vue router.
*/

Route::view('/{any?}', 'dashboard')
    ->where('any', '.*')
    ->name('dashboard');
