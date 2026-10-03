<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Announcement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AnnouncementController extends Controller
{
    public function index()
    {
        return response()->json([
            'data' => Announcement::query()->latest()->get(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'image_url' => ['required', 'string', 'max:500'],
            'is_active' => ['boolean'],
        ]);
        $data['is_active'] = $data['is_active'] ?? true;

        $announcement = DB::transaction(function () use ($data) {
            $announcement = Announcement::query()->create($data);
            $this->keepSingleActive($announcement);

            return $announcement;
        });

        return response()->json(['data' => $announcement], 201);
    }

    public function update(Request $request, Announcement $announcement)
    {
        $data = $request->validate([
            'image_url' => ['sometimes', 'string', 'max:500'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        DB::transaction(function () use ($announcement, $data) {
            $announcement->update($data);
            $this->keepSingleActive($announcement);
        });

        return response()->json(['data' => $announcement->fresh()]);
    }

    public function destroy(Announcement $announcement)
    {
        $announcement->delete();

        return response()->json(['message' => 'Annonce supprimée.']);
    }

    /** Une seule annonce est affichée dans l'app : activer l'une désactive les autres. */
    private function keepSingleActive(Announcement $announcement): void
    {
        if ($announcement->is_active) {
            Announcement::query()
                ->whereKeyNot($announcement->id)
                ->where('is_active', true)
                ->update(['is_active' => false]);
        }
    }
}
