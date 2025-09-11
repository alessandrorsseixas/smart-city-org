# Notification Service - User Stories

## Visão Geral
O microserviço Notification Service gerencia todas as comunicações na plataforma Smart City Mini. Desenvolvido em Node.js com Express, utiliza múltiplos canais (email, SMS, push notifications) para manter usuários engajados.

## Histórias de Usuário

### Épico: Notificações de Atividades

**Como criança,** eu quero ser lembrada de atividades pendentes para não perder prazos.

**Como professor,** eu quero notificar alunos sobre novas atividades ou mudanças.

**Como pai,** eu quero alertas sobre o progresso e participação do meu filho.

### Épico: Alertas de Sistema

**Como administrador,** eu quero alertas sobre problemas técnicos ou manutenção necessária.

**Como professor,** eu quero notificações sobre dispositivos com problemas.

**Como pai,** eu quero alertas sobre segurança e privacidade.

### Épico: Comunicação Escolar

**Como professor,** eu quero enviar mensagens para pais sobre eventos escolares.

**Como pai,** eu quero receber atualizações sobre atividades e progresso.

**Como administrador,** eu quero broadcast de anúncios importantes.

### Épico: Personalização de Notificações

**Como usuário,** eu quero escolher quais tipos de notificações receber.

**Como professor,** eu quero configurar alertas específicos para minha sala.

**Como pai,** eu quero preferências de comunicação personalizadas.

### Épico: Histórico e Rastreamento

**Como administrador,** eu quero logs de todas as notificações enviadas para auditoria.

**Como professor,** eu quero confirmar que notificações foram entregues.

**Como pai,** eu quero histórico de comunicações com a escola.

## Critérios de Aceitação
- Múltiplos canais: email, SMS, push, in-app
- Templates personalizáveis por idioma e preferência
- Agendamento de notificações
- Rastreamento de entrega e abertura
- Conformidade com leis de privacidade (LGPD, GDPR)

## Dependências
- Integração com Dashboard API para contexto de usuários
- Conexão com Energy Monitor para alertas energéticos
- Uso de provedores externos (SendGrid, Twilio) para envio
- Armazenamento de preferências de usuário
