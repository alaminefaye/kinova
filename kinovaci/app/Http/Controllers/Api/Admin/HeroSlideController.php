<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\HeroSlide;
use Illuminate\Http\Request;

class HeroSlideController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => HeroSlide::query()->orderBy('sort_order')->orderBy('id')->get(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $this->validated($request);
        $slide = HeroSlide::query()->create($data);

        return response()->json(['data' => $slide], 201);
    }

    public function show(HeroSlide $heroSlide)
    {
        return response()->json(['data' => $heroSlide]);
    }

    public function update(Request $request, HeroSlide $heroSlide)
    {
        $data = $this->validated($request, updating: true);
        $heroSlide->update($data);

        return response()->json(['data' => $heroSlide->fresh()]);
    }

    public function destroy(HeroSlide $heroSlide)
    {
        $heroSlide->delete();

        return response()->json(['message' => 'Slide supprimé.']);
    }

    private function validated(Request $request, bool $updating = false): array
    {
        $required = $updating ? 'sometimes' : 'required';

        $data = $request->validate([
            'title' => [$required, 'string', 'max:180'],
            'tag' => ['nullable', 'string', 'max:80'],
            'image_url' => [$required, 'string', 'max:500'],
            'cta_label' => ['nullable', 'string', 'max:60'],
            'link_type' => ['nullable', 'string', 'in:catalog,category,none'],
            'link_value' => ['nullable', 'string', 'max:120'],
            'is_active' => ['boolean'],
            'sort_order' => ['integer', 'min:0'],
        ]);

        if (! $updating) {
            $data['cta_label'] = $data['cta_label'] ?? 'DÉCOUVRIR';
            $data['link_type'] = $data['link_type'] ?? 'catalog';
            $data['is_active'] = $data['is_active'] ?? true;
            $data['sort_order'] = $data['sort_order'] ?? 0;
        }

        return $data;
    }
}
