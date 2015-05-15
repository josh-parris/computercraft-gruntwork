-- Can turtles rewrite signs?

idHopper = "minecraft:hopper"
idChest  = "minecraft:chest"
idTrapChest= "minecraft:trapped_chest"
idTorch  = "minecraft:torch"
idStairS = "minecraft:stone_stairs"

idLeaves = "minecraft:leaves"
idWood   = "minecraft:log"
idGrass  = "minecraft:grass"
idGrass2 = "minecraft:tallgrass"

idLava   = "minecraft:lava"
idLavaF  = "minecraft:flowing_lava"
idWater  = "minecraft:water"
idWaterF = "minecraft:flowing_water"
idBucket = "minecraft:bucket"
idBucketL= "minecraft:lava_bucket"
idBucketW= "minecraft:water_bucket"

idCobble = "minecraft:cobblestone"
idGravel = "minecraft:gravel"
idStone  = "minecraft:stone"
idDirt   = "minecraft:dirt"
idSand   = "minecraft:sand"
idNRack  = "minecraft:netherrack"
idBedrock= "minecraft:bedrock"

idDiamond= "minecraft:diamond_ore"
idEmerald= "minecraft:emerald_ore"
idIron   = "minecraft:iron_ore"
idGold   = "minecraft:gold_ore"
idCoal   = "minecraft:coal_ore"
idRedstone="minecraft:redstone_ore"
idLapis  = "minecraft:lapis_ore"
idClay   = "minecraft:clay"
idObsidian="minecraft:obsidian"

-- Burnable stuff
idSapling= "minecraft:sapling"
idStick="minecraft:stick"
idPlank="minecraft:planks"
idPickW="minecraft:wooden_pickaxe"
idAxeW="minecraft:wooden_axe"
idShovelW="minecraft:wooden_shovel"
idHoeW="minecraft:wooden_hoe"
idSwordW="minecraft:wooden_sword"
idStairW1="minecraft:oak_stairs"
idStairW2="minecraft:spruce_stairs"
idStairW3="minecraft:jungle_stairs"
idStairW4="minecraft:spruce_stairs"
idStairW5="minecraft:acacia_stairs"
idStairW6="minecraft:dark_oak_stairs"
idStair="spruce_stairs"
idStair="spruce_stairs"
idSlabW="minecraft:wooden_slab"
idSlabW2="minecraft:double_wooden_slab"
idBlazeRod="minecraft:blaze_rod"
idBookcase="minecraft:bookshelf"
idTrapDoor="minecraft:trapdoor"
idFence="minecraft:fence"
idGate="minecraft:fence_gate"
idMushBlkR="minecraft:red_mushroom_block"
idMushBlkB="minecraft:brown_mushroom_block"
idBanner="minecraft:banner"
idNoteBlk="minecraft:noteblock"
idJukebox="minecraft:jukebox"
idDaylight="minecraft:daylight_detector"
idPPlateW="minecraft:wooden_pressure_plate"
idCoalBlk="minecraft:coal_block"
idCharcoal="minecraft:coal"
idFurnace= "minecraft:furnace"
idFurnace2="minecraft:lit_furnace"

slots=16
blockStack=64
maxFuel=10000
lavaFuel=1000

local somethingThere, data

function NoOp()
end

-- Returns false if the item is not in any slot, 
-- otherwise selects that first slot with it in it and returns true
function Select(name)
  for slot=1,slots,1 do
    local data = turtle.getItemDetail(slot)
    if data and data.name==name then
      return turtle.select(slot)
    end
  end
  return false
end

-- How many slots have nothing in them?
function FreeSlots()
  local result=0
  for slot=1, slots, 1 do
    if turtle.getItemCount(slot) == 0 then
      result = result + 1
    end
  end
  return result
end

-- for each slot where the compare function returns true 
--   when passed the name of the item in the slot, 
--   select that slot and call action function (no params)
--  e.g.: ForEachSlotIf(IsWood, turtle.dropDown) -- dump wood
function ForEachSlotIf(compareFn, actionFn)
  for n=1, slots, 1 do
    local data = turtle.getItemDetail(n)
    if data and compareFn(data.name, data.damage) then
      turtle.select(n)
      actionFn()
    end
  end
