# 🛒 BCC Shops – Advanced Shop System for RedM

**BCC Shops** is a powerful and dynamic shop management system for RedM. It allows servers to create immersive NPC-run stores and fully functional player-owned shops, all configurable via an in-game menu. No need to touch config files!

---

## 🚀 Features

- 🧍 **NPC Shops**  
  Create NPC-operated shops with customizable blips, coordinates, and ped models.

- 🧑‍🌾 **Player-Owned Shops**  
  Players can own and manage their own shops, complete with inventory caps, ledgers, and sale tracking.

- 🔧 **Everything Configurable In-Game**  
  No complex config files — all shop settings can be created and edited directly through the management UI.

- 🧾 **Item & Weapon Categories**  
  Manage shop inventory with category support, separate stock for buy/sell quantities, and level restrictions.

- 💰 **Ledger System**  
  Track shop funds with deposit and withdrawal options, including automated transaction logging.

- 🤖 **NPC Customer Simulation**  
  NPCs dynamically spawn, walk to your shop, simulate purchases, and buy random items or weapons.

- 📢 **Discord Webhook Logging**  
  Important events like purchases, deposits, and edits are sent to a designated Discord channel for transparency.

- 🧭 **Custom Blip System**  
  Assign map markers to shops with visual identifiers (supports image and hash-based blips).

- 🧠 **Feather Menu Interface**  
  All menus are powered by `feather-menu`, offering a clean, responsive experience.
  Most of the notifications are `FeatherMenu:Notify` , no more vorp notification.

- 🌍 **Multilingual Support**  
  Fully localized in English and Romanian, with support for adding more languages using `_U("key")`.

---

## 📦 Dependencies

This system depends on the following RedM/FXServer resources:

- `vorp_core`
- `vorp_inventory`
- `feather-menu`
- `bcc-utils`
- `oxmysql`

---

## ⚙️ Installation

1. **Download the bcc-shops last version** into your server’s `resources/` folder:

2. **Add to your `server.cfg`** after all dependencies:
   ```txt
   ensure vorp_core
   ensure vorp_inventory
   ensure feather-menu
   ensure bcc-utils
   ensure oxmysql
   ensure bcc-shops
   ```

3. **Start the server once** to auto-generate the required database tables.

---

## 🔧 Configuration

Located in `config.lua`, the few basic options include:

- `defaultlang` – Language file to use (`en_lang` or `ro_lang`)
- `keys.access` – Interaction key for shop prompt (default: **G**)
- `ManageShopsCommand` – Command for opening admin management menu
- `Webhook` – Global Discord webhook URL
- `adminGroups`, `AllowedJobs` – Controls admin access to management UI
- `BlipStyles` – Configure available blip icons
- `NPC` – Control NPC buyer behavior and spawn points

> 📝 All critical shop settings like positions, peds, inventory, and labels are handled directly through the in-game UI — no need to edit config files.

---

## 🧑‍💼 Usage

- **Players** press the configured key to access nearby shops.
- **Shop owners** can manage inventory, prices, and funds via the in-game interface.
- **Admins** use the configured command to create, edit, or delete shops.
- **NPCs** will dynamically simulate buyers and engage in item or weapon purchases.
