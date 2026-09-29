<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\V1\{AnnouncementController,DeviceController,KycController,OrderController,ProductController,ReportController,SupportController};
Route::prefix('v1')->group(function(){
 Route::get('/products',[ProductController::class,'index']); Route::get('/products/{product}',[ProductController::class,'show']);
 Route::middleware('firebase')->group(function(){
  Route::post('/reports/users',[ReportController::class,'user']); Route::post('/reports/messages',[ReportController::class,'message']);
  Route::get('/seller/kyc',[KycController::class,'show']); Route::post('/seller/kyc',[KycController::class,'store']);
  Route::get('/orders',[OrderController::class,'index']); Route::post('/orders',[OrderController::class,'store']);
  Route::get('/support/tickets',[SupportController::class,'index']); Route::post('/support/tickets',[SupportController::class,'store']);
  Route::get('/announcements',[AnnouncementController::class,'index']);
  Route::get('/devices',[DeviceController::class,'index']); Route::post('/devices',[DeviceController::class,'register']); Route::post('/devices/{deviceId}/revoke',[DeviceController::class,'revoke']);
 });
});
