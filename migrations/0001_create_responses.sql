CREATE TABLE IF NOT EXISTS responses (
  row_id TEXT PRIMARY KEY,
  date TEXT NOT NULL,
  name TEXT NOT NULL,
  sex TEXT NOT NULL,
  age INTEGER NOT NULL,
  comment TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO responses (row_id, date, name, sex, age, comment) VALUES
('5086d970-bea3-11e9-ad23-91bad5638bcb', '14-08-2019', 'Niels', 'M', 31, 'Hello World!'),
('443cdd8c-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Theo', 'M', 26, 'Great!'),
('45511d6e-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Doris', 'F', 47, 'No comment'),
('4642e0ea-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Mark', 'M', 16, 'Thank You!'),
('47888130-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Bruno', 'M', 64, ''),
('47888131-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', '@(-.-)@', 'M', 26, ':-)'),
('4889d520-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Niels', 'F', 57, ''),
('4889d521-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Doris', 'F', 36, 'Nice!'),
('499d1aee-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Hugo', 'M', 59, ''),
('4ac24aa2-c014-11e9-bbe6-e73bd2ce8807', '14-08-2019', 'Sally', 'M', 53, 'Sucks!');
