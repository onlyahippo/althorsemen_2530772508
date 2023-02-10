local mod = Althorsemen

mod.HorseChanceDefault = 15
mod.EnableItemDropDefault = 1

function mod.CheckDefaultConfigs(savedata)
    savedata.HorseChance = savedata.HorseChance or mod.HorseChanceDefault
    savedata.EnableItemDrop = savedata.EnableItemDrop or mod.EnableItemDropDefault
end