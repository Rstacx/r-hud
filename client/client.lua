-- Config Stuff
if Config.QBCore then
  QBCore = exports["qb-core"]:GetCoreObject()
end
if Config.ESX then
  ESX = exports['es_extended']:getSharedObject()
end
if Config.MenuOptions.ID then
  Wait(2000)
  UIMessage("id", true)
end
if Config.Seatbelt then
  Wait(2000)
  UIMessage("seatbelt", true)
end
if Config.MenuOptions.Stress then
  Wait(2000)
  UIMessage("stress", true)
end
if Config.DisplayUserInfo then
  Wait(2000)
  UIMessage("displayBalance", true)
end

local function toggleNuiFrame(shouldShow)
  -- SetNuiFocus(shouldShow, shouldShow)
  UIMessage('setVisible', shouldShow)
  UIMessage("setUserId", GetPlayerServerId(PlayerId()))
  if Config.QBCore or Config.ESX or Config.vRP then
    UIMessage('framework', true)
  end
end

local function toggleVehHudFrame(shouldShow)
  -- SetNuiFocus(shouldShow, shouldShow)
  UIMessage('setVehV', shouldShow)
end

ShowSeatbelt = false
Seatbelt = false
Loaded = false


RegisterNetEvent('hud:client:ToggleShowSeatbelt', function()
  ShowSeatbelt = not ShowSeatbelt
end)

RegisterNetEvent('seatbelt:client:ToggleSeatbelt', function() -- Triggered in smallresources
  Seatbelt = not Seatbelt
end)

RegisterNetEvent("UIMessage", function(action, data)
  UIMessage(action, data)
end)

local function loadHud()
  toggleNuiFrame(true)
  CreateThread(function()
    local oldHealth = nil
    local oldArmour = nil
    local oldState = nil
    while Loaded do
      local ped = PlayerPedId()
      local hp = GetEntityHealth(ped)
      local armour = GetPedArmour(ped)
      local talking = NetworkIsPlayerTalking(PlayerId())
      local playerStatsChanged = false

      if hp ~= oldHealth or armour ~= oldArmour or talking ~= oldState then
        playerStatsChanged = true
      end

      if playerStatsChanged then
        local playerStats = {
          hp = hp,
          armour = armour,
          micActive = talking,
        }
        UIMessage("hudStats", playerStats)
        oldHealth = hp
        oldArmour = armour
        oldState = talking
      end
      Wait(1000)
    end
  end)
end

local function escapeMenuLoop()
  CreateThread(function()
    while Loaded do
      local menuActive = IsPauseMenuActive()
      if menuActive then
        toggleNuiFrame(false)
      else
        toggleNuiFrame(true)
      end
      Wait(1000)
    end
  end)
end


local function loadCarHud()
  CreateThread(function()
    while Loaded do
      local ped = PlayerPedId()
      local isInVeh = IsPedInAnyVehicle(ped, false)
      Wait(1000)
      if isInVeh then
        local vehicle = GetVehiclePedIsIn(ped, false)
        local gear = GetVehicleCurrentGear(vehicle)
        local fuel = math.floor(GetVehicleFuelLevel(vehicle))
        local speedVal = GetEntitySpeed(vehicle) *
            2.236936 --Feel free to edit this if needed to switch to KMH, currently using MPH. it's 3.6 for KMH.
        local speed = math.floor(speedVal)
        -- toggleNuiFrame(true)
        toggleVehHudFrame(true)
        local vehStats = {
          gear = gear,
          fuel = fuel,
          speed = speed,
          seatbeltOn = Seatbelt,
        }
        UIMessage("vehHud", vehStats)
      else
        toggleVehHudFrame(false)
      end
    end
  end)
end


local function loadHudMisc()
  CreateThread(function()
    local oldHunger = nil
    local oldThirst = nil
    local oldStress = nil
    while Loaded do
      local PlayerData = QBCore.Functions.GetPlayerData()
      local hunger = math.floor(PlayerData.metadata['hunger'])
      local thirst = math.floor(PlayerData.metadata['thirst'])
      local stress = math.floor(PlayerData.metadata['stress'])
      local qbData = {
        hunger = hunger,
        thirst = thirst,
        stress = stress
      }
      if oldHunger ~= hunger or oldThirst ~= thirst or oldStress ~= stress then
        UIMessage("frameworkStatus", qbData)
        -- print(qbData.hunger)
        oldHunger = hunger
        oldThirst = thirst
        oldStress = stress
      end
      Wait(1000)
    end
  end)
end

if Config.ESX then
  AddEventHandler('esx_status:onTick', function(data)
    local hunger, thirst
    for i = 1, #data do
      if data[i].name == 'thirst' then thirst = math.floor(data[i].percent) end
      if data[i].name == 'hunger' then hunger = math.floor(data[i].percent) end
    end

    local esxStatus = {
      hunger = hunger,
      thirst = thirst
    }
    UIMessage("frameworkStatus", esxStatus)
  end)
