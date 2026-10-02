<?php

use App\Http\Controllers\InvoiceController;
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
Route::view('/aide', 'legal.support')->name('legal.support');
Route::redirect('/confidentialite', '/politique-confidentialite');
Route::redirect('/privacy', '/politique-confidentialite');
Route::redirect('/privacy-policy', '/politique-confidentialite');
Route::redirect('/support', '/aide');

Route::get('/facture/{reference}', [InvoiceController::class, 'show'])->name('invoice.show');

/*
|--------------------------------------------------------------------------
| Public storefront — everything else
|--------------------------------------------------------------------------
*/
Route::view('/{any?}', 'storefront')
    ->where('any', '.*')
    ->name('storefront');
