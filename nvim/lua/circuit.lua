local CircuitBreaker = {}
CircuitBreaker.__index = CircuitBreaker

function CircuitBreaker.new(threshold, reset_timeout)
  return setmetatable({
    threshold = threshold or 3, -- Failures before opening
    reset_timeout = reset_timeout or 10, -- Seconds to stay open
    failures = 0,
    state = "CLOSED",
    last_failure_time = 0,
  }, CircuitBreaker)
end

function CircuitBreaker:call(func, ...)
  local now = os.time()

  if self.state == "OPEN" then
    if now - self.last_failure_time > self.reset_timeout then
      self.state = "HALF-OPEN"
    else
      return nil, "Circuit is OPEN (Fast Fail)"
    end
  end

  local success, result = pcall(func, ...)

  if success then
    self:on_success()
    return result
  else
    self:on_failure()
    return nil, "Request Failed: " .. tostring(result)
  end
end

function CircuitBreaker:on_success()
  self.failures = 0
  self.state = "CLOSED"
end

function CircuitBreaker:on_failure()
  self.failures = self.failures + 1
  self.last_failure_time = os.time()

  if self.failures >= self.threshold then
    self.state = "OPEN"
  end
end

return CircuitBreaker
