# =====================================================================================
# STAGE 1: Build Stage (Estágio de Compilação)
# Responsável por compilar o código-fonte Java e gerar o artefato executável (.jar).
# Utiliza uma imagem completa do Maven com o JDK Temurin 21. A tag :3.9.6 é uma
# versão estável e validada, corrigindo o erro "not found" anterior.
# =====================================================================================
FROM maven:3.9.6-eclipse-temurin-21 AS build

# Define o diretório de trabalho dentro do contêiner.
WORKDIR /app

# Copia o pom.xml primeiro para aproveitar o cache de camadas do Docker.
# Se as dependências não mudarem, o Docker não as baixará novamente em builds futuros.
COPY pom.xml .

# Baixa todas as dependências do projeto de forma offline.
RUN mvn dependency:go-offline -B

# Copia o restante do código-fonte da aplicação.
COPY src ./src

# Compila e empacota a aplicação, pulando os testes para agilizar o build no pipeline de CI.
# O '-B' (batch mode) garante que o Maven não utilize logs interativos.
RUN mvn package -DskipTests -B

# =====================================================================================
# STAGE 2: Runtime Stage (Estágio de Execução)
# Responsável por criar a imagem final, que irá executar a aplicação.
# Utiliza uma imagem JRE (Java Runtime Environment) mínima e baseada em Alpine,
# garantindo uma imagem final muito menor e com superfície de ataque reduzida.
# =====================================================================================
FROM eclipse-temurin:21-jre-alpine

# Define o diretório de trabalho para a execução.
WORKDIR /app

# [PRÁTICA DE SEGURANÇA] Cria um usuário e um grupo específicos para a aplicação.
# Executar o processo com um usuário não-root (princípio do menor privilégio)
# é uma camada de segurança essencial em ambientes conteinerizados.
RUN addgroup -S spring && adduser -S spring -G spring

# Cria o diretório de configuração e ajusta permissões para o usuário spring
RUN mkdir -p /app/config && chown -R spring:spring /app/config

# Alterna o contexto de execução para o usuário não-root recém-criado.
USER spring:spring

# Copia o arquivo de configuração application.yml para o diretório esperado
COPY --from=build /app/src/main/resources/application.yml /app/config/application.yml

# Copia o artefato .jar gerado no Stage 1 para a imagem final.
# Copia especificamente o jar do house-control para garantir que seja o arquivo correto.
COPY --from=build /app/target/house-control-*.jar app.jar

# Expõe a porta 8081, na qual a aplicação Spring Boot irá rodar.
# Esta é uma documentação para o orquestrador (ex: Kubernetes).
EXPOSE 8081

# Define o comando de entrada para iniciar a aplicação quando o contêiner for executado.
ENTRYPOINT ["java", "-jar", "app.jar"]
