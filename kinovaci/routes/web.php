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
| Pages légales (hors SPA — accessibles directement pour les stores)
|--------------------------------------------------------------------------
*/
Route::view('/politique-confidentialite', 'legal.privacy')->name('legal.privacy');
Route::redirect('/confidentialite', '/politique-confidentialite');
Route::redirect('/privacy', '/politique-confidentialite');
Route::redirect('/privacy-policy', '/politique-confidentialite');

/*
|--------------------------------------------------------------------------
| Public storefront — everything else
|--------------------------------------------------------------------------
*/
Route::view('/{any?}', 'storefront')
    ->where('any', '.*')
    ->name('storefront');
