@php
    use App\Services\AppSettings;

    $money = fn ($v) => AppSettings::formatMoney((float) $v);
    $status = $order->invoice_status;
    $statusLabel = [
        'confirmed' => 'FACTURE CONFIRMÉE — PAYÉE',
        'provisional' => 'FACTURE PROVISOIRE',
        'cancelled' => 'COMMANDE ANNULÉE',
    ][$status] ?? 'FACTURE';
@endphp
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="noindex">
    <title>{{ $order->invoice_number }} — KINOVA</title>
    <style>
        * { box-sizing: border-box; }
        body { margin: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f7f1ea; color: #2c1e14; }
        .wrap { max-width: 760px; margin: 24px auto; background: #fff; border-radius: 18px; padding: 32px; box-shadow: 0 10px 30px rgba(62, 39, 35, .12); }
        header { display: flex; justify-content: space-between; align-items: flex-start; gap: 16px; border-bottom: 2px solid #d4af37; padding-bottom: 18px; }
        .brand { font-family: Georgia, 'Playfair Display', serif; font-size: 28px; letter-spacing: 6px; font-weight: 700; }
        .muted { color: #8a7563; font-size: 13px; }
        .badge { display: inline-block; padding: 6px 12px; border-radius: 999px; font-size: 12px; font-weight: 800; letter-spacing: 1px; }
        .badge.provisional { background: #fff4d6; color: #8a6200; border: 1px solid #e6c200; }
        .badge.confirmed { background: #e3f6e8; color: #166534; border: 1px solid #22c55e; }
        .badge.cancelled { background: #fde8e8; color: #991b1b; border: 1px solid #ef4444; }
        .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 18px; margin: 22px 0; }
        h3 { margin: 0 0 6px; font-size: 12px; letter-spacing: 1.5px; color: #b08d57; text-transform: uppercase; }
        p { margin: 2px 0; font-size: 14px; }
        table { width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 14px; }
        th { text-align: left; font-size: 12px; color: #8a7563; border-bottom: 1px solid #eadfd3; padding: 8px 4px; }
        td { border-bottom: 1px solid #f3ebe2; padding: 10px 4px; vertical-align: top; }
        .right { text-align: right; }
        .totals { margin-top: 14px; margin-left: auto; width: 100%; max-width: 320px; }
        .totals div { display: flex; justify-content: space-between; padding: 4px 0; font-size: 14px; }
        .totals .grand { border-top: 2px solid #2c1e14; margin-top: 6px; padding-top: 8px; font-weight: 800; font-size: 17px; }
        .note { margin-top: 22px; padding: 14px; border-radius: 12px; background: #faf6f1; font-size: 13px; color: #5c4a3d; }
        .actions { text-align: center; margin: 18px 0 30px; }
        .actions button { background: #2c1e14; color: #f7e7ce; border: 0; padding: 12px 22px; border-radius: 999px; font-weight: 700; letter-spacing: 1px; cursor: pointer; }
        @media (max-width: 600px) { .wrap { margin: 0; border-radius: 0; padding: 20px; } .grid { grid-template-columns: 1fr; } }
        @media print { body { background: #fff; } .wrap { box-shadow: none; margin: 0; } .actions { display: none; } }
    </style>
</head>
<body>
<div class="wrap">
    <header>
        <div>
            <div class="brand">KINOVA</div>
            <div class="muted">Boutique KINOVA — Abidjan</div>
            @if ($support['phone'])<div class="muted">{{ $support['phone'] }}</div>@endif
            @if ($support['email'])<div class="muted">{{ $support['email'] }}</div>@endif
        </div>
        <div style="text-align:right">
            <span class="badge {{ $status }}">{{ $statusLabel }}</span>
            <p style="margin-top:10px"><strong>{{ $order->invoice_number }}</strong></p>
            <p class="muted">Commande {{ $order->reference }}</p>
            <p class="muted">Émise le {{ $order->created_at?->format('d/m/Y H:i') }}</p>
            @if ($order->paid_at)<p class="muted">Payée le {{ $order->paid_at->format('d/m/Y H:i') }}</p>@endif
        </div>
    </header>

    <div class="grid">
        <div>
            <h3>Client</h3>
            <p><strong>{{ $order->customer_name }}</strong></p>
            <p>{{ $order->customer_phone }}</p>
            @if ($order->customer_email)<p>{{ $order->customer_email }}</p>@endif
        </div>
        <div>
            <h3>Réception</h3>
            @if ($order->is_delivery)
                <p>Livraison à domicile</p>
                <p>{{ $order->address }}@if ($order->city), {{ $order->city }}@endif</p>
                @if ($order->delivery_details)<p class="muted">{{ $order->delivery_details }}</p>@endif
                @if ($order->maps_url)<p><a href="{{ $order->maps_url }}" target="_blank" rel="noopener">Voir la position sur la carte</a></p>@endif
            @else
                <p>Retrait en boutique KINOVA</p>
            @endif
            <p class="muted">Paiement à la livraison / au retrait</p>
        </div>
    </div>

    <table>
        <thead>
        <tr>
            <th>Article</th>
            <th class="right">Prix unitaire</th>
            <th class="right">Qté</th>
            <th class="right">Total</th>
        </tr>
        </thead>
        <tbody>
        @foreach ($order->items as $item)
            <tr>
                <td>
                    {{ $item->product_name }}
                    @if ($item->selected_size || $item->selected_color)
                        <div class="muted">
                            {{ collect([$item->selected_size ? 'Taille '.$item->selected_size : null, $item->selected_color ? 'Couleur '.$item->selected_color : null])->filter()->implode(' · ') }}
                        </div>
                    @endif
                </td>
                <td class="right">{{ $money($item->unit_price) }}</td>
                <td class="right">{{ $item->quantity }}</td>
                <td class="right">{{ $money($item->line_total) }}</td>
            </tr>
        @endforeach
        </tbody>
    </table>

    <div class="totals">
        <div><span>Sous-total</span><span>{{ $money($order->subtotal) }}</span></div>
        @if ($order->is_delivery)
            <div>
                <span>Livraison</span>
                <span>{{ (float) $order->shipping > 0 ? $money($order->shipping) : 'À régler au livreur' }}</span>
            </div>
        @endif
        <div class="grand"><span>Total</span><span>{{ $money($order->total) }}</span></div>
    </div>

    <div class="note">
        @if ($status === 'confirmed')
            Colis livré et paiement reçu. Cette facture est définitive. Merci pour votre confiance.
        @elseif ($status === 'cancelled')
            Cette commande a été annulée. Aucun montant n’est dû.
        @else
            Facture provisoire : elle deviendra définitive une fois le colis livré et payé.
            @if ($order->is_delivery && (float) $order->shipping <= 0)
                Les frais de livraison ne sont pas inclus et se règlent directement au livreur.
            @endif
        @endif
    </div>
</div>
<div class="actions">
    <button type="button" onclick="window.print()">IMPRIMER / ENREGISTRER EN PDF</button>
</div>
</body>
</html>
