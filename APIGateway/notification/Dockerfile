FROM python:3.9-slim

WORKDIR /app

COPY common/ /app/common/
COPY notification/ /app/notification/
COPY sse.py /app/

RUN pip install pika flask flask_sse flask-cors redis gunicorn

CMD ["python", "-u", "-m", "notification.notification"]