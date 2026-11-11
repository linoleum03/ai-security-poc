<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * 検査用テストアカウントを2件作成する。
     * いずれもTOTP(2FA)を既知のシードで有効化しておき、
     * DAST側が決定論的にワンタイムコードを算出してログインできるようにする。
     */
    public function run(): void
    {
        $this->testUser('Test User A', 'testa@example.com', 'password', 'JBSWY3DPEHPK3PXP');
        $this->testUser('Test User B', 'testb@example.com', 'password', 'MFRGGZDFMZTWQ2LK');
    }

    /**
     * パスワード認証＋TOTP(2FA)を有効化したテストユーザーを1件作る。
     * $totpSecret はBase32の共有シード（MFA登録時の「手動入力キー」相当）。
     */
    private function testUser(string $name, string $email, string $password, string $totpSecret): void
    {
        $user = User::factory()->create([
            'name'     => $name,
            'email'    => $email,
            'password' => Hash::make($password),
        ]);

        $user->forceFill([
            'two_factor_secret'         => encrypt($totpSecret),
            'two_factor_recovery_codes' => encrypt(json_encode([])),
            'two_factor_confirmed_at'   => now(),
        ])->save();
    }
}
