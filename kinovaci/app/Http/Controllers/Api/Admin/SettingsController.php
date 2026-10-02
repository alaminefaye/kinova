<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\AppSettings;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function show()
    {
        return response()->json([
            'data' => AppSettings::all(),
            'defaults' => AppSettings::DEFAULTS,
            'preview' => AppSettings::publicPayload(),
        ]);
    }

    public function update(Request $request)
    {
        $rules = [];
        foreach (AppSettings::DEFAULTS as $key => $default) {
            if (in_array($key, AppSettings::INTEGER_KEYS, true)) {
                $rules[$key] = ['sometimes', 'integer', 'min:0', 'max:1000000000'];
            } elseif (is_bool($default)) {
                $rules[$key] = ['sometimes', 'boolean'];
            } else {
                $rules[$key] = ['sometimes', 'nullable', 'string', 'max:255'];
            }
        }
        $rules['loyalty_amount_per_step'] = ['sometimes', 'integer', 'min:1', 'max:1000000000'];
        $rules['shipping_mode'] = ['sometimes', 'in:courier,fixed'];

        $data = $request->validate($rules);

        foreach ($data as $key => $value) {
            if ($value === null) {
                $data[$key] = '';
            }
        }

        AppSettings::update($data);

        return response()->json([
            'message' => 'Paramètres enregistrés.',
            'data' => AppSettings::all(),
            'defaults' => AppSettings::DEFAULTS,
            'preview' => AppSettings::publicPayload(),
        ]);
    }
}
