// Gera uma cópia consistente do banco do OmniRoute, mesmo com o servidor rodando.
// Uso: node snapshot-sqlite.mjs <origem.sqlite> <destino.sqlite>
import { DatabaseSync } from "node:sqlite";

const [origem, destino] = process.argv.slice(2);
if (!origem || !destino) {
  console.error("Uso: node snapshot-sqlite.mjs <origem> <destino>");
  process.exit(2);
}

const db = new DatabaseSync(origem);
try {
  // VACUUM INTO grava uma cópia íntegra (inclui o que ainda está no arquivo -wal).
  db.prepare("VACUUM INTO ?").run(destino);
} finally {
  db.close();
}
