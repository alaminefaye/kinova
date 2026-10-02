<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Services\AppSettings;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SettingsController extends Controller
{
    /** Gérés uniquement par les routes dédiées (upload / suppression). */
    private const MANAGED_KEYS = ['invoice_stamp_path'];

    public function show()
    {
        return response()->json($this->payload());
    }

    public function update(Request $request)
    {
        $rules = [];
        foreach (AppSettings::DEFAULTS as $key => $default) {
            if (in_array($key, self::MANAGED_KEYS, true)) {
                continue;
            }
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
        $rules['invoice_footer'] = ['sometimes', 'nullable', 'string', 'max:1000'];

        $data = $request->validate($rules);

        foreach ($data as $key => $value) {
            if ($value === null) {
                $data[$key] = '';
            }
        }

        AppSettings::update($data);

        return response()->json(['message' => 'Paramètres enregistrés.'] + $this->payload());
    }

    public function uploadInvoiceStamp(Request $request)
    {
        $data = $request->validate([
            'image' => ['required', 'image', 'mimes:png,jpg,jpeg,webp', 'max:4096'],
        ]);

        $file = $data['image'];
        $path = $file->storeAs(
            AppSettings::INVOICE_STAMP_DIR,
            'cachet-'.Str::random(12).'.'.$file->extension(),
            'public'
        );

        $this->deleteStampFile(AppSettings::get('invoice_stamp_path'));
        AppSettings::update(['invoice_stamp_path' => $path]);

        return response()->json(['message' => 'Cachet enregistré.'] + $this->payload());
    }

    public function deleteInvoiceStamp()
    {
        $this->deleteStampFile(AppSettings::get('invoice_stamp_path'));
        AppSettings::update(['invoice_stamp_path' => '']);

        return response()->json(['message' => 'Cachet supprimé.'] + $this->payload());
    }

    private function deleteStampFile(?string $path): void
    {
        if ($path && str_starts_with($path, AppSettings::INVOICE_STAMP_DIR.'/')) {
            Storage::disk('public')->delete($path);
        }
    }

    private function payload(): array
    {
        return [
            'data' => AppSettings::all(),
            'defaults' => AppSettings::DEFAULTS,
            'preview' => AppSettings::publicPayload(),
        ];
    }
}
