<?php

namespace App\Http\Controllers;

use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Inertia\Inertia;
use Inertia\Response;

class WebhookTestController extends Controller
{
    /**
     * Show the webhook URL test page.
     */
    public function edit(): Response
    {
        return Inertia::render('webhooks/test');
    }

    /**
     * Fetch the given webhook URL server-side and report back the response,
     * so the user can confirm their endpoint is reachable before saving it.
     */
    public function store(Request $request): RedirectResponse
    {
        $request->validate([
            'url' => ['required', 'string', 'max:2048'],
        ]);

        try {
            $response = Http::timeout(5)->get($request->string('url'));

            Inertia::flash('webhookResult', [
                'ok' => true,
                'status' => $response->status(),
                'preview' => mb_substr($response->body(), 0, 2000),
            ]);
        } catch (\Throwable $e) {
            Inertia::flash('webhookResult', [
                'ok' => false,
                'error' => $e->getMessage(),
            ]);
        }

        return to_route('webhooks.test');
    }
}