end

-- Fuel functions
-- The library offers automatic fuel consumption and prioritization
-- Fuels not in the priority list get the default priority of 10; 
--   list fuels with a small number to deprioritize them
--   do not list fuels, or list with nil priority, to use default priority
--   a negative priority will cause fuels not to be consumed (saplings 
--     for a lumberbot, for example)
-- e.g. priorities={}
--      priorities[idSapling]=-1
--      priorities[idCharcoal]=20
--      priorities[idWood]=5
--      SetFuelPriority(priorities)
local lowFuel = 20
local fuelDefaultPriority = 10
local fuelPriority = {}
local burnTime = {}
burnTime[idSapling] = 5
burnTime[idStick] = 5
burnTime[idSlabW] = 7.5
burnTime[idSlabW2] = 7.5 -- check this
burnTime[idPickW] = 10
burnTime[idAxeW] = 10
burnTime[idHoeW] = 10
burnTime[idSwordW] = 10
burnTime[idShovelW] = 10
burnTime[idWood] = 15
burnTime[idPlank] = 15
burnTime[idChest] = 15
burnTime[idBookcase] = 15
burnTime[idTrapDoor] = 15
burnTime[idPPlateW] = 15
burnTime[idGate] = 15
burnTime[idFence] = 15
burnTime[idMushBlkR] = 15
burnTime[idMushBlkB] = 15
burnTime[idBanner] = 15
burnTime[idNoteBlk] = 15
burnTime[idJukebox] = 15
burnTime[idDaylight] = 15
burnTime[idCharcoal] = 80
burnTime[idCoal] = 80
burnTime[idBlazeRod] = 120
burnTime[idCoalBlk] = 800
burnTime[idBucketL] = 1000

function IsFuel(name)
  return burnTime[name] ~= nil
end

function SetFuelPriority(newFuelPriority)
  fuelPriority = newFuelPriority
end

-- Tell the fuel management functions how far the turtle is required to go 
-- before it should take over refueling itself
function SetRequiredRange(distance)
  error("SetRequiredRange not done yet")
end

function SetLowFuelLevel(newLowFuel)
  if newLowFuel<0 then
    print("Negative fuel level has disabled fuel management")
  end
  lowFuel = newLowFuel
end

function LowOnFuel()
  return turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() <= lowFuel
end

-- Movement causes automatic refueling; 
-- if we're low on fuel then it's because we've burnt everything
function FuelExhausted()
  return turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < lowFuel
end

function Refuel()
  if LowOnFuel() then
    local slot = FuelSlot()
    if slot ~= 0 then
      turtle.select(slot)
-- can this fail?
      turtle.refuel(1)
    else
      print("Alert: low on fuel")
    end
  end
end

function RefuelToLevel(target)
  while turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < target do
    local slot = FuelSlot()
    if slot ~= 0 then
      turtle.select(slot)
      turtle.refuel(1)
    else
      print("Alert: failed to refuel adequately")
      return false
    end
  end
  return true
end

function FuelSlot()
  local bestFuel = 0
  local bestPriority = 0  -- negative values don't get burnt
  for slot = 1, slots, 1 do -- loop through the slots
    local data = turtle.getItemDetail(slot)
    if data and IsFuel(data.name) then
      thisPriority = fuelPriority[data.name]
      if thisPriority == nil then
        -- an unlisted fuel
        thisPriority = fuelDefaultPriority
      end
      if thisPriority > bestPriority then
        bestPriority = thisPriority
        bestFuel = slot
      end
    end
  end
  return bestFuel
end

-- The RefuelWithLavaX functions require a bucket in inventory to succeed
-- I'm still figuring out what kinds of flowing lava will succeed
function RefuelWithLava(inspectFn, placeFn)
  if turtle.getFuelLevel() ~= "unlimited" and turtle.getFuelLevel() < maxFuel - lavaFuel then
    local success, data = inspectFn()
    if success then
      if data.name == idLava or 
        (data.name == idLavaF and data.metadata==0) then
        if Select(idBucket) then
          placeFn()
          -- The bucket could have moved if there were two buckets to begin with
          if Select(idBucketL) then
            turtle.refuel(1)
          end
        end
      end
    end
  end
