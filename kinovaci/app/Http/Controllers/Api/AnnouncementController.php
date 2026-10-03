<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Announcement;

class AnnouncementController extends Controller
{
    /** Annonce affichée en popup sur l'accueil de l'app (null si aucune). */
    public function current()
    {
        $announcement = Announcement::query()
            ->where('is_active', true)
            ->latest('updated_at')
            ->first(['id', 'image_url', 'updated_at']);

        return response()->json(['data' => $announcement]);
    }

    /** Appelé par l'app à chaque affichage du popup (une fois par appareil et par annonce). */
    public function view(Announcement $announcement)
    {
        abort_unless($announcement->is_active, 404);
        $announcement->increment('views_count');

        return response()->json(['message' => 'ok']);
    }
}
