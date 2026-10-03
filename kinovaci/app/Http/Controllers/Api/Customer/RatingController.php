<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductRating;
use Illuminate\Http\Request;

class RatingController extends Controller
{
    public function show(Request $request, Product $product)
    {
        abort_unless($product->is_active, 404);

        $mine = null;
        $canRate = false;
        if ($user = $request->user()) {
            $mine = ProductRating::query()
                ->where('user_id', $user->id)
                ->where('product_id', $product->id)
                ->value('stars');
            $canRate = self::hasReceived($user->id, $product->id);
        }

        return response()->json([
            'data' => [
                'product_id' => $product->id,
                'average' => (float) $product->rating,
                'count' => (int) $product->ratings_count,
                'my_rating' => $mine,
                'can_rate' => $canRate,
            ],
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'product_id' => ['required', 'integer', 'exists:products,id'],
            'stars' => ['required', 'integer', 'min:1', 'max:5'],
        ]);

        $product = Product::query()->findOrFail($data['product_id']);
        abort_unless($product->is_active, 404);
        abort_unless(
            self::hasReceived($request->user()->id, $product->id),
            403,
            'Vous pourrez noter cet article une fois votre commande livrée.'
        );

        ProductRating::query()->updateOrCreate(
            [
                'user_id' => $request->user()->id,
                'product_id' => $product->id,
            ],
            ['stars' => $data['stars']]
        );

        $this->refreshProductRating($product);

        $product->refresh();

        return response()->json([
            'data' => [
                'product_id' => $product->id,
                'average' => (float) $product->rating,
                'count' => (int) $product->ratings_count,
                'my_rating' => (int) $data['stars'],
                'can_rate' => true,
            ],
            'message' => 'Merci pour votre note !',
        ]);
    }

    /** Seul un client ayant reçu l'article (commande livrée) peut le noter. */
    public static function hasReceived(int $userId, int $productId): bool
    {
        return Order::query()
            ->where('user_id', $userId)
            ->where('status', 'delivered')
            ->whereHas('items', fn ($q) => $q->where('product_id', $productId))
            ->exists();
    }

    public static function refreshProductRating(Product $product): void
    {
        $stats = ProductRating::query()
            ->where('product_id', $product->id)
            ->selectRaw('AVG(stars) as avg_stars, COUNT(*) as total')
            ->first();

        $product->update([
            'rating' => round((float) ($stats->avg_stars ?? 0), 1),
            'ratings_count' => (int) ($stats->total ?? 0),
        ]);
    }
}
