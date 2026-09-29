<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\{AppUser, Order, Product, Report, SellerKyc, SupportTicket, Transaction};
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $stats = [
            'users' => AppUser::count(),
            'products' => Product::count(),
            'orders' => Order::count(),
            'reports' => Report::where('status', 'open')->count(),
            'kyc' => SellerKyc::where('status', 'pending')->count(),
            'tickets' => SupportTicket::where('status', 'open')->count(),
            'transactions' => Transaction::count(),
        ];

        return $request->expectsJson()
            ? response()->json(['stats' => $stats])->header('Cache-Control', 'no-store')
            : view('admin.dashboard', ['stats' => $stats]);
    }
}