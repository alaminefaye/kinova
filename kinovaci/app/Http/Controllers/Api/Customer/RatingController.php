<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Product;
use App\Models\ProductRating;
use Illuminate\Http\Request;

class RatingController extends Controller
{
    public function show(Request $request, Product $product)
    {
        abort_unless($product->is_active, 404);

        $mine = null;
        if ($request->user()) {
            $mine = ProductRating::query()
                ->where('user_id', $request->user()->id)
                ->where('product_id', $product->id)
                ->value('stars');
        }

        return response()->json([
            'data' => [
                'product_id' => $product->id,
                'average' => (float) $product->rating,
                'count' => (int) $product->ratings_count,
                'my_rating' => $mine,
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
            ],
            'message' => 'Merci pour votre note !',
        ]);
    }

    private function refreshProductRating(Product $product): void
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
