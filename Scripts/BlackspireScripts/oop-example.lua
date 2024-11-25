-- Path to your script
local _, path = reaper.get_action_context()
-- Path to the parent folder of your script
local folder_path = path:match('^.+[\\/]')
-- Set the path of your package so that the 'require' function will search
-- for files there.
package.path = folder_path .. '?.lua;'

-- To import a script from the same directory as this script, e.g. utils.lua:
require 'utils'

-- To import a script from a subfolder, e.g. lib/utils.lua
require 'lib.utils'

-- If your utils file contains a function called 'DoStuff', you can now call
-- it like this:
DoStuff()

-- In larger projects this might be inadvisible though, as you're polluting
-- your global environment (e.g. you might have two functions called 'DoStuff' 
-- in two different files). Also lua becomes slower as you keep polluting.
-- So it might be a good idea to create modules or classes and import them
-- like this:

local my_module = require 'lib.my_module'
my_module.DoStuff()

local MyClass = require 'lib.my_class'
local instance = MyClass:New()
instance:DoStuff()

------------------- START OF FILE: lib/my_module --------------------------
-- Typical lua module

local my_module = {}

function my_module.DoStuff()
  -- Do stuff here
end

return my_module
------------------------- END OF FILE  -----------------------------------



------------------- START OF FILE: lib/my_class --------------------------
-- Typical lua class:

local MyClass = {}

function MyClass:New(obj)
  obj = obj or {}
  self.__index = self
  setmetatable(obj, self)
  return obj
end

function MyClass:DoStuff()
  -- Do stuff here
end

return MyClass
------------------------- END OF FILE  -----------------------------------