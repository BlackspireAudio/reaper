-- @description Increase preroll count
-- @version 1.0
-- @author Blackspire

--------------------------------------------------
--------------------PARAMS------------------------
--------------------------------------------------
local undo_message = 'Increase preroll count'

--------------------------------------------------
---------------------MAIN-------------------------
--------------------------------------------------
reaper.Undo_BeginBlock()

local preroll_count = reaper.SNM_GetDoubleConfigVar("prerollmeas", 0) -- get current preroll count
reaper.SNM_SetDoubleConfigVar("prerollmeas", preroll_count + 1)       -- increase preroll count

reaper.Undo_EndBlock(undo_message, 0)                                 -- 0 = only native actions were used
