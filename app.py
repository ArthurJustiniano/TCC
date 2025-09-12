from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy

# 1. Inicialização do App e do SQLAlchemy
app = Flask(__name__)

# 2. Configuração da Conexão com o Banco de Dados MySQL
# Formato: 'mysql+pymysql://<usuario>:<senha>@<host>/<nome_do_banco>'
# Substitua 'seu_usuario' e 'sua_senha' pelos seus dados do MySQL.
# Se o MySQL estiver rodando na mesma máquina, o host é 'localhost'.
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://seu_usuario:sua_senha@localhost/rotafacil_bd'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)


# 3. Modelo de Dados (Mapeamento da Tabela 'motoristas')
# Esta classe representa a tabela 'motoristas' no seu banco de dados.
class Motorista(db.Model):
    __tablename__ = 'motoristas'
    id = db.Column(db.String(50), primary_key=True)
    nome = db.Column(db.String(100), nullable=False)
    latitude = db.Column(db.Float, default=0.0)
    longitude = db.Column(db.Float, default=0.0)

    # Função auxiliar para converter o objeto em um dicionário (JSON)
    def to_dict(self):
        return {
            'id': self.id,
            'nome': self.nome,
            'latitude': self.latitude,
            'longitude': self.longitude
        }


# 4. Rota para o Passageiro OBTER a localização (GET)
# Esta rota busca o motorista no banco de dados e retorna sua localização.
@app.route('/motorista/<string:id_do_motorista>', methods=['GET'])
def obter_localizacao(id_do_motorista):
    # db.session.get() é a forma moderna de buscar pela chave primária
    motorista = db.session.get(Motorista, id_do_motorista)
    
    if motorista:
        # Se encontrou, retorna os dados do motorista em formato JSON
        return jsonify(motorista.to_dict())
    else:
        # Se não encontrou, retorna um erro 404
        return jsonify({"erro": "Motorista não encontrado no banco de dados"}), 404


# 5. Rota para o Motorista ENVIAR a localização (POST)
# Esta rota atualiza a localização de um motorista no banco de dados.
@app.route('/motorista/<string:id_do_motorista>/localizacao', methods=['POST'])
def atualizar_localizacao(id_do_motorista):
    motorista = db.session.get(Motorista, id_do_motorista)
    
    if not motorista:
        return jsonify({"erro": "Motorista não encontrado para atualizar"}), 404

    dados = request.get_json()
    if not dados or 'latitude' not in dados or 'longitude' not in dados:
        return jsonify({"erro": "Dados de localização inválidos"}), 400

    # Atualiza os campos do objeto motorista
    motorista.latitude = dados['latitude']
    motorista.longitude = dados['longitude']
    
    # Salva (commita) as alterações no banco de dados
    db.session.commit()

    print(f"Localização do motorista {id_do_motorista} atualizada no banco de dados!")
    return jsonify({"mensagem": "Localização atualizada com sucesso"}), 200


# Rota para buscar os pontos (exemplo, se você também tiver no DB)
@app.route('/pontos', methods=['GET'])
def obter_pontos():
    # Esta é uma implementação de exemplo. Você precisaria criar um modelo para 'pontos'.
    pontos_exemplo = [
        {"id_ponto": 1, "latitude": -20.83, "longitude": -49.48, "descricao": "Ponto A"},
        {"id_ponto": 2, "latitude": -20.84, "longitude": -49.49, "descricao": "Ponto B"}
    ]
    return jsonify(pontos_exemplo)


if __name__ == '__main__':
    # O host='0.0.0.0' é crucial para que o servidor seja acessível na sua rede local
    app.run(host='0.0.0.0', port=5000, debug=True)

