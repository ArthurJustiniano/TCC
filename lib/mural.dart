import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/user_data.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class NewsData extends ChangeNotifier {
  List<NewsItem> _newsItems = [];
  bool _isLoading = false;
  String? _error;

  List<NewsItem> get newsItems {
    // Retorna lista ordenada por data (mais recente primeiro)
    final sortedList = List<NewsItem>.from(_newsItems);
    sortedList.sort((a, b) {
      try {
        final dateA = DateTime.parse(a.date);
        final dateB = DateTime.parse(b.date);
        return dateB.compareTo(dateA); // Ordem decrescente (mais recente primeiro)
      } catch (e) {
        // Se houver erro no parse da data, mantém ordem original
        return 0;
      }
    });
    return sortedList;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadNews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Iniciando carregamento de notícias...');
      
      // Primeiro, tenta verificar se a tabela existe
      try {
        final testResponse = await Supabase.instance.client
            .from('noticias')
            .select('count')
            .limit(1);
        print('Tabela noticias existe e respondeu: $testResponse');
      } catch (e) {
        print('Erro ao acessar tabela noticias: $e');
        throw Exception('Tabela noticias não existe ou não é acessível: $e');
      }
      
      // Carrega as notícias
      final response = await Supabase.instance.client
          .from('noticias')
          .select('*')
          .order('data_publicacao', ascending: false);

      print('Notícias carregadas: ${response.length}');

      // Carrega os usuários para relacionar com as notícias
      final usersResponse = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario, nome_usuario');

      print('Usuários carregados: ${usersResponse.length}');

      // Cria um mapa de usuários para facilitar a busca
      final usersMap = <int, String>{};
      for (final user in usersResponse) {
        usersMap[user['id_usuario']] = user['nome_usuario'];
      }

      _newsItems = (response as List).map((item) {
        return NewsItem(
          id: item['id'],
          title: item['titulo'],
          content: item['conteudo'],
          date: item['data_publicacao'],
          authorId: item['autor_id'],
          authorName: usersMap[item['autor_id']] ?? 'Usuário Desconhecido',
          createdAt: DateTime.parse(item['created_at']),
        );
      }).toList();

      print('Processamento concluído. Total de notícias: ${_newsItems.length}');

    } catch (e) {
      _error = 'Erro ao carregar notícias: $e';
      print('Erro detalhado ao carregar notícias: $e');
      
      // Se não conseguir carregar do banco, usa dados de exemplo
      print('Carregando dados de exemplo devido ao erro...');
      _newsItems = [
        NewsItem(
          id: 1,
          title: "Feriado Municipal",
          content: "Na próxima segunda-feira, dia 22, não haverá expediente devido ao feriado municipal.",
          date: "2024-07-18",
          authorName: "Admin",
          authorId: 1,
          createdAt: DateTime.now(),
        ),
        NewsItem(
          id: 2,
          title: "Novo Horário de Funcionamento",
          content: "O novo horário de funcionamento da empresa passa a ser das 9h às 18h.",
          date: "2024-07-15",
          authorName: "Admin",
          authorId: 1,
          createdAt: DateTime.now(),
        ),
      ];
      print('Dados de exemplo carregados: ${_newsItems.length} notícias');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addNewsItem(NewsItem newsItem) async {
    try {
      print('Tentando inserir notícia: ${newsItem.title}');
      print('Autor ID: ${newsItem.authorId}');
      print('Data: ${newsItem.date}');
      
      // Verifica se o autor existe
      final userCheck = await Supabase.instance.client
          .from('usuario')
          .select('id_usuario')
          .eq('id_usuario', newsItem.authorId!)
          .maybeSingle();
          
      if (userCheck == null) {
        throw Exception('Usuário com ID ${newsItem.authorId} não encontrado');
      }
      
      // Insere a notícia
      final response = await Supabase.instance.client
          .from('noticias')
          .insert({
            'titulo': newsItem.title,
            'conteudo': newsItem.content,
            'data_publicacao': newsItem.date,
            'autor_id': newsItem.authorId,
          })
          .select()
          .single();

      print('Notícia inserida com sucesso: ID ${response['id']}');

      // Busca o nome do usuário
      String? authorName;
      try {
        final userResponse = await Supabase.instance.client
            .from('usuario')
            .select('nome_usuario')
            .eq('id_usuario', newsItem.authorId!)
            .single();
        authorName = userResponse['nome_usuario'];
      } catch (e) {
        print('Erro ao buscar nome do autor: $e');
        authorName = 'Usuário Desconhecido';
      }

      final newItem = NewsItem(
        id: response['id'],
        title: response['titulo'],
        content: response['conteudo'],
        date: response['data_publicacao'],
        authorId: response['autor_id'],
        authorName: authorName,
        createdAt: DateTime.parse(response['created_at']),
      );

      _newsItems.insert(0, newItem);
      notifyListeners();

      // Broadcast to Supabase Realtime so other devices get notified
      try {
        final channel = Supabase.instance.client.channel('news');
        channel.subscribe();
        channel.sendBroadcastMessage(
          event: 'news_created',
          payload: {
            'id': newItem.id,
            'title': newItem.title,
            'content': newItem.content,
            'date': newItem.date,
            'author_name': newItem.authorName,
          },
        );
      } catch (e) {
        print('Erro no broadcast: $e'); // Não é crítico
      }

      return true;
    } catch (e) {
      _error = 'Erro ao adicionar notícia: $e';
      print('Erro detalhado ao adicionar notícia: $e');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNewsItem(int newsId) async {
    try {
      await Supabase.instance.client
          .from('noticias')
          .delete()
          .eq('id', newsId);

      _newsItems.removeWhere((item) => item.id == newsId);
      notifyListeners();

      // Broadcast to Supabase Realtime
      final channel = Supabase.instance.client.channel('news');
      channel.subscribe();
      channel.sendBroadcastMessage(
        event: 'news_deleted',
        payload: {'id': newsId},
      );

      return true;
    } catch (e) {
      _error = 'Erro ao deletar notícia: $e';
      print('Erro ao deletar notícia: $e');
      notifyListeners();
      return false;
    }
  }
}

class NewsItem {
  final int? id;
  String title;
  String content;
  String date;
  final int? authorId;
  final String? authorName;
  final DateTime? createdAt;

  NewsItem({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.authorId,
    this.authorName,
    this.createdAt,
  });
}

class NewsApp extends StatelessWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mural de Notícias',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  @override
  void initState() {
    super.initState();
    // Carrega as notícias do banco de dados ao inicializar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NewsData>(context, listen: false).loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    final newsData = Provider.of<NewsData>(context);
    final userType = Provider.of<UserProfileData>(context).userType;
    final canAdd = userType == 2 || userType == 3; // 2 = motorista, 3 = administrador
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EEF2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header moderno
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea),
                      Color(0xFF764ba2),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.announcement,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mural de Notícias',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Fique por dentro das novidades',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canAdd)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddNewsPage(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'Adicionar Notícia',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Exibir erro se houver
              if (newsData.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              newsData.error!,
                              style: TextStyle(color: Colors.red.shade600),
                            ),
                          ),
                          IconButton(
                            onPressed: () => newsData.loadNews(),
                            icon: const Icon(Icons.refresh),
                            color: Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Lista de notícias
              Expanded(
                child: newsData.isLoading && newsData.newsItems.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : newsData.newsItems.isEmpty
                        ? Center(
                            child: Card(
                              margin: const EdgeInsets.all(24),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.article_outlined,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Nenhuma Notícia',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Ainda não há notícias publicadas no mural.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF7F8C8D),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    if (canAdd) ...[
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AddNewsPage(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Criar Primeira Notícia'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1976D2),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => newsData.loadNews(),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: newsData.newsItems.length,
                              itemBuilder: (context, index) {
                                return NewsCard(newsItem: newsData.newsItems[index]);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsItem newsItem;

  const NewsCard({Key? key, required this.newsItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Color(0xFFF8F9FA),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.announcement,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      newsItem.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE0E6ED),
                    width: 1,
                  ),
                ),
                child: Text(
                  newsItem.content,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF34495E),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: const Color(0xFF1976D2),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(newsItem.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (newsItem.authorName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: const Color(0xFF4CAF50),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            newsItem.authorName!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({Key? key}) : super(key: key);

  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSubmitting = false;

  String _todayStr() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    // Garante que apenas motoristas e administradores podem acessar esta tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userType = Provider.of<UserProfileData>(context, listen: false).userType;
      if (userType != 2 && userType != 3) { // 2 = motorista, 3 = administrador
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Apenas motoristas e administradores podem adicionar notícias.'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Adicionar Notícia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1976D2),
                Color(0xFF42A5F5),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE8EEF2),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667eea),
                            Color(0xFF764ba2),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.create,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nova Notícia',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Compartilhe informações importantes',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.title,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Título da Notícia',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _titleController,
                            maxLength: 100,
                            decoration: InputDecoration(
                              hintText: 'Digite o título da notícia...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, digite um título';
                              }
                              if (value.trim().length < 5) {
                                return 'O título deve ter pelo menos 5 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.article,
                                color: Color(0xFF1976D2),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Conteúdo da Notícia',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _contentController,
                            maxLines: 6,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText: 'Digite o conteúdo da notícia...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1976D2),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8F9FA),
                              contentPadding: const EdgeInsets.all(16),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor, digite o conteúdo';
                              }
                              if (value.trim().length < 10) {
                                return 'O conteúdo deve ter pelo menos 10 caracteres';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4FC3F7).withOpacity(0.1),
                            const Color(0xFF29B6F6).withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF1976D2),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Data de Publicação',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF546E7A),
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1976D2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitNews,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send),
                      label: Text(_isSubmitting ? 'Publicando...' : 'Publicar Notícia'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) return;

    final userProfileData = Provider.of<UserProfileData>(context, listen: false);
    final userData = Provider.of<UserData>(context, listen: false);
    final userType = userProfileData.userType;
    final userId = userData.userId;

    if (userType != 2 && userType != 3) { // 2 = motorista, 3 = administrador
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Apenas motoristas e administradores podem adicionar notícias.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: const Text('Erro: usuário não identificado.'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newNewsItem = NewsItem(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        date: _todayStr(),
        authorId: int.parse(userId),
      );
      
      final success = await Provider.of<NewsData>(context, listen: false).addNewsItem(newNewsItem);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Notícia publicada com sucesso!'),
              backgroundColor: Colors.green.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao publicar notícia: ${Provider.of<NewsData>(context, listen: false).error}'),
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao publicar notícia: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}