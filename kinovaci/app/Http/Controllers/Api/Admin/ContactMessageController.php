<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\ContactMessage;
use Illuminate\Http\Request;

class ContactMessageController extends Controller
{
    public function index(Request $request)
    {
        $query = ContactMessage::query()->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }

        return response()->json($query->paginate(20));
    }

    public function show(ContactMessage $contactMessage)
    {
        if ($contactMessage->status === 'new') {
            $contactMessage->update(['status' => 'read']);
        }

        return response()->json(['data' => $contactMessage->fresh()]);
    }

    public function update(Request $request, ContactMessage $contactMessage)
    {
        $data = $request->validate([
            'status' => ['sometimes', 'in:new,read,replied,closed'],
            'admin_reply' => ['nullable', 'string', 'max:5000'],
        ]);

        if (! empty($data['admin_reply'])) {
            $data['status'] = $data['status'] ?? 'replied';
        }

        $contactMessage->update($data);

        return response()->json(['data' => $contactMessage->fresh()]);
    }
}
