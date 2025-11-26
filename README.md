# elephant-dunst-history

Provides [Elephant][elephant] with notification history from [Dunst][dunst]. Actioning a notification will make Dunst replay it, allowing you to see the full summary and all the usual, as if the notification was new.

![image of Walker displaying two recent notifications as a visual example](https://github.com/user-attachments/assets/75ad5793-05cc-4d96-97db-e2a4e2ac44ab)

### Prerequisites

- Installed & running:
  - [Dunst][dunst]
  - [Elephant][elephant]
- Available in PATH:
  - `jq`
  - `dunstctl`
- Ensure "menus" provider is enabled in [Walker](https://github.com/abenz1267/walker), assuming you're using Walker to access this.

### Installation

1. Place dunst.lua file from this repository into `~/.config/elephant/menus/`
2. Restart elephant

  [elephant]: https://github.com/abenz1267/elephant
  [dunst]: https://github.com/dunst-project/dunst
