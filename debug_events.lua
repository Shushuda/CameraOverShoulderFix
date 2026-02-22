-- Standalone event debugger for druid form transitions
-- /run CosFixDebug:Enable() to start
-- /run CosFixDebug:Disable() to stop

CosFixDebug = CosFixDebug or {}
CosFixDebug.startTime = nil
CosFixDebug.enabled = false

local events = {
  "UPDATE_SHAPESHIFT_FORM",
  "UNIT_MODEL_CHANGED",
  "UNIT_AURA",
  "SPELL_UPDATE_COOLDOWN",
  "UNIT_SPELLCAST_SUCCEEDED",
  "UNIT_SPELLCAST_SENT",
}

function CosFixDebug:GetModelId()
  if not self.modelFrame then
    self.modelFrame = CreateFrame("PlayerModel")
  end
  self.modelFrame:SetUnit("player")
  return self.modelFrame:GetModelFileID()
end

function CosFixDebug:Log(event, ...)
  if not self.enabled then return end

  local now = GetTime()
  if not self.startTime then self.startTime = now end
  local elapsed = now - self.startTime

  local formId = GetShapeshiftFormID(true)
  local modelId = self:GetModelId()

  local extra = ""
  if event == "UNIT_MODEL_CHANGED" or event == "UNIT_AURA" or event == "UNIT_SPELLCAST_SUCCEEDED" or event == "UNIT_SPELLCAST_SENT" then
    local unit = ...
    if unit ~= "player" then return end -- Only care about player
    extra = " unit=" .. tostring(unit)
  end

  print(string.format("[%.3f] %s | formId=%s | model=%s%s",
    elapsed,
    event,
    tostring(formId),
    tostring(modelId),
    extra
  ))
end

function CosFixDebug:Enable()
  if not self.frame then
    self.frame = CreateFrame("Frame")
  end
  self.enabled = true
  self.startTime = GetTime()
  for _, event in ipairs(events) do
    self.frame:RegisterEvent(event)
  end
  self.frame:SetScript("OnEvent", function(_, event, ...)
    self:Log(event, ...)
  end)
  print("CosFixDebug ENABLED - tracking shapeshift events")
end

function CosFixDebug:Disable()
  self.enabled = false
  if self.frame then
    for _, event in ipairs(events) do
      self.frame:UnregisterEvent(event)
    end
    self.frame:SetScript("OnEvent", nil)
  end
  print("CosFixDebug DISABLED")
end

-- Also add an OnUpdate to sample model ID every frame during transitions
CosFixDebug.sampleMode = false
CosFixDebug.sampleStart = nil

function CosFixDebug:StartSampling()
  if not self.frame then
    self.frame = CreateFrame("Frame")
  end
  self.sampleMode = true
  self.sampleStart = GetTime()
  self.lastModel = nil
  self.frame:SetScript("OnUpdate", function(_, elapsed)
    if not self.sampleMode then return end
    if GetTime() - self.sampleStart > 1 then
      self:StopSampling()
      return
    end
    local model = self:GetModelId()
    if model ~= self.lastModel then
      print(string.format("[%.3f] MODEL CHANGED: %s -> %s",
        GetTime() - self.startTime,
        tostring(self.lastModel),
        tostring(model)
      ))
      self.lastModel = model
    end
  end)
  print("Sampling model changes for 1 second...")
end

function CosFixDebug:StopSampling()
  self.sampleMode = false
  if self.frame then
    self.frame:SetScript("OnUpdate", nil)
  end
  print("Sampling stopped")
end
