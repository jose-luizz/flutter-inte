require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('Defina JWT_SECRET no arquivo .env');
  process.exit(1);
}

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'integra',
  waitForConnections: true,
  connectionLimit: 10,
});

const app = express();
app.use(cors());
app.use(express.json());

// ---------- Helpers ----------

function gerarToken(usuario) {
  return jwt.sign({ id: usuario.id, usuario: usuario.usuario }, JWT_SECRET, {
    expiresIn: '7d',
  });
}

// Middleware: exige "Authorization: Bearer <token>"
function autenticar(req, res, next) {
  const [tipo, token] = (req.headers.authorization || '').split(' ');
  if (tipo !== 'Bearer' || !token) {
    return res.status(401).json({ erro: 'Faça login para continuar.' });
  }
  try {
    req.usuario = jwt.verify(token, JWT_SECRET);
    next();
  } catch (e) {
    return res
      .status(401)
      .json({ erro: 'Sessão expirada. Faça login novamente.' });
  }
}

// Escapa % e _ para o LIKE buscar o texto literal
function escaparLike(texto) {
  return texto.replace(/[\\%_]/g, '\\$&');
}

const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

// ---------- Rotas ----------

app.get('/', (req, res) => {
  res.json({ ok: true, nome: 'Integra+ API' });
});

// Cadastro
app.post('/cadastro', async (req, res) => {
  try {
    const usuario = String(req.body.usuario || '').trim();
    const email = String(req.body.email || '').trim().toLowerCase();
    const rm = String(req.body.rm || '').trim();
    const senha = String(req.body.senha || '');

    if (usuario.length < 3 || usuario.length > 50) {
      return res
        .status(400)
        .json({ erro: 'O nome de usuário deve ter de 3 a 50 caracteres.' });
    }
    if (!EMAIL_REGEX.test(email) || email.length > 150) {
      return res.status(400).json({ erro: 'Informe um email válido.' });
    }
    if (!/^\d{3,20}$/.test(rm)) {
      return res
        .status(400)
        .json({ erro: 'O RM deve conter apenas números.' });
    }
    if (senha.length < 6 || senha.length > 72) {
      return res
        .status(400)
        .json({ erro: 'A senha deve ter de 6 a 72 caracteres.' });
    }

    const senhaHash = await bcrypt.hash(senha, 10);
    const [r] = await pool.execute(
      'INSERT INTO usuarios (usuario, email, rm, senha_hash) VALUES (?, ?, ?, ?)',
      [usuario, email, rm, senhaHash]
    );

    const user = { id: r.insertId, usuario, email, rm };
    res.status(201).json({ token: gerarToken(user), usuario: user });
  } catch (e) {
    if (e.code === 'ER_DUP_ENTRY') {
      const campo = (/for key '(?:\w+\.)?(\w+)'/.exec(e.sqlMessage) || [])[1];
      const msgs = {
        email: 'Este email já está cadastrado.',
        rm: 'Este RM já está cadastrado.',
        usuario: 'Este nome de usuário já está em uso.',
      };
      return res
        .status(409)
        .json({ erro: msgs[campo] || 'Usuário já cadastrado.' });
    }
    console.error(e);
    res.status(500).json({ erro: 'Erro ao cadastrar. Tente novamente.' });
  }
});

// Login: email + RM + senha (os três são obrigatórios)
app.post('/login', async (req, res) => {
  try {
    const email = String(req.body.email || '').trim().toLowerCase();
    const rm = String(req.body.rm || '').trim();
    const senha = String(req.body.senha || '');

    if (!email || !rm || !senha) {
      return res
        .status(400)
        .json({ erro: 'Informe email, RM e senha.' });
    }

    const [rows] = await pool.execute(
      `SELECT id, usuario, email, rm, senha_hash FROM usuarios
       WHERE email = ? AND rm = ? LIMIT 1`,
      [email, rm]
    );

    const u = rows[0];
    const ok = u ? await bcrypt.compare(senha, u.senha_hash) : false;
    if (!ok) {
      return res
        .status(401)
        .json({ erro: 'Email, RM ou senha incorretos.' });
    }

    const user = { id: u.id, usuario: u.usuario, email: u.email, rm: u.rm };
    res.json({ token: gerarToken(user), usuario: user });
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao entrar. Tente novamente.' });
  }
});

// Dados do usuário logado
app.get('/me', autenticar, async (req, res) => {
  try {
    const [rows] = await pool.execute(
      'SELECT id, usuario, email, rm FROM usuarios WHERE id = ?',
      [req.usuario.id]
    );
    if (!rows[0]) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }
    res.json(rows[0]);
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao buscar o usuário.' });
  }
});

// Feed: últimas 50 publicações. Com ?q=termo, busca no texto e no autor.
app.get('/posts', autenticar, async (req, res) => {
  try {
    const q = String(req.query.q || '').trim().slice(0, 100);

    let where = '';
    const params = [];
    if (q) {
      // escapa os curingas do LIKE (% e _) para buscar o texto literal
      const like = `%${escaparLike(q)}%`;
      where = 'WHERE p.texto LIKE ? OR u.usuario LIKE ?';
      params.push(like, like);
    }

    const [rows] = await pool.execute(
      `SELECT p.id, p.texto, p.criado_em AS criadoEm, u.usuario AS autor
       FROM posts p
       JOIN usuarios u ON u.id = p.usuario_id
       ${where}
       ORDER BY p.criado_em DESC, p.id DESC
       LIMIT 50`,
      params
    );
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao carregar as publicações.' });
  }
});