end

function RefuelWithLavaForward()
  RefuelWithLava(turtle.inspect, turtle.place)
end

function RefuelWithLavaUp()
  RefuelWithLava(turtle.inspectUp, turtle.placeUp)
end

function RefuelWithLavaDown()
  RefuelWithLava(turtle.inspectDown, turtle.placeDown)
end

-- error "handling"
local function Bail(FnName)
  print(FnName, "() failed")
  print("Fuel level:", turtle.getFuelLevel())
  print("height:", CurrentY())
  error()
end

local dirNameForward
local dirNameTurnwise
local distanceTraveled={}
local currentDirection=0
local currentHeight=0
turnClockwise=true

-- Tells the library that this is 0,0,0 
--   and the name of the direction we're facing,
--   and the direction name one Turn() from there
function SetOrigin(facingName, turnToName)
  dirNameForward = facingName
  dirNameTurnwise = turnToName
  for direction = 0,3,1 do
    distanceTraveled[direction] = 0
  end
  currentDirection = 0
  currentHeight = 0
end

function CheckOriginSet()
  if #distanceTraveled == 0 then
    if turnClockwise then
      SetOrigin("Forward", "Right") 
    else
      SetOrigin("Forward", "Left") 
    end
  end
end

-- The Turn functions allow simple mirroring of directions
function TurnLeft()
  CheckOriginSet()
  turtle.turnLeft()
  currentDirection = (currentDirection + 1) % 4
end

function TurnRight()
  CheckOriginSet()
  turtle.turnRight()
  currentDirection = (currentDirection + 3) % 4
end

function Turn()
  CheckOriginSet()
  if turnClockwise then
    TurnRight()
  else
    TurnLeft()
  end
end

function TurnAnti()
  CheckOriginSet()
  if turnClockwise then
    TurnLeft()
  else
    TurnRight()
  end
end

function TurnAround()
  Turn()
  Turn()
end

-- The TurnsTo() functions measure how many turns in which direction are necessary 
-- to face towards the passed X (forwards-backwards) position
-- a negative value means TurnAnti, 
-- 2 means 180 degree turn, 0 already facing towards there
function TurnsToX(posForward)
  if CurrentX() == posForward then
    return 0
  end
  if CurrentX() > posForward then
    if currentDirection == 0 then
      return 0
    else
      if currentDirection == 2 then
        return 2
      else
        return currentDirection - 2
      end
    end
  else
    if currentDirection == 2 then
      return 0
    else
      if currentDirection == 0 then
        return 2
      else
        return -(currentDirection - 2)
      end
    end
  end
end

function TurnsToZ(posSideways)
  if CurrentZ() == posSideways then
    return 0
  end
  if CurrentZ() > posSideways then
    if currentDirection == 1 then
      return 0
    else
      if currentDirection == 3 then
        return 2
      else
        return -(currentDirection - 1)
      end
    end
  else
    if currentDirection == 3 then
      return 0
    else
      if currentDirection == 1 then
        return 2
      else
        return currentDirection - 1
      end
    end
  end
end

function TurnDirection(turns)
  while turns ~= 0 do
    if turns < 0 then
      TurnAnti()
      turns = turns + 1
    else
      Turn()
      turns = turns - 1
    end
  end
end

-- The Current() funtions get the XYZ location of the turtle relative to the origin
function CurrentX()
  CheckOriginSet()
  return distanceTraveled[0] - distanceTraveled[2]
end

function CurrentZ()
  CheckOriginSet()
  return distanceTraveled[1] - distanceTraveled[3]
end

function CurrentY()
  CheckOriginSet()
  return currentHeight
end

-- What is the X position the turtle is facing?
function FacingX()
  if currentDirection % 2 == 0 then
    return CurrentX() - currentDirection + 1
  else
    return CurrentX()
  end
