<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AppSettings;

class SettingsController extends Controller
{
    public function index()
    {
        return response()->json(['data' => AppSettings::publicPayload()]);
    }
}
