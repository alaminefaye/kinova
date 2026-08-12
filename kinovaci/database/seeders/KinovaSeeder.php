<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Category;
use App\Models\ContactMessage;
use App\Models\Favorite;
use App\Models\LoyaltyTransaction;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use App\Services\LoyaltyService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class KinovaSeeder extends Seeder
{
    public function run(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'admin@kinova.test'],
            [
                'name' => 'Admin KINOVA',
                'password' => Hash::make('password'),
                'role' => 'admin',
                'phone' => '+22500000000',
            ]
        );

        $customer = User::query()->updateOrCreate(
            ['email' => 'client@kinova.test'],
            [
                'name' => 'Awa Koné',
                'password' => Hash::make('password'),
                'role' => 'customer',
                'phone' => '+22507000000',
                'address' => 'Cocody, Riviera',
                'city' => 'Abidjan',
                'loyalty_points' => 620,
                'vip_tier' => LoyaltyService::tierFor(620),
            ]
        );

        $categories = [
            [
                'name' => 'Beauté',
                'slug' => 'beauty',
                'image_url' => 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=600&q=80',
                'sort_order' => 1,
            ],
            [
                'name' => 'Mode',
                'slug' => 'fashion',
                'image_url' => 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&q=80',
                'sort_order' => 2,
            ],
            [
                'name' => 'Maison',
                'slug' => 'home',
                'image_url' => 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=600&q=80',
                'sort_order' => 3,
            ],
            [
                'name' => 'Accessoires',
                'slug' => 'accessories',
                'image_url' => 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80',
                'sort_order' => 4,
            ],
        ];

        $categoryIds = [];
        foreach ($categories as $category) {
            $model = Category::query()->updateOrCreate(
                ['slug' => $category['slug']],
                $category + ['is_active' => true]
            );
            $categoryIds[$category['slug']] = $model->id;
        }

        $products = [
            [
                'slug' => 'serum-rose-doree',
                'name' => 'Sérum Rose Dorée',
                'category' => 'beauty',
                'description' => 'Sérum lumineux à la rose et à l’or, pour une peau hydratée et éclatante.',
                'price' => 48,
                'image_url' => 'https://images.unsplash.com/photo-1571781926291-c77df809e0b0?w=800&q=80',
                'is_featured' => true,
                'is_new' => true,
                'rating' => 4.9,
                'stock' => 40,
            ],
            [
                'slug' => 'sac-cuir-sable',
                'name' => 'Sac Cuir Sable',
                'category' => 'fashion',
                'description' => 'Sac en cuir grainé couleur sable, finitions or rose.',
                'price' => 189,
                'image_url' => 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=800&q=80',
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.8,
                'stock' => 15,
            ],
            [
                'slug' => 'bougie-ambre',
                'name' => 'Bougie Ambre',
                'category' => 'home',
                'description' => 'Bougie parfumée ambre & vanille, cire végétale.',
                'price' => 32,
                'image_url' => 'https://images.unsplash.com/photo-1603006905003-be21c6d3c0d6?w=800&q=80',
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.7,
                'stock' => 60,
            ],
            [
                'slug' => 'collier-lune',
                'name' => 'Collier Lune',
                'category' => 'accessories',
                'description' => 'Collier plaqué or avec pendentif croissant de lune.',
                'price' => 75,
                'image_url' => 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=800&q=80',
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.9,
                'stock' => 25,
            ],
            [
                'slug' => 'creme-velours',
                'name' => 'Crème Velours',
                'category' => 'beauty',
                'description' => 'Crème corps nourrissante au beurre de karité.',
                'price' => 36,
                'image_url' => 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?w=800&q=80',
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.6,
                'stock' => 50,
            ],
            [
                'slug' => 'echarpe-cachemire',
                'name' => 'Écharpe Cachemire',
                'category' => 'fashion',
                'description' => 'Écharpe 100 % cachemire, teinte taupe.',
                'price' => 120,
                'image_url' => 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=800&q=80',
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.8,
                'stock' => 20,
            ],
            [
                'slug' => 'vase-ceramique',
                'name' => 'Vase Céramique',
                'category' => 'home',
                'description' => 'Vase artisanal en céramique mate, tons beige et brun.',
                'price' => 58,
                'image_url' => 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?w=800&q=80',
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.7,
                'stock' => 18,
            ],
            [
                'slug' => 'montre-minimal',
                'name' => 'Montre Minimal',
                'category' => 'accessories',
                'description' => 'Montre bracelet cuir cognac, cadran champagne.',
                'price' => 210,
                'image_url' => 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=800&q=80',
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.9,
                'stock' => 12,
            ],
            [
                'slug' => 'huile-capillaire',
                'name' => 'Huile Capillaire',
                'category' => 'beauty',
                'description' => 'Huile légère argan & camélia.',
                'price' => 42,
                'image_url' => 'https://images.unsplash.com/photo-1608248543800-ba2635b1c1ce?w=800&q=80',
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.5,
                'stock' => 35,
            ],
            [
                'slug' => 'blazer-lin-beige',
                'name' => 'Blazer Lin Beige',
                'category' => 'fashion',
                'description' => 'Blazer en lin lavé, coupe droite.',
                'price' => 165,
                'image_url' => 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&q=80',
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.8,
                'stock' => 10,
            ],
        ];

        foreach ($products as $product) {
            Product::query()->updateOrCreate(
                ['slug' => $product['slug']],
                [
                    'category_id' => $categoryIds[$product['category']],
                    'name' => $product['name'],
                    'description' => $product['description'],
                    'price' => $product['price'],
                    'image_url' => $product['image_url'],
                    'gallery' => [$product['image_url']],
                    'rating' => $product['rating'],
                    'stock' => $product['stock'],
                    'is_active' => true,
                    'is_featured' => $product['is_featured'],
                    'is_new' => $product['is_new'],
                ]
            );
        }

        $featured = Product::query()->where('is_featured', true)->take(3)->get();
        foreach ($featured as $product) {
            Favorite::query()->firstOrCreate([
                'user_id' => $customer->id,
                'product_id' => $product->id,
            ]);
        }

        if (Order::query()->count() === 0) {
            $product = Product::query()->first();
            $order = Order::query()->create([
                'reference' => 'KV-DEMO0001',
                'user_id' => $customer->id,
                'customer_name' => $customer->name,
                'customer_phone' => $customer->phone,
                'customer_email' => $customer->email,
                'address' => $customer->address,
                'city' => $customer->city,
                'payment_method' => 'cod',
                'status' => 'shipped',
                'tracking_number' => 'KIN-TRACK-001',
                'carrier' => 'KINOVA Express',
                'subtotal' => $product->price,
                'shipping' => 0,
                'total' => $product->price,
            ]);

            $order->items()->create([
                'product_id' => $product->id,
                'product_name' => $product->name,
                'unit_price' => $product->price,
                'quantity' => 1,
                'line_total' => $product->price,
            ]);
        }

        if (LoyaltyTransaction::query()->where('user_id', $customer->id)->count() === 0) {
            LoyaltyTransaction::query()->create([
                'user_id' => $customer->id,
                'points' => 620,
                'type' => 'bonus',
                'description' => 'Bonus bienvenue KINOVA',
            ]);
        }

        if (AppNotification::query()->where('user_id', $customer->id)->count() === 0) {
            AppNotification::query()->create([
                'user_id' => $customer->id,
                'title' => 'Livraison en cours',
                'message' => 'Votre commande KV-DEMO0001 est en route (KIN-TRACK-001).',
                'category' => 'order',
                'icon' => 'package',
                'is_read' => false,
                'data' => ['order_reference' => 'KV-DEMO0001'],
            ]);
            AppNotification::query()->create([
                'user_id' => $customer->id,
                'title' => 'Statut Silver',
                'message' => 'Bravo ! Vous êtes Silver avec 620 points.',
                'category' => 'vip',
                'icon' => 'star',
                'is_read' => false,
            ]);
            AppNotification::query()->create([
                'user_id' => null,
                'title' => 'Promo printemps',
                'message' => '-15 % sur la sélection Beauté ce week-end.',
                'category' => 'promo',
                'icon' => 'tag',
                'is_read' => true,
            ]);
        }

        if (ContactMessage::query()->count() === 0) {
            ContactMessage::query()->create([
                'user_id' => $customer->id,
                'name' => $customer->name,
                'email' => $customer->email,
                'phone' => $customer->phone,
                'subject' => 'Question livraison',
                'message' => 'Bonjour, peut-on livrer le week-end à Cocody ?',
                'status' => 'new',
            ]);
        }
    }
}
