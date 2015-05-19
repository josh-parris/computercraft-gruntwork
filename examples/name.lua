-- ComputerCraft turtle program to identify things around the turtle
local somethingThere, data 
for slot=1,16,1 do
  data = turtle.getItemDetail(slot)
  if data then
    print("Slot",slot,":",data.name, " meta:", data.damage)
  end
end
somethingThere, data = turtle.inspectUp()
if somethingThere then
  print("Up:",data.name," meta:",data.metadata)
end
somethingThere, data = turtle.inspect()
if somethingThere then
  print("Fwd:",data.name," meta:",data.metadata)
end
somethingThere, data = turtle.inspectDown()
if somethingThere then
  print("Down:",data.name," meta:",data.metadata)
end