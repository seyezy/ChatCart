<?php
namespace Database\Seeders;

use App\Models\{Admin,AppUser,MarketplaceCategory,Order,OrderItem,Product,Role};
use App\Services\FirebaseService;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\{DB,File,Http};
use Kreait\Firebase\Exception\Auth\UserNotFound;

class DemoSeeder extends Seeder
{
    public function run(): void
    {
        if (!app()->environment(['local', 'development']) || config('database.connections.mysql.database') !== 'chatcart_dev') {
            throw new \RuntimeException('DemoSeeder is restricted to the local chatcart_dev database.');
        }
        $this->call(DatabaseSeeder::class);
        $root = dirname(base_path()).'/.local';
        File::ensureDirectoryExists($root);
        $credentialsPath = $root.'/demo-credentials.json';
        $credentials = File::exists($credentialsPath) ? json_decode(File::get($credentialsPath), true, 512, JSON_THROW_ON_ERROR) : [];
        $names = ['Amara Okafor', 'Tunde Adeyemi', 'Zainab Bello', 'Chidi Nwosu'];
        $photos = [
            'photo-1531123897727-8f129e1688ce',
            'photo-1500648767791-00dcc994a43e',
            'photo-1534528741775-53994a69daeb',
            'photo-1506794778202-cad84cf45f1d',
        ];
        $localOnly = getenv('CHATCART_DEMO_LOCAL_ONLY') === '1';
        $auth = $localOnly ? null : app(FirebaseService::class)->auth();
        $access = null;
        if (!$localOnly) {
            $key = json_decode(File::get(config('chatcart.firebase_credentials')), true, 512, JSON_THROW_ON_ERROR);
            $google = new ServiceAccountCredentials('https://www.googleapis.com/auth/cloud-platform', $key);
            $access = $google->fetchAuthToken()['access_token'];
        }
        $project = config('chatcart.firebase_project_id');
        $users = [];
        foreach ($names as $i => $name) {
            $uid = 'chatcart-local-demo-'.($i + 1);
            $phone = '+1650555010'.($i + 1);
            $credentials[$phone] = ['otp'=>'123456', 'uid'=>$uid, 'name'=>$name];
            unset($credentials['demo'.($i+1).'@chatcart.test']);
            File::put($credentialsPath, json_encode($credentials, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
            $photo = 'http://10.0.2.2:8000/storage/demo/customer-'.($i + 1).'.jpg';
            $this->image('customer-'.($i+1), $photos[$i]);
            if (!$localOnly) {
                try {
                    $record = $auth->getUser($uid);
                    if ($record->phoneNumber !== $phone) throw new \RuntimeException("Conflicting Firebase demo UID: $uid");
                } catch (UserNotFound) {
                    $auth->createUser(['uid'=>$uid, 'phoneNumber'=>$phone, 'displayName'=>$name, 'photoUrl'=>$photo, 'disabled'=>false]);
                }
                $url = "https://firestore.googleapis.com/v1/projects/$project/databases/(default)/documents/users/$uid";
                $response = Http::withToken($access)->timeout(30)->get($url);
                if ($response->status() === 404) {
                    $response = Http::withToken($access)->timeout(30)->patch($url.'?currentDocument.exists=false', ['fields'=>[
                        'uid'=>['stringValue'=>$uid], 'displayName'=>['stringValue'=>$name],
                        'phone'=>['stringValue'=>$phone], 'photoUrl'=>['stringValue'=>$photo],
                        'createdAt'=>['timestampValue'=>now()->toIso8601String()],
                        'updatedAt'=>['timestampValue'=>now()->toIso8601String()],
                    ]]);
                }
                if (!$response->successful()) throw new \RuntimeException("Firestore profile $uid failed: HTTP ".$response->status());
            }
            $users[] = AppUser::firstOrCreate(['firebase_uid'=>$uid], ['phone'=>$phone,'display_name'=>$name,'status'=>'active']);
            $this->command->info("Demo customer ready".($localOnly ? ' (local database only)' : '').": $phone");
        }


        $catalog = [
            ['Wireless Headphones','Electronics',45000,'photo-1505740420928-5e560c06d30e','Comfortable over-ear headphones for music and calls.'],
            ['Everyday Smart Watch','Electronics',32000,'photo-1523275335684-37898b6baf30','A lightweight watch with a clean everyday design.'],
            ['Portable Camera','Electronics',185000,'photo-1516035069371-29a1b244cc32','Capture everyday moments with a compact camera.'],
            ['Classic Sneakers','Fashion',28000,'photo-1542291026-7eec264c27ff','Comfortable sneakers for everyday wear.'],
            ['Everyday Backpack','Fashion',18500,'photo-1553062407-98eeb64c6a62','A practical backpack for work, study and weekend outings.'],
            ['Classic Sunglasses','Fashion',12000,'photo-1511499767150-a48a237f0083','Lightweight sunglasses with a timeless frame.'],
            ['Accent Chair','Home',95000,'photo-1567538096630-e0c55bd6374c','An accent chair to complete a comfortable reading corner.'],
            ['Ceramic Coffee Mug','Home',6500,'photo-1514228742587-6b1558fcca3d','A ceramic mug for coffee, tea and hot chocolate.'],
            ['Indoor Plant','Home',14000,'photo-1485955900006-10f4d324d411','A potted green plant to brighten your living space.'],
            ['Daily Skincare Set','Beauty',24500,'photo-1556229010-6c3f2c9ca5f8','A simple skincare collection for your daily routine.'],
            ['Signature Perfume','Beauty',38000,'photo-1541643600914-78b084683601','A fragrance for everyday wear and special occasions.'],
            ['Makeup Brushes','Beauty',15500,'photo-1512496015851-a90fb38ba796','A versatile collection of makeup brushes.'],
        ];
        $products = [];
        DB::transaction(function () use ($catalog, $users, &$products) {
            foreach ($catalog as $i => [$title,$category,$price,$photo,$description]) {
                $file = 'product-'.($i+1);
                $this->image($file,$photo);
                $products[] = Product::firstOrCreate(['seller_user_id'=>$users[$i%2]->id,'title'=>$title], [
                    'category_id'=>MarketplaceCategory::where('name',$category)->firstOrFail()->id,
                    'description'=>$description.' Sample listing for local testing.',
                    'price'=>$price,'currency'=>'NGN','stock'=>20+$i,
                    'image_urls'=>['/storage/demo/'.$file.'.jpg'],'status'=>'active',
                ]);
            }
            $states = ['pending','processing','shipped','delivered'];
            foreach (range(0,7) as $i) {
                $buyer = $users[$i%4];
                $product = $products[($i+($i%4<2 ? 1 : 0))%12];
                // Ensure buyers never purchase their own demo listing.
                if ($product->seller_user_id === $buyer->id) $product = $products[($i+1)%12];
                $qty = 1 + ($i%2);
                $subtotal = (float)$product->price * $qty;
                $order = Order::firstOrCreate(['order_no'=>'CC-DEMO-'.str_pad((string)($i+1),4,'0',STR_PAD_LEFT)], [
                    'buyer_user_id'=>$buyer->id,'subtotal'=>$subtotal,'commission'=>round($subtotal*0.05,2),
                    'total'=>$subtotal,'currency'=>'NGN','payment_method'=>'pay_on_delivery',
                    'payment_status'=>$states[$i%4]==='delivered' ? 'paid' : 'unpaid',
                    'status'=>$states[$i%4],
                    'delivery_address'=>['name'=>$buyer->display_name,'address'=>'12 Demo Street','city'=>'Lagos','state'=>'Lagos','country'=>'Nigeria','phone'=>'+2340000000000'],
                ]);
                OrderItem::firstOrCreate(['order_id'=>$order->id,'product_id'=>$product->id], [
                    'seller_user_id'=>$product->seller_user_id,'title'=>$product->title,
                    'quantity'=>$qty,'unit_price'=>$product->price,'line_total'=>$subtotal,
                ]);
                if ($order->wasRecentlyCreated) $product->decrement('stock',$qty);
            }
        });

        $email = 'admin@chatcart.test';
        $credentials[$email] ??= ['password'=>bin2hex(random_bytes(10)).'Aa1!'];
        File::put($credentialsPath, json_encode($credentials, JSON_PRETTY_PRINT|JSON_UNESCAPED_SLASHES));
        $admin = Admin::firstOrCreate(['email'=>$email], ['name'=>'ChatCart Local Admin','password'=>$credentials[$email]['password'],'is_active'=>true]);
        $admin->roles()->syncWithoutDetaching([Role::where('slug','super-admin')->firstOrFail()->id]);
        File::put(storage_path('app/installed.lock'), now()->toIso8601String());
        $this->command->info('Ready: 4 customers, 12 illustrated products, 8 orders, and local admin.');
        $this->command->info('Test login credentials saved privately in .local/demo-credentials.json.');
    }

    private function image(string $name, string $photo): void
    {
        $directory = storage_path('app/public/demo');
        File::ensureDirectoryExists($directory);
        $path = "$directory/$name.jpg";
        if (File::exists($path) && @getimagesize($path)) return;
        $url = "https://images.unsplash.com/$photo?w=800&h=800&fit=crop&fm=jpg&q=85";
        $response = Http::timeout(45)->retry(2,500)->get($url)->throw();
        if (@getimagesizefromstring($response->body()) === false) throw new \RuntimeException("Invalid demo image: $name");
        File::put($path,$response->body());
        File::append("$directory/sources.txt","$name.jpg $url\n");
    }
}
