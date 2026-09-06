<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DebugUserEndpointTest extends TestCase
{
    use RefreshDatabase;

    public function test_authenticated_users_can_view_their_own_debug_info()
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/debug/user');

        $response->assertOk();
        $response->assertJsonPath('id', $user->id);
        $response->assertJsonPath('email', $user->email);
    }

    public function test_authenticated_users_cannot_view_other_users_debug_info()
    {
        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/debug/user');

        $response->assertOk();
        $response->assertJsonPath('id', $user->id);
        $response->assertJsonMissing(['id' => $otherUser->id]);
        $response->assertJsonMissing(['email' => $otherUser->email]);
    }

    public function test_guests_cannot_access_the_debug_user_endpoint()
    {
        $response = $this->get('/debug/user');

        $response->assertRedirect(route('login'));
    }

    public function test_the_legacy_id_based_debug_url_no_longer_exists()
    {
        $user = User::factory()->create();

        $response = $this
            ->actingAs($user)
            ->get('/debug/user/'.$user->id);

        $response->assertNotFound();
    }
}
