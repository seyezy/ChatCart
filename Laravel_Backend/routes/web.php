<?php
use Illuminate\Support\Facades\Route; use App\Http\Controllers\InstallController; use App\Http\Controllers\Admin\{AuthController,DashboardController};
Route::get('/install',[InstallController::class,'form'])->name('install'); Route::post('/install',[InstallController::class,'install']);
Route::get('/admin/login',[AuthController::class,'form'])->name('admin.login'); Route::post('/admin/login',[AuthController::class,'login'])->name('admin.login.submit');
Route::middleware('admin')->group(function(){Route::get('/admin',[DashboardController::class,'index'])->middleware('permission:dashboard.view')->name('admin.dashboard');Route::post('/admin/logout',[AuthController::class,'logout'])->name('admin.logout');});
Route::get('/',fn()=>redirect('/admin'));
