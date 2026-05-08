<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TenantMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  Closure(Request): (Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $tenantId = $request->header('X-Tenant-ID') ?: $request->input('client_id');

        if (!$tenantId) {
            return response()->json(['message' => 'Tenant ID is required.'], 400);
        }

        $tenant = \App\Models\Tenant::find(strtoupper($tenantId));

        if (!$tenant) {
            return response()->json(['message' => 'Tenant not found.'], 404);
        }

        // Set the tenant in the request for easy access
        $request->merge(['tenant' => $tenant]);

        return $next($request);
    }
}
