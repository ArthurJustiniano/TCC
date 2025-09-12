# Este é um exemplo de código que ficaria no seu servidor (backend)

from flask import Flask, request, jsonify

app = Flask(__name__)

# Um "banco de dados" simples em memória para o exemplo
motoristas_db = {
    "ID_MOTORISTA_1": {"nome": "Carlos", "latitude": 0.0, "longitude": 0.0},
    "ID_MOTORISTA_2": {"nome": "Ana", "latitude": 0.0, "longitude": 0.0},
}

# Este é o endpoint que o seu app Flutter chama com o método POST
@app.route('/motorista/<string:id_do_motorista>/localizacao', methods=['POST'])
def atualizar_localizacao(id_do_motorista):
    # 1. Verifica se o motorista existe
    if id_do_motorista not in motoristas_db:
        return jsonify({"erro": "Motorista não encontrado"}), 404

    # 2. Pega os dados JSON enviados pelo app
    dados = request.get_json()
    if not dados or 'latitude' not in dados or 'longitude' not in dados:
        return jsonify({"erro": "Dados de localização inválidos"}), 400

    # 3. Atualiza a localização no "banco de dados"
    motoristas_db[id_do_motorista]['latitude'] = dados['latitude']
    motoristas_db[id_do_motorista]['longitude'] = dados['longitude']

    print(f"Localização do motorista {id_do_motorista} atualizada!")
    print(f"-> Novas coordenadas: {dados['latitude']}, {dados['longitude']}")

    # 4. Envia uma resposta de sucesso para o app
    return jsonify({"mensagem": "Localização atualizada com sucesso"}), 200


# Este seria o endpoint que o app do PASSAGEIRO usaria para buscar a localização
@app.route('/motorista/<string:id_do_motorista>', methods=['GET'])
def obter_localizacao(id_do_motorista):
    if id_do_motorista in motoristas_db:
        # Retorna os dados de localização para o app do passageiro
        return jsonify(motoristas_db[id_do_motorista])
    else:
        return jsonify({"erro": "Motorista não encontrado"}), 404

if __name__ == '__main__':
    # Roda o servidor, escutando na porta 5000
    app.run(host='0.0.0.0', port=5000, debug=True)

