# Energy Monitor - User Stories

## Visão Geral
O microserviço Energy Monitor rastreia a produção e consumo de energia renovável na plataforma Smart City Mini. Desenvolvido em Python com FastAPI, utiliza MQTT para comunicação e InfluxDB para armazenamento de séries temporais.

## Histórias de Usuário

### Épico: Monitoramento de Produção de Energia

**Como criança,** eu quero ver quanta energia meu painel solar está produzindo para entender conceitos de energia renovável.

**Como professor,** eu quero monitorar a produção total de energia da sala para ensinar sobre eficiência energética.

**Como pai,** eu quero acompanhar a produção de energia das atividades do meu filho para discutir sustentabilidade em casa.

### Épico: Rastreamento de Consumo de Energia

**Como criança,** eu quero monitorar quanto energia meus dispositivos estão consumindo para aprender sobre conservação.

**Como professor,** eu quero analisar padrões de consumo para identificar oportunidades de otimização.

**Como administrador,** eu quero gerar relatórios de consumo por dispositivo para planejamento de manutenção.

### Épico: Alertas e Notificações

**Como professor,** eu quero receber alertas quando a produção de energia cair abaixo de um limite para investigar problemas.

**Como criança,** eu quero ser notificada quando minha casa inteligente estiver usando muita energia.

**Como pai,** eu quero alertas sobre uso excessivo de energia durante as atividades escolares.

### Épico: Análise de Dados Energéticos

**Como professor,** eu quero visualizar gráficos de produção vs consumo ao longo do tempo para ensinar sobre balanço energético.

**Como criança,** eu quero comparar minha produção de energia com a de outros alunos para competição saudável.

**Como administrador,** eu quero dados históricos para avaliar a eficácia do programa educacional.

### Épico: Simulação de Cenários Energéticos

**Como professor,** eu quero simular diferentes cenários de produção/consumo para ensinar sobre impacto ambiental.

**Como criança,** eu quero experimentar com diferentes configurações de energia para ver os efeitos.

**Como pai,** eu quero ver simulações de economia de energia para discutir com meu filho.

## Critérios de Aceitação
- Dados devem ser coletados em tempo real via MQTT
- Interface deve mostrar métricas em unidades apropriadas para crianças (kWh, watts)
- Alertas devem ser configuráveis por usuário
- Dados históricos devem ser mantidos por pelo menos 1 ano
- Visualizações devem ser responsivas e acessíveis

## Dependências
- Comunicação MQTT com dispositivos de hardware
- Integração com InfluxDB para armazenamento de séries temporais
- Conexão com Dashboard API para exposição de métricas
