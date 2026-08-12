<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->orderBy('name')
            ->get();

        return response()->json(['data' => $categories]);
    }

    public function show(Category $category)
    {
        abort_unless($category->is_active, 404);

        $category->load(['products' => fn ($q) => $q->where('is_active', true)]);

        return response()->json(['data' => $category]);
    }
}
