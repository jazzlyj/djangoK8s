# Django

## Create project
```
django-admin startproject djangok8s

cd djangok8s
```

## Create docker image

```
vim Dockerfile
Dockerfile:

FROM ubuntu:22.04
RUN apt-get update && apt-get install -y \
    libpq-dev \
    nginx \
    python3.11 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*
RUN pip install django gunicorn psycopg2
ADD . /app
WORKDIR /app
EXPOSE 8000
CMD ["gunicorn", "--bind", ":8000", "--workers", "3", "djangok8s.wsgi"]
```

* exposes that port 8000 will be used to accept incoming container connections, and runs gunicorn with 3 workers and listening on port 8000.

## Build image:
```
docker build -t djangok8s .
```

```
docker images
```

## Creating the Database Schema
With the container built and configured, use docker run to override the CMD set in the Dockerfile and create the database schema using the manage.py makemigrations and manage.py migrate commands

```
docker run -i -t djangok8s sh
```
* Provides a shell prompt inside of the running container

create database and migrations
```
# at the "#" cmd prompt run:
python3 manage.py makemigrations && python3 manage.py migrate
```

```
python3 manage.py createsuperuser
```
 after creating the superuser, hit CTRL+D to quit the container and kill it.

## Test run docker container
```
docker run -p 80:8000 djangok8s
```

*should see :
```
Output
[2022-04-18 06:40:37 +0000] [1] [INFO] Starting gunicorn 20.1.0
[2022-04-18 06:40:37 +0000] [1] [INFO] Listening at: http://0.0.0.0:8000 (1)
[2022-04-18 06:40:37 +0000] [1] [INFO] Using worker: sync
[2022-04-18 06:40:37 +0000] [9] [INFO] Booting worker with pid: 9
[2022-04-18 06:40:37 +0000] [10] [INFO] Booting worker with pid: 10
[2022-04-18 06:40:37 +0000] [11] [INFO] Booting worker with pid: 11
```

Navigate to http://localhost to see the djangoapp:
Hit CTRL+C in the terminal window running the Docker container to kill the container.

# Minikube
K8s cluster on a single host

## Install and deploy
https://minikube.sigs.k8s.io/docs/start/

### Install
```powershell
choco install minikube
```

### Start
```powershell
minikube start
```

## Deploy Docker Registry

### Enable Add On
```powershell
minikube addons enable registry
```
https://minikube.sigs.k8s.io/docs/drivers/docker

* confirm
```powershell
kubectl get service --namespace kube-system
```

###
```powershell
kubectl port-forward --namespace kube-system service/registry 5000:80
```

### Run docker registry
```powershell
docker run --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:host.docker.internal:5000"
```

## Docker Tag
```bash
docker tag host.domain.com localhost:5000/ host.domain.com
docker tag djangok8s localhost:5000/djangok8s
```

## Docker Push Image to Registry
```bash
docker push localhost:5000/host.domain.com
docker push localhost:5000/djangok8s
```

### Test to see if registry is running
```bash
curl --location http://localhost:5000/v2
curl http://localhost:5000/v2/_catalog
```

* After the image is pushed, refer to it by localhost:5000/{name} in kubectl specs
With image available to Kubernetes on local Docker registry

# Deploy Django
```
vim django-deployment.yaml
# Paste in the following Deployment manifest:

apiVersion: apps/v1
kind: Deployment
metadata:
  name: django-app
  labels:
    app: django
spec:
  replicas: 3
  selector:
    matchLabels:
      app: django
  template:
    metadata:
      labels:
        app: django
    spec:
      containers:
        - image: localhost:5000/djangok8s
          name: django
          ports:
            - containerPort: 8000
              name: gunicorn

```

* Deploy
```
kubectl apply -f deployment.yaml
```

* Verify
```
kubectl get deploy django-app

# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# django-app   3/3     3            3           12s
```

* use the selector: app and the get the pods associated with that value
```bash
kubectl get pods -l app=django
```


### K8s Services
* Deploy the service "service.yaml"
```bash
kubectl apply -f service.yaml
```

* use the selector: "app" and the get all things associated with that value
```bash
kubectl get all -l app=django
```

* setup port forwarding 
```bash
kubectl port-forward service/django 8000:8000
```




### K8s Ingress
A reverse proxy that enables external access into other Kubernetes resources.

* Install ingress controller
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/do/deploy.yaml
```

* Confirm the pods have started:
```
kubectl get pods -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --watch
```

* Confirm that the Load Balancer was successfully created
```
kubectl get svc --namespace=ingress-nginx
```

* Unless deploying to DNS use /etc/hosts
```bash
vim /etc/hosts
# add an entry for our domain name
127.0.0.1 host.domain.com

```

* Deploy ingress
```bash
kubectl apply -f ingress.yaml
```

https://github.com/kubernetes/ingress-nginx









# Once built - Run these on subsequent starts

```
# port forwarding for docker registry to work 
kubectl port-forward --namespace kube-system service/registry 5000:80
# port forwarding for django deployment/service/ http://localhost:8000/ to work 
kubectl port-forward service/django 8000:8000
# to start the minikube dashboard in browser
minikube dashboard
```

command history
```
kubectl get service --namespace kube-system
curl http://localhost:5000/v2/_catalog
kubectl get deploy django-app
kubectl get pods -l app=django
kubectl get all -l app=django

```

















## K8s clean up
```bash
kubectl delete all --all
```

# Helm
Package manager for K8s. Packages all manifests "the app" needs into a single item called a chart

## Consists of 3 key parts: 
a) Metadata 

b) Values 

c) Templates

### Metadata
Chart.yaml

* Validate the chart is good
```bash
helm show all ./chart
```

### Values

### Templates

### Install Helm
```powershell
choco install kubernetes-helm
```

## Helm Upgrade
Instead of using install and uninstall use upgrade.

It versions all of your installs on top of each other. 
It knows when stuff has changed, to install the changes. If you've modified things, to modify in place

```bash
helm upgrade --atomic --install $HELM_CHART_NAME $CHART_LOCATION

#Eg
helm upgrade --atomic --install host-website ./chart
```
--atomic
* Deploy all resources as a single unit and if it doesnt work it rolls it back.
