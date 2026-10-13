
FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY req.txt .
RUN pip install --no-cache-dir -r req.txt

COPY kapp.py .

EXPOSE 5000

CMD ["python", "kapp.py"]
