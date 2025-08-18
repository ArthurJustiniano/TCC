<?php
header("Content-Type: application/json");

// conexão com o banco
$conn = new mysqli("localhost", "root", "", "rotafacil_bd");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Erro na conexão com o banco"]));
}

$nome = $_POST["nome_passageiro"];
$email = $_POST["email_passageiro"];
$senha = $_POST["senha_passageiro"];

// verifica se já existe usuário
$sql = "SELECT * FROM Passageiro WHERE email_passageiro='$email'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode(["status" => "error", "message" => "Usuário já cadastrado"]);
} else {
    $sql = "INSERT INTO Passageiro (nome_passageiro, email_passageiro, senha_passageiro) VALUES ('$nome', '$email', '$senha')";
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["status" => "success", "message" => "Cadastro realizado com sucesso"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Erro ao cadastrar"]);
    }
}
$conn->close();
?>