end

-- What is the Z position the turtle is facing?
function FacingZ()
  if currentDirection % 2 == 0 then
    return CurrentX()
  else
    return CurrentX() - currentDirection + 2
  end
end

local limitFwd = 10000
local limitBack = -10000
local limitTurn = 10000
local limitTurnAnti = -10000
local limitUp = 300
local limitDown = -300
-- The dead reckoning location of the turtle can be constrained to prevent runaway bots
-- Successful dead reckoning requires all movement to go through the library
--   - no calling turtle.forward yourself!
-- Backward and TurnAnti are expressed in terms relative to Forward and Turn
--   - so negative for behind, for example. 
function SetMovementBounds(newLimitFwd, newLimitBack, 
    newLimitTurn, newLimitTurnAnti, newLimitUp, newLimitDown)
  limitFwd = newLimitFwd
  limitBack = newLimitBack
  limitTurn = newLimitTurn
  limitTurnAnti = newLimitTurnAnti
  limitUp = newLimitUp
  limitDown = newLimitDown
end

function HaltIfOutOfBounds()
  if CurrentX() > limitFwd or
     CurrentX() < limitBack or
     CurrentY() > limitUp or
     CurrentY() < limitDown or
     CurrentZ() > limitTurn or
     CurrentZ() < limitTurnAnti then
    print("Turtle has been instructed to move Out of Bounds")
    Bail("movement")
  end
end

-- The MoveX functions attempt to move, and give it a few goes, 
--   but if that fails **the program halts**
-- This may be surprising if a mob (like the player) gets in the turtle's way 
--   or a tree suddenly grows.
-- For more insistant movement, try the DigX functions
function MoveX(moveFn, fnName, attackFn)
  CheckOriginSet()
  Refuel()
  for attempt = 1, 5, 1 do -- give this five goes, perhaps the mob will move
    if moveFn() then
      return true -- horary, we moved!
    end
    -- Is it a mob (non-player, if TvP attacks are turned off in config)?    
    if attackFn() then
      -- "Kill them"
      while attackFn() do
      end
    else
      -- make a display in trying to gain attention ("Get out of my way!")
      Turn()
      TurnAnti()
      TurnAnti()
      Turn()
    end
  end
  Bail(fnName)
  return false
end

function MoveForward()
  local result = MoveX(turtle.forward, "MoveForward", turtle.attack)
  distanceTraveled[currentDirection] = distanceTraveled[currentDirection] + 1
  HaltIfOutOfBounds()
  return result
end

function MoveBackward()
  local result = MoveX(turtle.back, "MoveBackward", turtle.attack) -- bad attack function, FIXME
  distanceTraveled[currentDirection] = distanceTraveled[currentDirection] - 1
  HaltIfOutOfBounds()
  return result
end

function MoveUp()
  local result = MoveX(turtle.up, "MoveUp", turtle.attackUp)
  currentHeight = currentHeight + 1
  HaltIfOutOfBounds()
  return result
end

function MoveDown()
  local result = MoveX(turtle.down, "MoveDown", turtle.attackDown)
  currentHeight = currentHeight - 1
  HaltIfOutOfBounds()
  return result
end

local function NeedsDigging(name)
  return 
    name ~= idLava and 
    name ~= idLavaF and
    name ~= idWater and
    name ~= idWaterF and
    name ~= idBedrock and
    string.find(name, "Oil") == nil and
    string.find(name, "gas") == nil
end

-- The DigX functions attempt to move, and dig if that fails. 
-- They give it a couple of goes before returning false
-- This is necessary to deal with a mob (like the player) 
-- getting in the turtle's way or a tree suddenly growing.
function DigX(moveFn, digFn, inspectFn, attackFn)
  CheckOriginSet()
  Refuel()
  for attempt = 1, 3, 1 do -- give this three goes, perhaps the mob will move
    if moveFn() then
      return true -- horary, we moved!
    else
      local somethingThere, data = inspectFn()
      digFn()
      if moveFn() then
        return true -- horary, we moved!
      else
        -- Is it a mob (non-player, if TvP attacks are turned off in config)?    
        while attackFn() do
        end
        repeat
          digFn()
          os.sleep(0.1)
          somethingThere, data = inspectFn()
        until not somethingThere or not NeedsDigging(data.name)
      end
    end
    -- make a display in trying to gain attention ("Get out of my way!")
    Turn()
    TurnAnti()
    TurnAnti()
    Turn()
  end
  return false
