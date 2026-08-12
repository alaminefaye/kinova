<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Admin SPA — /dashboard/admin/*
|--------------------------------------------------------------------------
*/
Route::view('/dashboard/admin/{any?}', 'dashboard')
    ->where('any', '.*')
    ->name('admin.dashboard');

/*
|--------------------------------------------------------------------------
| Public storefront — everything else
|--------------------------------------------------------------------------
*/
Route::view('/{any?}', 'storefront')
    ->where('any', '.*')
    ->name('storefront');
