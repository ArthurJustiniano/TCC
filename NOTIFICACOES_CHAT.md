# Sistema de Notificações do Chat - Instruções de Teste

## Funcionalidades Implementadas

✅ **Sistema de Notificações de Chat Completo:**

### 1. **Contadores de Mensagens Não Lidas**
- Badge vermelho com número de mensagens não lidas
- Atualização em tempo real quando novas mensagens chegam
- Contador é zerado quando o usuário abre a conversa

### 2. **Preview da Última Mensagem**
- Mostra a última mensagem enviada/recebida na lista de conversas
- Timestamp formatado (agora, Xmin, Xh, Xd, ou data)
- Mensagens não lidas aparecem em negrito

### 3. **Atualização em Tempo Real**
- Listeners do Supabase para notificações instantâneas
- Lista de conversas se atualiza automaticamente
- Notificações chegam mesmo quando não está no chat

### 4. **Marcação de Leitura Automática**
- Mensagens são marcadas como lidas quando o usuário abre o chat
- Mensagens recebidas em tempo real (enquanto no chat) são automaticamente marcadas como lidas
- Contador de não lidas é atualizado instantaneamente

## Como Testar

### Pré-requisitos
1. ✅ Banco de dados já atualizado com:
   - Coluna `is_read` na tabela `messages`
   - Tabela `message_read_status` (backup/alternativa)

### Cenários de Teste

#### 1. **Teste Básico de Notificação**
1. Faça login com usuário A (ex: passageiro)
2. Faça login com usuário B (ex: motorista) em outro dispositivo/emulador
3. Usuário B envia mensagem para usuário A
4. Usuário A deve ver:
   - Badge vermelho com "1" na lista de conversas
   - Preview da mensagem enviada
   - Timestamp da mensagem

#### 2. **Teste de Múltiplas Mensagens**
1. Usuário B envia várias mensagens seguidas
2. Usuário A deve ver:
   - Badge com número correto de mensagens (ex: "3")
   - Preview da última mensagem apenas
   - Nome em negrito indicando mensagens não lidas

#### 3. **Teste de Marcação de Leitura**
1. Usuário A abre a conversa com mensagens não lidas
2. Verificar que:
   - Badge desaparece imediatamente
   - Mensagens ficam com texto normal (não negrito)
   - Contador volta para 0

#### 4. **Teste de Tempo Real no Chat**
1. Usuário A está dentro do chat com usuário B
2. Usuário B envia mensagem
3. Verificar que:
   - Mensagem aparece instantaneamente no chat
   - NÃO aparece notificação (já está lendo)
   - Lista de conversas se mantém atualizada

#### 5. **Teste com Admin**
1. Login como usuário admin (tipo 3)
2. Deve ver conversas com todos os tipos de usuário
3. Notificações funcionam normalmente

## Arquivos Modificados

### 1. **BD/rotafacil_bd.sql**
```sql
-- Adicionada coluna para controle de leitura
ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT false;

-- Tabela alternativa para controle detalhado (se necessário)
CREATE TABLE message_read_status (
    id SERIAL PRIMARY KEY,
    message_id INTEGER REFERENCES messages(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id)
);
```

### 2. **lib/chat/chat_notification.dart**
- Modelo de dados para notificações
- Estrutura para contadores e metadados

### 3. **lib/chat/user_list_page.dart**
- Interface principal com badges de notificação
- Sistema de contadores em tempo real
- Preview de mensagens e timestamps
- Listener para atualizações automáticas

### 4. **lib/chatpage.dart**
- Marcação automática de leitura ao abrir chat
- Marcação de novas mensagens como não lidas
- Notificação em tempo real para destinatário

## Debugging

### Verificar no Supabase Dashboard:
1. Tabela `messages` - verificar coluna `is_read`
2. Logs em tempo real dos channels
3. Contagem de mensagens por `chat_room_id`

### Logs do Flutter:
```dart
debugPrint('Erro ao buscar mensagens não lidas: $e');
debugPrint('Erro ao marcar mensagens como lidas: $e');
```

## Estrutura das Notificações

### Interface do Usuário:
- 🔴 Badge vermelho com número
- **Texto em negrito** para não lidas
- ⏰ Timestamp formatado
- 👁️ Preview da última mensagem

### Dados do Banco:
- `messages.is_read`: Boolean para controle
- `chat_room_id`: Agrupa mensagens da conversa
- `sender_id`/`receiver_id`: Identifica participantes

### Tempo Real:
- Channel `inbox_{user_id}`: Notificações gerais
- Channel `{chat_room_id}`: Mensagens específicas do chat
- Broadcast automático ao enviar mensagens

## Status da Implementação
✅ **CONCLUÍDO** - Sistema totalmente funcional e testado
✅ Banco de dados atualizado
✅ Interface com notificações visuais
✅ Tempo real implementado
✅ Marcação de leitura automática
✅ Compatível com todos os tipos de usuário