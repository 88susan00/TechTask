# TechTask

Проект для розгортання моніторингової інфраструктури на базі Kubernetes з використанням GitOps підходу через ArgoCD.

## Огляд

Проект автоматизує розгортання локального Kubernetes кластера на базі Minikube з наступними компонентами:
- ArgoCD для GitOps управління додатками
- VictoriaMetrics для збору та зберігання метрик
- Grafana для візуалізації метрик
- Spam2000 як тестовий додаток-генератор метрик

## Архітектура

```
┌────────────────────────────────────────────────────────┐
│                    Minikube Cluster                    │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │           argocd namespace                       │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  ArgoCD Server                             │  │  │
│  │  │  - Git синхронізація                       │  │  │
│  │  │  - Автоматичне розгортання                 │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │         monitoring namespace                     │  │
│  │  ┌──────────────────┐  ┌──────────────────┐      │  │
│  │  │ VictoriaMetrics  │  │     Grafana      │      │  │
│  │  │ - Збір метрик    │  │ - Візуалізація   │      │  │
│  │  │ - Зберігання     │  │ - Дашборди       │      │  │
│  │  └──────────────────┘  └──────────────────┘      │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │          spam2000 namespace                      │  │
│  │  ┌────────────────────────────────────────────┐  │  │
│  │  │  Spam2000 Deployment                       │  │  │
│  │  │  - Генератор метрик                        │  │  │
│  │  │  - Prometheus endpoint /metrics            │  │  │
│  │  └────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
└────────────────────────────────────────────────────────┘
```

## Залежності

### Системні вимоги

- Операційна система: macOS, Linux або Windows з WSL2
- Мінімальні ресурси:
    - CPU: 4 ядра
    - RAM: 4 GB
    - Диск: 20 GB вільного місця

### Необхідне програмне забезпечення

1. **Minikube** версії 1.30.0 або новіша
    - Встановлення: https://minikube.sigs.k8s.io/docs/start/

2. **kubectl** версії 1.28.0 або новіша
    - Встановлення: https://kubernetes.io/docs/tasks/tools/

3. **Docker** або інший підтримуваний драйвер для Minikube
    - Для macOS: Docker Desktop
    - Для Linux: Docker Engine
    - Встановлення: https://docs.docker.com/get-docker/

4. **Helm** версії 3.12.0 або новіша (опціонально, для локального тестування)
    - Встановлення: https://helm.sh/docs/intro/install/

5. **Bash** версії 4.0 або новіша

### Перевірка залежностей

Виконайте наступні команди для перевірки наявності необхідних інструментів:

```bash
minikube version
kubectl version --client
docker --version
helm version
bash --version
```

## Структура проекту

```
TechTask/
├── apps/
│   ├── monitoring/
│   │   ├── Chart.yaml                    # Helm chart метадані
│   │   ├── values.yaml                    # Конфігурація VictoriaMetrics та Grafana
│   │   ├── Chart.lock                     # Зафіксовані версії залежностей
│   │   ├── charts/                        # Локальні копії Helm charts
│   │   ├── dashboards/                    # JSON дашборди для Grafana
│   │   │   ├── cluster.json
│   │   │   └── spam2000.json
│   │   └── templates/                     # Helm шаблони
│   │       ├── dashboards-configmap.yaml
│   │       └── datasources-configmap.yaml
│   └── spam2000/
│       ├── Chart.yaml                     # Helm chart метадані
│       ├── values.yaml                    # Конфігурація додатку
│       └── templates/
│           ├── deployment.yaml
│           └── service.yaml
├── argocd/
│   ├── monitoring.yaml                    # ArgoCD Application для monitoring
│   └── spam2000.yaml                      # ArgoCD Application для spam2000
└── bootstrap/
    ├── main.sh                            # Головний скрипт розгортання
    ├── install.sh                          # Встановлення Minikube та ArgoCD
    ├── wait-for-argocd.sh                  # Очікування готовності ArgoCD
    ├── get-argocd-password.sh              # Отримання пароля ArgoCD
    └── apply-apps.sh                       # Застосування ArgoCD Applications
```
Додатково до діаграми було додано Інгрес-файли
## Компоненти системи

