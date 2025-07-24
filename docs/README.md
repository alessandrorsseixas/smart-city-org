# Smart City Automation Project - Microservices Implementation

## Overview

This project implements a complete Smart City automation system using .NET 8 microservices with CQRS pattern, Angular frontend, and Kubernetes deployment. The system simulates a smart city environment with house automation, autonomous vehicles, renewable energy management, and real-time notifications.

## Architecture

### Microservices

| Service | Description | Port | Database |
|---------|-------------|------|----------|
| **Auth Service** | Authentication & Authorization | 5001 | MySQL |
| **House Control Service** | Smart home device management | 5002 | MySQL |
| **Car Control Service** | Autonomous vehicle control | 5003 | MySQL |
| **Energy Control Service** | Solar/Wind energy management | 5004 | MySQL |
| **Notification Service** | Multi-channel notifications | 5005 | MySQL |
| **Alexa Service** | Voice command integration | 5006 | MySQL |

### Technology Stack

- **Backend**: .NET 8, CQRS with MediatR, Entity Framework Core, MySQL
- **Caching**: Redis
- **Frontend**: Angular 18, Angular Material
- **Container**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: Jenkins, ArgoCD
- **API Gateway**: Kubernetes Ingress with NGINX

## Project Structure

```
/
├── src/
│   ├── services/
│   │   ├── auth-service/                 # Authentication & user management
│   │   │   ├── SmartCity.AuthService/
│   │   │   └── SmartCity.AuthService.Tests/
│   │   ├── house-control-service/        # Smart home automation
│   │   │   └── SmartCity.HouseControlService/
│   │   ├── car-control-service/          # Autonomous vehicle control
│   │   ├── energy-control-service/       # Renewable energy management
│   │   ├── notification-service/         # Multi-channel notifications
│   │   └── alexa-service/               # Voice command integration
│   ├── frontend/
│   │   └── smart-city-dashboard/        # Angular dashboard
│   └── shared/
│       └── common-libraries/            # Shared .NET libraries
│           ├── SmartCity.Shared.Common/
│           ├── SmartCity.Shared.CQRS/
│           └── SmartCity.Shared.Infrastructure/
├── k8s/
│   ├── infrastructure/                  # MySQL, Redis, Secrets
│   ├── services/                       # Service deployments
│   └── ingress/                        # API Gateway configuration
├── ci-cd/
│   ├── jenkins/                        # Jenkins pipeline
│   └── argocd/                         # ArgoCD GitOps
└── docs/                               # Documentation
```

## Features Implemented

### ✅ Completed Features

- [x] **Shared Libraries**
  - [x] CQRS pattern with MediatR
  - [x] Common entities and DTOs
  - [x] Infrastructure services (Database, Cache)
  - [x] Validation behaviors

- [x] **Auth Service**
  - [x] User registration and login
  - [x] JWT token authentication
  - [x] Password hashing with BCrypt
  - [x] Health checks and Swagger
  - [x] Unit tests
  - [x] Docker containerization

- [x] **House Control Service**
  - [x] Device management (lights, AC, security, etc.)
  - [x] CQRS commands for device control
  - [x] Real-time device status queries
  - [x] Multiple house support

- [x] **Angular Dashboard**
  - [x] Material Design UI
  - [x] Real-time device controls
  - [x] Energy monitoring display
  - [x] System status indicators
  - [x] Responsive design

- [x] **Infrastructure**
  - [x] Kubernetes manifests
  - [x] MySQL and Redis deployment
  - [x] Secrets management
  - [x] API Gateway with Ingress
  - [x] CI/CD pipeline (Jenkins)
  - [x] GitOps deployment (ArgoCD)

### 🚧 Planned Features (Future Iterations)

- [ ] **Remaining Services**
  - [ ] Car Control Service (autonomous navigation)
  - [ ] Energy Control Service (solar/wind management)
  - [ ] Notification Service (email, SMS, push, WhatsApp)
  - [ ] Alexa Service (voice commands)

