<?php
header("Content-Type: application/json");

$conn = new mysqli("localhost", "root", "", "rotafacil_bd");

if ($conn->connect_error) {
    die(json_encode(["status" => "error", "message" => "Erro na conexão com o banco"]));
}

$email = $_POST["email_passageiro"];
$senha = $_POST["senha_passageiro"];

//adicionar criptografia - "usar password_hash() e password_verify()"

$sql = "SELECT * FROM Passageiro WHERE email_passageiro='$email' AND senha_passageiro='$senha'";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    echo json_encode(["status" => "success", "message" => "Login realizado com sucesso"]);
} else {
    echo json_encode(["status" => "error", "message" => "Email ou senha incorretos"]);
}

$conn->close();
?>
