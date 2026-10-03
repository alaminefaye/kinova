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

    public function test_settings_never_expose_private_keys(): void
    {
        $payload = $this->getJson('/api/settings')->assertOk()->json('data');

        $this->assertArrayNotHasKey('invoice_stamp_path', $payload);
        $this->assertFalse($payload['loyalty']['enabled']);
    }
}
