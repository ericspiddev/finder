 local constants = {
     window = {
        INVALID_WINDOW_ID = -1,
        CURRENT_WINDOW = 0,
     },
     events = {
        WINDOW_ENTER_EVENT = "WinEnter",
     },
     position = {
        ROW_INDEX = 1,
        COL_INDEX = 2,
     },
     buffer = {
        CURRENT_BUFFER = 0,
        NO_CONTEXT = -1,
        EMPTY_BUFFER = {},
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
 }

 return constants
