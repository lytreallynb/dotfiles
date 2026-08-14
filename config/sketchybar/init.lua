-- Require the sketchybar module
sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
sbar.begin_config()
require("bar")
require("default")
require("items")
sbar.end_config()

-- Stop the legacy hover watcher. The bar now sits below regular windows, so
-- polling the mouse every 100 ms and hiding the bar is no longer necessary.
sbar.exec("pkill -f '[h]over_watcher.sh' >/dev/null 2>&1")

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
