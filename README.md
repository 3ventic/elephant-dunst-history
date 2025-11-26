# elephant-dunst-history

Provides [Elephant](https://github.com/abenz1267/elephant) with notification history from [Dunst](https://github.com/dunst-project/dunst). Requires `jq` and `dunstctl` to be available in PATH. Actioning a notification will make dunst replay it, allowing you to see the full summary and all the usual, as if the notification was new.

## Installation

Install by placing the dunst.lua file from this repository into `~/.config/elephant/menus/`, and ensure menus provider is enabled in [Walker](https://github.com/abenz1267/walker).