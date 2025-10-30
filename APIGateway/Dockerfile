FROM python:3.9-slim

WORKDIR /app

COPY * .

RUN pip install Flask flask_sse APScheduler flask-cors redis gunicorn

EXPOSE 5000

CMD ["gunicorn", "-b", "0.0.0.0:5000", "sse:app"]
