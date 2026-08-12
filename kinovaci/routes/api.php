<?php

use App\Http\Controllers\Api\Admin\CategoryController as AdminCategoryController;
use App\Http\Controllers\Api\Admin\ContactMessageController as AdminContactMessageController;
use App\Http\Controllers\Api\Admin\DashboardController;
use App\Http\Controllers\Api\Admin\HeroSlideController as AdminHeroSlideController;
use App\Http\Controllers\Api\Admin\LoyaltyController as AdminLoyaltyController;
use App\Http\Controllers\Api\Admin\MediaController;
use App\Http\Controllers\Api\Admin\NotificationController as AdminNotificationController;
use App\Http\Controllers\Api\Admin\OrderController as AdminOrderController;
use App\Http\Controllers\Api\Admin\ProductController as AdminProductController;
use App\Http\Controllers\Api\Admin\UserController as AdminUserController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\ContactController;
use App\Http\Controllers\Api\HeroSlideController;
use App\Http\Controllers\Api\Customer\AuthController as CustomerAuthController;
use App\Http\Controllers\Api\Customer\FavoriteController;
use App\Http\Controllers\Api\Customer\LoyaltyController as CustomerLoyaltyController;
use App\Http\Controllers\Api\Customer\NotificationController as CustomerNotificationController;
use App\Http\Controllers\Api\Customer\OrderController as CustomerOrderController;
use App\Http\Controllers\Api\Customer\ProfileController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\ProductController;
use App\Http\Middleware\EnsureUserIsAdmin;
use Illuminate\Support\Facades\Route;

Route::get('/health', fn () => response()->json([
    'status' => 'ok',
    'app' => config('app.name'),
]));

/*
|--------------------------------------------------------------------------
| API publique (future app mobile)
|--------------------------------------------------------------------------
*/
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/categories/{category}', [CategoryController::class, 'show']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/products/{product}', [ProductController::class, 'show']);
Route::get('/hero-slides', [HeroSlideController::class, 'index']);
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/orders/{reference}', [OrderController::class, 'show']);
Route::get('/help', [ContactController::class, 'help']);
Route::post('/contact', [ContactController::class, 'store']);

/*
|--------------------------------------------------------------------------
| Auth admin (dashboard)
|--------------------------------------------------------------------------
*/
Route::post('/auth/login', [AuthController::class, 'login']);

/*
|--------------------------------------------------------------------------
| Auth client (future app mobile)
|--------------------------------------------------------------------------
*/
Route::post('/customer/auth/register', [CustomerAuthController::class, 'register']);
Route::post('/customer/auth/login', [CustomerAuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    /*
    |--------------------------------------------------------------------------
    | Espace client authentifié
    |--------------------------------------------------------------------------
    */
    Route::prefix('customer')->group(function () {
        Route::get('/profile', [ProfileController::class, 'show']);
        Route::put('/profile', [ProfileController::class, 'update']);
        Route::post('/profile/avatar', [ProfileController::class, 'uploadAvatar']);
        Route::delete('/profile', [ProfileController::class, 'destroy']);

        Route::get('/favorites', [FavoriteController::class, 'index']);
        Route::post('/favorites', [FavoriteController::class, 'store']);
        Route::post('/favorites/sync', [FavoriteController::class, 'sync']);
        Route::delete('/favorites/{productId}', [FavoriteController::class, 'destroy']);

        Route::get('/orders', [CustomerOrderController::class, 'index']);
        Route::get('/orders/{reference}', [CustomerOrderController::class, 'show']);

        Route::get('/notifications', [CustomerNotificationController::class, 'index']);
        Route::post('/notifications/read-all', [CustomerNotificationController::class, 'markAllRead']);
        Route::post('/notifications/{appNotification}/read', [CustomerNotificationController::class, 'markRead']);

        Route::get('/loyalty', [CustomerLoyaltyController::class, 'show']);
        Route::post('/loyalty/redeem', [CustomerLoyaltyController::class, 'redeem']);
    });

    /*
    |--------------------------------------------------------------------------
    | API Admin (dashboard Vue)
    |--------------------------------------------------------------------------
    */
    Route::prefix('admin')->middleware(EnsureUserIsAdmin::class)->group(function () {
        Route::get('/dashboard', DashboardController::class);
        Route::apiResource('categories', AdminCategoryController::class);
        Route::apiResource('products', AdminProductController::class);
        Route::apiResource('hero-slides', AdminHeroSlideController::class);
        Route::apiResource('orders', AdminOrderController::class)->only(['index', 'show', 'update']);

        Route::post('/media', [MediaController::class, 'store']);

        Route::get('/notifications', [AdminNotificationController::class, 'index']);
        Route::post('/notifications', [AdminNotificationController::class, 'store']);
        Route::delete('/notifications/{appNotification}', [AdminNotificationController::class, 'destroy']);

        Route::get('/contact-messages', [AdminContactMessageController::class, 'index']);
        Route::get('/contact-messages/{contactMessage}', [AdminContactMessageController::class, 'show']);
        Route::put('/contact-messages/{contactMessage}', [AdminContactMessageController::class, 'update']);

        Route::get('/loyalty/customers', [AdminLoyaltyController::class, 'customers']);
        Route::post('/loyalty/customers/{user}/adjust', [AdminLoyaltyController::class, 'adjust']);

        Route::apiResource('users', AdminUserController::class);
        Route::post('/users/{user}/toggle-block', [AdminUserController::class, 'toggleBlock']);
    });
});
