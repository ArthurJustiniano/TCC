from flask import Flask, jsonify
import mysql.connector

app = Flask(__name__)

# Configuração do banco de dados MySQL
db_config = {
    'host': 'localhost',
    'user': 'seu_usuario',
    'password': 'sua_senha',
    'database': 'rotafacil_bd'
}

# Rota para obter localizações dos pontos
@app.route('/pontos', methods=['GET'])
def get_pontos():
    try:
        # Conecta ao banco de dados
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)

        # Consulta para obter os pontos com latitude e longitude
        query = """
        SELECT Ponto.id_ponto, Ponto.descricao, Ponto.latitude, Ponto.longitude, Usuario.nome_usuario
        FROM Ponto
        JOIN Rota ON Ponto.cod_rota = Rota.id_rota
        JOIN Usuario ON Rota.cod_associacao = Usuario.id_usuario
        """
        cursor.execute(query)
        pontos = cursor.fetchall()

        # Retorna os dados em formato JSON
        return jsonify(pontos)

    except mysql.connector.Error as err:
        return jsonify({'error': str(err)}), 500

    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

# Rota para obter localização de um motorista específico
@app.route('/motorista/<int:id_motorista>', methods=['GET'])
def get_motorista_localizacao(id_motorista):
    try:
        # Conecta ao banco de dados
        conn = mysql.connector.connect(**db_config)
        cursor = conn.cursor(dictionary=True)

        # Consulta para obter a última presença do motorista
        query = """
        SELECT Presenca.data_hora, Ponto.latitude, Ponto.longitude
        FROM Presenca
        JOIN Ponto ON Presenca.cod_ponto = Ponto.id_ponto
        WHERE Presenca.cod_motorista = %s
        ORDER BY Presenca.data_hora DESC
        LIMIT 1
        """
        cursor.execute(query, (id_motorista,))
        localizacao = cursor.fetchone()

        # Retorna os dados em formato JSON
        if localizacao:
            return jsonify(localizacao)
        else:
            return jsonify({'message': 'Nenhuma localização encontrada para o motorista.'}), 404

    except mysql.connector.Error as err:
        return jsonify({'error': str(err)}), 500

    finally:
        if conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == '__main__':
    app.run(debug=True)