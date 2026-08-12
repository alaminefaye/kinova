<?php

namespace Database\Seeders;

use App\Models\AppNotification;
use App\Models\Category;
use App\Models\ContactMessage;
use App\Models\Favorite;
use App\Models\HeroSlide;
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

        $heroSlides = [
            [
                'title' => "Une sélection\npremium pour vous",
                'tag' => 'COLLECTION 2026',
                'image_url' => 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=1400&q=80',
                'cta_label' => 'DÉCOUVRIR',
                'link_type' => 'catalog',
                'sort_order' => 1,
            ],
            [
                'title' => "Beauté & Soins\nd’exception",
                'tag' => 'UNIVERS BEAUTÉ',
                'image_url' => 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=1400&q=80',
                'cta_label' => 'EXPLORER',
                'link_type' => 'category',
                'link_value' => (string) $categoryIds['beauty'],
                'sort_order' => 2,
            ],
            [
                'title' => "Cuir & Finitions\nor métallique",
                'tag' => 'ACCESSOIRES',
                'image_url' => 'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=1400&q=80',
                'cta_label' => 'VOIR LA SÉLECTION',
                'link_type' => 'category',
                'link_value' => (string) $categoryIds['accessories'],
                'sort_order' => 3,
            ],
            [
                'title' => "Maison & Atmosphère\nchaleureuse",
                'tag' => 'ART DE VIVRE',
                'image_url' => 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=1400&q=80',
                'cta_label' => 'DÉCOUVRIR',
                'link_type' => 'category',
                'link_value' => (string) $categoryIds['home'],
                'sort_order' => 4,
            ],
        ];

        foreach ($heroSlides as $slide) {
            HeroSlide::query()->updateOrCreate(
                ['sort_order' => $slide['sort_order']],
                $slide + ['is_active' => true, 'link_value' => $slide['link_value'] ?? null]
            );
        }

        // Désactive d’éventuels anciens slides hors seed (images cassées / hors tri)
        HeroSlide::query()
            ->whereNotIn('sort_order', [1, 2, 3, 4])
            ->update(['is_active' => false]);

        $products = [
            [
                'slug' => 'serum-rose-doree',
                'name' => 'Sérum Rose Dorée',
                'category' => 'beauty',
                'description' => "Sérum lumineux à la rose de Damas et à l’or colloïdal. Texture soyeuse qui pénètre rapidement pour hydrater, lisser et révéler un teint éclatant. Contenance 30 ml.",
                'price' => 28500,
                'image_url' => 'https://images.unsplash.com/photo-1741896135512-084b251887f7?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1741896135512-084b251887f7?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1741896136069-f3588d8993b5?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1741896135490-4062a3b21abf?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => true,
                'rating' => 4.9,
                'ratings_count' => 24,
                'stock' => 40,
            ],
            [
                'slug' => 'creme-velours',
                'name' => 'Crème Velours Karité',
                'category' => 'beauty',
                'description' => "Crème corps nourrissante au beurre de karité et huile de coco. Texture fondante, peau souple et parfumée. Pot 200 ml.",
                'price' => 18500,
                'image_url' => 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.6,
                'ratings_count' => 18,
                'stock' => 50,
            ],
            [
                'slug' => 'huile-capillaire',
                'name' => 'Huile Capillaire Argan',
                'category' => 'beauty',
                'description' => "Huile légère argan & camélia pour nourrir les longueurs sans les alourdir. Brillance immédiate. Flacon 50 ml.",
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1527799820374-dcf8d9d4a388?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1515688594390-b649af70d282?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.5,
                'ratings_count' => 12,
                'stock' => 35,
            ],
            [
                'slug' => 'rouge-velours-kinova',
                'name' => 'Rouge Velours KINOVA',
                'category' => 'beauty',
                'description' => "Rouge à lèvres mat velours, teinte terracotta signature. Tenue longue durée, confort non asséchant. Étui doré.",
                'price' => 14500,
                'image_url' => 'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1631214524020-7e18db9a8f92?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => true,
                'rating' => 4.8,
                'ratings_count' => 31,
                'stock' => 45,
            ],
            [
                'slug' => 'parfum-essence-kinova',
                'name' => 'Parfum Essence KINOVA',
                'category' => 'beauty',
                'description' => "Eau de parfum unisexe notes de bois de santal, rose et musc blanc. Flacon 50 ml, sillage élégant et persistant.",
                'price' => 68000,
                'image_url' => 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1587017539504-67cfbddac569?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => true,
                'rating' => 4.9,
                'ratings_count' => 33,
                'stock' => 30,
            ],
            [
                'slug' => 'masque-argile-doree',
                'name' => 'Masque Argile Dorée',
                'category' => 'beauty',
                'description' => "Masque purifiant à l’argile et paillettes dorées. Affine le grain de peau et matifie sans dessécher. Pot 75 ml.",
                'price' => 21000,
                'image_url' => 'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1556228720-195a672e8a03?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.7,
                'ratings_count' => 14,
                'stock' => 28,
            ],
            [
                'slug' => 'brume-eclat',
                'name' => 'Brume Éclat Visage',
                'category' => 'beauty',
                'description' => "Brume hydratante vitamine C et eau de rose. Fixe le maquillage et ravive l’éclat en journée. Spray 100 ml.",
                'price' => 16000,
                'image_url' => 'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1741896135512-084b251887f7?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.6,
                'ratings_count' => 9,
                'stock' => 40,
            ],
            [
                'slug' => 'sac-cuir-sable',
                'name' => 'Sac Cuir Sable',
                'category' => 'fashion',
                'description' => "Sac en cuir grainé couleur sable, finitions or rose et doublure coton. Porté main ou épaule. 28 × 18 × 10 cm.",
                'price' => 89000,
                'image_url' => 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1584917865442-de89df76afd3?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1590874103328-eac38a683ce7?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.8,
                'ratings_count' => 19,
                'stock' => 15,
            ],
            [
                'slug' => 'echarpe-cachemire',
                'name' => 'Écharpe Cachemire Taupe',
                'category' => 'fashion',
                'description' => "Écharpe 100 % cachemire, teinte taupe douce. Toucher exceptionnel, finitions frangées. 200 × 70 cm.",
                'price' => 55000,
                'image_url' => 'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1520903920243-00d872a2d1c9?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1576566588028-4147f3842f27?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.8,
                'ratings_count' => 9,
                'stock' => 20,
            ],
            [
                'slug' => 'blazer-lin-beige',
                'name' => 'Blazer Lin Beige',
                'category' => 'fashion',
                'description' => "Blazer en lin lavé, coupe droite légèrement structurée. Couleur beige sable, boutons nacre. Tailles 36 à 44.",
                'price' => 78000,
                'image_url' => 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.8,
                'ratings_count' => 14,
                'stock' => 10,
            ],
            [
                'slug' => 'robe-soie-ivoire',
                'name' => 'Robe Soie Ivoire',
                'category' => 'fashion',
                'description' => "Robe fluide en soie lavée ivoire, drapé élégant et ceinture fine. Longueur midi. Tailles 34 à 42.",
                'price' => 125000,
                'image_url' => 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => true,
                'rating' => 4.9,
                'ratings_count' => 7,
                'stock' => 8,
            ],
            [
                'slug' => 'trench-beige',
                'name' => 'Trench Beige Classique',
                'category' => 'fashion',
                'description' => "Trench coton mélangé beige, ceinture et boutons ton sur ton. Coupe mi-longue intemporelle. Tailles 36 à 44.",
                'price' => 98000,
                'image_url' => 'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.7,
                'ratings_count' => 11,
                'stock' => 12,
            ],
            [
                'slug' => 'pantalon-fluide',
                'name' => 'Pantalon Fluide Sable',
                'category' => 'fashion',
                'description' => "Pantalon fluide taille haute, tissu léger couleur sable. Jambe large et confortable. Tailles 34 à 42.",
                'price' => 45000,
                'image_url' => 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.5,
                'ratings_count' => 8,
                'stock' => 18,
            ],
            [
                'slug' => 'top-satin-champagne',
                'name' => 'Top Satin Champagne',
                'category' => 'fashion',
                'description' => "Top satiné champagne, bretelles fines et dos croisé. Se porte en soirée ou au quotidien. Tailles 34 à 40.",
                'price' => 32000,
                'image_url' => 'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1515372039744-b8f02a3ae446?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1566174053879-31528523f8ae?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1595777457583-95e059d581b8?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.6,
                'ratings_count' => 10,
                'stock' => 22,
            ],
            [
                'slug' => 'bougie-ambre',
                'name' => 'Bougie Ambre & Vanille',
                'category' => 'home',
                'description' => "Bougie parfumée ambre & vanille en cire végétale. Pot verre fumé, combustion jusqu’à 45 heures.",
                'price' => 16500,
                'image_url' => 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1615529328331-f8917597711f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.7,
                'ratings_count' => 22,
                'stock' => 60,
            ],
            [
                'slug' => 'vase-ceramique',
                'name' => 'Vase Céramique Mate',
                'category' => 'home',
                'description' => "Vase artisanal en céramique mate, tons beige et brun. Forme organique. Hauteur 28 cm.",
                'price' => 32000,
                'image_url' => 'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1581783898377-1c85bf937427?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.7,
                'ratings_count' => 11,
                'stock' => 18,
            ],
            [
                'slug' => 'diffuseur-senteur',
                'name' => 'Diffuseur Senteur Cèdre',
                'category' => 'home',
                'description' => "Diffuseur à bâtonnets cèdre & bergamote. Flacon 100 ml, diffusion jusqu’à 8 semaines.",
                'price' => 19500,
                'image_url' => 'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1615634260167-c8cdede054de?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.6,
                'ratings_count' => 16,
                'stock' => 28,
            ],
            [
                'slug' => 'coussin-velours-dore',
                'name' => 'Coussin Velours Doré',
                'category' => 'home',
                'description' => "Coussin décoratif velours doré champagne, housse amovible. Format 45 × 45 cm.",
                'price' => 24000,
                'image_url' => 'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1615529328331-f8917597711f?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.5,
                'ratings_count' => 8,
                'stock' => 40,
            ],
            [
                'slug' => 'plateau-marbre',
                'name' => 'Plateau Marbre Doré',
                'category' => 'home',
                'description' => "Plateau en marbre veiné avec poignées dorées. Idéal pour service ou décoration. 35 × 20 cm.",
                'price' => 38000,
                'image_url' => 'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1610701596007-11502861dcfa?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1581783898377-1c85bf937427?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1578500494198-246f612d3b3d?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.8,
                'ratings_count' => 6,
                'stock' => 14,
            ],
            [
                'slug' => 'lampe-ambiance',
                'name' => 'Lampe Ambiance Laiton',
                'category' => 'home',
                'description' => "Lampe de table abat-jour tissu crème et pied laiton brossé. Lumière chaude pour salon ou chambre.",
                'price' => 72000,
                'image_url' => 'https://images.unsplash.com/photo-1615529328331-f8917597711f?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1615529328331-f8917597711f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1584100936595-c0654b55a2e2?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.7,
                'ratings_count' => 5,
                'stock' => 9,
            ],
            [
                'slug' => 'collier-lune',
                'name' => 'Collier Lune Or Rose',
                'category' => 'accessories',
                'description' => "Collier plaqué or rose 18k avec pendentif croissant de lune. Chaîne 42 cm + rallonge. Écrin KINOVA inclus.",
                'price' => 35000,
                'image_url' => 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.9,
                'ratings_count' => 27,
                'stock' => 25,
            ],
            [
                'slug' => 'montre-minimal',
                'name' => 'Montre Minimal Cognac',
                'category' => 'accessories',
                'description' => "Montre bracelet cuir cognac, cadran champagne. Mouvement quartz, diamètre 38 mm.",
                'price' => 95000,
                'image_url' => 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1524592094714-0f0654e20314?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1523275335684-37898b6baf30?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1539533018447-63fcce2678e3?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => false,
                'rating' => 4.9,
                'ratings_count' => 15,
                'stock' => 12,
            ],
            [
                'slug' => 'lunettes-soleil-or',
                'name' => 'Lunettes Soleil Or',
                'category' => 'accessories',
                'description' => "Lunettes de soleil monture métal or rose, verres dégradés brun. Protection UV400. Étui inclus.",
                'price' => 42000,
                'image_url' => 'https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1511499767150-a48a237f0083?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1572635196237-14b3f281503f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.7,
                'ratings_count' => 13,
                'stock' => 22,
            ],
            [
                'slug' => 'bague-solitaire',
                'name' => 'Bague Solitaire Champagne',
                'category' => 'accessories',
                'description' => "Bague fine plaqué or, pierre champagne centrale. Tailles 50 à 58. Livrée en écrin.",
                'price' => 28000,
                'image_url' => 'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => true,
                'is_new' => true,
                'rating' => 4.8,
                'ratings_count' => 17,
                'stock' => 20,
            ],
            [
                'slug' => 'bracelet-maille',
                'name' => 'Bracelet Maille Or',
                'category' => 'accessories',
                'description' => "Bracelet maille gourmette plaqué or rose. Fermoir sécurisé. Longueur ajustable 16–19 cm.",
                'price' => 31000,
                'image_url' => 'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1605100804763-247f67b3557e?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => false,
                'rating' => 4.6,
                'ratings_count' => 12,
                'stock' => 26,
            ],
            [
                'slug' => 'boucles-lune',
                'name' => 'Boucles d’Oreilles Lune',
                'category' => 'accessories',
                'description' => "Puces croissant de lune plaqué or rose. Légères et hypoallergéniques. Paire avec emballage cadeau.",
                'price' => 18500,
                'image_url' => 'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?auto=format&fit=crop&w=900&q=80',
                'gallery' => [
                    'https://images.unsplash.com/photo-1617038260897-41a1f14a8ca0?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?auto=format&fit=crop&w=900&q=80',
                    'https://images.unsplash.com/photo-1599643478518-a784e5dc4c8f?auto=format&fit=crop&w=900&q=80',
                ],
                'is_featured' => false,
                'is_new' => true,
                'rating' => 4.8,
                'ratings_count' => 20,
                'stock' => 35,
            ],
        ];

        // Remplace les anciennes URLs cassées / galeries vides
        $fallbackGallery = [
            'https://images.unsplash.com/photo-1483985988355-763728e1935b?auto=format&fit=crop&w=900&q=80',
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?auto=format&fit=crop&w=900&q=80',
            'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&w=900&q=80',
        ];

        foreach ($products as $product) {
            $gallery = array_values(array_filter($product['gallery'] ?? []));
            if ($gallery === []) {
                $gallery = [$product['image_url'], ...$fallbackGallery];
            }

            Product::query()->updateOrCreate(
                ['slug' => $product['slug']],
                [
                    'category_id' => $categoryIds[$product['category']],
                    'name' => $product['name'],
                    'description' => $product['description'],
                    'price' => $product['price'],
                    'image_url' => $product['image_url'],
                    'gallery' => $gallery,
                    'rating' => $product['rating'],
                    'ratings_count' => $product['ratings_count'] ?? 0,
                    'stock' => $product['stock'],
                    'is_active' => true,
                    'is_featured' => $product['is_featured'],
                    'is_new' => $product['is_new'],
                ]
            );
        }

        // Répare tout produit existant encore incomplet (créé à la main / ancien seed)
        Product::query()->each(function (Product $product) use ($fallbackGallery) {
            $dirty = false;

            if (! filled($product->name)) {
                $product->name = 'Article KINOVA #'.$product->id;
                $dirty = true;
            }

            if (! filled($product->description)) {
                $product->description = 'Sélection KINOVA : pièce soigneusement choisie pour sa qualité, son style et sa finition. Disponible immédiatement, livraison soignée.';
                $dirty = true;
            }

            if (! filled($product->image_url)) {
                $product->image_url = $fallbackGallery[0];
                $dirty = true;
            }

            $gallery = is_array($product->gallery) ? array_values(array_filter($product->gallery)) : [];
            if ($gallery === []) {
                $product->gallery = array_values(array_unique([
                    $product->image_url,
                    ...$fallbackGallery,
                ]));
                $dirty = true;
            }

            if ((float) $product->price <= 0) {
                $product->price = 15000;
                $dirty = true;
            }

            if ((int) $product->stock < 0) {
                $product->stock = 10;
                $dirty = true;
            }

            if ($product->is_active === null) {
                $product->is_active = true;
                $dirty = true;
            }

            if ($dirty) {
                $product->save();
            }
        });

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
