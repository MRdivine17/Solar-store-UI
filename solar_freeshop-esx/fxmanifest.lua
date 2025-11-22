fx_version 'cerulean'
game 'gta5'

author 'Solar SCRIPTS | Solar Development Team'
description 'Dynamic Shop UI - NUI Based'
version '1.0.0'

lua54 'yes'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/styles.css',
    'ui/script.js',
    'ui/images/*.png'
}

shared_script 'config.lua'  

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}
