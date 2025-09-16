-- ========================================
-- Tabela Usuario
-- ========================================
CREATE TABLE Usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome_usuario VARCHAR(100),
    email_usuario VARCHAR(100),
    senha_usuario VARCHAR(100),
    pagamento_status VARCHAR(50),
    tipo_usuario INT NOT NULL,  -- 1 = passageiro, 2 = motorista, 3 = admin (exemplo)
    reset_code VARCHAR(6) NULL,
    reset_expires TIMESTAMP NULL
);

-- ========================================
-- Tabela Rota
-- ========================================
CREATE TABLE Rota (
    id_rota SERIAL PRIMARY KEY,
    nome_rota VARCHAR(100),
    cod_associacao INT,
    FOREIGN KEY (cod_associacao) REFERENCES Usuario(id_usuario)
);

-- ========================================
-- Tabela Ponto
-- ========================================
CREATE TABLE Ponto (
    id_ponto SERIAL PRIMARY KEY,
    descricao VARCHAR(255),
    latitude DECIMAL(10, 6),
    longitude DECIMAL(10, 6),
    cod_rota INT,
    FOREIGN KEY (cod_rota) REFERENCES Rota(id_rota)
);

-- ========================================
-- Tabela Presenca
-- ========================================
CREATE TABLE Presenca (
    id_presenca SERIAL PRIMARY KEY,
    cod_motorista INT,
    cod_ponto INT,
    data_hora TIMESTAMP,
    FOREIGN KEY (cod_motorista) REFERENCES Usuario(id_usuario),
    FOREIGN KEY (cod_ponto) REFERENCES Ponto(id_ponto)
);

-- ========================================
-- Tabela Pagamento
-- ========================================
CREATE TABLE Pagamento (
    id_pagamento SERIAL PRIMARY KEY,
    cod_passageiro INT,
    valor DECIMAL(10, 2),
    data_pagamento DATE,
    status TEXT CHECK (status IN ('PAGO', 'PENDENTE', 'INADIMPLENTE')),
    FOREIGN KEY (cod_passageiro) REFERENCES Usuario(id_usuario)
);

-- ========================================
-- Tabela Chat
-- ========================================
CREATE TABLE Chat (
    id_chat SERIAL PRIMARY KEY,
    cod_passageiro INT,
    cod_motorista INT,
    FOREIGN KEY (cod_passageiro) REFERENCES Usuario(id_usuario),
    FOREIGN KEY (cod_motorista) REFERENCES Usuario(id_usuario)
);

-- ========================================
-- Tabela Localizacoes (histórico simples, sem RLS)
-- ========================================
CREATE TABLE Localizacoes (
    id SERIAL PRIMARY KEY,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    ultima_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================
-- Tabela locations (para motoristas, vinculada a Usuario)
-- ========================================
DROP TABLE IF EXISTS public.locations CASCADE;

CREATE TABLE public.locations (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES Usuario(id_usuario) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ========================================
-- Inserts iniciais
-- ========================================
INSERT INTO Usuario (nome_usuario, email_usuario, senha_usuario, pagamento_status, tipo_usuario) VALUES
('Ana Souza', 'ana.souza@email.com', 'ana123', 'PAGO', 1),
('Bruno Lima', 'bruno.lima@email.com', 'bruno456', 'PENDENTE', 1),
('Carla Mendes', 'carla.mendes@email.com', 'carla789', 'PAGO', 1),
('James', 'James@email.com', 'james', NULL, 2),
('Leandro', 'Leandro@email.com', 'leandro', NULL, 2),
('Davi Beraldi dos Santos', 'daviok25@gmail.com', '32424266', NULL, 3),
('Arthur Justiniano', 'justiniano@email.com', 'justiniano', NULL, 3),
('Arthur Nasioseno de Araujo Baroni', 'Baroni@email.com', 'baroni', NULL, 3);

INSERT INTO Pagamento (cod_passageiro, valor, data_pagamento, status) VALUES
(1, 120.50, '2025-07-01', 'PAGO'),
(2, 120.50, NULL, 'PENDENTE'),
(3, 120.50, '2025-06-28', 'PAGO');

INSERT INTO Rota (nome_rota, cod_associacao) VALUES
('Linha Centro - Norte', 1),
('Linha Sul Expressa', 2),
('Rota Leste Universitária', 3),
('Circular Oeste', 4),
('Linha Popular Centro', 5);

INSERT INTO Ponto (descricao, latitude, longitude, cod_rota) VALUES
('Ponto Central - Terminal Principal', -3.7327, -38.5270, 1),
('Av. Norte - Estação 1', -3.7295, -38.5300, 1),
('Rua das Palmeiras - Escola Técnica', -3.7255, -38.5330, 1),
('Terminal Sul', -3.7650, -38.5420, 2),
('Av. Beira Sul - Shopping Sul', -3.7685, -38.5490, 2),
('Estação Bairro Novo', -3.7700, -38.5555, 2),
('Universidade Estadual - Portão 1', -3.7450, -38.5050, 3),
('Biblioteca Central', -3.7480, -38.5020, 3),
('Terminal Leste', -3.7510, -38.4980, 3),
('Ponto Oeste I - Centro Médico', -3.7600, -38.5750, 4),
('Av. Oeste - Fórum', -3.7630, -38.5725, 4),
('Praça da Cidadania', -3.7655, -38.5700, 4),
('Estação Popular 1', -3.7400, -38.5200, 5),
('Rua das Flores - Feira', -3.7380, -38.5180, 5),
('Ponto Final - Mercado Municipal', -3.7355, -38.5155, 5);

INSERT INTO Presenca (cod_motorista, cod_ponto, data_hora) VALUES
(1, 1, '2025-07-10 06:45:00'),
(1, 2, '2025-07-10 07:00:00'),
(1, 3, '2025-07-10 07:15:00'),
(2, 4, '2025-07-10 06:30:00'),
(2, 5, '2025-07-10 06:50:00');

INSERT INTO Chat (cod_passageiro, cod_motorista) VALUES
(1, 1),
(2, 2),
(3, 3);

-- ========================================
-- Inserir motoristas na tabela locations
-- ========================================
INSERT INTO public.locations (user_id, latitude, longitude)
SELECT id_usuario, 0.0, 0.0
FROM Usuario
WHERE tipo_usuario = 2;

-- ========================================
-- Políticas RLS (se quiser habilitar, mas sem auth.uid)
-- Aqui deixamos tudo liberado para usuários autenticados
-- ========================================
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Todos podem ver localizações"
ON public.locations
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Todos podem inserir localizações"
ON public.locations
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY "Todos podem atualizar localizações"
ON public.locations
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Todos podem deletar localizações"
ON public.locations
FOR DELETE
TO authenticated
USING (true);
