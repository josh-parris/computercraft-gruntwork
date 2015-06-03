-- TODO:Support bot (clears dump chest; makes things - torches, buckets, obsidian, blocks of redstone; makes pedestrian tunnels, lights them)
-- TODO: label discovered gases:gasFallingExplosive etc

shell.run("common")

local torchesEvery=8
local tunnelLength=0
local maxTravel=16
local currentTravel=0
local maxHeight=12
local shaftSpacing=4

idPlug = idCobble

function IsOreRare(name)
  return idDiamond == name or idEmerald == name
end

function MineableOre(name, meta)
  return name ~= idTurtle and GenericOreIdentifier(name, meta)
end

function IsPluggedForward()
  local success, data = turtle.inspect()
  return success and data.name == idPlug
end

function OnStopBlock()
  local success, data = turtle.inspect()
  return success and data.name == idChest
end

function IsValuableCargo(name)
  return GenericOreIdentifier(name) and not IsFuel(name) 
end

-- prefer anything the user has loaded over coal which we're here to mine, lava is all over the place, 
priorities={}
priorities[idCoal]=5
priorities[idBucketL]=15
SetFuelPriority(priorities)
SetLowFuelLevel(maxTravel * 4)
-- -------

function MinTotalTravel()
  return maxTravel/shaftSpacing * (maxTravel*2*maxHeight/shaftSpacing + maxHeight*3)
end

function IsNotNeededForFuel(name)
  if CanTravel(MinTotalTravel()*3) then
    return name ~= idBucket
  else
    return name ~= idBucket and not IsFuel(name)
  end
end

function DumpIntoChestForward()
  local Result = OnStopBlock()
  -- If there's no chest, don't dump
  if Result then
    -- Dump valuable cargo first
    ForEachSlotIf(IsValuableCargo, turtle.drop)
    -- Dump excess spoil
    ForEachSlotIf(IsNotNeededForFuel, turtle.drop)
  else
    print("ERROR: told to dump, no chest")
    error() -- halt, we're lost
  end
  print("Fuel level:", turtle.getFuelLevel())
  if LowOnFuel() then
    print("Low on fuel, stopping for safety")
    Result = false
  end
  turtle.select(1) -- start back at the begining
  return Result
end

function ExtractOreHorizontalPlane()
  ExtractOreForward(oreFn)
  Turn()
  ExtractOreForward(oreFn)
  Turn()
  ExtractOreForward(oreFn)
  Turn()
  ExtractOreForward(oreFn)
  Turn()
end

function NeedsDigging(name)
  return 
    name ~= idLava and 
    name ~= idLavaF and
    name ~= idWater and
    name ~= idWaterF and
    name ~= idBedrock and
    string.find(name, "gas") == nil
end

-- Try to uncover nearby orebodies for small, valuable ores that generate in non-contiguous seams
-- Recover from collisions with bedrock
function MineAroundRareOre(name)
  if not IsOreRare(name) then return end
  local success
  -- Move up to and then mine the 3x3 layer above the discovered ore
  success = false
  if MineUp() then
    ExtractOreUp(oreFn)
    for side=1,4,1 do
      if not success and MineForward() then
        success = Extract3x3RingLayer(oreFn)
        MineBackward() -- known safe
      end
      Turn()
    end
    MineDown() -- known safe
  else
    for side=1,4,1 do
      if success then 
        if MineForward() then
          if MineUp() then
            success = Extract3x3RingLayer(oreFn)
            MineDown()
          end
          -- return to our starting position
          MineBackward() -- known safe
        end
      end
      Turn()
    end
  end
  -- Mine 3x3 middle layer 
  success = false
  for side=1,4,1 do
    if not success and MineForward() then
      success = Extract3x3RingLayer(oreFn)
      MineBackward() -- known safe
    end
    Turn()
  end
  -- Move down to and then mine the 3x3 layer below the discovered ore
  success = false
  if MineDown() then
    ExtractOreDown(oreFn)
    for side=1,4,1 do
      if not success and MineForward() then
        success = Extract3x3RingLayer(oreFn)
        MineBackward() -- known safe
      end
      Turn()
    end
    MineUp() -- known safe
  else
    for side=1,4,1 do
      if not success and MineForward() then
        if MineDown() then
          success = Extract3x3RingLayer(oreFn)
          MineUp()
        end
        -- return to our starting position
        MineBackward() -- known safe
      end
      Turn()
    end
  end
end

-- Shafts are lined to prevent creating large cavities in which mobs might spawn
function MineHorizontalShaft()
  -- Mine out a 1x1 shaft
  for n=1, tunnelLength, 1 do
    MineForward()
    ExtractOreUp(oreFn)
    Select(idCobble)
    turtle.placeUp()
    Turn()
    ExtractOreForward(oreFn)
    Select(idCobble)
    turtle.place()
    Turn()
    -- seal the tunnel to prevent gas/fluid leakage
    if n==2 and Select(idPlug) then
      turtle.place()
      turtle.select(1)
    end
    Turn()
    ExtractOreForward(oreFn)
    Select(idCobble)
    turtle.place()
    Turn()
    ExtractOreDown(oreFn)
    Select(idCobble)
    turtle.placeDown()
  end
end

