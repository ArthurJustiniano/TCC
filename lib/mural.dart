import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class NewsData extends ChangeNotifier {
  final List<NewsItem> _newsItems = [
    NewsItem(
      title: "Reunião da Diretoria",
      content: "A próxima reunião da diretoria será realizada na terça-feira, dia 25, às 10h.",
      date: "2024-07-18",
    ),
    NewsItem(
      title: "Novo Horário de Funcionamento",
      content: "O novo horário de funcionamento da empresa passa a ser das 9h às 18h.",
      date: "2024-07-15",
    ),
    NewsItem(
      title: "Feriado Municipal",
      content: "Na próxima segunda-feira, dia 22, não haverá expediente devido ao feriado municipal.",
      date: "2024-07-12",
    ),
  ];

  List<NewsItem> get newsItems => _newsItems;

  void addNewsItem(NewsItem newsItem) {
    _newsItems.add(newsItem);
    notifyListeners();
  }
}

class NewsItem {
  String title;
  String content;
  String date;

  NewsItem({
    required this.title,
    required this.content,
    required this.date,
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

class NewsPage extends StatelessWidget {
  const NewsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final newsData = Provider.of<NewsData>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural de Notícias'),
        backgroundColor: Colors.blue[700],
      ),
      body: ListView.builder(
        itemCount: newsData.newsItems.length,
        itemBuilder: (context, index) {
          return NewsCard(newsItem: newsData.newsItems[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddNewsPage()),
          );
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue[700],
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
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              newsItem.title,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              newsItem.content,
              style: const TextStyle(fontSize: 16.0),
            ),
            const SizedBox(height: 8.0),
            Text(
              "Data: ${newsItem.date}",
              style: const TextStyle(fontSize: 14.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class AddNewsPage extends StatefulWidget {
  const AddNewsPage({Key? key}) : super(key: key);

  @override
  _AddNewsPageState createState() => _AddNewsPageState();
}

class _AddNewsPageState extends State<AddNewsPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _dateController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Notícia'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Conteúdo'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Data (AAAA-MM-DD)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newNewsItem = NewsItem(
                  title: _titleController.text,
                  content: _contentController.text,
                  date: _dateController.text,
                );
                Provider.of<NewsData>(context, listen: false).addNewsItem(newNewsItem);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _dateController.dispose();
    super.dispose();
  }
}