# Dashboard API - User Stories

## Visão Geral
O microserviço Dashboard API é o ponto central de agregação de dados na plataforma Smart City Mini. Desenvolvido em .NET 8 com ASP.NET Core, fornece APIs RESTful para integração com dashboards e aplicações móveis.

## Histórias de Usuário

### Épico: Agregação de Dados de Dispositivos

**Como professor,** eu quero acessar dados consolidados de todos os dispositivos da sala para criar dashboards educacionais.

**Como criança,** eu quero ver meus dados pessoais de forma organizada para acompanhar meu progresso.

**Como pai,** eu quero dados agregados das atividades do meu filho para discussões familiares.

### Épico: APIs de Integração

**Como desenvolvedor,** eu quero APIs bem documentadas para integrar com aplicações móveis e web.

**Como administrador,** eu quero endpoints seguros para gerenciamento de dados.

**Como professor,** eu quero APIs para criar visualizações personalizadas.

### Épico: Autenticação e Autorização

**Como pai,** eu quero acessar apenas dados do meu filho para privacidade.

**Como professor,** eu quero acesso aos dados da minha sala de aula.

**Como administrador,** eu quero controle total sobre permissões de acesso.

### Épico: Cache e Performance

**Como usuário,** eu quero respostas rápidas mesmo com muitos dados.

**Como administrador,** eu quero cache inteligente para reduzir carga no banco.

**Como desenvolvedor,** eu quero APIs otimizadas para aplicações móveis.

### Épico: Relatórios e Exportação

**Como professor,** eu quero exportar dados para planilhas para análise offline.

**Como pai,** eu quero relatórios semanais do progresso do meu filho.

**Como administrador,** eu quero relatórios mensais para stakeholders.

## Critérios de Aceitação
- APIs devem seguir padrões RESTful
- Autenticação via JWT tokens
- Cache com Redis para performance
- Documentação Swagger/OpenAPI
- Suporte a paginação e filtros
- Rate limiting para proteção

## Dependências
- Integração com Device Management para dados de dispositivos
- Conexão com Energy Monitor para métricas energéticas
- Uso de Redis para cache
- Autenticação via Keycloak
