resource_manifest_version '77731fab-63ca-442c-a67b-abc70f28dfa5'

dependency 'vrp'

description 'Menu Polizia'
author 'KingRich'
version '1.0'

server_scripts {
    '@vrp/lib/utils.lua',
    'server.lua'
}

client_scripts {
    'lib/Proxy.lua',
    'lib/Tunnel.lua',
    'gui.lua',
    'client.lua'
}
