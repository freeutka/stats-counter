<?php

namespace Jexactyl\Http\Controllers\Base;

use Illuminate\Http\JsonResponse;
use Jexactyl\Http\Controllers\Controller;
use Jexactyl\Contracts\Repository\NodeRepositoryInterface;
use Jexactyl\Contracts\Repository\ServerRepositoryInterface;
use Jexactyl\Models\User;

class StatsController extends Controller
{
    public function __construct(
        private NodeRepositoryInterface $nodeRepository,
        private ServerRepositoryInterface $serverRepository
    ) {
    }

    public function index(): JsonResponse
    {
        $nodes = $this->nodeRepository->all()->where('deployable', true);

        $servers = $this->serverRepository->all()->filter(function ($server) use ($nodes) {
            return $nodes->pluck('id')->contains($server->node_id);
        });

        return response()->json([
            'total_servers' => $servers->count(),
            'total_users'   => User::count(),
        ]);
    }
}