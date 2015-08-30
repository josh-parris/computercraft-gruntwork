shell.run("common")

oreFn = GenericOreIdentifier
haltFn = function()
  return FreeSlots() == 0
end

function IsLiningMaterial(data)
  return IsCrappyMoonStuff(data.name, data.metadata) or
    data.name==idNRack or
    data.name==idCobble
end

function LineTunnel(extractFn, inspectFn, placeFn)
  RefuelWithLava(inspectFn, placeFn)
  extractFn(oreFn)
  for slot=1,slots,1 do
    local data = turtle.getItemDetail(slot)
    if data and IsLiningMaterial(data) then
      turtle.select(slot)
      placeFn()
      return
    end
  end
  error("Error: Out of blocks")
end

function LineTunnelForward(subsequentFn)
  LineTunnel(ExtractOreForward, turtle.inspect, turtle.place)
  subsequentFn()
end

function LineTunnelUp()
  LineTunnel(ExtractOreUp, turtle.inspectUp, turtle.placeUp)
end

function LineTunnelDown()
  LineTunnel(ExtractOreDown, turtle.inspectDown, turtle.placeDown)
end

function MineHorizontalTunnelTwoSteps()
  -- First Step, bottom block
  MineForward()
  RefuelWithLavaForward()
  LineTunnelDown()
  TurnAnti()
  LineTunnelForward(TurnAround)
  LineTunnelForward(NoOp)
  -- First Step, top block
  MineUp()
  LineTunnelForward(TurnAnti)
  RefuelWithLavaForward()
  TurnAnti()
  LineTunnelForward(Turn)
  LineTunnelUp()
  -- Second Step, top block
  MineForward()
  RefuelWithLavaForward()
  LineTunnelUp()
  TurnAnti()
  LineTunnelForward(TurnAround)
  LineTunnelForward(NoOp)
  -- Second Step, bottom block
  MineDown()
  LineTunnelForward(TurnAnti)
  RefuelWithLavaForward()
  TurnAnti()
  LineTunnelForward(Turn)
  LineTunnelDown()
end

function MineHorizontalTunnelFast()
  -- First Step, bottom block
  MineForward()
  RefuelWithLavaForward()
  LineTunnelDown()
  -- First Step, top block
  turtle.digUp() -- mine it, but don't move
  local success, data = turtle.inspectUp()
  if success then
    MoveBackward()
    MineHorizontalTunnelTwoSteps()
  end
end

function MineStepUp()
  -- bottom block
  MineForward()
  LineTunnelDown()
  LineTunnelForward(TurnAnti)
  LineTunnelForward(TurnAround)
  -- middle block
  LineTunnelForward(MineUp)
  LineTunnelForward(TurnAnti)
  LineTunnelForward(TurnAnti)
  -- top block
  LineTunnelForward(MineUp)
  LineTunnelForward(Turn)
  LineTunnelForward(Turn)
  LineTunnelForward(TurnAnti)
  LineTunnelUp()
  -- reset for next step
  MineDown()
end

function MineStepDown()
  -- middle block
  MineForward()
  LineTunnelForward(TurnAnti)
  LineTunnelForward(TurnAround)
  -- top block
  LineTunnelForward(MineUp)
  LineTunnelUp()
  LineTunnelForward(TurnAnti)
  LineTunnelForward(TurnAnti)
  LineTunnelForward(MineDown)
  -- bottom block
  MineDown()
  LineTunnelDown()
  LineTunnelForward(Turn)
  LineTunnelForward(Turn)
  LineTunnelForward(TurnAnti)
end

-- expects to start on the step below the step we're about to make
function MineStairUp()
  MineUp()
  -- Bottom block
  MineForward()
  LineTunnelForward(TurnAnti)
  for n=1,2,1 do
    LineTunnelForward(MineUp)
    LineTunnelForward(Turn)
    LineTunnelForward(MineUp)
    LineTunnelForward(TurnAnti)
  end
  -- top block
  LineTunnelUp()
  LineTunnelForward(Turn)
  for n=1,4,1 do
    LineTunnelForward(MineDown)
  end
  LineTunnelForward(TurnAnti)
end

-- expects to start on the step above the step we're about to make
function MineStairDown()
  -- 2nd from bottom block
  MineForward()
  LineTunnelForward(TurnAnti)
  LineTunnelForward(MineUp)
  -- 3rd block / middle
  LineTunnelForward(Turn)
  LineTunnelForward(MineUp)
  -- 4th block
  LineTunnelForward(TurnAnti)
  LineTunnelForward(MineUp)
  -- top block
  LineTunnelForward(Turn)
  LineTunnelForward(Turn)
  LineTunnelUp()
  for n=1,4,1 do
    LineTunnelForward(MineDown)
  end
  LineTunnelDown()
  LineTunnelForward(TurnAnti)
  LineTunnelForward(TurnAnti)
  LineTunnelForward(Turn)
end

function MakeTubeBy(tubeFn, times)
  for n=1,times do
    if haltFn() then
      print("Storage full. Halting after " .. n .. " steps")
      break
    end
    tubeFn()
  end
end

function usage()
  print( "Usage: tube <up|dn|fwd|fast|stairdn|stairup>" )
  print( "            <length> [dump|noore]" )
  print( "Makes a sealed passageway, for travelling" )
  print( "through lava, gases and hostile environments" )
  print( "  fwd makes a two high, 1 wide sealed tunnel" )
  print( "  fast does the same but unsealed" )
  print( "  up makes minimum height stairs" )
  print( "  stairup makes 5-high staircase for steps" )
  print( "  unless 'dump', will stop when full" )
  print( "  noore causes orebodies to be not followed" )
end

-- Main routine
local tArgs = { ... }
if #tArgs == 1 or #tArgs > 3 then
  usage()
  return
end

local length = tonumber( tArgs[2] )
if length < 1 then
  print( "Tunnel length must be positive" )
  return
end
if length > 64 then
  -- because, chunk unloading and stuff
  print( "Tunnel can't be more than 64 blocks long" )
  return
end

if tArgs[3] == 'noore' then
  oreFn = NoOp
elseif tArgs[3] == 'dump' then
  haltFn = NoOp
elseif tArgs[3] ~= nil then
  print("I don't know " .. tArgs[3])
  usage()
  return
end

if tArgs[1] =='up' then
  MineUp()
  MakeTubeBy(MineStepUp, length)
  MineDown()
elseif tArgs[1] =='dn' or tArgs[1] =='down' then
  MakeTubeBy(MineStepDown, length)
elseif tArgs[1] == 'stairdn' then
  MakeTubeBy(MineStairDown, length)
elseif tArgs[1] == 'stairup' then
  MakeTubeBy(MineStairUp, length)
elseif tArgs[1] == 'fwd' or tArgs[1] == 'forward' then
  MakeTubeBy(MineHorizontalTunnelTwoSteps, length/2)
elseif tArgs[1] == 'fast' or tArgs[1] == 'ff' then
  MakeTubeBy(MineHorizontalTunnelFast, length)
else
  print("I don't know " .. tArgs[1])
  usage()
end
