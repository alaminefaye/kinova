<?php

namespace App\Http\Controllers\Api\Customer;

use App\Http\Controllers\Controller;
use App\Models\Favorite;
use App\Models\Product;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        $products = $request->user()
            ->favoriteProducts()
            ->with('category:id,name,slug')
            ->where('is_active', true)
            ->latest('favorites.created_at')
            ->get();

        return response()->json(['data' => $products]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'product_id' => ['required', 'exists:products,id'],
        ]);

        Product::query()
            ->where('id', $data['product_id'])
            ->where('is_active', true)
            ->firstOrFail();

        Favorite::query()->firstOrCreate([
            'user_id' => $request->user()->id,
            'product_id' => $data['product_id'],
        ]);

        return response()->json(['message' => 'Ajouté aux favoris.'], 201);
    }

    public function destroy(Request $request, int $productId)
    {
        Favorite::query()
            ->where('user_id', $request->user()->id)
            ->where('product_id', $productId)
            ->delete();

        return response()->json(['message' => 'Retiré des favoris.']);
    }

    public function sync(Request $request)
    {
        $data = $request->validate([
            'product_ids' => ['required', 'array'],
            'product_ids.*' => ['integer', 'exists:products,id'],
        ]);

        $user = $request->user();
        $ids = collect($data['product_ids'])->unique()->values();

        $user->favoriteProducts()->sync($ids);

        return response()->json([
            'message' => 'Favoris synchronisés.',
            'data' => $user->favoriteProducts()->with('category:id,name,slug')->get(),
        ]);
    }
}
