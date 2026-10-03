<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Product;
use Illuminate\Support\Collection;

/**
 * Stock global + stock par taille / par couleur (tableaux JSON sizes / colors).
 * Un stock de variante null signifie « suit le stock global ».
 * À appeler dans une transaction.
 */
class StockService
{
    /**
     * Verrouille les produits, vérifie les quantités cumulées et retourne les produits indexés par id.
     *
     * @param  array<int, array{product_id:int, quantity:int, selected_size?:?string, selected_color?:?string}>  $items
     * @return Collection<int, Product>
     */
    public function reserve(array $items, bool $activeOnly = true, bool $requireVariants = true): Collection
    {
        $products = Product::query()
            ->whereKey(collect($items)->pluck('product_id')->unique()->sort()->values())
            ->when($activeOnly, fn ($q) => $q->where('is_active', true))
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        $total = [];
        $bySize = [];
        $byColor = [];

        foreach ($items as $item) {
            $product = $products->get($item['product_id']);
            abort_unless($product, 404, 'Produit introuvable ou indisponible.');

            $qty = (int) $item['quantity'];
            $total[$product->id] = ($total[$product->id] ?? 0) + $qty;

            foreach (['size' => 'sizes', 'color' => 'colors'] as $kind => $field) {
                $options = is_array($product->{$field}) ? $product->{$field} : [];
                if ($options === []) {
                    continue;
                }
                $selected = $item['selected_'.$kind] ?? null;
                $label = $kind === 'size' ? 'taille' : 'couleur';

                if ($selected === null || $selected === '') {
                    abort_if($requireVariants, 422, "Choisissez une {$label} pour {$product->name}.");

                    continue;
                }

                abort_unless(
                    self::findOption($options, $selected) !== null,
                    422,
                    ucfirst($label)." « {$selected} » indisponible pour {$product->name}."
                );

                if ($kind === 'size') {
                    $bySize[$product->id][$selected] = ($bySize[$product->id][$selected] ?? 0) + $qty;
                } else {
                    $byColor[$product->id][$selected] = ($byColor[$product->id][$selected] ?? 0) + $qty;
                }
            }
        }

        foreach ($total as $id => $qty) {
            $product = $products[$id];
            if ($product->stock < $qty) {
                abort(422, "Stock insuffisant pour {$product->name} (disponible : {$product->stock}).");
            }
            foreach ($bySize[$id] ?? [] as $name => $wanted) {
                $stock = self::findOption($product->sizes, $name)['stock'] ?? null;
                if ($stock !== null && (int) $stock < $wanted) {
                    abort(422, "Taille {$name} : stock insuffisant pour {$product->name} (disponible : {$stock}).");
                }
            }
            foreach ($byColor[$id] ?? [] as $name => $wanted) {
                $stock = self::findOption($product->colors, $name)['stock'] ?? null;
                if ($stock !== null && (int) $stock < $wanted) {
                    abort(422, "Couleur {$name} : stock insuffisant pour {$product->name} (disponible : {$stock}).");
                }
            }
        }

        return $products;
    }

    /** Retire une ligne du stock (global + variantes). */
    public function take(Product $product, int $quantity, ?string $size, ?string $color): void
    {
        $this->apply($product, -$quantity, $size, $color);
    }

    /** Remet une ligne en stock (annulation). */
    public function restore(Product $product, int $quantity, ?string $size, ?string $color): void
    {
        $this->apply($product, $quantity, $size, $color);
    }

    /** Remet en stock toutes les lignes d'une commande annulée. */
    public function restoreOrder(Order $order): void
    {
        $order->loadMissing('items');
        $products = Product::query()
            ->whereKey($order->items->pluck('product_id')->filter()->unique()->sort()->values())
            ->lockForUpdate()
            ->get()
            ->keyBy('id');

        foreach ($order->items as $item) {
            if ($product = $products->get($item->product_id)) {
                $this->restore($product, (int) $item->quantity, $item->selected_size, $item->selected_color);
            }
        }
    }

    private function apply(Product $product, int $delta, ?string $size, ?string $color): void
    {
        $product->stock = max(0, (int) $product->stock + $delta);
        $product->sizes = self::shiftOption($product->sizes, $size, $delta);
        $product->colors = self::shiftOption($product->colors, $color, $delta);
        $product->save();
    }

    private static function shiftOption(?array $options, ?string $name, int $delta): ?array
    {
        if (! is_array($options) || $name === null || $name === '') {
            return $options;
        }

        return array_map(function ($option) use ($name, $delta) {
            if (is_array($option) && ($option['name'] ?? null) === $name && isset($option['stock'])) {
                $option['stock'] = max(0, (int) $option['stock'] + $delta);
            }

            return $option;
        }, $options);
    }

    private static function findOption(?array $options, string $name): ?array
    {
        foreach ($options ?? [] as $option) {
            if (is_array($option) && ($option['name'] ?? null) === $name) {
                return $option;
            }
            if (is_string($option) && $option === $name) {
                return ['name' => $option, 'stock' => null];
            }
        }

        return null;
    }
}
