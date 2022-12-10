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


# FROM ubuntu:22.04
# RUN apt-get update && apt-get install -y tzdata && apt install -y python3.11 python3-pip
# RUN apt install python3-dev libpq-dev nginx -y
# RUN pip install django gunicorn psycopg2
# ADD . /app
# WORKDIR /app
# EXPOSE 8000
# CMD ["gunicorn", "--bind", ":8000", "--workers", "3", "djangok8s.wsgi"]
