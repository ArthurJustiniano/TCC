import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_flutter/user_profile_data.dart';
import 'package:app_flutter/user_data.dart';

class DeleteUsersPage extends StatefulWidget {
	const DeleteUsersPage({super.key});

	@override
	State<DeleteUsersPage> createState() => _DeleteUsersPageState();
}

class _DeleteUsersPageState extends State<DeleteUsersPage> {
	bool _loading = true;
	String? _error;
	List<Map<String, dynamic>> _users = [];
	bool _deleting = false;

	@override
	void initState() {
		super.initState();
		_loadUsers();
	}

	Future<void> _loadUsers() async {
		setState(() {
			_loading = true;
			_error = null;
		});
		try {
			final data = await Supabase.instance.client
					.from('usuario')
					.select('id_usuario, nome_usuario, email_usuario, tipo_usuario')
					.order('id_usuario');
			setState(() {
				_users = List<Map<String, dynamic>>.from(data as List);
				_loading = false;
			});
		} catch (e) {
			setState(() {
				_error = 'Erro ao carregar usuários: $e';
				_loading = false;
			});
		}
	}

	Future<void> _deleteUser(Map<String, dynamic> user, {bool cascade = false}) async {
		final userId = user['id_usuario'] as int;
		setState(() => _deleting = true);
		try {
			if (cascade) {
				await _cleanupDependencias(user);
			}
			await Supabase.instance.client.from('usuario').delete().eq('id_usuario', userId);
			setState(() {
				_users.removeWhere((u) => (u['id_usuario'] as int) == userId);
			});
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(cascade ? 'Usuário e dependências excluídos.' : 'Usuário excluído.')),
				);
			}
		} catch (e) {
			String msg = 'Falha ao excluir: $e';
			final errStr = e.toString();
			final isFk = errStr.toLowerCase().contains('foreign key') || errStr.contains('23503');
			if (isFk) {
				if (mounted) {
					_showCascadeDialog(user);
				}
				msg = 'Existem registros relacionados (pagamentos, rotas, chats, presenças ou mensagens).';
			}
			if (mounted) {
				ScaffoldMessenger.of(context).showSnackBar(
					SnackBar(content: Text(msg)),
				);
			}
		} finally {
			if (mounted) setState(() => _deleting = false);
		}
	}

	Future<void> _cleanupDependencias(Map<String, dynamic> user) async {
		final userId = user['id_usuario'] as int;
		final tipo = user['tipo_usuario'] as int?; // 1=passageiro, 2=motorista, 3=admin
		final client = Supabase.instance.client;
		// Mensagens (envio ou recebimento)
		await client.from('messages').delete().or('sender_id.eq.$userId,receiver_id.eq.$userId');
		// Chats (como passageiro ou motorista)
		await client.from('chat').delete().or('cod_passageiro.eq.$userId,cod_motorista.eq.$userId');
		// Localizações
		await client.from('locations').delete().eq('user_id', userId);
		// Se passageiro: pagamentos + rotas associadas (opção: null ou delete)
		if (tipo == 1) {
			await client.from('pagamento').delete().eq('cod_passageiro', userId);
			// Em vez de deletar a rota (poderia haver histórico), vamos apenas dessassociar
			await client.from('rota').update({'cod_associacao': null}).eq('cod_associacao', userId);
		}
		// Se motorista: presenças onde ele aparece
		if (tipo == 2) {
			await client.from('presenca').delete().eq('cod_motorista', userId);
			// Rotas que por acaso estejam associadas (se modelo permitir motorista ali)
			await client.from('rota').update({'cod_associacao': null}).eq('cod_associacao', userId);
		}
		// Para admin, apenas limpeza genérica já feita acima (mensagens/chats/locations). Demais dados normalmente não vinculados.
	}

	void _showCascadeDialog(Map<String, dynamic> user) {
		showDialog(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Excluir com dependências?'),
				content: const Text(
					'A exclusão direta falhou porque existem registros vinculados. Você pode limpar dados relacionados (mensagens, chats, pagamentos, presenças, localizações e dessassociar rotas) e tentar novamente.'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx),
						child: const Text('Cancelar'),
					),
					ElevatedButton.icon(
						icon: const Icon(Icons.delete_forever),
						label: const Text('Excluir Tudo'),
						style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
						onPressed: _deleting
								? null
								: () async {
									Navigator.pop(ctx);
									await _deleteUser(user, cascade: true);
								},
					),
				],
			),
		);
	}

	void _confirmDelete(Map<String, dynamic> user) {
		final currentUserIdStr = context.read<UserData>().userId;
		final currentUserId = int.tryParse(currentUserIdStr ?? '');
		final targetId = user['id_usuario'] as int;
		if (currentUserId != null && currentUserId == targetId) {
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(content: Text('Você não pode excluir a sua própria conta.')),
			);
			return;
		}
		showDialog(
			context: context,
			builder: (ctx) => AlertDialog(
				title: const Text('Confirmar exclusão'),
				content: Text('Excluir o usuário "${user['nome_usuario']}" (ID ${user['id_usuario']})?'),
				actions: [
					TextButton(
						onPressed: () => Navigator.pop(ctx),
						child: const Text('Cancelar'),
					),
            
					ElevatedButton.icon(
						onPressed: _deleting
								? null
								: () async {
										Navigator.pop(ctx);
									await _deleteUser(user);
									},
						icon: const Icon(Icons.delete),
						label: const Text('Excluir'),
						style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
					),
				],
			),
		);
	}

	@override
	Widget build(BuildContext context) {
		final userType = context.watch<UserProfileData>().userType;
		final isAdmin = userType == 3;
		if (!isAdmin) {
			return Scaffold(
				appBar: AppBar(
					title: const Text('Gerenciar Usuários'),
					backgroundColor: Colors.blue,
				),
				body: const Center(
					child: Padding(
						padding: EdgeInsets.all(16.0),
						child: Text('Acesso restrito. Apenas administradores podem acessar esta página.'),
					),
				),
			);
		}

		return Scaffold(
			appBar: AppBar(
				title: const Text('Gerenciar Usuários'),
				backgroundColor: Colors.blue,
				actions: [
					IconButton(
						tooltip: 'Recarregar',
						onPressed: _loading ? null : _loadUsers,
						icon: const Icon(Icons.refresh),
					),
				],
			),
			body: _loading
					? const Center(child: CircularProgressIndicator())
					: _error != null
							? Center(
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										children: [
											const Icon(Icons.error_outline, color: Colors.red, size: 48),
											const SizedBox(height: 12),
											Text(_error!),
											const SizedBox(height: 12),
											ElevatedButton.icon(
												onPressed: _loadUsers,
												icon: const Icon(Icons.refresh),
												label: const Text('Tentar novamente'),
											)
										],
									),
								)
							: RefreshIndicator(
									onRefresh: _loadUsers,
									child: ListView.separated(
										physics: const AlwaysScrollableScrollPhysics(),
										padding: const EdgeInsets.all(12),
										itemCount: _users.length,
										separatorBuilder: (_, __) => const Divider(height: 1),
										itemBuilder: (ctx, i) {
											final u = _users[i];
											final tipo = u['tipo_usuario'];
											String tipoLabel;
											switch (tipo) {
												case 1:
													tipoLabel = 'Passageiro';
													break;
												case 2:
													tipoLabel = 'Motorista';
													break;
												case 3:
													tipoLabel = 'Admin';
													break;
												default:
													tipoLabel = 'Desconhecido';
											}
											return ListTile(
												leading: CircleAvatar(
													backgroundColor: Colors.blue.shade100,
													child: Text(u['id_usuario'].toString()),
												),
												title: Text(u['nome_usuario'] ?? ''),
												subtitle: Text('${u['email_usuario']} • $tipoLabel'),
												trailing: IconButton(
													icon: const Icon(Icons.delete, color: Colors.redAccent),
													tooltip: 'Excluir',
													onPressed: () => _confirmDelete(u),
												),
											);
										},
									),
								),
		);
	}
}

