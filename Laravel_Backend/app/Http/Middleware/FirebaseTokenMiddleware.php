<?php
namespace App\Http\Middleware;

use App\Models\AppUser;
use App\Services\FirebaseService;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class FirebaseTokenMiddleware
{
    public function __construct(private FirebaseService $firebase) {}

    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();
        abort_unless($token, 401, 'Firebase bearer token required.');
        try { $verified = $this->firebase->auth()->verifyIdToken($token); }
        catch (\Throwable $e) { abort(401, 'Invalid or expired Firebase token.'); }
        $uid = $verified->claims()->get('sub');
        $claims=$verified->claims(); $email=$claims->has('email')?$claims->get('email'):null; $phone=$claims->has('phone_number')?$claims->get('phone_number'):null; $user=AppUser::firstOrCreate(['firebase_uid'=>$uid],['email'=>$email,'phone'=>$phone]);
        $request->attributes->set('firebase_uid', $uid);
        $request->attributes->set('app_user', $user);
        return $next($request);
    }
}
