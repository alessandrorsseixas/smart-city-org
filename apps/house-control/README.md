# house-control

Serviço House Control (Spring Boot) do projeto Smart City.

Resumo
- Aplicação REST simples para controlar/monitorar dispositivos da casa.
- Tech: Java 17, Spring Boot 3.x, Maven.

Principais arquivos
- `src/` — código fonte (controller, service, etc.)
- `pom.xml` — build Maven
- `Dockerfile` — imagem base para produzir a JAR

Endpoints
- GET /api/house/status — retorna status do serviço
- Actuator: /actuator/health, /actuator/info (exposto conforme `application.yml`)

Executar localmente (desenvolvimento)
- Pré-requisitos: JDK 17, Maven
- Build e executar:
  - mvn clean package
  - java -jar target/house-control-0.0.1-SNAPSHOT.jar
- Alternativa (hot-reload durante desenvolvimento):
  - mvn spring-boot:run

Construir imagem Docker
- docker build -t smartcity/house-control:dev .
- docker run --rm -p 8080:8080 -e SPRING_PROFILES_ACTIVE=dev smartcity/house-control:dev

Kubernetes (manifests)
- Manifests sugeridos: `k8s/base/house-control/` (Deployment + Service + optional Ingress)
- Exemplo (aplicar overlay dev):
  - kubectl apply -k k8s/overlays/dev/house-control

Variáveis de ambiente (exemplos)
- `SPRING_PROFILES_ACTIVE` — perfil do Spring (dev/prod)
- `SERVER_PORT` — porta do servidor (padrão 8080)

Testes
- Testes unitários podem ser executados com:
  - mvn test

Contribuição
- Siga o padrão de commits e crie PRs para a branch `main`.
- Antes de abrir PR, execute `mvn -DskipTests=false clean package` e testes locais.

Notas
- Este README tem um propósito didático: ajustar conforme necessidades do time (configurações de CI, registry, políticas de imagem).
