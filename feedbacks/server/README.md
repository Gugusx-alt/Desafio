# API Feedbacks

API REST em Node.js para o sistema de feedbacks.

## Configuração

1. Instale as dependências:
```bash
npm install
```

2. Copie o arquivo `.env.example` para `.env` e configure suas credenciais:
```bash
cp .env.example .env
```

3. Edite o arquivo `.env` com suas credenciais do MariaDB:
```
DB_HOST=localhost
DB_PORT=3306
DB_USER=seu_usuario
DB_PASSWORD=sua_senha
DB_NAME=feedbacks
JWT_SECRET=seu_jwt_secret_aqui
```

## Executar

```bash
npm start
```

Para desenvolvimento com auto-reload:
```bash
npm run dev
```

## Endpoints

### POST /api/auth/register
Cadastro de usuário

**Body:**
```json
{
  "name": "Nome do usuário",
  "email": "email@exemplo.com",
  "password": "senha123",
  "role": "cliente" // opcional: admin, cliente, desenvolvedor (padrão: cliente)
}
```

### POST /api/auth/login
Login de usuário

**Body:**
```json
{
  "email": "email@exemplo.com",
  "password": "senha123"
}
```

**Response:**
```json
{
  "message": "Login realizado com sucesso",
  "token": "jwt_token_aqui",
  "user": {
    "id": 1,
    "name": "Nome do usuário",
    "email": "email@exemplo.com",
    "role": "cliente"
  }
}
```
