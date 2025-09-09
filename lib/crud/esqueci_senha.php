<?php
header('Content-Type: application/json; charset=UTF-8');

// Conexão com o banco
$conn = new mysqli("localhost", "root", "", "rotafacil_bd");
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Falha na conexão"]);
    exit;
}

$email = $_POST['email_usuario'] ?? '';
$email = trim($email);

if ($email === '') {
    echo json_encode(["status" => "error", "message" => "Informe o e-mail"]);
    exit;
}

// Verifica se existe usuário
$stmt = $conn->prepare("SELECT id_usuario FROM Usuario WHERE email_usuario = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$res = $stmt->get_result();

if (!$res || $res->num_rows === 0) {
    echo json_encode(["status" => "error", "message" => "E-mail não encontrado"]);
    $stmt->close();
    $conn->close();
    exit;
}

$row = $res->fetch_assoc();
$id = $row['id_usuario'];

// Gera código e validade
$code = strval(random_int(100000, 999999));
$expires = date('Y-m-d H:i:s', time() + 15 * 60); // 15 min

// Atualiza o banco
$upd = $conn->prepare("UPDATE Usuario SET reset_code = ?, reset_expires = ? WHERE id_usuario = ?");
$upd->bind_param("ssi", $code, $expires, $id);

// Envie o e-mail para o usuário
$to = $email;
$subject = "Código de redefinição de senha";
$message = "Seu código de redefinição é: $code\nEste código expira em 15 minutos.";
$headers = "From: no-reply@seudominio.com\r\n" .
           "Content-Type: text/plain; charset=UTF-8\r\n";

$mailSent = mail($to, $subject, $message, $headers);

if ($upd->execute() && $mailSent) {
    echo json_encode([
        "status" => "success",
        "message" => "Código enviado para seu e-mail"
    ]);
} else {
    echo json_encode(["status" => "error", "message" => "Falha ao enviar código"]);
}

$upd->close();
$stmt->close();
$conn->close();
