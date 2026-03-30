.load /nix/store/piw5h87zbmn5prk7wr1d6wh3fz1kna9i-sqlite-vec-0.1.6/lib/vec0.so
.mode table
.header on

select sqlite_version(), vec_version();

CREATE VIRTUAL TABLE vec_items USING vec0(embedding float[8]);

INSERT INTO vec_items(rowid, embedding)
  select
    value ->> 0,
    value ->> 1
  from json_each('[
    [1, [1.1, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1, 1.1]],
    [2, [2.2, 2.2, 2.2, 2.2, 2.2, 2.2, 2.2, 2.2]],
    [3, [3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3]],
    [4, [4.4, 4.4, 4.4, 4.4, 4.4, 4.4, 4.4, 4.4]],
    [5, [5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5, 5.5]],
  ]');

SELECT
  rowid,
  distance
FROM vec_items
WHERE embedding MATCH '[3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3, 3.3]'
ORDER BY distance
LIMIT 3;
