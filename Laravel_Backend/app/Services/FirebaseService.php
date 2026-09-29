<?php
namespace App\Services;

use Kreait\Firebase\Factory;

class FirebaseService
{
    public function auth()
    {
        $factory = (new Factory)->withServiceAccount(config('chatcart.firebase_credentials'));
        if (config('chatcart.firebase_project_id')) $factory = $factory->withProjectId(config('chatcart.firebase_project_id'));
        return $factory->createAuth();
    }
}
