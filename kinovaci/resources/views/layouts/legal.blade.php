<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="robots" content="index, follow">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600;700&family=Playfair+Display:wght@600&display=swap" rel="stylesheet">
    <title>@yield('title') — KINOVA</title>
    <style>
        :root {
            --kv-bg: #f8f2ec;
            --kv-cream: #fdfbf7;
            --kv-surface: #ffffff;
            --kv-sand: #c1a895;
            --kv-brown: #3e2723;
            --kv-muted: #a88f80;
            --kv-gold-light: #e8d7c8;
            --kv-shadow: 0 6px 20px rgba(62, 39, 35, 0.07);
        }
        * { box-sizing: border-box; }
        body {
            margin: 0;
            font-family: 'Montserrat', system-ui, sans-serif;
            background: var(--kv-bg);
            color: var(--kv-brown);
            -webkit-font-smoothing: antialiased;
        }
        .kv-container {
            width: min(100% - 2rem, 720px);
            margin-inline: auto;
        }
        .head {
            background: linear-gradient(135deg, #3e2723, #251614);
            border-radius: 0 0 28px 28px;
            padding: 1rem 0 1.25rem;
            color: var(--kv-cream);
        }
        .row {
            display: flex;
            align-items: center;
            gap: 0.75rem;
        }
        .back {
            width: 42px;
            height: 42px;
            border-radius: 999px;
            border: 1px solid rgba(197, 160, 128, 0.35);
            background: rgba(255, 255, 255, 0.1);
            color: var(--kv-cream);
            display: grid;
            place-items: center;
            text-decoration: none;
            font-size: 1.1rem;
        }
        h1 {
            margin: 0;
            font-family: 'Playfair Display', Georgia, serif;
            font-size: 1.15rem;
            color: #f7e7ce;
            font-weight: 600;
        }
        .body {
            padding: 1rem 0 2.5rem;
        }
        .updated {
            color: var(--kv-muted);
            font-size: 0.82rem;
            margin: 0 0 1rem;
        }
        .card {
            background: var(--kv-surface);
            border-radius: 18px;
            padding: 1rem 1.1rem;
            border: 1px solid rgba(197, 160, 128, 0.18);
            margin-bottom: 0.85rem;
            box-shadow: var(--kv-shadow);
        }
        .card h2 {
            margin: 0 0 0.55rem;
            font-family: 'Playfair Display', Georgia, serif;
            font-size: 0.95rem;
            color: var(--kv-brown);
        }
        .card p, .card li {
            margin: 0.35rem 0;
            color: var(--kv-muted);
            font-size: 0.86rem;
            line-height: 1.55;
        }
        .card ul {
            margin: 0.4rem 0 0;
            padding-left: 1.1rem;
        }
        a {
            color: var(--kv-brown);
            font-weight: 700;
        }
        code {
            background: rgba(197, 160, 128, 0.15);
            padding: 0.1rem 0.35rem;
            border-radius: 4px;
            font-size: 0.82rem;
        }
    </style>
</head>
<body>
    <header class="head">
        <div class="kv-container row">
            <a class="back" href="{{ url('/') }}" aria-label="Retour à l'accueil">←</a>
            <h1>@yield('heading')</h1>
        </div>
    </header>
    <main class="kv-container body">
        @yield('content')
    </main>
</body>
</html>
