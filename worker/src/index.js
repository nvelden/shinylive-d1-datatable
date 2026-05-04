const seedRows = [
  ["5086d970-bea3-11e9-ad23-91bad5638bcb", "14-08-2019", "Niels", "M", 31, "Hello World!"],
  ["443cdd8c-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Theo", "M", 26, "Great!"],
  ["45511d6e-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Doris", "F", 47, "No comment"],
  ["4642e0ea-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Mark", "M", 16, "Thank You!"],
  ["47888130-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Bruno", "M", 64, ""],
  ["47888131-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "@(-.-)@", "M", 26, ":-)"],
  ["4889d520-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Niels", "F", 57, ""],
  ["4889d521-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Doris", "F", 36, "Nice!"],
  ["499d1aee-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Hugo", "M", 59, ""],
  ["4ac24aa2-c014-11e9-bbe6-e73bd2ce8807", "14-08-2019", "Sally", "M", 53, "Sucks!"]
];

export default {
  async fetch(request, env) {
    const cors = corsHeadersFor(env);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }

    if (env.SHARED_SECRET) {
      const presented = request.headers.get("x-api-key") || "";
      if (!safeEquals(presented, env.SHARED_SECRET)) {
        return withCors(jsonResponse({ error: "Unauthorized." }, 401), cors);
      }
    }

    const response = await handle(request, env);
    return withCors(response, cors);
  }
};

function corsHeadersFor(env) {
  return {
    "access-control-allow-origin": env.ALLOWED_ORIGIN || "*",
    "access-control-allow-methods": "GET, POST, PUT, DELETE, OPTIONS",
    "access-control-allow-headers": "Content-Type, X-API-Key",
    "access-control-max-age": "86400",
    "vary": "origin"
  };
}

function withCors(response, cors) {
  const headers = new Headers(response.headers);
  for (const [key, value] of Object.entries(cors)) {
    headers.set(key, value);
  }
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers
  });
}

function safeEquals(a, b) {
  if (a.length !== b.length) return false;
  let result = 0;
  for (let i = 0; i < a.length; i++) {
    result |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return result === 0;
}

async function handle(request, env) {
  if (!env.SQL_TABLE_DB) {
    return errorResponse("Missing SQL_TABLE_DB D1 binding.", 500);
  }

  await ensureSchema(env.SQL_TABLE_DB);

  try {
    if (request.method === "GET") {
      return listRows(env.SQL_TABLE_DB);
    }

    const body = await readJson(request);

    if (request.method === "POST" && body.action === "create") {
      return createRow(env.SQL_TABLE_DB, body.row);
    }

    if (request.method === "POST" && body.action === "copy") {
      return copyRows(env.SQL_TABLE_DB, body.row_ids);
    }

    if (request.method === "PUT") {
      return updateRow(env.SQL_TABLE_DB, body.row);
    }

    if (request.method === "DELETE") {
      return deleteRows(env.SQL_TABLE_DB, body.row_ids);
    }

    return errorResponse("Unsupported request.", 405);
  } catch (error) {
    return errorResponse(error.message || "Unexpected error.", 400);
  }
}

async function ensureSchema(db) {
  await db.prepare(`
    CREATE TABLE IF NOT EXISTS responses (
      row_id TEXT PRIMARY KEY,
      date TEXT NOT NULL,
      name TEXT NOT NULL,
      sex TEXT NOT NULL,
      age INTEGER NOT NULL,
      comment TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `).run();

  const count = await db.prepare("SELECT COUNT(*) AS count FROM responses").first();

  if (count.count === 0) {
    for (const row of seedRows) {
      await db.prepare(`
        INSERT INTO responses (row_id, date, name, sex, age, comment)
        VALUES (?, ?, ?, ?, ?, ?)
      `).bind(...row).run();
    }
  }
}

async function listRows(db) {
  const { results } = await db.prepare(`
    SELECT row_id, date, name, sex, age, comment
    FROM responses
    ORDER BY created_at, row_id
  `).all();

  return jsonResponse({ rows: results || [] });
}

async function createRow(db, input) {
  const row = normaliseRow(input);
  row.row_id = crypto.randomUUID();

  await db.prepare(`
    INSERT INTO responses (row_id, date, name, sex, age, comment)
    VALUES (?, ?, ?, ?, ?, ?)
  `).bind(row.row_id, row.date, row.name, row.sex, row.age, row.comment).run();

  return jsonResponse({ ok: true, row_id: row.row_id }, 201);
}

async function updateRow(db, input) {
  const row = normaliseRow(input, true);

  await db.prepare(`
    UPDATE responses
    SET date = ?, name = ?, sex = ?, age = ?, comment = ?, updated_at = CURRENT_TIMESTAMP
    WHERE row_id = ?
  `).bind(row.date, row.name, row.sex, row.age, row.comment, row.row_id).run();

  return jsonResponse({ ok: true });
}

async function deleteRows(db, rowIds) {
  const ids = normaliseIds(rowIds);

  for (const rowId of ids) {
    await db.prepare("DELETE FROM responses WHERE row_id = ?").bind(rowId).run();
  }

  return jsonResponse({ ok: true, deleted: ids.length });
}

async function copyRows(db, rowIds) {
  const ids = normaliseIds(rowIds);
  let copied = 0;

  for (const rowId of ids) {
    const row = await db.prepare(`
      SELECT date, name, sex, age, comment
      FROM responses
      WHERE row_id = ?
    `).bind(rowId).first();

    if (!row) {
      continue;
    }

    await db.prepare(`
      INSERT INTO responses (row_id, date, name, sex, age, comment)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(crypto.randomUUID(), row.date, row.name, row.sex, row.age, row.comment).run();

    copied += 1;
  }

  return jsonResponse({ ok: true, copied });
}

function normaliseRow(input, requireId = false) {
  if (!input || typeof input !== "object") {
    throw new Error("Missing row data.");
  }

  const row = {
    row_id: stringValue(input.row_id),
    date: stringValue(input.date) || formatDate(new Date()),
    name: stringValue(input.name),
    sex: stringValue(input.sex),
    age: Number.parseInt(input.age, 10),
    comment: stringValue(input.comment)
  };

  if (requireId && !row.row_id) {
    throw new Error("Missing row_id.");
  }

  if (!row.name || !row.sex) {
    throw new Error("Name and sex are required.");
  }

  if (!Number.isFinite(row.age)) {
    row.age = 0;
  }

  return row;
}

function normaliseIds(rowIds) {
  const ids = Array.isArray(rowIds) ? rowIds : [rowIds];
  const clean = ids.map(stringValue).filter(Boolean);

  if (clean.length === 0) {
    throw new Error("No rows selected.");
  }

  return clean;
}

async function readJson(request) {
  try {
    return await request.json();
  } catch {
    return {};
  }
}

function stringValue(value) {
  if (value === undefined || value === null) {
    return "";
  }

  return String(value).trim();
}

function formatDate(date) {
  const day = String(date.getUTCDate()).padStart(2, "0");
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const year = date.getUTCFullYear();

  return `${day}-${month}-${year}`;
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store"
    }
  });
}

function errorResponse(message, status = 400) {
  return jsonResponse({ error: message }, status);
}
