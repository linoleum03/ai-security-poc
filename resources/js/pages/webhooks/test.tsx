import { Form, Head, usePage } from '@inertiajs/react';
import Heading from '@/components/heading';
import InputError from '@/components/input-error';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';

type WebhookResult =
    | { ok: true; status: number; preview: string }
    | { ok: false; error: string };

type PageFlash = {
    webhookResult?: WebhookResult;
};

export default function WebhookTest() {
    const { webhookResult } = usePage().flash as PageFlash;

    return (
        <>
            <Head title="Webhook URL test" />

            <div className="space-y-6">
                <Heading
                    variant="small"
                    title="Webhook URL test"
                    description="Confirm your webhook endpoint is reachable before saving it"
                />

                <Form
                    method="post"
                    action="/webhooks/test"
                    options={{ preserveScroll: true }}
                    className="max-w-xl space-y-6"
                >
                    {({ processing, errors }) => (
                        <>
                            <div className="grid gap-2">
                                <Label htmlFor="url">Webhook URL</Label>
                                <Input
                                    id="url"
                                    name="url"
                                    type="text"
                                    placeholder="https://example.com/webhooks/incoming"
                                />
                                <InputError message={errors.url} />
                            </div>

                            <Button type="submit" disabled={processing}>
                                Test URL
                            </Button>
                        </>
                    )}
                </Form>

                {webhookResult && (
                    <div className="max-w-xl space-y-2 rounded-lg border p-4 text-sm">
                        {webhookResult.ok ? (
                            <>
                                <p>
                                    Response status:{' '}
                                    <span className="font-medium">
                                        {webhookResult.status}
                                    </span>
                                </p>
                                <pre className="max-h-64 overflow-auto rounded bg-muted p-2 text-xs whitespace-pre-wrap">
                                    {webhookResult.preview}
                                </pre>
                            </>
                        ) : (
                            <p className="text-destructive">{webhookResult.error}</p>
                        )}
                    </div>
                )}
            </div>
        </>
    );
}
