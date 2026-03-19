<?php

require_once __DIR__ . '/config.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PATCH, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$db = getDb();
$method = $_SERVER['REQUEST_METHOD'];
$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);

// Si l'API est derrière un reverse proxy sur /api/php
$prefix = '/api/php';
if (str_starts_with($uri, $prefix)) {
    $uri = substr($uri, strlen($prefix));
}
if ($uri === '') {
    $uri = '/';
}

try {
    if ($method === 'GET' && $uri === '/health') {
        jsonResponse(['status' => 'ok', 'service' => 'php-api']);
    }

    if ($method === 'GET' && $uri === '/products') {
        $stmt = $db->query('SELECT id, name, description, price, created_at FROM products ORDER BY id ASC');
        jsonResponse($stmt->fetchAll());
    }

    if ($method === 'POST' && $uri === '/products') {
        $body = getJsonBody();

        $name = trim($body['name'] ?? '');
        $description = trim($body['description'] ?? '');
        $price = $body['price'] ?? null;

        if ($name === '' || $price === null || !is_numeric($price)) {
            jsonResponse(['error' => 'Invalid payload'], 400);
        }

        $stmt = $db->prepare('
            INSERT INTO products (name, description, price)
            VALUES (:name, :description, :price)
            RETURNING id, name, description, price, created_at
        ');
        $stmt->execute([
            ':name' => $name,
            ':description' => $description,
            ':price' => $price,
        ]);

        jsonResponse($stmt->fetch(), 201);
    }

    if ($method === 'GET' && $uri === '/orders') {
        $sql = '
            SELECT
                o.id,
                o.customer_name,
                o.status,
                o.total_amount,
                o.created_at,
                COALESCE(
                    json_agg(
                        json_build_object(
                            \'product_id\', oi.product_id,
                            \'product_name\', p.name,
                            \'quantity\', oi.quantity,
                            \'unit_price\', oi.unit_price,
                            \'line_total\', oi.line_total
                        )
                    ) FILTER (WHERE oi.id IS NOT NULL),
                    \'[]\'
                ) AS items
            FROM orders o
            LEFT JOIN order_items oi ON oi.order_id = o.id
            LEFT JOIN products p ON p.id = oi.product_id
            GROUP BY o.id
            ORDER BY o.id DESC
        ';

        $stmt = $db->query($sql);
        jsonResponse($stmt->fetchAll());
    }

    if ($method === 'POST' && $uri === '/orders') {
        $body = getJsonBody();

        $customerName = trim($body['customer_name'] ?? '');
        $items = $body['items'] ?? [];

        if ($customerName === '' || !is_array($items) || count($items) === 0) {
            jsonResponse(['error' => 'Invalid payload'], 400);
        }

        $db->beginTransaction();

        $totalAmount = 0.0;
        $preparedItems = [];

        foreach ($items as $item) {
            $productId = $item['product_id'] ?? null;
            $quantity = $item['quantity'] ?? null;

            if (!$productId || !$quantity || !is_numeric($quantity) || (int)$quantity <= 0) {
                $db->rollBack();
                jsonResponse(['error' => 'Invalid order item'], 400);
            }

            $stmt = $db->prepare('SELECT id, name, price FROM products WHERE id = :id');
            $stmt->execute([':id' => $productId]);
            $product = $stmt->fetch();

            if (!$product) {
                $db->rollBack();
                jsonResponse(['error' => "Product not found: $productId"], 404);
            }

            $unitPrice = (float)$product['price'];
            $lineTotal = $unitPrice * (int)$quantity;
            $totalAmount += $lineTotal;

            $preparedItems[] = [
                'product_id' => (int)$product['id'],
                'quantity' => (int)$quantity,
                'unit_price' => $unitPrice,
                'line_total' => $lineTotal,
            ];
        }

        $stmt = $db->prepare('
            INSERT INTO orders (customer_name, status, total_amount)
            VALUES (:customer_name, :status, :total_amount)
            RETURNING id, customer_name, status, total_amount, created_at
        ');
        $stmt->execute([
            ':customer_name' => $customerName,
            ':status' => 'pending',
            ':total_amount' => $totalAmount,
        ]);

        $order = $stmt->fetch();
        $orderId = $order['id'];

        $insertItem = $db->prepare('
            INSERT INTO order_items (order_id, product_id, quantity, unit_price, line_total)
            VALUES (:order_id, :product_id, :quantity, :unit_price, :line_total)
        ');

        foreach ($preparedItems as $item) {
            $insertItem->execute([
                ':order_id' => $orderId,
                ':product_id' => $item['product_id'],
                ':quantity' => $item['quantity'],
                ':unit_price' => $item['unit_price'],
                ':line_total' => $item['line_total'],
            ]);
        }

        $db->commit();

        jsonResponse([
            'message' => 'Order created',
            'order' => $order,
        ], 201);
    }

    if ($method === 'PATCH' && preg_match('#^/orders/([0-9]+)/status$#', $uri, $matches)) {
        $orderId = (int)$matches[1];
        $body = getJsonBody();
        $status = $body['status'] ?? '';

        $allowed = ['pending', 'preparing', 'ready', 'delivered', 'cancelled'];

        if (!in_array($status, $allowed, true)) {
            jsonResponse(['error' => 'Invalid status'], 400);
        }

        $stmt = $db->prepare('
            UPDATE orders
            SET status = :status
            WHERE id = :id
            RETURNING id, customer_name, status, total_amount, created_at
        ');
        $stmt->execute([
            ':status' => $status,
            ':id' => $orderId,
        ]);

        $updated = $stmt->fetch();

        if (!$updated) {
            jsonResponse(['error' => 'Order not found'], 404);
        }

        jsonResponse($updated);
    }

    jsonResponse(['error' => 'Route not found'], 404);
} catch (Throwable $e) {
    jsonResponse([
        'error' => 'Internal server error',
        'details' => $e->getMessage(),
    ], 500);
}
