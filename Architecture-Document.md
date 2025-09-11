# Smart City Mini - Architecture Document

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Smart City Mini Platform                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  Web UI     │  │  Mobile App │  │   Alexa     │  │   n8n   │ │
│  │  (React)    │  │ (React Nat) │  │   Skills    │  │Workflows│ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │Device Mgmt  │  │Energy Mon  │   │Dashboard    │  │ AI Tutor│ │
│  │(.NET 8)     │  │(Python)     │  │(Node.js)    │  │(Python) │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                    Message Bus (RabbitMQ)                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ PostgreSQL  │  │  InfluxDB   │  │   Redis     │              │
│  │ (Relational)│  │(Time-series)│  │  (Cache)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                    Hardware Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │Raspberry Pi │  │ Arduino/    │  │   Sensors   │               │
│  │   (Hub)     │  │  ESP32      │  │ & Actuators │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Microservices

| Service Name | Responsibility | Technology Stack |
|--------------|----------------|------------------|
| Device Management | Hardware device registration, configuration, and control | .NET 8, REST API, MQTT client |
| Energy Monitor | Track renewable energy production and consumption | Python (FastAPI), MQTT, InfluxDB |
| Dashboard API | Provide data aggregation and API endpoints for web/mobile | Node.js (Express), REST, WebSockets |
| AI Tutor | Interactive learning assistant with personalized guidance | Python (Flask), AI APIs (OpenAI), PostgreSQL |
| Notification Service | Handle alerts and notifications across platforms | Node.js, RabbitMQ, Email/SMS APIs |

## Communication Patterns

- **MQTT**: Real-time sensor data from hardware to microservices
- **REST APIs**: Synchronous communication between services and clients
- **WebSockets**: Real-time updates for dashboards and mobile apps
- **Message Bus (RabbitMQ)**: Asynchronous event-driven communication
- **HTTP Webhooks**: Integration with external services (Alexa, n8n)

## Data Storage

- **PostgreSQL**: User data, device configurations, learning progress
- **InfluxDB**: Time-series data for energy metrics and sensor readings
- **Redis**: Session management, caching, real-time data buffering
- **File Storage**: Media files (images, videos) via cloud storage APIs

## DevOps & CI/CD

- **Containerization**: Docker for all services and dependencies
- **Orchestration**: Kubernetes for cluster management and scaling
- **CI/CD Pipeline**: GitHub Actions for automated testing and deployment
- **Monitoring**: Prometheus for metrics, Grafana for dashboards
- **Logging**: ELK stack (Elasticsearch, Logstash, Kibana)

## Cloud Free-Tier Strategy

- **GitHub Actions**: CI/CD with 2,000 minutes/month free
- **Render**: Free tier for web services and databases
- **Railway**: Free tier for databases and background services
- **AWS Free Tier**: EC2, Lambda, S3 for 12 months
- **GCP Free Tier**: Compute Engine, Cloud Storage
- **Kubernetes**: Self-hosted on free-tier VMs or local clusters

## Security and Privacy Considerations

- **Data Encryption**: All data encrypted at rest and in transit
- **Access Control**: Role-based access for children, teachers, parents
- **Privacy Compliance**: COPPA compliance for children's data
- **Secure APIs**: JWT tokens, API rate limiting
- **Hardware Security**: Secure boot, firmware updates
- **Monitoring**: Real-time security monitoring and alerts
- **Parental Controls**: Opt-in data sharing, activity monitoring

---

# Smart City Mini - Documento de Arquitetura

## Arquitetura de Alto Nível

