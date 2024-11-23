-- FX Information
fx_version 'cerulean'
use_experimental_fxv2_oal 'yes'
lua54 'yes'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'Advanced Ranching script for RSG-Framework. Thanks to RexShack for his base work!'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@rsg-core/shared/locale.lua',
    'locales/en.lua', -- preferred language
    'config.lua',
}

client_scripts {
    'client/client.lua',
    'client/client_shop.lua',
    'client/client_dealer.lua',
    'client/client_jobs.lua'
}

server_scripts {
    'server/server.lua',
    'server/server_shop.lua',
    'server/server_jobs.lua',
    '@oxmysql/lib/MySQL.lua',
}

dependencies {
    'rsg-core',
    'ox_lib',
}
