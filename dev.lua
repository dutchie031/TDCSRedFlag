

local basePath = "C:\\Repos\\DCS\\TDCSRedFlag\\"

local classPath = basePath .. "classes\\"

assert(loadfile(classPath .. "eventhandler.lua"))()

assert(loadfile(classPath .."tankerops\\" .. "TankerOps.lua"))()


assert(loadfile(basePath .. "TDCSRedFlag.lua"))()


