local RSGCore = exports['rsg-core']:GetCoreObject()
local AnimalsLoaded = false

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'

    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/Rexshack-RedM/qc-advancedranch/main/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')

        if not text then 
            versionCheckPrint('error', 'Currently unable to run a version check.')
            return 
        end

        --versionCheckPrint('success', ('Current Version: %s'):format(currentVersion))
        --versionCheckPrint('success', ('Latest Version: %s'):format(text))
        
        if text == currentVersion then
            versionCheckPrint('success', 'You are running the latest version.')
        else
            versionCheckPrint('error', ('You are currently running an outdated version, please update to version %s'):format(text))
        end
    end)
end

-----------------------------------------------------------------------

-- use chicken
RSGCore.Functions.CreateUseableItem("chicken", function(source)
    local src = source
    TriggerClientEvent('qc-advancedranch:client:newanimaluseitem', src, 'chicken', joaat('a_c_chicken_01'), 'egg')
end)

-- use pig
RSGCore.Functions.CreateUseableItem("pig", function(source)
    local src = source
    TriggerClientEvent('qc-advancedranch:client:newanimaluseitem', src, 'pig', joaat('a_c_pig_01'), 'truffle')
end)

-----------------------------------------------------------------------

RSGCore.Commands.Add('herd', 'Herd Animals (Ranchers Only)', { { name = 'animal type', help = 'Type of animal to herd' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('qc-advancedranch:client:herdanimals', src, args[1])
end)

RSGCore.Commands.Add('herdoff', 'Un-Herd Animals (Ranchers Only)', { { name = 'animal type', help = 'Type of animal to un-herd' } }, true, function(source, args)
    local src = source
    TriggerClientEvent('qc-advancedranch:client:unherdanimals', src, args[1])
end)

-----------------------------------------------------------------------

-- get all animal data
RSGCore.Functions.CreateCallback('qc-advancedranch:server:getanimaldata', function(source, cb, animalid)
    MySQL.query('SELECT * FROM ranch_animals WHERE animalid = ?', {animalid}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

-----------------------------------------------------------------------

-- update animal data
CreateThread(function()
    while true do
        Wait(5000)
        if AnimalsLoaded then
            TriggerClientEvent('qc-advancedranch:client:updateAnimalData', -1, Config.RanchAnimals)
        end
    end
end)

CreateThread(function()
    TriggerEvent('rsg-gangcamp:server:getAnimals')
    AnimalsLoaded = true
end)

-- get animals
RegisterServerEvent('rsg-gangcamp:server:getAnimals')
AddEventHandler('rsg-gangcamp:server:getAnimals', function()
    local result = MySQL.query.await('SELECT * FROM ranch_animals')

    if not result[1] then return end

    for i = 1, #result do
        local animalData = json.decode(result[i].animals)
        print('loading '..animalData.animal..' with ID: '..animalData.id)
        table.insert(Config.RanchAnimals, animalData)
    end
end)

-----------------------------------------------------------------------

-- new animal
RegisterServerEvent('qc-advancedranch:server:newanimal')
AddEventHandler('qc-advancedranch:server:newanimal', function(data)

    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local animalid = math.random(111111, 999999)
    local money = Player.Functions.GetMoney('cash')
    if money < data.cost then
        TriggerClientEvent('ox_lib:notify', src, {title = 'Not Enough Cash', description = 'you don\'t have enough cash to do that!', type = 'error' })
        goto continue 
    end

    local AnimalData =
    {
        id = animalid,
        animal = data.animal,
        health = 100,
        product = 0,
        productoutput = data.product,
        x = data.animalspawn.x,
        y = data.animalspawn.y,
        z = data.animalspawn.z,
        h = 0,
        hash = data.hash,
        ranchid = data.playerjob,
        borntime = os.time()
    }

    local AnimalCount = 0

    for _, v in pairs(Config.RanchAnimals) do
        if v.playerjob == Player.PlayerData.playerjob then
            AnimalCount = AnimalCount + 1
        end
    end

    if AnimalCount >= Config.MaxAnimalCount then
    
        TriggerClientEvent('ox_lib:notify', src, {title = 'Maximum Animals', description = 'you have the maximum animals alowed!', type = 'inform' })
        
    else
        table.insert(Config.RanchAnimals, AnimalData)
        TriggerEvent('qc-advancedranch:server:saveAnimal', AnimalData, data.playerjob, animalid)
        TriggerEvent('qc-advancedranch:server:updateAnimals')
        Player.Functions.RemoveMoney('cash', tonumber(data.cost))
    end

    ::continue::

end)

RegisterServerEvent('qc-advancedranch:server:saveAnimal')
AddEventHandler('qc-advancedranch:server:saveAnimal', function(AnimalData, playerjob, animalid)
    local datas = json.encode(AnimalData)

    MySQL.Async.execute('INSERT INTO ranch_animals (animals, ranchid, animalid) VALUES (@animals, @ranchid, @animalid)',
    {
        ['@animals'] = datas,
        ['@ranchid'] = playerjob,
        ['@animalid'] = animalid,
    })
end)

RegisterServerEvent('qc-advancedranch:server:updateAnimals')
AddEventHandler('qc-advancedranch:server:updateAnimals', function()
    local src = source
    TriggerClientEvent('qc-advancedranch:client:updateAnimalData', src, Config.RanchAnimals)
end)

-- feed animal
RegisterNetEvent('qc-advancedranch:server:feedanimal', function(animalid, animalhealth, animaltype)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local result = MySQL.query.await('SELECT * FROM ranch_animals WHERE animalid = ?', {animalid})
    
    for i = 1, #result do
        local id = result[i].id
        local animalData = json.decode(result[i].animals)
        -- update animal health
        local healthadjust = (animalData.health + Config.AnimalFeedAdd)
        animalData.health = healthadjust
        MySQL.update("UPDATE ranch_animals SET `animals` = ? WHERE `id` = ?", {json.encode(animalData), id})
        Player.Functions.RemoveItem('animalfeed', 1)
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['animalfeed'], "remove")
        TriggerClientEvent('ox_lib:notify', src, {title = 'Animals Fed', description = 'animal feeding was successful!', type = 'inform' })
    end
end)

-- collect product from animal
RegisterNetEvent('qc-advancedranch:server:collectproduct', function(ranchid, animalid, animalproduct, animalproductoutput, animaltype)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    local result = MySQL.query.await('SELECT * FROM ranch_animals WHERE animalid = ?', {animalid})

    for i = 1, #result do
        local id = result[i].id
        local animalData = json.decode(result[i].animals)
        -- reset animal product
        animalData.product = 0
        MySQL.update("UPDATE ranch_animals SET `animals` = ? WHERE `id` = ?", {json.encode(animalData), id})
        
        -- add stock to ranch
        local giveamount = 1
        
        MySQL.query('SELECT * FROM ranch_stock WHERE jobaccess = ? AND item = ?',{ranchid, animalproductoutput} , function(result)
            if result[1] ~= nil then
                local stockadd = result[1].stock + giveamount
                MySQL.update('UPDATE ranch_stock SET stock = ? WHERE jobaccess = ? AND item = ?',{stockadd, ranchid, animalproductoutput})
                TriggerClientEvent('ox_lib:notify', src, {title = 'Stock Added', description = animalproductoutput..' has been added to your stock', type = 'inform' })
            else
                MySQL.insert('INSERT INTO ranch_stock (`jobaccess`, `item`, `stock`) VALUES (?, ?, ?);', {ranchid, animalproductoutput, giveamount})
            end
        end)
    end

end)

-- collect job product
RegisterNetEvent('qc-advancedranch:server:collectjobproduct', function(ranchid, jobproduct, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    local giveamount = amount
    
    MySQL.query('SELECT * FROM ranch_stock WHERE jobaccess = ? AND item = ?',{ranchid, jobproduct} , function(result)
        if result[1] ~= nil then
            local stockadd = result[1].stock + giveamount
            MySQL.update('UPDATE ranch_stock SET stock = ? WHERE jobaccess = ? AND item = ?',{stockadd, ranchid, jobproduct})
            TriggerClientEvent('ox_lib:notify', src, {title = 'Stock Added', description = jobproduct..' has been added to your stock', type = 'inform' })
        else
            MySQL.insert('INSERT INTO ranch_stock (`jobaccess`, `item`, `stock`) VALUES (?, ?, ?);', {ranchid, jobproduct, giveamount})
        end
    end)

end)

-- update new animal position to database
RegisterNetEvent('qc-advancedranch:server:updateposition', function(animalid, posx, posy, posz)

    local result = MySQL.query.await('SELECT * FROM ranch_animals')

    if not result then goto continue end

    for k, v in pairs(result) do
        local animalData = json.decode(v.animals)
        animalData.x = posx
        animalData.y = posy
        animalData.z = posz
        MySQL.update("UPDATE ranch_animals SET `animals` = ? WHERE `animalid` = ?", {json.encode(animalData), animalid})
    end

    ::continue::
end)

-- if animal is killed it will be removed from the database
RegisterServerEvent('qc-advancedranch:server:animalkilled')
AddEventHandler('qc-advancedranch:server:animalkilled', function(animalid)
    MySQL.update('DELETE FROM ranch_animals WHERE animalid = ?', {animalid})
    TriggerEvent('rsg-log:server:CreateLog', 'ranch', 'Ranch Animal Killed', 'red', 'animal with the branding id of '..animalid..' was killed!')
end)

-----------------------------------------------------------------------------------

-- remove item/amount
RegisterServerEvent('qc-advancedranch:server:removeitem')
AddEventHandler('qc-advancedranch:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)

    if Player.Functions.RemoveItem(item, amount) then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], 'remove')
    end
end)

-----------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------------
-- ranch upkeep system
--------------------------------------------------------------------------------------------------
UpkeepInterval = function()
    local result = MySQL.query.await('SELECT * FROM ranch_animals')

    if not result then goto continue end

    for i = 1, #result do
        local id = result[i].id
        local animalData = json.decode(result[i].animals)
        -- animal age workings
        local borntime = animalData.borntime
        local daysfrom = os.difftime(os.time(), borntime) / (24 * 60 * 60) -- seconds in a day
        local animalage = math.floor(daysfrom)
        -- update animal age starts at zero (today)
        animalData.age = animalage
        MySQL.update("UPDATE ranch_animals SET `animals` = ? WHERE `id` = ?", {json.encode(animalData), id})
        
        if animalData.age == Config.AnimalDieAge then
            MySQL.update('DELETE FROM ranch_animals WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'ranch', 'Ranch Animal Died', 'red', 'animal '..animalData.animal..' with the id of '..animalData.id..' owned by ranch '..animalData.ranchid.. ' died of old age!')
            goto continue
        end
        
        if animalData.health > 1 then
            -- update animal health
            local healthadjust = (animalData.health - Config.HealthRemovePerCycle)
            animalData.health = healthadjust
            MySQL.update("UPDATE ranch_animals SET `animals` = ? WHERE `id` = ?", {json.encode(animalData), id})
        else
            print('animal '..animalData.animal..' with the id of '..animalData.id..' owned by ranch '..animalData.ranchid..' died!')
            MySQL.update('DELETE FROM ranch_animals WHERE id = ?', {id})
            TriggerEvent('rsg-log:server:CreateLog', 'ranch', 'Ranch Animal Died', 'red', 'animal '..animalData.animal..' with the id of '..animalData.id..' owned by ranch '..animalData.ranchid.. ' died!')
        end
        
        if animalData.product < 100 then
            -- update animal product
            local productadjust = (animalData.product + Config.ProductAddPerCycle)
            animalData.product = productadjust
            MySQL.update("UPDATE ranch_animals SET `animals` = ? WHERE `id` = ?", {json.encode(animalData), id})
        end
        
    end

    ::continue::
    
    TriggerEvent('qc-advancedranch:server:updateAnimals')
    print('animal check cycle complete')

    SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)
end

SetTimeout(Config.CheckCycle * (60 * 1000), UpkeepInterval)


-- setup wagon
RegisterServerEvent('qc-advancedranch:server:SetupWagon', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local isBoss = Player.PlayerData.job.isboss
    local job = Player.PlayerData.job.name
    if isBoss == true then
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM job_wagons WHERE job = ?", { job })
        if result == 0 then
            local plate = GeneratePlate()
            MySQL.insert('INSERT INTO job_wagons(job, plate, active) VALUES(@job, @plate, @active)', {
                ['@job'] = job,
                ['@plate'] = plate,
                ['@active'] = 1,
            })
            TriggerClientEvent('ox_lib:notify', source, {title = Lang:t('success.wagon_setup_successfully'), type = 'success' })
        else
            TriggerClientEvent('ox_lib:notify', source, {title = Lang:t('error.already_have_wagon'), type = 'error' })
        end
    else
        TriggerClientEvent('ox_lib:notify', source, {title = Lang:t('error.not_the_boss'), type = 'error' })
    end
end)

-- get active wagon
RSGCore.Functions.CreateCallback('qc-advancedranch:server:GetActiveWagon', function(source, cb)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local job = Player.PlayerData.job.name
    local result = MySQL.query.await('SELECT * FROM job_wagons WHERE job=@job AND active=@active', {
        ['@job'] = job,
        ['@active'] = 1
    })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        cb(nil)
    end
end)

-- generate wagon plate
function GeneratePlate()
    local UniqueFound = false
    local plate = nil
    while not UniqueFound do
        plate = tostring(RSGCore.Shared.RandomStr(3) .. RSGCore.Shared.RandomInt(3)):upper()
        local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM job_wagons WHERE plate = ?", { plate })
        if result == 0 then
            UniqueFound = true
        end
    end
    return plate
end


--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
