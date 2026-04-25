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

-- Background watcher: hide bar when cursor is near the top edge
sbar.exec("pkill -f sketchybar_hover_watcher; (CONFIG_DIR=" .. os.getenv("CONFIG_DIR") .. " nohup bash -c 'exec -a sketchybar_hover_watcher \"$CONFIG_DIR/hover_watcher.sh\"' >/dev/null 2>&1 &)")

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
sbar.event_loop()