end

function DigGravityBlocksThatAreAbove()
  -- chew up that which is going to fall and block our movement
  local somethingThere, data = turtle.inspectUp()
  while something and IsGravityBlock(data.name) do
    turtle.digUp()
    somethingThere, data = turtle.inspectUp()
  end
end

function DigForward()
  result = DigX(turtle.forward, turtle.dig, turtle.inspect, turtle.attack)
  if result then
    distanceTraveled[currentDirection] = distanceTraveled[currentDirection] + 1
    DigGravityBlocksThatAreAbove()
    HaltIfOutOfBounds()
  end
  return result
end

function DigBackward()
  if not turtle.back() then
    TurnAround()
    result = DigForward()
    TurnAround()
  else
    distanceTraveled[currentDirection] = distanceTraveled[currentDirection] - 1
  end
  return result
end

function DigUp()
  result = DigX(turtle.up, turtle.digUp, turtle.inspectUp, turtle.attackUp)
  if result then
    currentHeight = currentHeight + 1
    DigGravityBlocksThatAreAbove()
    HaltIfOutOfBounds()
  end
  return result
end

function DigDown()
  result = DigX(turtle.down, turtle.digDown, turtle.inspectDown, turtle.attackDown)
  if result then
    currentHeight = currentHeight -1
    HaltIfOutOfBounds()
  end
  return result
end

-- The MineX functions succeed in going forward, 
--   dealing with as many gravity blocks (sand, gravel) as necessary.
-- The only thing that could stop them is bedrock, 
--   causing them to return false rather than true.
-- The "success" return value is coupled with the name of the last block mined
-- If lava is come across it is consumed for fuel if the turtle has a bucket to do so.

local justMinedFn = nil
function AfterMiningCall(fnFn)
  justMinedFn = fnFn
end

-- MoveForward, digging as long as necessary
function MineForward()
  local somethingThere, data = turtle.inspect()
  local dug_name = nil
  -- loop because of gravity blocks
  while somethingThere and NeedsDigging(data.name) do
    if not turtle.dig() then
      -- Is it a mob (non-player, if TvP attacks are turned off in config)?    
      while turtle.attack() do
      end      
    end
    dug_name = dug_name or data.name
    somethingThere, data = turtle.inspect()
  end
  if somethingThere then
    if data.name == idBedrock then
      return false, data.name
    end
    RefuelWithLavaForward()
  end
  result = DigForward()
  if result and justMinedFn and dug_name then 
    justMinedFn(dug_name)
  end
  return result, dug_name
end

function MineBackward()
  TurnAround()
  local result = MineForward()
  TurnAround()
  return result
end

function MineUp()
  local somethingThere, data = turtle.inspectUp()
  local dug_name = nil
  -- loop because of gravity blocks
  while somethingThere and NeedsDigging(data.name) do
    if not turtle.digUp() then
      -- Is it a mob (non-player, if TvP attacks are turned off in config)?    
      while turtle.attackUp() do
      end      
    end
    dug_name = data.name
    somethingThere, data = turtle.inspectUp()
  end
  if somethingThere then
    if data.name == idBedrock then
      return false, data.name
    end
    RefuelWithLavaUp()
  end
  result=DigUp()
  if result and justMinedFn and dug_name then 
    justMinedFn(dug_name)
  end
  return result, dug_name
end

function MineDown()
  local somethingThere, data = turtle.inspectDown()
  local dug_name = nil
  if somethingThere and NeedsDigging(data.name) then
    if not turtle.digDown() then
      -- Is it a mob (non-player, if TvP attacks are turned off in config)?    
      while turtle.attackDown() do
      end      
    end
    dug_name = data.name
  else 
    if somethingThere then
      if data.name == idBedrock then
        return false, data.name
      end
      RefuelWithLavaDown()
    end
  end
  result = DigDown()
  if result and justMinedFn and dug_name then 
    justMinedFn(dug_name)
  end
  return result, dug_name