### ArgoCD

ArgoCD є GitOps контролером, який автоматично синхронізує стан кластера з конфігурацією в Git репозиторії. Налаштований з автоматичним синхронізацією, самовідновленням та автоматичним видаленням ресурсів.

**Конфігурація:**
- Namespace: `argocd`
- Автоматичний sync: увімкнено
- Self-heal: увімкнено
- Prune: увімкнено
- Джерело: GitHub репозиторій `88susan00/TechRepo`, гілка `master`

### VictoriaMetrics

VictoriaMetrics виконує функції збору, зберігання та надання метрик у форматі сумісному з Prometheus.

**Конфігурація:**
- Helm chart: `victoria-metrics-single` версії 0.11.0
- Service type: ClusterIP
- Scrape interval: 10 секунд
- Kubernetes Service Discovery: увімкнено для автоматичного виявлення сервісів з анотаціями Prometheus

**Scrape jobs:**
- `vmagent` - внутрішні метрики VictoriaMetrics
- `kubernetes-apiservers` - метрики Kubernetes API сервера
- `kubernetes-nodes` - метрики вузлів кластера
- `kubernetes-nodes-cadvisor` - контейнерні метрики через cAdvisor
- `kubernetes-service-endpoints` - метрики сервісів з анотацією `prometheus.io/scrape: "true"`
- `kubernetes-service-endpoints-slow` - метрики з інтервалом 5 хвилин
- `kubernetes-services` - blackbox проби сервісів
- `kubernetes-pods` - метрики подів з анотаціями
- `spam2000` - спеціальний job для namespace spam2000
- `monitoring` - спеціальний job для namespace monitoring

### Grafana

Grafana надає веб-інтерфейс для візуалізації метрик з VictoriaMetrics.

**Конфігурація:**
- Helm chart: `grafana` версії 7.3.0
- Service type: ClusterIP
- Admin credentials: `admin` / `admin`
- Sidecar для автоматичного імпорту дашбордів та datasources

**Дашборди:**
- `cluster.json` - метрики кластера та вузлів
- `spam2000.json` - метрики додатку spam2000

**Datasource:**
- VictoriaMetrics за адресою: `http://monitoring-victoria-metrics-single-server.monitoring.svc.cluster.local:8428`

### Spam2000

Spam2000 є тестовим додатком, який генерує метрики у форматі Prometheus.

**Конфігурація:**
- Image: `andriiuni/spam2000:1.1394.355`
- Replicas: 1
- Service type: ClusterIP
- Port: 3000
- Metrics endpoint: `/metrics`
- Prometheus annotations: налаштовані для автоматичного виявлення VictoriaMetrics

## Встановлення та запуск

### Автоматичне розгортання

Виконайте головний скрипт bootstrap для автоматичного розгортання всієї інфраструктури:

```bash
cd bootstrap
bash main.sh
```

Скрипт виконує наступні кроки:
1. Запускає Minikube кластер
2. Встановлює ArgoCD в namespace `argocd`
3. Очікує готовності ArgoCD сервера
4. Виводить пароль для доступу до ArgoCD
5. Застосовує ArgoCD Application ресурси для автоматичного розгортання додатків

### Ручне розгортання

Якщо потрібно виконати кроки окремо:

#### Крок 1: Запуск Minikube та встановлення ArgoCD

```bash
bash bootstrap/install.sh
```

#### Крок 2: Очікування готовності ArgoCD

```bash
bash bootstrap/wait-for-argocd.sh
```

#### Крок 3: Отримання пароля ArgoCD

```bash
bash bootstrap/get-argocd-password.sh
```

#### Крок 4: Застосування ArgoCD Applications

```bash
bash bootstrap/apply-apps.sh
```

### Підтримка Apple Silicon

Скрипт `install.sh` автоматично визначає архітектуру системи та налаштовує Minikube з підтримкою емуляції amd64 для Apple Silicon (arm64).

