Config = {}

-- ACE-Recht, das zum Vergeben/Entziehen des Filmmodus berechtigt
-- (in server.cfg: add_ace group.admin rose_moviemode.admin allow)
-- Wer dieses Recht hat, gilt auch als "Team-Mitglied" und bekommt die Meldungen.
Config.Ace = 'rose_moviemode.admin'

-- Zusaetzlich: ESX-Gruppen, die als Team zaehlen (Fallback, falls kein ACE gesetzt ist)
Config.AdminGroups = { admin = true, superadmin = true, mod = true }

-- Befehle
Config.GrantCommand = 'filmmodus'   -- Admin: /filmmodus <ID> [an|aus]
Config.MenuCommand  = 'filmmenu'    -- berechtigter Spieler: Menue oeffnen
Config.MenuKey      = ''            -- optionale Taste fuer das Menue (z.B. 'F7'), leer = keine

-- Noclip
Config.Noclip = {
    speed      = 1.0,   -- Grundgeschwindigkeit
    fastMulti  = 4.0,   -- Shift
    slowMulti  = 0.25,  -- Alt
}

-- Spieler sieht sich selbst trotz Unsichtbarkeit (nur lokal, im Filmmodus)
Config.SeeSelf = false

-- txAdmin-Benachrichtigung an das Team, sobald ein Spieler den Filmmodus an- oder ausschaltet
Config.TxAdminAuthor  = 'Filmmodus'  -- Absendername in der txAdmin-Nachricht
Config.ToggleCooldown = 3            -- Sekunden Spam-Schutz zwischen zwei Umschaltungen
