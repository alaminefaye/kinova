<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class CategoryController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => Category::query()->withCount('products')->orderBy('sort_order')->get(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'slug' => ['nullable', 'string', 'max:140', 'unique:categories,slug'],
            'image_url' => ['nullable', 'string', 'max:500'],
            'is_active' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
        ]);

        $data['slug'] = $data['slug'] ?? Str::slug($data['name']);

        $category = Category::query()->create($data);

        return response()->json(['data' => $category], 201);
    }

    public function show(Category $category)
    {
        return response()->json(['data' => $category->loadCount('products')]);
    }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'slug' => ['sometimes', 'string', 'max:140', 'unique:categories,slug,'.$category->id],
            'image_url' => ['nullable', 'string', 'max:500'],
            'is_active' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
        ]);

        $category->update($data);

        return response()->json(['data' => $category->fresh()]);
    }

    public function destroy(Category $category)
    {
        // La suppression d'une catégorie supprimerait aussi tous ses produits (clé étrangère en cascade).
        if ($category->products()->exists()) {
            return response()->json([
                'message' => 'Cette catégorie contient des produits. Déplacez-les ou supprimez-les avant de supprimer la catégorie.',
            ], 422);
        }

        $category->delete();

        return response()->json(['message' => 'Catégorie supprimée.']);
    }
}
