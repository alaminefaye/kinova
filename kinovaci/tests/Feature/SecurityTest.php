<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Spatie\Permission\Models\Role;
use Tests\TestCase;

class SecurityTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        foreach (['super-admin', 'admin', 'customer'] as $role) {
            Role::findOrCreate($role, 'web');
        }
    }

    private function user(string $role = 'customer', array $attributes = []): User
    {
        $user = User::factory()->create($attributes);
        $user->assignRole($role);

        return $user;
    }

    private function product(int $stock = 10, float $price = 5000): Product
    {
        $category = Category::query()->create(['name' => 'Soins', 'slug' => 'soins-'.uniqid()]);

        return Product::query()->create([
            'category_id' => $category->id,
            'name' => 'Crème',
            'slug' => 'creme-'.uniqid(),
            'price' => $price,
            'stock' => $stock,
            'is_active' => true,
        ]);
    }

    private function orderFor(?User $user, array $attributes = []): Order
    {
        return Order::query()->create(array_merge([
            'reference' => 'KV-'.strtoupper(substr(md5(uniqid()), 0, 8)),
            'user_id' => $user?->id,
            'customer_name' => 'Client',
            'customer_phone' => '0700000000',
            'address' => 'Cocody',
            'city' => 'Abidjan',
            'payment_method' => 'cod',
            'payment_status' => 'unpaid',
            'status' => 'pending',
            'subtotal' => 5000,
            'shipping' => 0,
            'total' => 5000,
        ], $attributes));
    }

    private function orderPayload(Product $product, int $quantity = 1, array $extra = []): array
    {
        return array_merge([
            'customer_name' => 'Awa',
            'customer_phone' => '0700000000',
            'is_delivery' => false,
            'items' => [['product_id' => $product->id, 'quantity' => $quantity]],
        ], $extra);
    }

    public function test_admin_api_rejects_guests_customers_and_simple_admins(): void
    {
        $this->getJson('/api/admin/dashboard')->assertUnauthorized();

        Sanctum::actingAs($this->user('customer'));
        $this->getJson('/api/admin/dashboard')->assertForbidden();

        Sanctum::actingAs($this->user('admin'));
        $this->getJson('/api/admin/orders')->assertForbidden();
    }

    public function test_blocked_super_admin_loses_admin_access(): void
    {
        Sanctum::actingAs($this->user('super-admin', ['is_blocked' => true]));

        $this->getJson('/api/admin/dashboard')->assertForbidden();
    }

    public function test_super_admin_can_access_admin_api(): void
    {
        Sanctum::actingAs($this->user('super-admin'));

        $this->getJson('/api/admin/dashboard')->assertOk();
    }

    public function test_customer_cannot_read_or_cancel_another_customer_order(): void
    {
        $owner = $this->user();
        $order = $this->orderFor($owner);

        Sanctum::actingAs($this->user());

        $this->getJson("/api/customer/orders/{$order->reference}")->assertNotFound();
        $this->postJson("/api/customer/orders/{$order->reference}/cancel")->assertNotFound();
        $this->getJson('/api/customer/orders')->assertOk()->assertJsonCount(0, 'data');
        $this->assertSame('pending', $order->fresh()->status);
    }

    public function test_paid_order_cannot_be_cancelled_by_customer(): void
    {
        $owner = $this->user();
        $order = $this->orderFor($owner, ['payment_status' => 'paid', 'paid_at' => now()]);

        Sanctum::actingAs($owner);

        $this->postJson("/api/customer/orders/{$order->reference}/cancel")->assertStatus(422);
        $this->assertSame('pending', $order->fresh()->status);
    }

    public function test_cancelling_an_order_restores_stock(): void
    {
        $owner = $this->user();
        $product = $this->product(stock: 10);

        Sanctum::actingAs($owner);
        $reference = $this->postJson('/api/orders', $this->orderPayload($product, 3))
            ->assertCreated()
            ->json('data.reference');

        $this->assertSame(7, $product->fresh()->stock);

        $this->postJson("/api/customer/orders/{$reference}/cancel")->assertOk();
        $this->assertSame(10, $product->fresh()->stock);
    }

    public function test_customer_cannot_mark_another_customer_notification_as_read(): void
    {
        $notification = AppNotification::query()->create([
            'user_id' => $this->user()->id,
            'title' => 'Commande',
            'message' => 'Test',
            'category' => 'order',
            'is_read' => false,
        ]);

        Sanctum::actingAs($this->user());

        $this->postJson("/api/customer/notifications/{$notification->id}/read")->assertNotFound();
        $this->assertFalse($notification->fresh()->is_read);
    }

    public function test_order_total_is_computed_server_side(): void
    {
        $product = $this->product(stock: 10, price: 5000);

        $response = $this->postJson('/api/orders', $this->orderPayload($product, 2, [
            'total' => 1,
            'subtotal' => 1,
            'payment_status' => 'paid',
            'status' => 'delivered',
        ]))->assertCreated();

        $this->assertEquals(10000, $response->json('data.total'));
        $this->assertSame('unpaid', $response->json('data.payment_status'));
        $this->assertSame('pending', $response->json('data.status'));
    }

    public function test_order_rejects_quantity_above_stock_even_when_split_across_lines(): void
    {
        $product = $this->product(stock: 5);

        $this->postJson('/api/orders', $this->orderPayload($product, 6))->assertStatus(422);

        $this->postJson('/api/orders', array_merge($this->orderPayload($product), [
            'items' => [
                ['product_id' => $product->id, 'quantity' => 3],
                ['product_id' => $product->id, 'quantity' => 3],
            ],
        ]))->assertStatus(422);

        $this->assertSame(5, $product->fresh()->stock);
    }

    public function test_inactive_product_cannot_be_ordered(): void
    {
        $product = $this->product();
        $product->update(['is_active' => false]);

        $this->postJson('/api/orders', $this->orderPayload($product))->assertNotFound();
    }

    public function test_customer_cannot_escalate_privileges_through_profile_update(): void
    {
        $customer = $this->user('customer', ['loyalty_points' => 0]);
        Sanctum::actingAs($customer);

        $this->putJson('/api/customer/profile', [
            'name' => 'Pirate',
            'role' => 'admin',
            'is_blocked' => false,
            'loyalty_points' => 99999,
            'vip_tier' => 'vip',
        ]);

        $customer->refresh();
        $this->assertSame(0, $customer->loyalty_points);
        $this->assertNotSame('admin', $customer->role);
        $this->assertFalse($customer->isSuperAdmin());
    }

    public function test_login_is_refused_for_blocked_customer(): void
    {
        $this->user('customer', ['email' => 'bloque@kinova.test', 'is_blocked' => true]);

        $this->postJson('/api/customer/auth/login', [
            'login' => 'bloque@kinova.test',
            'password' => 'password',
        ])->assertStatus(422);
    }

    public function test_admin_login_is_refused_for_non_super_admin(): void
    {
        $this->user('customer', ['email' => 'client@kinova.test']);

        $this->postJson('/api/auth/login', [
            'email' => 'client@kinova.test',
            'password' => 'password',
        ])->assertForbidden();
    }

    public function test_admin_cancel_then_reopen_keeps_stock_consistent(): void
    {
        $product = $this->product(stock: 10);
        $reference = $this->postJson('/api/orders', $this->orderPayload($product, 4))->json('data.reference');
        $order = Order::query()->where('reference', $reference)->firstOrFail();
        $this->assertSame(6, $product->fresh()->stock);

        Sanctum::actingAs($this->user('super-admin'));

        $this->putJson("/api/admin/orders/{$order->id}", ['status' => 'cancelled'])->assertOk();
        $this->assertSame(10, $product->fresh()->stock);

        $this->putJson("/api/admin/orders/{$order->id}", ['status' => 'pending'])->assertOk();
        $this->assertSame(6, $product->fresh()->stock);

        $product->update(['stock' => 1]);
        $this->putJson("/api/admin/orders/{$order->id}", ['status' => 'cancelled'])->assertOk();
        $this->assertSame(5, $product->fresh()->stock);
        $product->update(['stock' => 2]);
        $this->putJson("/api/admin/orders/{$order->id}", ['status' => 'pending'])->assertStatus(422);
        $this->assertSame(2, $product->fresh()->stock);
        $this->assertSame('cancelled', $order->fresh()->status);
    }

    public function test_no_loyalty_points_when_program_disabled(): void
    {
        $customer = $this->user('customer', ['loyalty_points' => 0]);
        $order = $this->orderFor($customer, ['total' => 100000, 'subtotal' => 100000]);

        Sanctum::actingAs($this->user('super-admin'));
        $this->putJson("/api/admin/orders/{$order->id}", ['status' => 'delivered'])->assertOk();

        $this->assertSame(0, $customer->fresh()->loyalty_points);
        $this->assertSame(0, AppNotification::query()->where('user_id', $customer->id)
            ->where('title', \App\Services\LoyaltyService::POINTS_NOTIFICATION_TITLE)->count());
    }

    public function test_avatar_upload_ignores_client_extension(): void
    {
        \Illuminate\Support\Facades\Storage::fake('public');
        Sanctum::actingAs($customer = $this->user());

        $html = \Illuminate\Http\UploadedFile::fake()->createWithContent('a.html', "GIF89a<script>alert(1)</script>");
        $this->postJson('/api/customer/profile/avatar', ['avatar' => $html])->assertStatus(422);

        $disguised = \Illuminate\Http\UploadedFile::fake()->image('photo.html', 50, 50);
        $this->postJson('/api/customer/profile/avatar', ['avatar' => $disguised])->assertStatus(422);

        $png = \Illuminate\Http\UploadedFile::fake()->image('photo.png', 50, 50);
        $this->postJson('/api/customer/profile/avatar', ['avatar' => $png])->assertOk();

        $files = \Illuminate\Support\Facades\Storage::disk('public')->files('avatars');
        $this->assertCount(1, $files);
        $this->assertStringEndsWith('.png', $files[0]);
        $this->assertStringContainsString('/storage/avatars/', (string) $customer->fresh()->avatar_url);
    }

    public function test_customer_cannot_point_avatar_to_other_files_and_delete_them(): void
    {
        \Illuminate\Support\Facades\Storage::fake('public');
        \Illuminate\Support\Facades\Storage::disk('public')->put('products/victim.jpg', 'x');

        $customer = $this->user();
        Sanctum::actingAs($customer);

        $this->putJson('/api/customer/profile', [
            'avatar_url' => 'https://kinovaci.com/storage/avatars/../products/victim.jpg',
        ])->assertOk();
        $this->assertNull($customer->fresh()->avatar_url);

        $customer->forceFill(['avatar_url' => 'https://kinovaci.com/storage/avatars/../products/victim.jpg'])->save();
        $png = \Illuminate\Http\UploadedFile::fake()->image('a.png');
        $this->postJson('/api/customer/profile/avatar', ['avatar' => $png])->assertOk();

        \Illuminate\Support\Facades\Storage::disk('public')->assertExists('products/victim.jpg');
    }

    public function test_public_order_lookup_hides_personal_data(): void
    {
        $order = $this->orderFor(null, ['notes' => 'note interne', 'latitude' => 5.3, 'longitude' => -4.0]);

        $data = $this->getJson("/api/orders/{$order->reference}")->assertOk()->json('data');

        $this->assertSame($order->reference, $data['reference']);
        foreach (['customer_phone', 'customer_name', 'address', 'latitude', 'longitude', 'notes', 'user_id'] as $key) {
            $this->assertArrayNotHasKey($key, $data);
        }
    }

    public function test_product_listing_page_size_is_capped(): void
    {
        $this->product();

        $this->getJson('/api/products?per_page=100000')->assertOk()->assertJsonPath('per_page', 200);
        $this->getJson('/api/products?per_page=-5')->assertOk()->assertJsonPath('per_page', 1);
    }

    public function test_last_super_admin_cannot_be_blocked_demoted_or_deleted(): void
    {
        $admin = $this->user('super-admin');
        Sanctum::actingAs($admin);

        $this->postJson("/api/admin/users/{$admin->id}/toggle-block")->assertStatus(422);
        $this->putJson("/api/admin/users/{$admin->id}", ['name' => 'Moi', 'roles' => ['customer']])->assertStatus(422);
        $this->assertTrue($admin->fresh()->isSuperAdmin());

        $other = $this->user('super-admin');
        $this->postJson("/api/admin/users/{$other->id}/toggle-block")->assertOk();
        $this->assertTrue($other->fresh()->is_blocked);
    }

    public function test_admin_user_edit_keeps_unsent_fields_and_accepts_real_tiers(): void
    {
        Sanctum::actingAs($this->user('super-admin'));
        $customer = $this->user('customer', ['loyalty_points' => 42, 'vip_tier' => 'silver', 'city' => 'Bouaké']);

        $this->putJson("/api/admin/users/{$customer->id}", ['name' => 'Nouveau nom', 'email' => $customer->email])->assertOk();
        $customer->refresh();
        $this->assertSame(42, $customer->loyalty_points);
        $this->assertSame('silver', $customer->vip_tier);
        $this->assertSame('Bouaké', $customer->city);

        $this->putJson("/api/admin/users/{$customer->id}", ['name' => 'X', 'vip_tier' => 'vip'])->assertOk();
        $this->putJson("/api/admin/users/{$customer->id}", ['name' => 'X', 'roles' => ['inexistant']])->assertStatus(422);
    }

    public function test_system_roles_cannot_be_renamed(): void
    {
        Sanctum::actingAs($this->user('super-admin'));
        $customerRole = Role::findByName('customer', 'web');

        $this->putJson("/api/admin/roles/{$customerRole->id}", ['name' => 'clients'])->assertStatus(422);
        $this->assertNotNull(Role::where('name', 'customer')->first());
    }

    public function test_category_with_products_cannot_be_deleted(): void
    {
        $product = $this->product();
        Sanctum::actingAs($this->user('super-admin'));

        $this->deleteJson("/api/admin/categories/{$product->category_id}")->assertStatus(422);
        $this->assertNotNull($product->fresh());
    }

    public function test_admin_manual_order_checks_stock_and_uses_server_price(): void
    {
        $product = $this->product(stock: 3, price: 7000);
        Sanctum::actingAs($this->user('super-admin'));

        $payload = [
            'customer_name' => 'Boutique',
            'customer_phone' => '0700000000',
            'is_delivery' => false,
            'items' => [['product_id' => $product->id, 'quantity' => 2, 'unit_price' => 1]],
        ];

        $this->postJson('/api/admin/orders', $payload)->assertCreated()->assertJsonPath('data.total', '14000.00');
        $this->assertSame(1, $product->fresh()->stock);

        $this->postJson('/api/admin/orders', $payload)->assertStatus(422);
        $this->assertSame(1, $product->fresh()->stock);
    }

    public function test_password_change_revokes_other_sessions(): void
    {
        $customer = $this->user('customer', ['email' => 'pwd@kinova.test']);
        $customer->createToken('autre-telephone');
        $current = $customer->createToken('ce-telephone')->plainTextToken;

        $this->withToken($current)->putJson('/api/customer/profile', [
            'current_password' => 'password',
            'password' => 'Nouveau-123456',
            'password_confirmation' => 'Nouveau-123456',
        ])->assertOk();

        $this->assertSame(['ce-telephone'], $customer->tokens()->pluck('name')->all());
    }

    public function test_settings_never_expose_private_keys(): void
    {
        $payload = $this->getJson('/api/settings')->assertOk()->json('data');

        $this->assertArrayNotHasKey('invoice_stamp_path', $payload);
        $this->assertFalse($payload['loyalty']['enabled']);
    }

    public function test_customer_cannot_rate_product_without_delivered_purchase(): void
    {
        $customer = $this->user();
        $product = $this->product();
        Sanctum::actingAs($customer);

        $this->getJson("/api/customer/products/{$product->id}/rating")
            ->assertOk()->assertJsonPath('data.can_rate', false);
        $this->postJson('/api/customer/ratings', ['product_id' => $product->id, 'stars' => 1])
            ->assertForbidden();

        $pending = $this->orderFor($customer, ['status' => 'pending']);
        $pending->items()->create([
            'product_id' => $product->id, 'product_name' => $product->name,
            'unit_price' => 5000, 'quantity' => 1, 'line_total' => 5000,
        ]);
        $this->postJson('/api/customer/ratings', ['product_id' => $product->id, 'stars' => 1])
            ->assertForbidden();
        $this->assertSame(0, (int) $product->fresh()->ratings_count);
    }

    public function test_customer_can_rate_product_after_delivery(): void
    {
        $customer = $this->user();
        $product = $this->product();
        $order = $this->orderFor($customer, ['status' => 'delivered']);
        $order->items()->create([
            'product_id' => $product->id, 'product_name' => $product->name,
            'unit_price' => 5000, 'quantity' => 1, 'line_total' => 5000,
        ]);
        Sanctum::actingAs($customer);

        $this->getJson("/api/customer/products/{$product->id}/rating")
            ->assertOk()->assertJsonPath('data.can_rate', true);
        $this->postJson('/api/customer/ratings', ['product_id' => $product->id, 'stars' => 4])
            ->assertOk()->assertJsonPath('data.my_rating', 4);
        $this->assertSame(1, (int) $product->fresh()->ratings_count);
    }

    private function variantProduct(): Product
    {
        $product = $this->product(10);
        $product->update([
            'sizes' => [['name' => 'M', 'stock' => 3], ['name' => 'L', 'stock' => null]],
            'colors' => [['name' => 'Noir', 'hex' => '#000', 'stock' => 2]],
        ]);

        return $product->fresh();
    }

    private function variantLine(Product $product, int $qty, string $size = 'M', string $color = 'Noir'): array
    {
        return ['product_id' => $product->id, 'quantity' => $qty, 'selected_size' => $size, 'selected_color' => $color];
    }

    public function test_order_decrements_size_and_color_stock(): void
    {
        $product = $this->variantProduct();

        $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [$this->variantLine($product, 2)],
        ]))->assertCreated();

        $product->refresh();
        $this->assertSame(8, (int) $product->stock);
        $this->assertSame(1, $product->sizes[0]['stock']);
        $this->assertNull($product->sizes[1]['stock']);
        $this->assertSame(0, $product->colors[0]['stock']);
    }

    public function test_order_rejects_when_variant_stock_is_insufficient(): void
    {
        $product = $this->variantProduct();

        // 2 lignes de 1 : cumul 2 en Noir OK, mais 3 lignes dépassent le stock couleur (2)
        $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [$this->variantLine($product, 1), $this->variantLine($product, 1, 'L'), $this->variantLine($product, 1, 'L')],
        ]))->assertStatus(422);

        $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [$this->variantLine($product, 4, 'M')],
        ]))->assertStatus(422);

        $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [['product_id' => $product->id, 'quantity' => 1]],
        ]))->assertStatus(422);

        $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [$this->variantLine($product, 1, 'XXL')],
        ]))->assertStatus(422);

        $this->assertSame(10, (int) $product->fresh()->stock);
        $this->assertSame(3, $product->fresh()->sizes[0]['stock']);
    }

    public function test_cancel_restores_variant_stock(): void
    {
        $customer = $this->user();
        $product = $this->variantProduct();
        Sanctum::actingAs($customer);

        $reference = $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [$this->variantLine($product, 2)],
        ]))->assertCreated()->json('data.reference');

        $this->postJson("/api/customer/orders/{$reference}/cancel")->assertOk();

        $product->refresh();
        $this->assertSame(10, (int) $product->stock);
        $this->assertSame(3, $product->sizes[0]['stock']);
        $this->assertSame(2, $product->colors[0]['stock']);
    }

    public function test_admin_reopen_reserves_variant_stock_again(): void
    {
        $admin = $this->user('super-admin');
        $product = $this->variantProduct();

        $reference = $this->postJson('/api/orders', $this->orderPayload($product, 1, [
            'items' => [$this->variantLine($product, 2)],
        ]))->assertCreated()->json('data.reference');
        $order = Order::query()->where('reference', $reference)->firstOrFail();

        Sanctum::actingAs($admin);
        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'cancelled'])->assertOk();
        $this->assertSame(2, $product->fresh()->colors[0]['stock']);

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'pending'])->assertOk();
        $product->refresh();
        $this->assertSame(8, (int) $product->stock);
        $this->assertSame(1, $product->sizes[0]['stock']);
        $this->assertSame(0, $product->colors[0]['stock']);
    }
}
