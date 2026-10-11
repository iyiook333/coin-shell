# Coin Shell

Coin Shell is an investment learning project with three modules:

- `backend`: Spring Boot backend
- `harmonyos`: HarmonyOS ArkTS client
- `ai-server`: Python AI service

## Run locally

### Backend

```bash
cd backend
mvn spring-boot:run
```

Set `MYSQL_PASSWORD` for the database.

### HarmonyOS client

Open `harmonyos/` with DevEco Studio.

### AI server

```bash
cd ai-server
pip install -r requirements.txt
copy .env.example .env
python coin-shell-ai-server.py
```
