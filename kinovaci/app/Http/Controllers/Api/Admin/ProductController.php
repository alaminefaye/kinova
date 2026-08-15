<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::query()->with('category:id,name');

        if ($request->filled('q')) {
            $q = $request->string('q');
            $query->where('name', 'like', "%{$q}%");
        }

        return response()->json($query->latest()->paginate(20));
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $data['slug'] = $data['slug'] ?? Str::slug($data['name']).'-'.Str::lower(Str::random(4));

        $product = Product::query()->create($data);

        return response()->json(['data' => $product->load('category')], 201);
    }

    public function show(Product $product)
    {
        return response()->json(['data' => $product->load('category')]);
    }

    public function update(Request $request, Product $product)
    {
        $data = $this->validated($request, $product->id);
        $product->update($data);

        return response()->json(['data' => $product->fresh()->load('category')]);
    }

    public function destroy(Product $product)
    {
        $product->delete();

        return response()->json(['message' => 'Produit supprimé.']);
    }

    private function validated(Request $request, ?int $productId = null): array
    {
        return $request->validate([
            'category_id' => [$productId ? 'sometimes' : 'required', 'exists:categories,id'],
            'name' => [$productId ? 'sometimes' : 'required', 'string', 'max:160'],
            'slug' => [
                'nullable',
                'string',
                'max:180',
                $productId
                    ? 'unique:products,slug,'.$productId
                    : 'unique:products,slug',
            ],
            'description' => ['nullable', 'string'],
            'price' => [$productId ? 'sometimes' : 'required', 'numeric', 'min:0'],
            'promo_price' => ['nullable', 'numeric', 'min:0'],
            'image_url' => ['nullable', 'string', 'max:500'],
            'gallery' => ['nullable', 'array'],
            'gallery.*' => ['string', 'max:500'],
            'sizes' => ['nullable', 'array'],
            'sizes.*.name' => ['required_with:sizes', 'string'],
            'sizes.*.stock' => ['nullable', 'integer', 'min:0'],
            'colors' => ['nullable', 'array'],
            'colors.*.name' => ['required_with:colors', 'string'],
            'colors.*.hex' => ['nullable', 'string', 'max:20'],
            'colors.*.stock' => ['nullable', 'integer', 'min:0'],
            'rating' => ['nullable', 'numeric', 'min:0', 'max:5'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['boolean'],
            'is_featured' => ['boolean'],
            'is_new' => ['boolean'],
        ]);
    }
}
