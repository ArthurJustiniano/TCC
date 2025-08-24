CREATE DATABASE rotafacil_bd;
USE rotafacil_bd;

-- Tabela usuario
CREATE TABLE Usuario (
    id_usuario INT PRIMARY KEY AUTO_INCREMENT,
    nome_usuario VARCHAR(100),
    email_usuario VARCHAR(100),
    senha_usuario VARCHAR(100),
    pagamento_status VARCHAR(50),
    tipo_usuario INT NOT null
);
-- Tabela Rota
CREATE TABLE Rota (
    id_rota INT PRIMARY KEY AUTO_INCREMENT,
    nome_rota VARCHAR(100),
    cod_associacao INT,
    FOREIGN KEY (cod_associacao) REFERENCES Usuario(id_usuario)
);

-- Tabela Ponto
CREATE TABLE Ponto (
    id_ponto INT PRIMARY KEY AUTO_INCREMENT,
    descricao VARCHAR(255),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    cod_rota INT,
    FOREIGN KEY (cod_rota) REFERENCES Rota(id_rota)
);

-- Tabela Presença
CREATE TABLE Presenca (
    id_presenca INT PRIMARY KEY AUTO_INCREMENT,
    cod_motorista INT,
    cod_ponto INT,
    data_hora DATETIME,
    FOREIGN KEY (cod_motorista) REFERENCES Usuario(id_usuario),
    FOREIGN KEY (cod_ponto) REFERENCES Ponto(id_ponto)
);

-- Tabela Pagamento
CREATE TABLE Pagamento (
    id_pagamento INT PRIMARY KEY AUTO_INCREMENT,
    cod_passageiro INT,
    valor DECIMAL(10, 2),
    data_pagamento DATE,
    STATUS ENUM ('PAGO', 'PENDENTE', 'INADIMPLENTE'),
    FOREIGN KEY (cod_passageiro) REFERENCES Usuario(id_usuario)
);

-- Tabela Chat
CREATE TABLE Chat (
    id_chat INT PRIMARY KEY AUTO_INCREMENT,
    cod_passageiro INT,
    cod_motorista INT,
    FOREIGN KEY (cod_passageiro) REFERENCES Usuario(id_usuario),
    FOREIGN KEY (cod_motorista) REFERENCES Usuario(id_Usuario)
);

-- INSERTS

-- usuarios (passageiros)
INSERT INTO Usuario (nome_usuario, email_usuario, senha_usuario, pagamento_status, tipo_usuario) VALUES
('Ana Souza', 'ana.souza@email.com', 'ana123', 'PAGO', 1),
('Bruno Lima', 'bruno.lima@email.com', 'bruno456', 'PENDENTE', 1),
('Carla Mendes', 'carla.mendes@email.com', 'carla789', 'PAGO', 1);


-- usuarios (motoristas)
INSERT INTO Usuario (nome_usuario, email_usuario, senha_usuario, pagamento_status, tipo_usuario) VALUES
('James', 'James@email.com', 'james', '', 2),
('Leandro', 'Leandro@email.com', 'leandro', '', 2);

-- usuarios (administradores)
INSERT INTO Usuario (nome_usuario, email_usuario, senha_usuario, pagamento_status, tipo_usuario) VALUES
('Davi Beraldi dos Santos', 'daviok25@gmail.com', '32424266', '', 3),
('Arthur Justiniano', 'justiniano@email.com', 'justiniano', '', 3),
('Arthur Nasioseno de Araujo Baroni', 'Baroni@email.com', 'baroni', NUll, 3);

-- Pagamento
INSERT INTO Pagamento (cod_passageiro, valor, data_pagamento, STATUS) VALUES
(1, 120.50, '2025-07-01', 'PAGO'),
(2, 120.50, NULL, 'PENDENTE'),
(3, 120.50, '2025-06-28', 'PAGO');

-- Rota
INSERT INTO Rota (nome_rota, cod_associacao) VALUES
('Linha Centro - Norte', 1),
('Linha Sul Expressa', 2),
('Rota Leste Universitária', 3),
('Circular Oeste', 4),
('Linha Popular Centro', 5);

-- Ponto
INSERT INTO Ponto (descricao, latitude, longitude, cod_rota) VALUES
-- Linha Centro - Norte
('Ponto Central - Terminal Principal', -3.7327, -38.5270, 1),
('Av. Norte - Estação 1', -3.7295, -38.5300, 1),
('Rua das Palmeiras - Escola Técnica', -3.7255, -38.5330, 1),
-- Linha Sul Expressa
('Terminal Sul', -3.7650, -38.5420, 2),
('Av. Beira Sul - Shopping Sul', -3.7685, -38.5490, 2),
('Estação Bairro Novo', -3.7700, -38.5555, 2),
-- Rota Leste Universitária
('Universidade Estadual - Portão 1', -3.7450, -38.5050, 3),
('Biblioteca Central', -3.7480, -38.5020, 3),
('Terminal Leste', -3.7510, -38.4980, 3),
-- Circular Oeste
('Ponto Oeste I - Centro Médico', -3.7600, -38.5750, 4),
('Av. Oeste - Fórum', -3.7630, -38.5725, 4),
('Praça da Cidadania', -3.7655, -38.5700, 4),
-- Linha Popular Centro
('Estação Popular 1', -3.7400, -38.5200, 5),
('Rua das Flores - Feira', -3.7380, -38.5180, 5),
('Ponto Final - Mercado Municipal', -3.7355, -38.5155, 5);

-- Presença
INSERT INTO Presenca (cod_motorista, cod_ponto, data_hora) VALUES
-- Motorista 1
(1, 1, '2025-07-10 06:45:00'),
(1, 2, '2025-07-10 07:00:00'),
(1, 3, '2025-07-10 07:15:00'),
-- Motorista 2
(2, 4, '2025-07-10 06:30:00'),
(2, 5, '2025-07-10 06:50:00');

-- Chat
INSERT INTO Chat (cod_passageiro, cod_motorista) VALUES
(1, 1),
(2, 2),
(3, 3);