// Nova publicação
app.post('/posts', autenticar, async (req, res) => {
  try {
    const texto = String(req.body.texto || '').trim();
    if (!texto) {
      return res.status(400).json({ erro: 'Escreva algo para publicar.' });
    }
    if (texto.length > 1000) {
      return res
        .status(400)
        .json({ erro: 'A publicação pode ter no máximo 1000 caracteres.' });
    }

    const [r] = await pool.execute(
      'INSERT INTO posts (usuario_id, texto) VALUES (?, ?)',
      [req.usuario.id, texto]
    );

    res.status(201).json({
      id: r.insertId,
      autor: req.usuario.usuario,
      texto,
      criadoEm: new Date().toISOString(),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao publicar. Tente novamente.' });
  }
});

// ---------- Chat (mensagens diretas entre usuários) ----------

function idValido(valor) {
  const n = Number(valor);
  return Number.isInteger(n) && n > 0 ? n : null;
}

// Usuários para iniciar uma conversa (nunca expõe email nem RM)
app.get('/usuarios', autenticar, async (req, res) => {
  try {
    const q = String(req.query.q || '').trim().slice(0, 100);
    const params = [req.usuario.id];
    let where = "WHERE id <> ? AND senha_hash <> '!'";
    if (q) {
      where += ' AND usuario LIKE ?';
      params.push(`%${escaparLike(q)}%`);
    }
    const [rows] = await pool.execute(
      `SELECT id, usuario FROM usuarios ${where} ORDER BY usuario LIMIT 50`,
      params
    );
    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao buscar usuários.' });
  }
});

// Lista de conversas: a última mensagem trocada com cada pessoa
app.get('/conversas', autenticar, async (req, res) => {
  try {
    const me = req.usuario.id;
    const [rows] = await pool.execute(
      `SELECT u.id AS usuarioId, u.usuario, m.texto AS ultimaMensagem,
              m.criado_em AS criadoEm, (m.remetente_id = ?) AS minha
       FROM mensagens m
       JOIN (
         SELECT MAX(id) AS id FROM mensagens
         WHERE remetente_id = ? OR destinatario_id = ?
         GROUP BY LEAST(remetente_id, destinatario_id),
                  GREATEST(remetente_id, destinatario_id)
       ) ult ON ult.id = m.id
       JOIN usuarios u
         ON u.id = IF(m.remetente_id = ?, m.destinatario_id, m.remetente_id)
       ORDER BY m.id DESC`,
      [me, me, me, me]
    );
    res.json(rows.map((r) => ({ ...r, minha: Boolean(r.minha) })));
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao carregar as conversas.' });
  }
});

// Mensagens com uma pessoa. Com ?depois=<id>, só as mais novas que esse id.
app.get('/mensagens/:usuarioId', autenticar, async (req, res) => {
  try {
    const outro = idValido(req.params.usuarioId);
    if (!outro) return res.status(400).json({ erro: 'Usuário inválido.' });

    const me = req.usuario.id;
    const depois = idValido(req.query.depois);
    let rows;

    if (depois) {
      [rows] = await pool.execute(
        `SELECT id, remetente_id AS remetenteId, texto, criado_em AS criadoEm
         FROM mensagens
         WHERE ((remetente_id = ? AND destinatario_id = ?)
             OR (remetente_id = ? AND destinatario_id = ?))
           AND id > ?
         ORDER BY id ASC
         LIMIT 200`,
        [me, outro, outro, me, depois]
      );
    } else {
      [rows] = await pool.execute(
        `SELECT * FROM (
           SELECT id, remetente_id AS remetenteId, texto, criado_em AS criadoEm
           FROM mensagens
           WHERE (remetente_id = ? AND destinatario_id = ?)
              OR (remetente_id = ? AND destinatario_id = ?)
           ORDER BY id DESC
           LIMIT 100
         ) t
         ORDER BY id ASC`,
        [me, outro, outro, me]
      );
    }

    res.json(rows);
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao carregar as mensagens.' });
  }
});

// Enviar mensagem
app.post('/mensagens', autenticar, async (req, res) => {
  try {
    const me = req.usuario.id;
    const destinatarioId = idValido(req.body.destinatarioId);
    const texto = String(req.body.texto || '').trim();

    if (!destinatarioId) {
      return res.status(400).json({ erro: 'Destinatário inválido.' });
    }
    if (destinatarioId === me) {
      return res
        .status(400)
        .json({ erro: 'Você não pode enviar mensagem para si mesmo.' });
    }
    if (!texto) {
      return res.status(400).json({ erro: 'Escreva uma mensagem.' });
    }
    if (texto.length > 1000) {
      return res
        .status(400)
        .json({ erro: 'A mensagem pode ter no máximo 1000 caracteres.' });
    }

    const [dest] = await pool.execute('SELECT id FROM usuarios WHERE id = ?', [
      destinatarioId,
    ]);
    if (!dest[0]) {
      return res.status(404).json({ erro: 'Usuário não encontrado.' });
    }

    const [r] = await pool.execute(
      'INSERT INTO mensagens (remetente_id, destinatario_id, texto) VALUES (?, ?, ?)',
      [me, destinatarioId, texto]
    );

    res.status(201).json({
      id: r.insertId,
      remetenteId: me,
      texto,
      criadoEm: new Date().toISOString(),
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ erro: 'Erro ao enviar a mensagem.' });
  }
});

app.use((req, res) => {
  res.status(404).json({ erro: 'Rota não encontrada.' });
});

const PORT = Number(process.env.PORT || 3000);
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Integra+ API rodando em http://localhost:${PORT}`);
});