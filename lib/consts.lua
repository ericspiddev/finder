 local constants = {
     window = {
        INVALID_WINDOW_ID = -1,
        CURRENT_WINDOW = 0,
     },
     events = {
        WINDOW_ENTER_EVENT = "WinEnter",
        WINDOW_LEAVE_EVENT = "WinLeave",
        WINDOW_RESIZED = "WinResized",
        BUFFER_ENTER = "BufEnter"
     },
     position = {
        ROW_INDEX = 1,
        COL_INDEX = 2,
     },
     buffer = {
        CURRENT_BUFFER = 0,
        INVALID_BUFFER = -1,
        NO_CONTEXT = -1,
        EMPTY_BUFFER = {},
        SCRATCH_BUFFER = true,
        LIST_BUFFER = true,
        VALID_LUA_EVENTS = {"on_lines", "on_bytes", "on_changedtick", "on_detach", "on_reload"}
     },
     highlight = {
         NO_WORD_COUNT_EXTMARK = -1,
         FINDER_NAMESPACE = "finder",
         MATCH_HIGHLIGHT = "Search",
         CURR_MATCH_HIGHLIGHT = "WildMenu" --CurSearch",
     },
     search = {
        FORWARD = 1,
        BACKWARD = -1,
     },
     lines = {
         START = 0,
         END = -1,
     },
     cmds = {
        CENTER_SCREEN = "norm! zz"
     },
     history = {
        MAX_ENTRIES = 100,
     }
 }

 return constants
