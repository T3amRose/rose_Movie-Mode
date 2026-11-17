fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'rose_Movie-Mode'
author 'Rose'
description 'Filmmodus: Admins geben einzelnen Spielern dauerhaft ein Menue mit Unsichtbarkeit und Noclip, Oeffnen wird per txAdmin ans Team gemeldet'
version '1.0.0'

dependency 'ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

server_scripts {
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/noclip.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
