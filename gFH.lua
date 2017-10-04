if gFHLoaded then print("[|cFFb50201gFH|r] Already Loaded.") return end
gFHLoaded = true

local gFH = {}
local printOrig = print
local function print(...)
   -- printOrig("[".."|cFFb50201gFH|r".."] "..text)
   local message = "[".."|cFFb50201gFH|r".."] "
   for i = 1, select("#", ...) do
      if i == select("#", ...) then
         message = message..tostring(select(i, ...))
      else
         message = message..tostring(select(i, ...))..", "
      end
   end
   ChatFrame1:AddMessage(message)
end

local function LoadFile(FilePath, LoadMsg)
   if not FileExists(FilePath) then print("File, "..FilePath..", does not exist.") return end
   local lua = ReadFile(FilePath)
   -- local func,err = loadstring(lua,Root .. "\\" .. FilePath)
   local func,err = loadstring(lua)
   if err then
      error(err,0)
   else
      pcall(func)
      if LoadMsg then
         print(LoadMsg)
      end
   end
end

gFH.CO = coroutine.create(function()
   while (not FireHack) do
      coroutine.yield(false)
   end

   gFH.Version = 1.1
   local waitForUpdateCheck = false
   local updateCheckSucceeded = false

   local settingsTable
   local playerFullName = UnitFullName("player")..string.gsub(GetRealmName(), " ", "")
   LoadFile(GetHackDirectory().."\\Scripts\\gFH\\JSONParser.lua")
   local settingsFile = GetHackDirectory().."\\Scripts\\gFH\\settings.json"
   if not FileExists(settingsFile) or not json.decode(ReadFile(settingsFile)) then
      WriteFile(settingsFile, "")
      settingsTable = {}
      settingsTable[playerFullName] = {}
   else
      settingsTable = json.decode(ReadFile(settingsFile))
      if not settingsTable[playerFullName] then settingsTable[playerFullName] = {} end
   end

   local writeSettingsQueued = false
   local function writeSettingsToDisk()
      WriteFile(settingsFile, json.encode(settingsTable, {indent=true}))
      writeSettingsQueued = false
   end

   local function checkUpdate(source)
      if updateCheckSucceeded then return end
      local engineVersion = string.match(source, "=%d*%.*%d+")
      engineVersion = string.gsub(engineVersion, "[%a=]", "")
      engineVersion = tonumber(engineVersion)

      if gFH.Version < engineVersion then print("Update Available. Latest Version: "..engineVersion..", Current Version: "..gFH.Version) end
      waitForUpdateCheck = false
      updateCheckSucceeded = true
   end
   
   local function checkFailed()
      waitForUpdateCheck = false
   end

   while (not updateCheckSucceeded) do
      if not waitForUpdateCheck then SendHTTPRequest("https://raw.githubusercontent.com/g1zstar/gFH/master/Version.txt", nil, checkUpdate, checkFailed) end
      coroutine.yield(false)
   end
   
   local gFHCOFrame = CreateFrame("Frame")
   local gFHCO
   local gFHCOQueue = {}
   local function queueUpCO(func)
      if func then table.insert(gFHCOQueue, func) end
      if gFHCO and type(gFHCO) == "thread" and coroutine.status(gFHCO) == "suspended" then coroutine.resume(gFHCO) elseif type(gFHCOQueue[1]) ~= "nil" then gFHCO = coroutine.create(gFHCOQueue[1]); table.remove(gFHCOQueue, 1) end
   end
   gFHCOFrame:SetScript("OnUpdate", function() if gFHCO and type(gFHCO) == "thread" and coroutine.status(gFHCO) == "suspended" then coroutine.resume(gFHCO) end end)

   local guiFrame = CreateFrame("Frame")
   local Backdrop = {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Background",
      tileSize = 32,
      edgeFile = "Interface\\FriendsFrame\\UI-Toast-Border",
      tile = 1,
      edgeSize = 7,
      insets = {
         top = 2,
         right = 2,
         left = 3,
         bottom = 3,
      },
   }
   guiFrame:SetBackdrop(Backdrop)
   guiFrame:SetSize(210, 348)

   guiFrame:SetFrameStrata("HIGH")
   guiFrame:SetMovable(true)
   local AnchorPoint = settingsTable["UIAnchorPoint"] or "CENTER"
   local X  = settingsTable["UIX"] and tonumber(settingsTable["UIX"]) or -200
   local Y  = settingsTable["UIY"] and tonumber(settingsTable["UIY"]) or 100
   guiFrame:SetPoint(AnchorPoint, X, Y)
   
   guiFrame:SetScript("OnShow", function() settingsTable[playerFullName]["UIVisible"] = "true"; if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   guiFrame:SetScript("OnHide", function() settingsTable[playerFullName]["UIVisible"] = "false"; if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   if not settingsTable[playerFullName]["UIVisible"] or settingsTable[playerFullName]["UIVisible"] == "false" then guiFrame:Hide() end

   local TitleBar = CreateFrame("Frame", nil, guiFrame)
   TitleBar:SetPoint("TOPLEFT", 1, -1)
   TitleBar:SetPoint("TOPRIGHT", -2, -1)
   TitleBar:SetHeight(16)

   Backdrop.bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background"
   Backdrop.edgeSize = 2
   Backdrop.insets.bottom = 1
   TitleBar:SetBackdrop(Backdrop)
   TitleBar:SetBackdropColor(0, 0, 0, 1)

   TitleBar:SetScript("OnMouseUp", function ()

      guiFrame:StopMovingOrSizing()

      local Point, RelativeTo, RelativePoint, X, Y = guiFrame:GetPoint()
      settingsTable["UIAnchorPoint"] = Point
      settingsTable["UIX"] = X
      settingsTable["UIY"] = Y
      if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end
   end
   )
   TitleBar:SetScript("OnMouseDown", function () guiFrame:StartMoving() end)
   
   local TitleBarText = TitleBar:CreateFontString()
   TitleBarText:SetAllPoints(TitleBar)
   TitleBarText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
   TitleBarText:SetText("gFireHack")
   TitleBarText:SetJustifyH("CENTER")

   local CloseButton = CreateFrame("Button", nil, TitleBar, "UIPanelCloseButton")
   CloseButton:SetPoint("TOPRIGHT", 1, 1)
   CloseButton:SetHeight(18)
   CloseButton:SetWidth(18)
   CloseButton:SetScript("OnClick", function () guiFrame:Hide() end)

   local AddedCount = 0
   local function AddOption (Name, OnChange)
      local CheckBox = CreateFrame("CheckButton", nil, guiFrame, "ChatConfigSmallCheckButtonTemplate")  
      CheckBox:SetPoint("TOPLEFT", AddedCount % 2 == 0 and 8 or 100, -21 - math.floor(AddedCount / 2) * 25)
      CheckBox:SetScript("PostClick", OnChange)

      local Label = guiFrame:CreateFontString(nil, "HIGH", "GameFontNormal")
      Label:SetAllPoints()
      Label:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
      Label:SetJustifyH("LEFT")
      Label:SetText(Name)
      Label:SetPoint("TOPLEFT", AddedCount % 2 == 0 and 30 or 122, 287 - math.floor(AddedCount / 2) * 50)

      AddedCount = AddedCount + 1
      return CheckBox
   end

   local function AddSectionDivider (Name)
      local Label = guiFrame:CreateFontString(nil, "HIGH")
      Label:SetAllPoints()
      Label:SetFont("Fonts\\ARIALN.TTF", 11, "OUTLINE")
      Label:SetJustifyH("CENTER")
      Label:SetText(Name)
      Label:SetPoint("TOPLEFT", 0, 287 - math.ceil(AddedCount / 2) * 50)
      Label:SetPoint("TOPRIGHT", 0, 287 - math.ceil(AddedCount / 2) * 50)

      AddedCount = AddedCount + (AddedCount % 2 == 0 and 2 or 3)
      return Label
   end

   local function toggleGUI(msg)
      msg = string.lower(msg)

      if msg == "show" and not guiFrame:IsVisible() then
         guiFrame:Show()
      elseif msg == "hide" and guiFrame:IsVisible() then
         guiFrame:Hide()
      elseif msg == "" then
         if guiFrame:IsVisible() then guiFrame:Hide() else guiFrame:Show() end
      end
   end
   SLASH_TOGGLEGFHGUI1 = "/gfh"
   SlashCmdList["TOGGLEGFHGUI"] = toggleGUI

   if not settingsTable["checkBoxSave"] then settingsTable["checkBoxSave"] = {} end
   if not settingsTable[playerFullName]["checkBoxSave"] then settingsTable[playerFullName]["checkBoxSave"] = {} end


   AddSectionDivider("Talent Hack")
   local leftClickTalentHack, middleClickTalentHack, rightClickTalentHack
   local talentHackCheckBoxes = {}

   talentHackCheckBoxes["TALENTLEFTCLICK"]   = AddOption("LeftClick Choose",      function(CheckBox) leftClickTalentHack   = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["TALENTLEFTCLICK"]   = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   talentHackCheckBoxes["TALENTRIGHTCLICK"]  = AddOption("RightClick Clear",      function(CheckBox) rightClickTalentHack  = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["TALENTRIGHTCLICK"]  = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   talentHackCheckBoxes["TALENTMIDDLECLICK"] = AddOption("MiddleClick Clear All", function(CheckBox) middleClickTalentHack = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["TALENTMIDDLECLICK"] = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   
   for i, v in pairs(talentHackCheckBoxes) do
      if settingsTable[playerFullName]["checkBoxSave"][i] then v:Click("LeftButton", true) end
   end
   
   local function setTalent(msg)
      msg = string.lower(msg)
      local r, c = strsplit(" ", msg)
      r = tonumber(r)
      c = tonumber(c)

      if r < 1 or r > 7 or c < 1 or c > 3 then print("Invalid arguments. Correct Usage: /talent tier column Eg. /talent 4 1") return end

      local switch

      if r and c and not select(4, GetTalentInfo(r, c, 1)) then
         for column = 1, 3 do
            if c ~= column and select(4, GetTalentInfo(r, column, 1)) then
               -- RemoveTalent(GetTalentInfo(r, column, 1))
               -- RemoveTalent(GetTalentInfo(r, column, 1))
               switch = true
               queueUpCO(function() while (select(4, GetTalentInfo(r, column, 1))) do RemoveTalent(GetTalentInfo(r, column, 1)); RemoveTalent(GetTalentInfo(r, column, 1)); coroutine.yield(false) end; C_Timer.After(0, function() queueUpCO(function() while (not select(4, GetTalentInfo(r, c, 1))) do LearnTalent(GetTalentInfo(r, c, 1)); coroutine.yield(false) end; C_Timer.After(.350, function() UIErrorsFrame:Clear() end) return true end) end) return true end)
               break
            end
         end
         if not switch then queueUpCO(function() while (not select(4, GetTalentInfo(r, c, 1))) do LearnTalent(GetTalentInfo(r, c, 1)); coroutine.yield(false) end; C_Timer.After(.350, function() UIErrorsFrame:Clear() end) return true end) end
      end
   end

   SLASH_GFHSETTALENT1 = "/talent"
   SlashCmdList["GFHSETTALENT"] = setTalent

   local function setTalents(msg)
      msg = string.lower(msg)
      local talents = { strsplit(" ", msg) }

      local timeSince = debugprofilestop()
      for r = 1, 7 do
         local switch
         talents[r] = tonumber(talents[r])
         if talents[r] and talents[r] >= 1 and talents[r] <= 3 and not select(4, GetTalentInfo(r, talents[r], 1)) then
            for c = 1,3 do
               if select(4, GetTalentInfo(r, c, 1)) then
                  -- RemoveTalent(GetTalentInfo(r, c, 1))
                  -- RemoveTalent(GetTalentInfo(r, c, 1))
                  switch = true
                  queueUpCO(function() while (select(4, GetTalentInfo(r, c, 1))) do RemoveTalent(GetTalentInfo(r, c, 1)); RemoveTalent(GetTalentInfo(r, c, 1)); coroutine.yield(false) end; C_Timer.After(0, function() queueUpCO(function() while (not select(4, GetTalentInfo(r, talents[r], 1))) do LearnTalent(GetTalentInfo(r, talents[r], 1)); coroutine.yield(false) end; C_Timer.After(.350, function() UIErrorsFrame:Clear() end) return true end) end) return true end)
                  break
               end
            end
            if not switch then queueUpCO(function() while (not select(4, GetTalentInfo(r, talents[r], 1))) do LearnTalent(GetTalentInfo(r, talents[r], 1)); coroutine.yield(false) end; C_Timer.After(.350, function() UIErrorsFrame:Clear() end) return true end) end
         end
      end
   end
   SLASH_GFHSETTALENTS1 = "/talents"
   SlashCmdList["GFHSETTALENTS"] = setTalents

   local function clearAllTalents()
      print("Clearing All Talents.")
      for r = 1, 7 do
         for c = 1, 3 do
            while (select(4, GetTalentInfo(r, c, 1))) do
               RemoveTalent(GetTalentInfo(r, c, 1))
               coroutine.yield(false)
            end
         end
      end      
      print("Done Clearing All Talents.")
      return true
   end

   local function talentReplace(self, button, down)
      if button == "LeftButton" and not down and leftClickTalentHack then
         -- Find the Talent we clicked
         local rF, cF
         rF = self.tier
         cF = self.column

         -- Step Out if not found or if it's already learned
         if select(4, GetTalentInfo(rF, cF, 1)) then return end

         -- Remove Other Talent on Row that is learned
         local switch
         for c = 1, 3 do
            if cF ~= c and select(4, GetTalentInfo(rF, c, 1)) then
               -- RemoveTalent(GetTalentInfo(rF, c, 1))
               -- RemoveTalent(GetTalentInfo(rF, c, 1))
               switch = true
               queueUpCO(function() while (select(4, GetTalentInfo(rF, c, 1))) do RemoveTalent(GetTalentInfo(rF, c, 1)); RemoveTalent(GetTalentInfo(rF, c, 1)); coroutine.yield(false) end; C_Timer.After(0, function() queueUpCO(function() while (not select(4, GetTalentInfo(rF, cF, 1))) do LearnTalent(GetTalentInfo(rF, cF, 1)); coroutine.yield(false) end; C_Timer.After(.350, function() UIErrorsFrame:Clear() end) return true end); UIErrorsFrame:Clear() end) return true end)
               break
            end
         end

         -- Learn Desired Talent
         if not switch then queueUpCO(function() while (not select(4, GetTalentInfo(rF, cF, 1))) do LearnTalent(GetTalentInfo(rF, cF, 1)); coroutine.yield(false) end; C_Timer.After(.350, function() UIErrorsFrame:Clear() end) return true end) end
      elseif button == "RightButton" and not down and rightClickTalentHack then
         -- Get rid of the talent we clicked
         RemoveTalent(self:GetID())
         C_Timer.After(0.3, function() RemoveTalent(self:GetID()) end)
      elseif button == "MiddleButton" and not down and middleClickTalentHack then
         queueUpCO(clearAllTalents)
      end
   end

   local function setTalentRemove(boolean)
      local hide, frame
      if not PlayerTalentFrame then ToggleTalentFrame(); hide = true end

      for r = 1, 7 do
         for c = 1, 3 do
            if boolean then
               _G["PlayerTalentFrameTalentsTalentRow"..r.."Talent"..c]:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp", "MiddleButtonDown", "MiddleButtonUp")
               _G["PlayerTalentFrameTalentsTalentRow"..r.."Talent"..c]:SetScript("PostClick", talentReplace)
            else
               _G["PlayerTalentFrameTalentsTalentRow"..r.."Talent"..c]:SetScript("PostClick", nil)
            end
         end
      end

      if hide then HideUIPanel(PlayerTalentFrame) end
   end
   setTalentRemove(true)

   
   AddSectionDivider("Render Hack")
   local playerRender, pPetsRender, ePlayersRender, ePetsRender, fPlayersRender, fPetsRender, eMobsRender, fMobsRender
   local RenderingCheckboxes = {}

   RenderingCheckboxes["RENDERPLAYER"]   = AddOption("Player",                 function(CheckBox) playerRender   = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDERPLAYER"]   = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDERPPETS"]    = AddOption("Player's Pets",          function(CheckBox) pPetsRender    = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDERPPETS"]    = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDEREPLAYERS"] = AddOption("Enemy Players",          function(CheckBox) ePlayersRender = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDEREPLAYERS"] = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDEREPETS"]    = AddOption("Enemy Players' Pets",    function(CheckBox) ePetsRender    = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDEREPETS"]    = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDERFPLAYERS"] = AddOption("Friendly Players",       function(CheckBox) fPlayersRender = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDERFPLAYERS"] = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDERFPETS"]    = AddOption("Friendly Players' Pets", function(CheckBox) fPetsRender    = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDERFPETS"]    = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDERHMOBS"]    = AddOption("Enemy Mobs",             function(CheckBox) eMobsRender    = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDERHMOBS"]    = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)
   RenderingCheckboxes["RENDERFMOBS"]    = AddOption("Friendly Mobs",          function(CheckBox) fMobsRender    = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["RENDERFMOBS"]    = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)

   for i, v in pairs(RenderingCheckboxes) do
      if settingsTable[playerFullName]["checkBoxSave"][i] == nil or settingsTable[playerFullName]["checkBoxSave"][i] then v:Click("LeftButton", true) end
      -- if settingsTable[playerFullName]["checkBoxSave"][i] then v:Click("LeftButton", true) end
   end 


   AddSectionDivider("Automation")
   local tFelExplosives
   local AutomationCheckboxes = {}
   
   AutomationCheckboxes["TFELEXPLOSIVES"] = AddOption("Target Fel Explosives", function(CheckBox) tFelExplosives = CheckBox:GetChecked(); settingsTable[playerFullName]["checkBoxSave"]["TFELEXPLOSIVES"] = CheckBox:GetChecked(); if not writeSettingsQueued then queueUpCO(writeSettingsToDisk); writeSettingsQueued = true end end)

   for i, v in pairs(AutomationCheckboxes) do
      if settingsTable[playerFullName]["checkBoxSave"][i] then v:Click("LeftButton", true) end
   end

   local omFrame = CreateFrame("Frame")
   local omCO
   local function omParse()
      if UnitExists("target") and UnitIsDead("target") and ObjectID("target") == 120651 then ClearTarget() end
      local unit
      for i = 1, GetObjectCount() do
         unit = GetObjectWithIndex(i)
         if ObjectIsType(unit, ObjectType.Unit) then
            if UnitCanAttack("player", unit) then                                                                                -- Hostile
               if ObjectIsType(unit, ObjectType.Player) then                                             -- Hostile Players
                  if ePlayersRender and UnitDisplayID(unit) == 32542 then
                     UnitMountDisplayID(unit, UnitMountDisplayID(unit))
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not ePlayersRender then
                     UnitMountDisplayID(unit, 1)
                     if UnitDisplayID(unit) ~= 32542 then
                        UnitSetDisplayID(unit, 32542)
                        UnitUpdateModel(unit)
                     end
                  end
               elseif UnitCreator(unit) and ObjectIsType(UnitCreator(unit), ObjectType.Player) then      -- Hostile Pets
                  if ePetsRender and UnitDisplayID(unit) == 32542 then
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not ePetsRender and UnitDisplayID(unit) ~= 32542 then
                     UnitSetDisplayID(unit, 32542)
                     UnitUpdateModel(unit)
                  end
               else                                                                                      -- Hostile Mobs
                  if ObjectID(unit) == 120651 and tFelExplosives and not UnitIsDead(unit) then
                     if (not UnitExists("target") or ObjectID("target") ~= 120651 or UnitIsDead("target")) then TargetUnit(unit) end
                  end
                  if eMobsRender and UnitDisplayID(unit) == 32542 then
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not eMobsRender and UnitDisplayID(unit) ~= 32542 then
                     UnitSetDisplayID(unit, 32542)
                     UnitUpdateModel(unit)
                  end
               end
            else                                                                                                                 -- Friendly
               if UnitIsUnit(unit, "player") then                                                        -- Player
                  if playerRender and UnitDisplayID("player") == 32542 then
                     UnitMountDisplayID("player", UnitMountDisplayID("player"))
                     UnitSetDisplayID("player", UnitNativeDisplayID("player"))
                     UnitUpdateModel("player")
                  elseif not playerRender then
                     UnitMountDisplayID("player", 1)
                     if UnitDisplayID("player") ~= 32542 then
                        UnitSetDisplayID("player", 32542)
                        UnitUpdateModel("player")
                     end
                  end
               elseif UnitCreator(unit) and UnitIsUnit("player", UnitCreator(unit)) then                  -- Player's Pets
                  if pPetsRender and UnitDisplayID(unit) == 32542 then
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not pPetsRender and UnitDisplayID(unit) ~= 32542 then
                     UnitSetDisplayID(unit, 32542)
                     UnitUpdateModel(unit)
                  end
               elseif ObjectIsType(unit, ObjectType.Player) then                                         -- Friendly Players
                  if fPlayersRender and UnitDisplayID(unit) == 32542 then
                     UnitMountDisplayID(unit, UnitMountDisplayID(unit))
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not fPlayersRender then
                     UnitMountDisplayID(unit, 1)
                     if UnitDisplayID(unit) ~= 32542 then
                        UnitSetDisplayID(unit, 32542)
                        UnitUpdateModel(unit)
                     end
                  end
               elseif UnitCreator(unit) and ObjectIsType(UnitCreator(unit), ObjectType.Player) then      -- Friendly Pets
                  if fPetsRender and UnitDisplayID(unit) == 32542 then
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not fPetsRender and UnitDisplayID(unit) ~= 32542 then
                     UnitSetDisplayID(unit, 32542)
                     UnitUpdateModel(unit)
                  end
               else                                                                                      -- Friendly Mobs
                  if fMobsRender and UnitDisplayID(unit) == 32542 then
                     UnitSetDisplayID(unit, UnitNativeDisplayID(unit))
                     UnitUpdateModel(unit)
                  elseif not fMobsRender and UnitDisplayID(unit) ~= 32542 then
                     UnitSetDisplayID(unit, 32542)
                     UnitUpdateModel(unit)
                  end
               end
            end
         end
         if i % 50 == 0 then coroutine.yield(false) end
      end
   end
   omCO = coroutine.create(omParse)
   omFrame:SetScript("OnUpdate", function() if omCO and type(omCO) == "thread" then if coroutine.status(omCO) == "suspended" then coroutine.resume(omCO) elseif coroutine.status(omCO) == "dead" then omCO = coroutine.create(omParse) end end end)


   print("Version "..gFH.Version.." loaded.")
   gFH.loaded = true
   return true
   end)

local frame = CreateFrame("Frame")
local function loadGFH(self, elapsed)
   if not gFH.loaded then coroutine.resume(gFH.CO) else frame:SetScript("OnUpdate", nil) end
end
frame:SetScript("OnUpdate", loadGFH)