end

---------------- vRP -----------------
if Config.vRP then
  Loaded = true

  CreateThread(function()
    while true do
      TriggerServerEvent("vrp_version:r-hud:GetStatus")
      Wait(1500)
    end
  end)

  RegisterNetEvent("vrp_version:r-hud:GetStatus:return")
  AddEventHandler("vrp_version:r-hud:GetStatus:return", function(stats)
    local vRPStatus = {
      hunger = math.floor(100 - stats.hunger),
      thirst = math.floor(100 - stats.thirst),
    }
    local vRPUserStats = {
      cash = stats.money,
      bank = stats.bank
    }
    UIMessage("frameworkStatus", vRPStatus)
    UIMessage("userInfo", vRPUserStats)
  end)
end

-- User Info
local function loadUserInfo()
  if Config.QBCore and Config.DisplayUserInfo then
    local oldCash = nil
    local oldBank = nil
    local oldJob = nil
    CreateThread(function()
      while Loaded do
        local Player = QBCore.Functions.GetPlayerData()
        local cash = Player.money["cash"]
        local bank = Player.money["bank"]
        local jobName = Player.job.name or 'unemployed'
        local jobLabel = Player.job.grade.name or 'Civilian'
        local job = jobName .. " - " .. jobLabel
        local dataChanged = false

        -- I should just loop through these if i decide to add more stats lmfao.
        if cash ~= oldCash or bank ~= oldBank or job ~= oldJob then
          dataChanged = true
        end

        if dataChanged then
          local data = {
            cash = cash,
            bank = bank,
            job = job,
          }
          oldCash = cash
          oldBank = bank
          oldJob = job
          UIMessage("userInfo", data)
        end
        Wait(1000)
      end
    end)
  elseif Config.ESX and Config.DisplayUserInfo then
    local society_money
    RegisterNetEvent('esx_addonaccount:setMoney')
    AddEventHandler('esx_addonaccount:setMoney', function(society, money)
      if ESX.PlayerData.job and ESX.PlayerData.job.grade_name == 'boss' and 'society_' .. ESX.PlayerData.job.name == society then
        society_money = money
      end
    end)
    CreateThread(function()
      local oldCash = nil
      local oldBank = nil
      local oldDirty = nil
      local oldJob = nil
      while Loaded do
        local data = {}
        local xPlayer = ESX.GetPlayerData()
        data.job = string.format("%s - %s", xPlayer.job.label, xPlayer.job.grade_label)
        -- UIMessage("debug", xPlayer)
        data.society_money = society_money
        for k, v in pairs(xPlayer.accounts) do
          if v.name == "money" then
            data.cash = v.money
            -- print("Debug Stuff: [$"..data.cash.. "] Debug Stuff 2: [$" ..v.money.. "]")
          elseif v.name == "bank" then
            data.bank = v.money
            -- print("Debug Stuff: [$"..data.cash.. "] Debug Stuff 2: [$" ..v.money.. "]")
          elseif v.name == "black_money" then
            data.dirty_cash = v.money
            -- print("Debug Stuff: [$"..data.cash.. "] Debug Stuff 2: [$" ..v.money.. "]")
          elseif v.name == "society_money" then
            data.society_money = v.money
            -- print("Debug Stuff: [$"..data.cash.. "] Debug Stuff 2: [$" ..v.money.. "]")
          end
          Wait(1000)
        end


        local dataChanged = false
        if data.cash ~= oldCash or data.bank ~= oldBank or data.dirty_cash ~= oldDirty or data.job ~= oldJob then
          dataChanged = true
        end

        if dataChanged then
          oldCash = data.cash
          oldBank = data.bank
          oldDirty = data.dirty_cash
          oldJob = data.job
          UIMessage("userInfo", data)
        end
        Wait(1000)
      end
    end)
  end
end

-- QB-Multicharacter Fix.

if Config.QBCore then
  RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    QBCore.Functions.Notify("Loading Hud!", 'success', 1000)
    Wait(2000)
    Loaded = true
    loadHud()
    loadCarHud()
    loadHudMisc()
    if Config.EscapeMenuLoop then
      escapeMenuLoop()
    end
    loadUserInfo()
    QBCore.Functions.Notify("Hud Loaded!", 'success', 1000)
    print("Loaded Hud!")
  end)
else
  print("Loading Hud!")
  Wait(2000)
  Loaded = true
  loadHud()
  loadCarHud()
  loadUserInfo()
  if Config.EscapeMenuLoop then
    escapeMenuLoop()
  end
end

RegisterCommand("reloadHud", function()
  Loaded = true
  loadHud()
  loadCarHud()
  loadHudMisc()
  loadUserInfo()
end, false)