end

-- Without consideration of the path, nor with what is in the way, proceed to 
function MineToXYZ(posForward, posVert, posSideways)
  local result
  if TurnsToX(posForward) == 0 or TurnsToZ(posSideways) == 2 then
    result = MineToX(posForward)
    result = result and MineToZ(posSideways)
  else
    result = MineToZ(posForward)
    result = result and MineToX(posSideways)
  end
  return result and MineToY(posVert)
end

function MineToX(posForward)
  TurnDirection(TurnsToX(posForward))
  while CurrentX() ~= posForward do
    if not MineForward() then
      print("Hit bedrock during MineToX()")
      return false
    end
  end
  return true
end

function MineToZ(posSideways)
  TurnDirection(TurnsToZ(posSideways))
  while CurrentZ() ~= posSideways do
    if not MineForward() then
      print("Hit bedrock during MineToZ()")
      return false
    end
  end
  return true
end

-- If bedrock is encountered, will return false
function MineToY(posVert)
  while currentHeight ~= posVert do
    if currentHeight<posVert then
      if not MineUp() then
        print("Hit bedrock during MineToY()")
        return false
      end
    else
      if not MineDown() then
        print("Hit bedrock during MineToY()")
        return false
      end
    end
  end
  return true
end

-- The ExtractOreX functions mine a contiguous orebody to exhaustion
-- The functions are recursive, so the path taken into the orebody 
--    is reversed working out once it is exhausted; 
--    this can be slow, but it was easy to program
-- Given that you supply a function to determine what ore is, 
--    this can work quite nicely for "mining" a tree (well, simple trees anyway)
--    or clearing a beach of sand down to a certain level

idMoon = "GalacticraftCore:tile.moonBlock"
idGCOil = "GalacticraftCore:tile.crudeOilStill"
idBCOil = "BuildCraft|Energy:blockOil"

function IsOil(name)
  return string.find(name, "Oil") ~= nil
end

function IsGas(name)
  return string.find(name, "gas") ~= nil
end

function HasOreInTheName(name)
  return string.find(name, "_ore") ~= nil
end

function IsTree(name)
  return IsWood(name) or string.find(name, ":leaves") ~= nil
end

function IsWood(name)
  return string.find(name, ":log") ~= nil
end

function IsGravityBlock(name)
  return name == idGravel or name == idSand
end

function IsAnything(name)
  return name ~= nil
end

-- GenericOreIdentifier is a function that given the identifying data of a
-- block is generally right in figuring out if it's valuable and needs mining
-- Tested with various mods such as Glens Gases, Buildcraft and Galaticraft.
-- Will go a little haywire aboveground in Biomes O' Plenty.
function GenericOreIdentifier(name, meta)
  -- oil and gas don't mine well
  if IsOil(name) or IsGas(name) or
     -- crappy moon rock should stay where it is
     (name == idMoon and (meta >= 3 and meta <= 5))
    then return false
  end
  return 
    -- anything not from vanilla Minecraft is probably good
    string.find(name, "minecraft") == nil or
    -- clay's handy
    name == idClay or
    -- as is Obsidian
    name == idObsidian or
    -- but as a fallback, if it HasOreInTheName then that's good, right?
    HasOreInTheName(name)
end

local steps=6
local extractUp=1
local extractDown=2
local extractForward=3
local step = {}
  step[1] = {turtle.inspectUp, turtle.placeUp, MineUp, MineDown, nil}
  step[2] = {turtle.inspectDown, turtle.placeDown, MineDown, MineUp, nil}
  step[3] = {turtle.inspect, turtle.place, MineForward, MineBackward, Turn}
  step[4] = {turtle.inspect, turtle.place, MineForward, MineBackward, Turn}
  step[5] = {turtle.inspect, turtle.place, MineForward, MineBackward, Turn}
  step[6] = {turtle.inspect, turtle.place, MineForward, MineBackward, Turn}

