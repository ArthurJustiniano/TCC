<?php
header("Content-Type: application/json");

// conexão com o banco
$conn = new mysqli("localhost", "root", "", "rotafacil_bd");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Erro na conexão com o banco"]));
}

$nome = $_POST["nome_usuario"];
$email = $_POST["email_usuario"];
$senha = $_POST["senha_usuario"];

// verifica se já existe usuário
$sql = "SELECT * FROM Usuario WHERE email_usuario='$email'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "Usuário já cadastrado"]);
} else {
    $sql = "INSERT INTO Usuario (nome_usuario, email_usuario, senha_usuario, tipo_usuario) VALUES ('$nome', '$email', '$senha', 1)";
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Cadastro realizado com sucesso"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Erro ao cadastrar"]);
    }
}
$conn->close();
?>
