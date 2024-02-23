<?php

use Phalcon\Db\Adapter\Pdo\Postgresql;
use Phalcon\Db\Enum;
use Phalcon\Filter\Validation;
use Phalcon\Filter\Validation\Validator\InclusionIn;
use Phalcon\Filter\Validation\Validator\Numericality;
use Phalcon\Filter\Validation\Validator\StringLength;
use Phalcon\Http\ResponseInterface;
use Phalcon\Messages\Messages;
use Phalcon\Mvc\Micro;
use Phalcon\Http\Response;

$app = new Micro();

function getDbConn(): Postgresql
{
    return new Postgresql([
        'host' => 'db',
        'username' => 'rinha',
        'password' => 'rinha',
        'dbname' => 'rinha_backend_2024_q1',
    ]);
}

$dbConn = getDbConn();

function respondNotFound(): ResponseInterface
{
    return (new Response())
        ->setStatusCode(404)
        ->sendHeaders()
        ->setContentType('application/json')
        ->setContent(json_encode([]))
        ->send();
}

function respondSuccess(array $data = []): ResponseInterface
{
    return (new Response())
        ->setStatusCode(200)
        ->sendHeaders()
        ->setContentType('application/json')
        ->setContent(json_encode($data))
        ->send();
}

function respondUnprocessable(
    ?Messages $messages,
    array $errors = [],
    string $message = 'Unprocessable'
): ResponseInterface {
    if (empty($errors) && !empty($messages)) {
        foreach ($messages as $message) {
            $errors[] = [
                'campo' => $message->getField(),
                'mensagem' => $message->getMessage()
            ];
        }
    }

    return (new Response())
        ->setStatusCode(422)
        ->sendHeaders()
        ->setContentType('application/json')
        ->setContent(json_encode(['message' => $message, 'errors' => $errors]))
        ->send();
}

function getTransactionValidationRules(): Validation
{
    $validation = new Validation();
    $validation->add(
        'valor',
        new Numericality(['message' => 'O campo não é um numero válido.'])
    );
    $validation->add(
        'tipo',
        new InclusionIn(['domain' => ['c', 'd'], 'message' => 'O campo tipo deve ter um dos seguintes valores: c,d'])
    );
    $validation->add(
        'descricao',
        new StringLength([
            'min' => 1,
            'max' => 10,
            'message' => 'O campo descricao deve ter um tamanho entre 1 e 10 caracteres'
        ])
    );
    return $validation;
}

$app->post(
    routePattern: '/clientes/{id:[0-9]+}/transacoes',
    handler: function ($id) use ($app, $dbConn) {

        $customer = $dbConn->fetchOne("SELECT saldo,limite FROM clientes WHERE id = $id");

        if (!$customer) {
            return respondNotFound();
        }

        $requestData = $app->request->getJsonRawBody(true);

        $validation = getTransactionValidationRules();
        $messages = $validation->validate($requestData);

        if (count($messages) > 0) {
            return respondUnprocessable($messages);
        }

        $data = $validation->getData();

        $newBalance = $customer['saldo'] + (int)$data['valor'];
        // Verifica regra de debito
        if ($data['tipo'] === 'd') {
            $newBalance = $customer['saldo'] - (int)$data['valor'];
            if ($newBalance < -$customer['limite']) {
                return respondUnprocessable(null, [], "Pedido recusado, saldo insuficiente.");
            }
        }

        // Insere transação
        $sql = "INSERT INTO transacoes (cliente_id,valor,tipo,descricao) 
                VALUES (:cliente_id,:valor,:tipo,:descricao)";
        $dbConn
            ->query(
                $sql,
                [
                    'cliente_id' => $id,
                    'valor' => (int)$data['valor'],
                    'tipo' => $data['tipo'],
                    'descricao' => $data['descricao'],
                ]
            );

        $sql = "UPDATE clientes SET saldo = :saldo WHERE id = :id";
        $dbConn->query($sql, ['id' => $id, 'saldo' => $newBalance]);

        return respondSuccess([
            'limite' => $customer['limite'],
            'saldo' => $newBalance
        ]);
    }
);

$app->get(
    routePattern: '/clientes/{id:[0-9]+}/extrato',
    handler: function ($id) use ($app, $dbConn) {
        $customer = $dbConn->fetchOne("SELECT saldo,limite FROM clientes WHERE id = $id");

        if (!$customer) {
            return respondNotFound();
        }

        $sql = "SELECT valor,tipo,descricao,to_char(realizada_em::timestamptz,'YYYY-MM-DD\"T\"HH24:MI:SS.US\"Z') as realizada_em
                FROM transacoes 
                WHERE cliente_id = :cliente_id
                ORDER BY realizada_em DESC
                LIMIT 10
                ";
        $lastTransactions = $dbConn->fetchAll($sql, Enum::FETCH_ASSOC, ['cliente_id' => $id]);

        return respondSuccess([
            'saldo' => [
                'total' => $customer['saldo'],
                'data_extrato' => (new DateTime())->format('Y-m-d\TH:i:s.u\Z'),
                'limite' => $customer['limite']
            ],
            'ultimas_transacoes' => [
                $lastTransactions
            ]
        ]);
    });

$app->notFound(handler: 'respondNotFound');

$app->handle($_SERVER["REQUEST_URI"]);