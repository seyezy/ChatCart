<?php
require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
function check(bool $condition, string $message): void {
    if (!$condition) throw new RuntimeException($message);
    echo "PASS: $message\n";
}
check(app()->environment(['development','local']), 'Development environment');
check(App\Models\AppUser::where('firebase_uid','like','chatcart-local-demo-%')->count() === 4, 'Four demo customers');
$orders = App\Models\Order::where('order_no','like','CC-DEMO-%')->get();
check($orders->count() === 8, 'Eight demo orders');
foreach ($orders as $order) {
    $items = App\Models\OrderItem::where('order_id',$order->id)->get();
    check(abs($items->sum('line_total') - $order->subtotal) < .01 && abs($order->total - $order->subtotal) < .01, $order->order_no.' totals match items');
    check($items->every(fn($item) => $item->seller_user_id !== $order->buyer_user_id), $order->order_no.' buyer differs from seller');
}
$client = new GuzzleHttp\Client(['base_uri'=>'http://127.0.0.1:8000','cookies'=>true,'http_errors'=>false,'timeout'=>10]);
check($client->get('/up')->getStatusCode() === 200,'Laravel health');
$products=json_decode((string)$client->get('/api/v1/products')->getBody(),true)['products'];
check(count($products) === 12, 'Twelve products returned by API');
foreach($products as $product) {
    $image=$client->get($product['imageUrls'][0]);
    check($image->getStatusCode()===200 && getimagesizefromstring((string)$image->getBody())!==false,$product['title'].' image');
}
foreach(range(1,4) as $i) check($client->get('/storage/demo/customer-'.$i.'.jpg')->getStatusCode()===200,'Customer '.$i.' portrait');
check($client->get('/api/v1/orders',['headers'=>['Accept'=>'application/json']])->getStatusCode()===401,'Orders require authentication');
$html=(string)$client->get('/admin/login')->getBody();
preg_match('/name="_token"[^>]*value="([^"]+)"/',$html,$match);
check(isset($match[1]),'Admin CSRF form');
$credentials=json_decode(file_get_contents(dirname(__DIR__,2).'/.local/demo-credentials.json'),true);
$response=$client->post('/admin/login',['form_params'=>['_token'=>$match[1],'email'=>'admin@chatcart.test','password'=>$credentials['admin@chatcart.test']['password']]]);
check($response->getStatusCode()===200 && str_contains((string)$response->getBody(),'ChatCart operations overview'),'Admin login and dashboard');
check($client->get('/install')->getStatusCode()===404,'Installer locked');
