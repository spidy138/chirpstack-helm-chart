# ChirpStack LoRaWAN Helm Charts

A comprehensive Kubernetes deployment for **ChirpStack**, a full-stack LoRaWAN network server, along with supporting infrastructure services (PostgreSQL, Redis, and VerneMQ).

## Overview

This repository contains production-ready Helm charts for deploying ChirpStack v4.10.0 on Kubernetes with:

- **ChirpStack Application Server** - Core LoRaWAN network server
- **Gateway Bridge** - Connects LoRa gateways to ChirpStack
- **Gateway Bridge Basic Station** - Support for basic station protocol
- **REST API** - HTTP API for applications
- **PostgreSQL** - Persistent data store
- **Redis** - In-memory cache layer
- **VerneMQ** - MQTT message broker

All services are configured to work together seamlessly with TLS encryption, persistent storage, and horizontal pod autoscaling capabilities.

---

## Table of Contents

1. [ChirpStack](#chirpstack)
2. [PostgreSQL](#postgresql)
3. [Redis](#redis)
4. [VerneMQ](#vernemq)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [Services & Networking](#services--networking)

---

## ChirpStack

### Description

ChirpStack is an open-source LoRaWAN network server. It provides:

- **Application Server**: Manages connected devices and applications
- **Gateway Bridge**: Translates between LoRa gateways and the application server
- **REST API**: Programmatic access to ChirpStack functionality
- **Web Interface**: Management UI for devices, applications, and gateways

### Version

- **Application Version**: 4.10.0
- **Chart Version**: 0.1.0

### Components

#### 1. **ChirpStack Application Server**

The core component that handles LoRaWAN protocol and device management.

**Key Configuration:**
- **Image**: `chirpstack/chirpstack:4`
- **Port**: 8080 (LoadBalancer)
- **Replicas**: 1 (configurable)
- **Storage Backend**: PostgreSQL + Redis

**Environment Variables:**
```yaml
POSTGRESQL_HOST: postgres.chirpstack
POSTGRESQL_PORT: 5432
POSTGRESQL_USER: chirpstack
POSTGRESQL_PASSWORD: chirpstack
POSTGRESQL_DB: chirpstack
REDIS_HOST: redis.chirpstack
REDIS_PORT: 6379
REDIS_PASSWORD: password
MQTT_BROKER_HOST: vernemq.vernemq
MQTT_BROKER_PORT: 8883
```

**Database Dependencies:**
- PostgreSQL for application data, device information, and configuration
- Redis for caching and session management

#### 2. **Gateway Bridge**

Connects standard LoRa gateways to ChirpStack using the Semtech UDP protocol.

**Key Configuration:**
- **Image**: `chirpstack/chirpstack-gateway-bridge:4`
- **Port**: 1700 (UDP, LoadBalancer) - Standard LoRa gateway port
- **Replicas**: 1 (configurable, supports autoscaling)

**Event Topic Template:**
```
in865/gateway/{{ .GatewayID }}/event/{{ .EventType }}
```

**State Topic Template:**
```
in865/gateway/{{ .GatewayID }}/state/{{ .StateType }}
```

**MQTT Integration:**
- Publishes gateway events to MQTT broker (VerneMQ)
- Subscribes to command topics for downlink messages
- Uses TLS encryption for secure communication

#### 3. **Gateway Bridge Basic Station**

Support for the newer ChirpStack Basic Station protocol for advanced gateways.

**Key Configuration:**
- **Image**: `chirpstack/chirpstack-gateway-bridge:4`
- **Port**: 3001 (ClusterIP)
- **Replicas**: 1 (configurable)
- **Protocol**: Basic Station (proprietary Semtech protocol)

**Use Case:** 
Basic Station is a more modern protocol for gateways, offering better performance and reliability than the UDP protocol. Use this bridge for newer gateway hardware.

#### 4. **REST API**

HTTP/gRPC API for external applications to interact with ChirpStack.

**Key Configuration:**
- **Image**: `chirpstack/chirpstack-rest-api:4`
- **Port**: 8090 (ClusterIP)
- **Replicas**: 1 (configurable)
- **Server**: Connects to ChirpStack application server on port 8080

**Typical Use Cases:**
- Device provisioning and management
- Application configuration
- Data retrieval and analytics
- Integration with external systems

### Autoscaling

All components support Horizontal Pod Autoscaling (HPA):

```yaml
autoscaling:
  enabled: false  # Set to true to enable
  minReplicas: 1
  maxReplicas: 3
  targetCPUUtilizationPercentage: 80
```

Enable autoscaling in `values.yaml` to automatically scale based on CPU usage.

### TLS/Certificate Management

ChirpStack communicates with VerneMQ over TLS. Certificates are managed via:

- **CA Certificate**: Root CA for broker verification
- **Client Certificate**: Signed client certificate for ChirpStack
- **Client Key**: Private key for TLS authentication

Certificates are mounted from Kubernetes secrets at `/etc/ssl/vernemq/`.

### Service Account

The chart creates a service account with minimal permissions for running the containers.

---

## PostgreSQL

### Description

PostgreSQL database stores all persistent data for ChirpStack, including:

- Device information and state
- Application configuration
- User accounts and permissions
- LoRaWAN network keys and session data
- Device activation records (ABP and OTAA)

### Version

- **Database Version**: 14 (Alpine)
- **Chart Version**: 1.0.0

### Configuration

**Default Settings:**
```yaml
replicaCount: 1
namespace: chirpstack
image:
  repository: postgres
  tag: 14-alpine
```

**Service:**
- **Type**: ClusterIP
- **Port**: 5432
- **Service Name**: `postgres.chirpstack`

**Credentials (defaults - change in production):**
```yaml
POSTGRES_USER: chirpstack
POSTGRES_PASSWORD: chirpstack
POSTGRES_DB: chirpstack
```

**Persistence:**
- **Storage Class**: `local-path`
- **Size**: 10Gi (adjust for your needs)
- **Mount Path**: `/var/lib/postgresql/data`
- **Access Mode**: ReadWriteOnce

### Database Initialization

The chart includes init scripts that automatically:
1. Create the ChirpStack database
2. Set up required schema
3. Configure necessary extensions
4. Initialize application tables

All init scripts are stored in `init-configmap.yaml`.

### Monitoring

- **Prometheus Integration**: Enabled via annotations
  ```yaml
  prometheus.io/scrape: "true"
  prometheus.io/port: "9187"
  ```
- Use a PostgreSQL exporter for detailed metrics

### Security

**Pod Security Context:**
```yaml
runAsUser: 999  # Non-root postgres user
fsGroup: 999
```

**Container Security:**
- `allowPrivilegeEscalation: false`
- All capabilities dropped
- Read-only filesystem (except data directory)

---

## Redis

### Description

Redis provides high-performance caching and session storage for ChirpStack:

- Session data caching
- Device state caching
- Real-time metrics and counters
- Queue management for asynchronous tasks

### Version

- **Redis Version**: 7 (Alpine)
- **Chart Version**: 1.0.0

### Configuration

**Default Settings:**
```yaml
replicaCount: 1
namespace: chirpstack
image:
  repository: redis
  tag: 7-alpine
```

**Service:**
- **Type**: ClusterIP
- **Port**: 6379
- **Service Name**: `redis.chirpstack`

**Authentication:**
```yaml
redis:
  password: "password"  # Change in production
```

**Persistence:**
- **Storage Class**: `local-path`
- **Size**: 5Gi
- **Mount Path**: `/data`
- **Access Mode**: ReadWriteOnce

### Performance Tuning

Redis is configured for optimal performance with:
- AOF (Append-Only File) persistence
- Configurable memory limits
- Support for clustering (via values)

### Monitoring

- **Prometheus Integration**: Enabled
  ```yaml
  prometheus.io/scrape: "true"
  prometheus.io/port: "9121"
  ```

### Security

**Pod Security Context:**
```yaml
runAsUser: 999      # Non-root redis user
runAsNonRoot: true
fsGroup: 999
```

**Container Security:**
- `allowPrivilegeEscalation: false`
- All capabilities dropped
- Restricted filesystem access

---

## VerneMQ

### Description

VerneMQ is a high-performance, distributed MQTT message broker. It acts as the central message hub for:

- Gateway-to-server communication
- Device uplink messages
- Server-to-gateway downlink commands
- Event distribution to multiple subscribers

### Version

- **VerneMQ Version**: 2.1.1
- **Chart Type**: Helm v2 compatible

### Key Features

- **High Performance**: Handles thousands of concurrent connections
- **Distributed Architecture**: Supports clustering for scalability
- **MQTT 3.1.1 & 5.0**: Full protocol compliance
- **TLS/SSL**: Secure encrypted communication
- **ACL Support**: Fine-grained access control

### Ports

- **8883**: MQTT over TLS (main protocol port)
- **8888**: HTTP management API
- **9100**: Cluster communication
- **44053**: Cluster communication (alternate)

### TLS Configuration

VerneMQ is configured to require TLS for all MQTT connections:

**Certificates:**
- CA certificate for client validation
- Server certificate and private key
- Client certificates for ChirpStack and Gateway Bridges

**Mount Points:**
- `/etc/ssl/vernemq/ca.crt` - Root CA
- `/etc/ssl/vernemq/cert.crt` - Server certificate  
- `/etc/ssl/vernemq/key.key` - Private key

### ACL (Access Control List)

VerneMQ includes an ACL configuration that controls:
- Which clients can connect
- Topic permissions (publish/subscribe)
- Message size limits

See `templates/configmap-acl.yaml` for detailed rules.

### Clustering

For high availability, VerneMQ supports clustering:
- StatefulSet deployment ensures stable node names
- Headless service for peer discovery
- Pod disruption budget for safe rolling updates

Enable clustering in values:
```yaml
clustering:
  enabled: true
  nodes: 3
```

### Pod Disruption Budget

Protects against involuntary disruptions:
```yaml
minAvailable: 1  # At least one broker always running
```

### Monitoring

Kubernetes integration:
- **ServiceMonitor** for Prometheus scraping
- Health check endpoints for readiness/liveness probes
- Detailed metrics on connections, messages, and performance

---

## Installation

### Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- Persistent storage backend (local-path, NFS, etc.)
- TLS certificates (for VerneMQ)

### Quick Start

```bash
# 1. Add the chart repository (if using a registry)
helm repo add chirpstack https://your-registry.com/charts
helm repo update

# 2. Create namespace
kubectl create namespace chirpstack

# 3. Install all charts in dependency order

# Install PostgreSQL first
helm install postgres ./postgres \
  --namespace chirpstack

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod \
  -l app=postgres -n chirpstack --timeout=300s

# Install Redis
helm install redis ./redis \
  --namespace chirpstack

# Install VerneMQ
helm install vernemq ./vernemq \
  --namespace vernemq

# Finally, install ChirpStack (depends on all others)
helm install chirpstack ./chirpstack \
  --namespace chirpstack
```

### Custom Values

Create a `custom-values.yaml` and override defaults:

```yaml
chirpstack:
  replicaCount: 2
  chirpstack:
    postgresql:
      password: "your-secure-password"
    redis:
      password: "your-secure-password"
  autoscaling:
    enabled: true
    maxReplicas: 5

postgres:
  persistence:
    size: 50Gi

redis:
  persistence:
    size: 20Gi
```

Install with custom values:

```bash
helm install chirpstack ./chirpstack \
  --namespace chirpstack \
  -f custom-values.yaml
```

---

## Configuration

### Common Configuration Changes

#### Enable Autoscaling

```bash
helm upgrade chirpstack ./chirpstack \
  --set chirpstack.autoscaling.enabled=true \
  --set chirpstack.autoscaling.maxReplicas=5
```

#### Change Database Credentials

```bash
kubectl patch secret chirpstack-secret \
  -p '{"data":{"POSTGRESQL_PASSWORD":"...",
            "REDIS_PASSWORD":"..."}}'
```

#### Increase Storage

```bash
helm upgrade postgres ./postgres \
  --set persistence.size=100Gi

helm upgrade redis ./redis \
  --set persistence.size=50Gi
```

#### Update Gateway Bridge Topics

Edit `chirpstack/values.yaml`:

```yaml
gatewaybridge:
  configMapData:
    INTEGRATION__MQTT__EVENT_TOPIC_TEMPLATE: "custom/gateway/{{ .GatewayID }}/event"
    INTEGRATION__MQTT__COMMAND_TOPIC_TEMPLATE: "custom/gateway/{{ .GatewayID }}/command"
```

### Environment-Specific Values

Create separate value files for different environments:

```
values-dev.yaml
values-staging.yaml
values-prod.yaml
```

Deploy to specific environment:

```bash
helm install chirpstack ./chirpstack \
  -f values-prod.yaml
```

---

## Services & Networking

### Service Endpoints

| Component | Service Name | Port | Type | Purpose |
|-----------|--------------|------|------|---------|
| ChirpStack | `chirpstack` | 8080 | LoadBalancer | Application Server |
| Gateway Bridge | `gateway-bridge` | 1700 | LoadBalancer | LoRa Gateway UDP |
| Gateway Bridge BS | `gateway-bridge-basicstation` | 3001 | ClusterIP | Basic Station |
| REST API | `rest-api` | 8090 | ClusterIP | HTTP API |
| PostgreSQL | `postgres.chirpstack` | 5432 | ClusterIP | Database |
| Redis | `redis.chirpstack` | 6379 | ClusterIP | Cache |
| VerneMQ | `vernemq.vernemq` | 8883 | ClusterIP | MQTT Broker |

### Accessing Services

**From within cluster:**
```bash
# Connect to ChirpStack
curl http://chirpstack:8080

# Query REST API
curl http://rest-api:8090/api/...

# Connect to PostgreSQL
psql -h postgres.chirpstack -U chirpstack -d chirpstack

# Connect to Redis
redis-cli -h redis.chirpstack
```

**From outside cluster (for LoadBalancer services):**
```bash
# Get LoadBalancer IP
kubectl get svc -n chirpstack

# Connect to gateway bridge
nc -u <EXTERNAL-IP> 1700
```

### Network Policies

All services are isolated within the `chirpstack` and `vernemq` namespaces. For production, consider adding network policies:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: chirpstack-ingress
  namespace: chirpstack
spec:
  podSelector:
    matchLabels:
      app: chirpstack
  policyTypes:
    - Ingress
  ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            name: chirpstack
      ports:
      - protocol: TCP
        port: 8080
```

---

## Troubleshooting

### Check Pod Status

```bash
# List all pods
kubectl get pods -n chirpstack

# Check logs
kubectl logs -n chirpstack -f deployment/chirpstack

# Describe pod for events
kubectl describe pod -n chirpstack <pod-name>
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl run -it --rm debug --image=postgres:14-alpine \
  --restart=Never -- psql -h postgres.chirpstack \
  -U chirpstack -d chirpstack
```

### Redis Connectivity

```bash
# Test Redis connection
kubectl run -it --rm debug --image=redis:7-alpine \
  --restart=Never -- redis-cli -h redis.chirpstack ping
```

### MQTT Connection Issues

```bash
# Check VerneMQ logs
kubectl logs -n vernemq -f statefulset/vernemq

# Verify TLS certificates
kubectl get secret -n chirpstack chirpstack-certs -o yaml
```

---

## Production Checklist

- [ ] Change all default passwords in `values.yaml`
- [ ] Enable autoscaling for all components
- [ ] Configure persistent volume storage (use cloud provider storage classes)
- [ ] Set resource requests and limits
- [ ] Configure ingress for REST API access
- [ ] Set up monitoring with Prometheus
- [ ] Configure logging (ELK stack or cloud provider)
- [ ] Enable pod disruption budgets for high availability
- [ ] Set up backup strategy for PostgreSQL
- [ ] Review and customize network policies
- [ ] Test failover and recovery procedures
- [ ] Document your customizations

---

## License

These Helm charts are provided as-is for deploying ChirpStack and its dependencies on Kubernetes.

---

## Support

For issues related to:
- **ChirpStack**: https://github.com/chirpstack/chirpstack
- **VerneMQ**: https://vernemq.com
- **PostgreSQL**: https://www.postgresql.org
- **Redis**: https://redis.io

For issues with these Helm charts, please refer to the project documentation or contact your DevOps team.