-- Preconditions: Facing out from a horizontal shaft
-- Postconditons: Moved over two and up two, facing away from the intial shaft
function MoveToOffset(direction)
  TurnAnti()
  Select(idPlug)
  if direction==-1 then
    TurnAnti()
    turtle.place()
    Turn()
    MineUp()
  else
    MineUp()
    turtle.placeDown()
  end
  turtle.select(1)
  ExtractOreHorizontalPlane(oreFn)
  MineUp()
  ExtractOreHorizontalPlane(oreFn)
  ExtractOreUp(oreFn)
  for n=1,shaftSpacing/2,1 do
    MineForward()
    currentTravel = currentTravel + direction
    ExtractOreUp(oreFn)
    ExtractOreDown(oreFn)
  end
end

-- Preconditions: turtle is facing home
-- Postcondition: either all unchanged except most of the turtle's load is dumped,
--    or OnStopBlock() is true and the chest is full
function DumpWhileMining()
  local returnHeight = CurrentY()
  MineToY(0)
  for n=1, currentTravel, 1 do
    MineForward()
  end
  if DumpIntoChestForward() then
    for n=1, currentTravel, 1 do
      MineBackward()
      turtle.suck()
      if ExtractOreDown(oreFn) then
        Select(idCobble)
        turtle.placeDown()
        turtle.select(1)
      end
    end
    for y=1,returnHeight,1 do
      MineUp()
      turtle.suckDown()
      ExtractOreForward(oreFn)
    end
  else
    print("Chest full after ", currentTravel, " out, ", returnHeight, " up")
  end
end

-- Precondition: on main axis, facing into wall
-- Postcondition: on main axis, facing out from wall, over two and up two.
function MineOffsetShafts()
  MineHorizontalShaft()
  if FreeSlots() < 3 or LowOnFuel() then
    print("Dumping after mining outbound shaft")
    -- back out of shaft
    for n=tunnelLength-2, 1, -1 do
      MineBackward()
    end
    -- seal the tunnel to prevent gas leakage
    MineBackward()
    MineBackward()
    Select(idPlug)
    turtle.place()
    Turn()
    DumpWhileMining()
    if not OnStopBlock() then
      TurnAnti()
      MineForward()
      MineForward()
      TurnAround()
      Select(idPlug)
      turtle.place()
      TurnAround()
      for n=tunnelLength-2, 1, -1 do
        MineForward()
      end
    end
  end
  if not OnStopBlock() then
    MoveToOffset(1) -- We're travelling forwards to do this offset
    TurnAnti()
    MineHorizontalShaft()
    -- Because we're mining down, we can afford to not pick up mined blocks -
    -- we'll just get them when we return from the chest
    if FreeSlots() < 4 or LowOnFuel() then
      TurnAnti()
      DumpWhileMining()
      if not OnStopBlock() then
        Turn()
      end
    end
  end
end


-- write to http server to keep track of where we're at
local tArgs = { ... }
tunnelLength = maxTravel
if tArgs[1]=="rescue" then
  oreFn = GenericOreIdentifier
else
  oreFn = MineableOre
end
AfterMiningCall(MineAroundRareOre)
turtle.select(1)
turnClockwise=false
-- Locate stop block
for n=1,4,1 do
  if OnStopBlock() then
    break
  else
    Turn()
  end
end
if OnStopBlock() then
  TurnAround()
  SetOrigin("Forward", "Right")
  repeat
    Turn()
    if not IsPluggedForward() then
      MineOffsetShafts()
      if not OnStopBlock() then
        MoveToOffset(-1) -- We're travelling backwards to do this offset
        TurnAnti()
      end
    else
      for n=1,shaftSpacing,1 do
        MineUp()
      end
    end
    if not OnStopBlock() then
      if not IsPluggedForward() then
        MineOffsetShafts()
        if not OnStopBlock() then
          MoveToOffset(-1) -- We're travelling backwards to do this offset
          TurnAnti()
        end
      else
        for n=1,shaftSpacing,1 do
          MineUp()
        end
      end
    end
    if not OnStopBlock() then
      local distanceToNextCycle
      if not IsPluggedForward() then
        MineOffsetShafts()
        -- Move to start of next cycle
        if not OnStopBlock() then
          TurnAround()
          Select(idPlug)
          turtle.place()
          distanceToNextCycle = shaftSpacing/2
        end
      else
        distanceToNextCycle = shaftSpacing
      end
      if not OnStopBlock() then
        -- Move to start of next cycle
        TurnAnti()
        if currentTravel + distanceToNextCycle < maxTravel then
          MineToY(0)
          for n=1,distanceToNextCycle,1 do
            MineForward()
            currentTravel = currentTravel + 1
          end
        else
          break
        end
      end
    end
  until currentTravel>=maxTravel or OnStopBlock()
  if not OnStopBlock() then
    MineToY(0)
    TurnAround()
    for n=1,currentTravel,1 do
      MineForward()
    end
    if not OnStopBlock() then
      print("Dead reckoning failed, I'm lost")
      error()
    end
  end
  if DumpIntoChestForward() then
    print("Success: cycle completed")
  else
    print("Success: cycle completed, turtle not empty")
  end
else
  print("Worm mining program, gets all ores")
  print("Expects to start at y=5")
  print("Mines out a ",maxTravel,"*",maxTravel,"*10 block")
  print("Start next to a chest from which to work outwards")
  print("Add 'rescue' to the command to mine turtles")
end