```
┌─────────────────────────────────────────────────────────────────┐
│                  Plataforma Smart City Mini                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  UI Web     │  │  App Mobile │  │   Alexa     │  │   n8n   │ │
│  │  (React)    │  │ (React Nat) │  │   Skills    │  │ Workflows│ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │Gerenc Disps │  │Monitor Ener│  │Dashboard   │  │ Tutor IA │ │
│  │(.NET 8)     │  │(Python)     │  │(Node.js)   │  │(Python)  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────────────┤
│                 Barramento de Mensagens (RabbitMQ)             │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ PostgreSQL  │  │  InfluxDB   │  │   Redis     │              │
│  │ (Relacional)│  │(Séries Temp)│  │  (Cache)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                    Camada de Hardware                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │Raspberry Pi │  │ Arduino/   │  │   Sensores   │              │
│  │   (Hub)     │  │  ESP32      │  │ & Atuadores │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Microsserviços

| Nome do Serviço | Responsabilidade | Stack Tecnológico |
|-----------------|------------------|-------------------|
| Gerenciamento de Dispositivos | Registro, configuração e controle de dispositivos de hardware | .NET 8, API REST, Cliente MQTT |
| Monitor de Energia | Rastrear produção e consumo de energia renovável | Python (FastAPI), MQTT, InfluxDB |
| API do Dashboard | Agregação de dados e endpoints de API para web/móvel | Node.js (Express), REST, WebSockets |
| Tutor IA | Assistente de aprendizagem interativo com orientação personalizada | Python (Flask), APIs IA (OpenAI), PostgreSQL |
| Serviço de Notificações | Gerenciar alertas e notificações entre plataformas | Node.js, RabbitMQ, APIs Email/SMS |

## Padrões de Comunicação

- **MQTT**: Dados de sensores em tempo real do hardware para microsserviços
- **APIs REST**: Comunicação síncrona entre serviços e clientes
- **WebSockets**: Atualizações em tempo real para dashboards e apps móveis
- **Barramento de Mensagens (RabbitMQ)**: Comunicação assíncrona orientada a eventos
- **Webhooks HTTP**: Integração com serviços externos (Alexa, n8n)

## Armazenamento de Dados

- **PostgreSQL**: Dados de usuários, configurações de dispositivos, progresso de aprendizagem
- **InfluxDB**: Dados de séries temporais para métricas de energia e leituras de sensores
- **Redis**: Gerenciamento de sessão, cache, buffer de dados em tempo real
- **Armazenamento de Arquivos**: Arquivos de mídia (imagens, vídeos) via APIs de armazenamento em nuvem

## DevOps & CI/CD

- **Containerização**: Docker para todos os serviços e dependências
- **Orquestração**: Kubernetes para gerenciamento e escalabilidade de cluster
- **Pipeline CI/CD**: GitHub Actions para testes automatizados e implantação
- **Monitoramento**: Prometheus para métricas, Grafana para dashboards
- **Logging**: Stack ELK (Elasticsearch, Logstash, Kibana)

## Estratégia de Camada Gratuita na Nuvem

- **GitHub Actions**: CI/CD com 2.000 minutos/mês gratuitos
- **Render**: Camada gratuita para serviços web e bancos de dados
- **Railway**: Camada gratuita para bancos de dados e serviços em segundo plano
- **AWS Free Tier**: EC2, Lambda, S3 por 12 meses
- **GCP Free Tier**: Compute Engine, Cloud Storage
- **Kubernetes**: Auto-hospedado em VMs de camada gratuita ou clusters locais

## Considerações de Segurança e Privacidade

- **Criptografia de Dados**: Todos os dados criptografados em repouso e em trânsito
- **Controle de Acesso**: Acesso baseado em função para crianças, professores, pais
- **Conformidade com Privacidade**: Conformidade COPPA para dados de crianças
- **APIs Seguras**: Tokens JWT, limitação de taxa de API
- **Segurança de Hardware**: Inicialização segura, atualizações de firmware
- **Monitoramento**: Monitoramento de segurança em tempo real e alertas
- **Controles Parentais**: Compartilhamento de dados opcional, monitoramento de atividade

---

# Smart City Mini - Documento de Arquitectura

## Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────────┐
│                  Plataforma Smart City Mini                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  UI Web     │  │  App Móvil  │  │   Alexa     │  │   n8n   │ │
│  │  (React)    │  │ (React Nat) │  │   Skills    │  │ Workflows│ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │Gestión Disp │  │Monitor Ener│  │Dashboard   │  │ Tutor IA │ │
│  │(.NET 8)     │  │(Python)     │  │(Node.js)   │  │(Python)  │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
├─────────────────────────────────────────────────────────────────┤
│               Bus de Mensajes (RabbitMQ)                       │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │ PostgreSQL  │  │  InfluxDB   │  │   Redis     │              │
│  │ (Relacional)│  │(Series Temp)│  │  (Cache)    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
├─────────────────────────────────────────────────────────────────┤
│                    Capa de Hardware                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │Raspberry Pi │  │ Arduino/   │  │   Sensores   │              │
│  │   (Hub)     │  │  ESP32      │  │ & Actuadores│              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Microservicios

| Nombre del Servicio | Responsabilidad | Stack Tecnológico |
|---------------------|----------------|-------------------|
| Gestión de Dispositivos | Registro, configuración y control de dispositivos de hardware | .NET 8, API REST, Cliente MQTT |
| Monitor de Energía | Rastrear producción y consumo de energía renovable | Python (FastAPI), MQTT, InfluxDB |
| API del Dashboard | Proporcionar agregación de datos y endpoints de API para web/móvil | Node.js (Express), REST, WebSockets |
| Tutor IA | Asistente de aprendizaje interactivo con guía personalizada | Python (Flask), APIs IA (OpenAI), PostgreSQL |
| Servicio de Notificaciones | Manejar alertas y notificaciones entre plataformas | Node.js, RabbitMQ, APIs Email/SMS |

## Patrones de Comunicación

- **MQTT**: Datos de sensores en tiempo real desde hardware a microservicios
- **APIs REST**: Comunicación síncrona entre servicios y clientes
- **WebSockets**: Actualizaciones en tiempo real para dashboards y apps móviles
- **Bus de Mensajes (RabbitMQ)**: Comunicación asíncrona orientada a eventos
- **Webhooks HTTP**: Integración con servicios externos (Alexa, n8n)

## Almacenamiento de Datos

- **PostgreSQL**: Datos de usuarios, configuraciones de dispositivos, progreso de aprendizaje
- **InfluxDB**: Datos de series temporales para métricas de energía y lecturas de sensores
- **Redis**: Gestión de sesiones, caché, búfer de datos en tiempo real
- **Almacenamiento de Archivos**: Archivos multimedia (imágenes, videos) vía APIs de almacenamiento en nube

## DevOps & CI/CD

- **Containerización**: Docker para todos los servicios y dependencias
- **Orquestación**: Kubernetes para gestión y escalado de clúster
- **Pipeline CI/CD**: GitHub Actions para pruebas automatizadas y despliegue
- **Monitoreo**: Prometheus para métricas, Grafana para dashboards
- **Logging**: Stack ELK (Elasticsearch, Logstash, Kibana)

## Estrategia de Capa Gratuita en la Nube

- **GitHub Actions**: CI/CD con 2.000 minutos/mes gratuitos
- **Render**: Capa gratuita para servicios web y bases de datos
- **Railway**: Capa gratuita para bases de datos y servicios en segundo plano
- **AWS Free Tier**: EC2, Lambda, S3 por 12 meses
- **GCP Free Tier**: Compute Engine, Cloud Storage
- **Kubernetes**: Auto-hospedado en VMs de capa gratuita o clústeres locales

## Consideraciones de Seguridad y Privacidad

- **Cifrado de Datos**: Todos los datos cifrados en reposo y en tránsito
- **Control de Acceso**: Acceso basado en roles para niños, profesores, padres
- **Cumplimiento de Privacidad**: Cumplimiento COPPA para datos de niños
- **APIs Seguras**: Tokens JWT, limitación de tasa de API
- **Seguridad de Hardware**: Arranque seguro, actualizaciones de firmware
- **Monitoreo**: Monitoreo de seguridad en tiempo real y alertas
- **Controles Parentales**: Compartir datos opcional, monitoreo de actividad
