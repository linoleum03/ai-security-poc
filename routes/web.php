<?php

use App\Http\Controllers\WebhookTestController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::inertia('/', 'welcome')->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('dashboard');
});

require __DIR__.'/settings.php';

Route::middleware(['auth'])->group(function () {
    Route::get('webhooks/test', [WebhookTestController::class, 'edit'])->name('webhooks.test');
    Route::post('webhooks/test', [WebhookTestController::class, 'store'])->name('webhooks.test.submit');
});

Route::get('/debug/user', function (Request $request) {
    return $request->user();
})->middleware('auth');


use App\Models\User;

Route::get('/debug/user/{id}', function ($id) {
    return User::findOrFail($id);
})->middleware('auth');