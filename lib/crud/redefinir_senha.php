<?php
header('Content-Type: application/json; charset=UTF-8');

// Conexão
$conn = new mysqli("localhost", "root", "", "rotafacil_bd");
if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Falha na conexão"]);
    exit;
}

$email = $_POST['email_usuario'] ?? '';
$codigo = $_POST['codigo'] ?? '';
$nova = $_POST['nova_senha'] ?? '';

$email = trim($email);
$codigo = trim($codigo);
$nova = trim($nova);

if ($email === '' || $codigo === '' || $nova === '') {
    echo json_encode(["status" => "error", "message" => "Campos faltando"]);
    exit;
}

// Confere código e validade
$stmt = $conn->prepare("SELECT id_usuario FROM Usuario WHERE email_usuario = ? AND reset_code = ? AND reset_expires >= NOW()");
$stmt->bind_param("ss", $email, $codigo);
$stmt->execute();
$res = $stmt->get_result();

if ($res && $res->num_rows > 0) {
    $row = $res->fetch_assoc();
    $id = $row['id_usuario'];

    // ⚠️ Em produção: use password_hash()/password_verify()
    $upd = $conn->prepare("UPDATE Usuario SET senha_usuario = ?, reset_code = NULL, reset_expires = NULL WHERE id_usuario = ?");
    $upd->bind_param("si", $nova, $id);

    if ($upd->execute()) {
        echo json_encode(["status" => "success", "message" => "Senha redefinida com sucesso"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Erro ao atualizar senha"]);
    }
    $upd->close();
} else {
    echo json_encode(["status" => "error", "message" => "Código inválido ou expirado"]);
}

$stmt->close();
$conn->close();