-- Extracts whatever ore it can find around itself
-- Coded as an iterative implementation because large orebodies (say, a big tree)
-- can exhaust the host language's stack
function ExtractOre(isOreFn)
  if isOreFn == nil then return false end

  local inspectFn, placeFn, extractFn, reverseFn, nextFn
  local stack = {}
  local somethingThere, data
  local result = false
  local stepNum
  stepNum = 1
  repeat
    inspectFn = step[stepNum][1] 
    placeFn   = step[stepNum][2]
    extractFn = step[stepNum][3]
    nextFn    = step[stepNum][5]
    somethingThere, data = inspectFn()
    if somethingThere then
      if isOreFn(data.name, data.metadata) then
        result = extractFn() or result
        -- push stepNum
        table.insert(stack, stepNum)
        stepNum = 0
      else
        RefuelWithLava(inspectFn, placeFn)
        if nextFn then 
          nextFn()
        end
      end
    else
      if nextFn then 
        nextFn()
      end
    end
    while stepNum == steps and #stack ~= 0 do
      -- pop stepNum
      stepNum = table.remove(stack)
      reverseFn = step[stepNum][4]
      nextFn    = step[stepNum][5]
      if not reverseFn() then
        error("ExtractOre reversing failed")
      end
      if nextFn then 
        nextFn()
      end
    end
    stepNum = stepNum + 1
  until stepNum > steps and #stack == 0
  return result
end

function ExtractOreDirection(direction, isOreFn)
  local inspectFn = step[direction][1] 
  local placeFn   = step[direction][2]
  local extractFn = step[direction][3]
  local reverseFn = step[direction][4]
  local somethingThere, data = inspectFn()
  local extracted = false
  if somethingThere then
    if isOreFn(data.name, data.metadata) then
      local result, dug_name = extractFn()
      extracted = ExtractOre(isOreFn) or extracted
      if not reverseFn() then
        error("ExtractOreDirection Reversing failed dir=",direction)
      end
    else
      RefuelWithLava(inspectFn, placeFn)
    end
  end
  return extracted
end

function ExtractOreForward(isOreFn)
  if isOreFn == nil then
    error("ExtractOreForward no isOreFn")
  end
  return ExtractOreDirection(extractForward, isOreFn)
end

function ExtractOreUp(isOreFn)
  if isOreFn == nil then
    error("ExtractOreUp no isOreFn")
  end
  return ExtractOreDirection(extractUp, isOreFn)
end

function ExtractOreDown(isOreFn)
  if isOreFn == nil then
    error("ExtractOreDown no isOreFn")
  end
  return ExtractOreDirection(extractDown, isOreFn)
end

function MineCubeCorner(isOreFn)
  ExtractOreForward(isOreFn)
  ExtractOreUp(isOreFn)
  ExtractOreDown(isOreFn)
  Turn()
  local success = MineForward()
  if success then
    ExtractOreForward(isOreFn)
    ExtractOreUp(isOreFn)
    ExtractOreDown(isOreFn)
    TurnAnti()
    ExtractOreForward(isOreFn)
    TurnAround()
    success = MineForward()
    TurnAnti()
    if not success then
      MoveBackward()      
    end
  end
  if not success then
    TurnAnti()
  end
  return success
end

-- FIXME Perhaps all the following the preceeding path is unnecessary?
function BackoutCubeCorner(times)
  Turn()
  for n=1,times,1 do
    MoveBackward()
    TurnAnti()
    MoveBackward()
  end
  TurnAnti()
end

-- FIXME corner will be missed if edge is blocked
function Extract3x3RingLayer(isOreFn)
  local success = false
  if MineCubeCorner(isOreFn) then
    if MineCubeCorner(isOreFn) then
      if MineCubeCorner(isOreFn) then
        success = MineCubeCorner(isOreFn)
        if not success then
          BackoutCubeCorner(3)
        end
      else
        BackoutCubeCorner(2)
      end
    else
      BackoutCubeCorner(1)
    end
  end
  return success
end
