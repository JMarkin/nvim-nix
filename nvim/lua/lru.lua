-- A tiny, dependency‑free LRU cache for Lua (Neovim) --------------------
-- Usage:
--   local LRU = require('lru')
--   local cache = LRU.new(100)          -- capacity = 100 items
--   cache:set('foo', 42)
--   local val = cache:get('foo')        -- 42

local LRU = {}
LRU.__index = LRU

-- ----------------------------------------------------------------------
-- Create a new cache with given capacity
-- ----------------------------------------------------------------------
function LRU.new(capacity)
  assert(type(capacity) == "number" and capacity > 0, "LRU.new requires a positive numeric capacity")

  return setmetatable({
    capacity = capacity,
    size = 0,
    head = nil, -- most recently used
    tail = nil, -- least recently used
    hash = {}, -- key -> node
  }, LRU)
end

-- ----------------------------------------------------------------------
-- Internal helper: move a node to the head (MRU position)
-- ----------------------------------------------------------------------
local function move_to_head(cache, node)
  if cache.head == node then
    return
  end -- already MRU

  -- unlink node
  if node.prev then
    node.prev.next = node.next
  end
  if node.next then
    node.next.prev = node.prev
  end

  if cache.tail == node then
    cache.tail = node.prev
  end

  -- insert at head
  node.prev = nil
  node.next = cache.head
  if cache.head then
    cache.head.prev = node
  end
  cache.head = node

  if not cache.tail then
    cache.tail = node
  end
end

-- ----------------------------------------------------------------------
-- Internal helper: evict the least‑recently used item (tail)
-- ----------------------------------------------------------------------
local function evict(cache)
  local tail = cache.tail
  if not tail then
    return
  end

  -- remove from hash
  cache.hash[tail.key] = nil

  -- unlink tail
  if tail.prev then
    tail.prev.next = nil
    cache.tail = tail.prev
  else
    cache.head = nil
    cache.tail = nil
  end

  cache.size = cache.size - 1
end

-- ----------------------------------------------------------------------
-- Get a value from the cache
-- ----------------------------------------------------------------------
function LRU:get(key)
  local node = self.hash[key]
  if not node then
    return nil
  end

  -- Mark as most recently used
  move_to_head(self, node)
  return node.value
end

-- ----------------------------------------------------------------------
-- Set a key/value pair, evicting if capacity exceeded
-- ----------------------------------------------------------------------
function LRU:set(key, value)
  local node = self.hash[key]

  if node then
    -- Update value and move to head
    node.value = value
    move_to_head(self, node)
  else
    -- Insert new node
    node = { key = key, value = value }

    -- Insert at head
    node.next = self.head
    if self.head then
      self.head.prev = node
    end
    self.head = node
    if not self.tail then
      self.tail = node
    end

    self.hash[key] = node
    self.size = self.size + 1

    -- Evict if over capacity
    if self.size > self.capacity then
      evict(self)
    end
  end
end

-- ----------------------------------------------------------------------
-- Optional: clear the cache
-- ----------------------------------------------------------------------
function LRU:clear()
  self.head = nil
  self.tail = nil
  self.hash = {}
  self.size = 0
end

return LRU
