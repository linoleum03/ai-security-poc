<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::inertia('/', 'welcome')->name('home');

Route::middleware(['auth', 'verified'])->group(function () {
    Route::inertia('dashboard', 'dashboard')->name('dashboard');
});

require __DIR__.'/settings.php';

Route::get('/debug/user', function (Request $request) {
    return $request->user();
})->middleware('auth');