<?php

use Illuminate\Support\Facades\Route;

Route::inertia('/', 'welcome')->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('dashboard');
});

require __DIR__.'/settings.php';


use App\Models\User;

Route::get('/debug/user/{id}', function ($id) {
    return User::findOrFail($id);
})->middleware('auth');