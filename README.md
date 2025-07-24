# Smart City Automation Project

A comprehensive microservices-based smart city automation platform built with .NET 8, Angular, and Kubernetes.

## 🚀 Project Overview

This project implements a complete smart city ecosystem featuring:

- **🏠 House Automation**: Smart device control for lights, HVAC, security systems
- **🚗 Autonomous Vehicles**: Car control with sensors and navigation (planned)
- **⚡ Energy Management**: Solar and wind power generation with battery storage (planned)
- **🔔 Real-time Notifications**: Multi-channel alerts via email, SMS, push, WhatsApp (planned)
- **🎤 Voice Control**: Alexa integration for hands-free operation (planned)
- **📱 Web & Mobile**: Angular dashboard with responsive design

## 🏗️ Architecture

### Microservices (.NET 8 + CQRS)
- **Auth Service** - JWT authentication & user management ✅
- **House Control Service** - Smart home device automation ✅  
- **Car Control Service** - Autonomous vehicle management (planned)
- **Energy Control Service** - Renewable energy orchestration (planned)
- **Notification Service** - Multi-channel messaging (planned)
- **Alexa Service** - Voice command processing (planned)

### Frontend
- **Angular Dashboard** - Real-time monitoring and control interface ✅

### Infrastructure
- **Kubernetes** - Container orchestration with MySQL & Redis ✅
- **CI/CD** - Jenkins pipeline with ArgoCD GitOps ✅
- **API Gateway** - NGINX Ingress for service routing ✅

## 🛠️ Technology Stack

| Component | Technology |
|-----------|------------|
| **Backend** | .NET 8, CQRS with MediatR, Entity Framework Core |
| **Database** | MySQL with Redis caching |
| **Frontend** | Angular 18, Angular Material |
| **Authentication** | JWT with BCrypt password hashing |
| **Container** | Docker |
| **Orchestration** | Kubernetes |
| **CI/CD** | Jenkins + ArgoCD |
| **API Gateway** | Kubernetes Ingress (NGINX) |

## 📁 Project Structure

```
smart-city-org/
├── src/
│   ├── services/           # Microservices
│   │   ├── auth-service/          ✅ Complete
│   │   ├── house-control-service/ ✅ Complete  
│   │   ├── car-control-service/   🚧 Planned
│   │   ├── energy-control-service/ 🚧 Planned
│   │   ├── notification-service/  🚧 Planned
│   │   └── alexa-service/         🚧 Planned
│   ├── frontend/
│   │   └── smart-city-dashboard/  ✅ Complete
│   └── shared/
│       └── common-libraries/      ✅ Complete
├── k8s/                    # Kubernetes manifests ✅
├── ci-cd/                  # CI/CD pipelines ✅
└── docs/                   # Documentation ✅
```

## 🚀 Quick Start

### Prerequisites
- .NET 8 SDK
- Node.js 18+
- Docker
- Kubernetes (Minikube for local)

### Local Development

1. **Clone & Build**
   ```bash
   git clone https://github.com/alessandrorsseixas/smart-city-org.git
   cd smart-city-org
   dotnet restore && dotnet build
   ```

2. **Run Services**
   ```bash
   # Auth Service
   cd src/services/auth-service/SmartCity.AuthService
   dotnet run  # http://localhost:5001
   
   # House Control Service  
   cd src/services/house-control-service/SmartCity.HouseControlService
   dotnet run  # http://localhost:5002
   ```

3. **Run Dashboard**
   ```bash
   cd src/frontend/smart-city-dashboard
   npm install && npm start  # http://localhost:4200
   ```

### Kubernetes Deployment

```bash
# Deploy infrastructure
kubectl apply -f k8s/infrastructure/

# Deploy services
kubectl apply -f k8s/services/

# Setup API Gateway
kubectl apply -f k8s/ingress/
```

## 🎯 Key Features

### ✅ Implemented
- **Authentication**: Secure JWT-based user management
- **House Control**: Real-time smart device automation
- **Dashboard**: Angular Material UI with responsive design
- **CQRS Architecture**: Scalable command/query separation
- **Containerization**: Docker + Kubernetes deployment
- **CI/CD**: Automated build, test, and deployment pipeline

### 🚧 Planned (Next Iterations)
- **Autonomous Vehicle Control**: Sensor-based navigation
- **Energy Management**: Solar/wind power optimization
- **Multi-channel Notifications**: Email, SMS, push, WhatsApp
- **Voice Integration**: Alexa skill development
- **Mobile Apps**: iOS and Android applications
- **Advanced Analytics**: ML-powered automation

## 🔧 API Endpoints

### Auth Service (`/api/auth`)
- `POST /login` - User authentication
- `POST /register` - User registration
- `GET /profile` - User profile retrieval

### House Control (`/api/house`)
- `GET /{id}/status` - House and device status
- `POST /devices/control` - Smart device control

## 📊 Monitoring & Health

- **Health Checks**: `/health` endpoint on all services
- **API Documentation**: Swagger UI in development mode  
- **Logging**: Structured logging with correlation IDs
- **Metrics**: Performance and business metrics

## 🧪 Testing

```bash
# Run all tests
dotnet test

# Run specific service tests
dotnet test src/services/auth-service/SmartCity.AuthService.Tests/
```

## 🔒 Security

- **JWT Authentication** with configurable expiration
- **Role-based Authorization** for service access
- **Kubernetes Secrets** for sensitive data management
- **Network Security** via service mesh communication

## 📈 Scalability

- **Horizontal Pod Autoscaling** with Kubernetes
- **Redis Caching** for performance optimization
- **Database Connection Pooling** for efficiency
- **Load Balancing** via Kubernetes Services

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 📞 Support

For questions or issues, please open a GitHub issue.

---

**Smart City Automation Project** - *Building the future of urban technology* 🌆
