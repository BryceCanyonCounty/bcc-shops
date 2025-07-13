CreateThread(function()
    -- bcc_shops table
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS bcc_shops (
            shop_id INT(11) NOT NULL AUTO_INCREMENT,
            owner_id INT(30) DEFAULT NULL,
            shop_name VARCHAR(255) NOT NULL,
            shop_location VARCHAR(255) NOT NULL,
            shop_type VARCHAR(20) NOT NULL,
            webhook_link VARCHAR(255) NOT NULL DEFAULT 'none',
            inv_limit INT(30) NOT NULL DEFAULT 0,
            ledger DOUBLE(11,2) NOT NULL DEFAULT 0.00,
            blip_hash VARCHAR(255) NOT NULL DEFAULT 'none',
            is_npc_shop TINYINT(1) NOT NULL DEFAULT 0,
            pos_x DOUBLE NOT NULL,
            pos_y DOUBLE NOT NULL,
            pos_z DOUBLE NOT NULL,
            pos_heading DOUBLE NOT NULL,
            npc_model VARCHAR(255),
            PRIMARY KEY (shop_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_shop_access
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS bcc_shop_access (
            id INT(11) NOT NULL AUTO_INCREMENT,
            shop_id INT(11) NOT NULL,
            character_id VARCHAR(50) NOT NULL,
            PRIMARY KEY (id),
            KEY shop_id (shop_id),
            CONSTRAINT bcc_shop_access_ibfk_1 FOREIGN KEY (shop_id) REFERENCES bcc_shops(shop_id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_shop_categories
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS bcc_shop_categories (
            id INT(11) NOT NULL AUTO_INCREMENT,
            type ENUM('item', 'weapon') NOT NULL,
            name VARCHAR(64) NOT NULL,
            label VARCHAR(64),
            PRIMARY KEY (id),
            UNIQUE KEY type (type, name)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_shop_items
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS bcc_shop_items (
            item_id INT(11) NOT NULL AUTO_INCREMENT,
            shop_id INT(11) NOT NULL,
            item_label VARCHAR(255) NOT NULL,
            item_name VARCHAR(255) NOT NULL,
            currency_type VARCHAR(50) NOT NULL,
            buy_price DOUBLE NOT NULL,
            sell_price DOUBLE NOT NULL,
            level_required INT(11) NOT NULL,
            is_weapon TINYINT(1) NOT NULL DEFAULT 0,
            item_quantity INT(11) DEFAULT 0,
            buy_quantity INT(11) DEFAULT 0,
            sell_quantity INT(11) DEFAULT 0,
            category_id INT(11),
            PRIMARY KEY (item_id),
            KEY shop_id (shop_id),
            KEY fk_item_category (category_id),
            CONSTRAINT fk_item_category FOREIGN KEY (category_id) REFERENCES bcc_shop_categories(id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- bcc_shop_weapon_items
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS bcc_shop_weapon_items (
            weapon_id INT(30) NOT NULL AUTO_INCREMENT,
            shop_id INT(30) NOT NULL,
            weapon_name VARCHAR(255) NOT NULL,
            weapon_label VARCHAR(255) NOT NULL,
            buy_price DOUBLE(11,2) NOT NULL,
            sell_price DOUBLE(11,2) NOT NULL,
            currency_type VARCHAR(50) NOT NULL,
            level_required INT(11) NOT NULL,
            item_quantity INT(11) DEFAULT 0,
            buy_quantity INT(11) DEFAULT 0,
            sell_quantity INT(11) DEFAULT 0,
            custom_desc VARCHAR(255),
            weapon_info LONGTEXT NOT NULL,
            category_id INT(11),
            PRIMARY KEY (weapon_id),
            KEY shop_id (shop_id),
            KEY fk_weapon_category (category_id),
            CONSTRAINT bcc_shop_weapon_items_ibfk_1 FOREIGN KEY (shop_id) REFERENCES bcc_shops(shop_id) ON DELETE CASCADE,
            CONSTRAINT fk_weapon_category FOREIGN KEY (category_id) REFERENCES bcc_shop_categories(id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]])

    -- Insert default categories (only if table is empty)
    local categoryCount = MySQL.scalar.await("SELECT COUNT(*) FROM bcc_shop_categories")

    if categoryCount == 0 then
        MySQL.query.await([[
        INSERT INTO bcc_shop_categories (type, name, label) VALUES
        ('item', 'herbs', 'Herbs'),
        ('item', 'oil', 'Oil'),
        ('item', 'plants', 'Plants'),
        ('item', 'water', 'Water'),
        ('item', 'animals', 'Animals'),
        ('item', 'materials', 'Materials'),
        ('item', 'pastry', 'Pastry'),
        ('item', 'horses_wagons', 'Horses & Wagons'),
        ('item', 'antibiotice', 'Antibiotics'),
        ('item', 'antidot', 'Antidote'),
        ('item', 'default', 'Default'),
        ('item', 'gardening', 'Gardening'),
        ('item', 'medical', 'Medical'),
        ('item', 'other', 'Other'),
        ('item', 'stimulants', 'Stimulants'),
        ('item', 'textile', 'Textile'),
        ('weapon', 'melee', 'Melee Weapons'),
        ('weapon', 'rifles', 'Rifles'),
        ('weapon', 'shotguns', 'Shotguns'),
        ('weapon', 'repeaters', 'Repeaters'),
        ('weapon', 'pistols', 'Pistols'),
        ('weapon', 'bows', 'Bows & Lassos');
    ]])
        print("^3[bcc-shops]^0 Default EN categories ^2inserted successfully^0 into bcc_shop_categories.")
    else
        print("^3[bcc-shops]^0 bcc_shop_categories already populated (^5" .. categoryCount .. "^0 rows).")
    end

    print("^3[bcc-shops]^0 Database schema updated ^2successfully^0.")
end)
