<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="csrf-token" content="{{ csrf_token() }}">
        <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">
        <title>{{ config('app.name', 'KINOVA') }} — Dashboard</title>
        @vite(['resources/js/main.ts'])
    </head>
    <body class="dark:bg-gray-900">
        <div id="app"></div>
    </body>
</html>
