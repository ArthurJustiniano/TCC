<?php
header("Content-Type: application/json");

$conn = new mysqli("localhost", "root", "", "rotafacil_bd");

if ($conn->connect_error) {
    echo json_encode(["status" => "error", "message" => "Erro na conexão com o banco: " . $conn->connect_error]);
    exit();
}

if (!isset($_POST["email_usuario"]) || !isset($_POST["senha_usuario"])) {
    echo json_encode(["status" => "error", "message" => "Email ou senha não fornecidos."]);
    exit();
}

$email = $_POST["email_usuario"];
$senha = $_POST["senha_usuario"];

$stmt = $conn->prepare("SELECT id_usuario, nome_usuario, senha_usuario FROM Usuario WHERE email_usuario = ?");
if (!$stmt) {
    echo json_encode(["status" => "error", "message" => "Erro na preparação da consulta: " . $conn->error]);
    exit();
}

$stmt->bind_param("s", $email);

if (!$stmt->execute()) {
    echo json_encode(["status" => "error", "message" => "Erro na execução da consulta: " . $stmt->error]);
    exit();
}

$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    // SE a senha no banco estiver sem criptografia, comente a linha abaixo
    // e descomente a próxima
    // if (password_verify($senha, $user['senha_usuario'])) {
    if ($senha === $user['senha_usuario']) { // APENAS PARA TESTE SEM HASH
        echo json_encode([
            "status" => "success", 
            "message" => "Login realizado com sucesso",
            "id_usuario" => $user['id_usuario'],
            "nome_usuario" => $user['nome_usuario']
        ]);
    } else {
        echo json_encode(["status" => "error", "message" => "Email ou senha incorretos"]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Email ou senha incorretos"]);
}

$stmt->close();
$conn->close();
?>