- [ ] **Advanced Features**
  - [ ] Real-time WebSocket communication
  - [ ] Advanced energy analytics
  - [ ] ML-based automation
  - [ ] Mobile app (iOS/Android)

## Quick Start

### Prerequisites

- .NET 8 SDK
- Node.js 18+
- Docker
- Kubernetes (Minikube for local development)

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/alessandrorsseixas/smart-city-org.git
   cd smart-city-org
   ```

2. **Build shared libraries**
   ```bash
   dotnet restore
   dotnet build
   ```

3. **Run Auth Service**
   ```bash
   cd src/services/auth-service/SmartCity.AuthService
   dotnet run
   ```

4. **Run House Control Service**
   ```bash
   cd src/services/house-control-service/SmartCity.HouseControlService
   dotnet run
   ```

5. **Run Angular Dashboard**
   ```bash
   cd src/frontend/smart-city-dashboard
   npm install
   npm start
   ```

### Kubernetes Deployment

1. **Create namespace and secrets**
   ```bash
   kubectl apply -f k8s/infrastructure/namespace.yaml
   kubectl apply -f k8s/infrastructure/secrets.yaml
   ```

2. **Deploy infrastructure**
   ```bash
   kubectl apply -f k8s/infrastructure/
   ```

3. **Deploy services**
   ```bash
   kubectl apply -f k8s/services/
   ```

4. **Setup API Gateway**
   ```bash
   kubectl apply -f k8s/ingress/
   ```

## API Documentation

### Auth Service Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | User login |
| POST | `/api/auth/register` | User registration |
| GET | `/api/auth/profile` | Get user profile |
| POST | `/api/auth/logout` | User logout |

### House Control Service Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/house/{id}/status` | Get house and device status |
| POST | `/api/house/devices/control` | Control smart devices |

## Smart City Features

### 🏠 House Automation
- **Devices Supported**: Lights, HVAC, Security, Smart Plugs, Cameras
- **Control Methods**: Web dashboard, API calls, (Future: Voice commands)
- **Features**: Remote control, scheduling, energy monitoring

### 🚗 Autonomous Vehicle (Planned)
- **Navigation**: Sensor-based autonomous driving
- **Integration**: Charging stations, traffic management
- **Monitoring**: Real-time location and battery status

### ⚡ Energy Management (Planned)
- **Sources**: Solar panels, wind turbines
- **Storage**: Battery system with smart distribution
- **Analytics**: Energy production vs consumption tracking

### 📱 Notifications (Planned)
- **Channels**: Email, SMS, Push notifications, WhatsApp
- **Triggers**: Security alerts, energy events, device status
- **Integration**: Alexa voice notifications

## Testing

### Unit Tests
```bash
# Run all tests
dotnet test

# Run specific service tests
dotnet test src/services/auth-service/SmartCity.AuthService.Tests/
```

### Integration Tests
```bash
# Build and test all services
dotnet build && dotnet test
```

## Monitoring and Health Checks

All services include:
- **Health Check Endpoints**: `/health`
- **Swagger Documentation**: Available in development mode
- **Logging**: Structured logging with correlation IDs
- **Metrics**: Performance and business metrics

## Security

- **Authentication**: JWT-based with configurable expiration
- **Authorization**: Role-based access control
- **Secrets**: Kubernetes secrets for sensitive data
- **Network**: Service-to-service communication via internal network

## Scalability

- **Horizontal Scaling**: Kubernetes ReplicaSets
- **Caching**: Redis for performance optimization
- **Database**: MySQL with connection pooling
- **Load Balancing**: Kubernetes Services with NGINX Ingress

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add/update tests
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For questions or support, please open an issue in the GitHub repository.

---

*This Smart City project demonstrates a production-ready microservices architecture with modern DevOps practices and cloud-native technologies.*