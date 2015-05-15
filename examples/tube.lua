function LineTunnel(extractFn, inspectFn, placeFn)
  RefuelWithLava(inspectFn, placeFn)
  extractFn(GenericOreIdentifier)
  if Select(idNRack) then
    placeFn()
  else
    if Select(idCobble) then
      placeFn()
    else
      error("Error: Out of blocks")
    end
  end
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
  LineTunnelForward(Noop)
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
  LineTunnelForward(Noop)
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

local tArgs = { ... }
if #tArgs ~= 2 then
	print( "Usage: tube <up|dn|fwd|fast|stairdn|stairup> <length>" )
  print( "  Makes a sealed passageway, useful for travelling" )
  print( "  through lava, gases and other hostile environments -" )
  print( "  fwd makes a two high, 1 wide sealed tunnel" )
  print( "  fast does the same but doesn't bother sealing" )
  print( "  up makes minimum height stairs which bump your head" )
  print( "  stairup makes 5-high staircase with space for steps" )
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

if tArgs[1] =='up' then
  MineUp()
  for n=1,length,1 do
    MineStepUp()
  end
  MineDown()
  return
end
if tArgs[1] =='dn' or tArgs[1] =='down' then
  for n=1,length,1 do
    MineStepDown()
  end
  return
end
if tArgs[1] == 'stairdn' then
  for n=1,length,1 do
    MineStairDown()
  end
  return
end
if tArgs[1] == 'stairup' then
  for n=1,length,1 do
    MineStairUp()
  end
  return
end
if tArgs[1] == 'fwd' or tArgs[1] == 'forward' then
  for n=length/2,1,-1 do
    MineHorizontalTunnelTwoSteps()
  end
  return
end
if tArgs[1] == 'fast' or tArgs[1] == 'ff' then
  for n=1,length,1 do
    MineHorizontalTunnelFast()
  end
  return
end