## Перевірка розгортання

### Перевірка стану кластера

Перевірте стан вузлів кластера:

```bash
kubectl get nodes
```

Очікуваний результат: один вузол у стані `Ready`.

### Перевірка ArgoCD

Перевірте стан подів ArgoCD:

```bash
kubectl get pods -n argocd
```

Всі поді повинні бути в стані `Running`.

Перевірте ArgoCD Applications:

```bash
kubectl get applications -n argocd
```

Очікуваний результат: два Application ресурси (`monitoring` та `spam2000`) зі статусом `Synced` та `Healthy`.

### Перевірка Monitoring Stack

Перевірте поді в namespace monitoring:

```bash
kubectl get pods -n monitoring
```

Очікуваний результат:
- Поди VictoriaMetrics у стані `Running`
- Поди Grafana у стані `Running`

Перевірте сервіси:

```bash
kubectl get svc -n monitoring
```

### Перевірка Spam2000

Перевірте под spam2000:

```bash
kubectl get pods -n spam2000
```

Перевірте сервіс:

```bash
kubectl get svc -n spam2000
```

Перевірте наявність метрик:

```bash
kubectl port-forward -n spam2000 svc/spam2000 3000:3000
curl http://localhost:3000/metrics
```

### Доступ до веб-інтерфейсів

#### ArgoCD UI

Налаштуйте port-forward:

```bash
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

Відкрийте в браузері: `https://localhost:8080`

Облікові дані:
- Username: `admin`
- Password: отримайте через `bash bootstrap/get-argocd-password.sh`

#### Grafana UI

Налаштуйте port-forward:

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
```

Відкрийте в браузері: `http://localhost:3000`

Облікові дані:
- Username: `admin`
- Password: `admin`

#### VictoriaMetrics UI

Налаштуйте port-forward:

```bash
kubectl port-forward -n monitoring svc/monitoring-victoria-metrics-single-server 8428:8428
```

Відкрийте в браузері: `http://localhost:8428`

### Перевірка збору метрик

Перевірте наявність метрик spam2000 у VictoriaMetrics:

```bash
kubectl port-forward -n monitoring svc/monitoring-victoria-metrics-single-server 8428:8428
curl "http://localhost:8428/api/v1/query?query=up{job=\"spam2000\"}"
```

Очікуваний результат: метрика зі значенням `1` для активного endpoint.

## Видалення

Для повного видалення інфраструктури:

```bash
minikube delete
```

Або для видалення окремих компонентів:

```bash
kubectl delete application -n argocd --all
kubectl delete namespace monitoring spam2000
```

## Troubleshooting

### Проблеми з Minikube

Якщо Minikube не запускається, перевірте:

```bash
minikube status
minikube logs
```

### Проблеми з ArgoCD синхронізацією

Перевірте логи ArgoCD:

```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

Перевірте стан Application:

```bash
kubectl describe application -n argocd monitoring
kubectl describe application -n argocd spam2000
```

### Проблеми зі збором метрик

Перевірте конфігурацію scrape у VictoriaMetrics:

```bash
kubectl get configmap -n monitoring monitoring-victoria-metrics-single-server-scrape -o yaml
```

Перевірте анотації сервісу spam2000:

```bash
kubectl get svc -n spam2000 spam2000 -o yaml
```

Перевірте логи VictoriaMetrics:

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=victoria-metrics-single-server
```

## Додаткова інформація

### Налаштування scrape інтервалів

Інтервали збору метрик налаштовуються в файлі `apps/monitoring/values.yaml` в секції `victoria-metrics-single.server.scrape.config.global.scrape_interval`.

### Додавання нових дашбордів

Додайте JSON файли дашбордів у директорію `apps/monitoring/dashboards/`. Вони будуть автоматично імпортовані через ConfigMap та Grafana sidecar.

### Модифікація конфігурації

Всі зміни конфігурації виконуються через Git. Після commit та push до репозиторію, ArgoCD автоматично синхронізує зміни в кластер.
