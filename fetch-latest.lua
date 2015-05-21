local function get(repoFile,saveTo)
  print("Fetching " .. repoFile)
  local download = http.get("https://github.com/josh-parris/computercraft-gruntwork/raw/master/"..repoFile) --This will make 'download' hold the contents of the file.
  if download then --checks if download returned true or false
    local handle = download.readAll() --Reads everything in download
    download.close() --remember to close the download!
    local file = fs.open(saveTo,"w") --opens the file defined in 'saveTo' with the permissions to write.
    file.write(handle) --writes all the stuff in handle to the file defined in 'saveTo'
    file.close() --remember to close the file!
  else --if returned false
    print("Unable to download the file "..repoFile)
    print("Make sure you have the HTTP API enabled or")
    print("an internet connection!")
  end --end the if
end --close the function

-- The common library of routines to make turtle programming better
get("common.lua", "common")

-- Not an example, but handy to find out the name of items and blocks
get("examples/name.lua", "name")

-- Ore mining by wormholing the rock - fuel efficient, gets almost all ore
get("examples/worm.lua", "worm")

-- Get down to bedrock without worrying about lava, gases et al
-- Travel through the nether without ghasts griefing you or lava burns
get("examples/tube.lua", "tube")

-- Follow orebodies to exhaustion - great for caving, especially if set as 
-- the startup script. Is also a great example of how easy programming 
-- turtles gets when there's a powerful library behind you - it's 1 line long.
get("examples/extract.lua", "extract")

shell.run("common")
