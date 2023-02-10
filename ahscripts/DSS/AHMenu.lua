local DSSModName = "Dead Sea Scrolls (Alt Horsemen)"
local DSSCoreVersion = 3
local MenuProvider = {}

function MenuProvider.SaveSaveData()
    Althorsemen.StoreSaveData()
end

function MenuProvider.GetPaletteSetting()
    return Althorsemen.GetSaveData().MenuPalette
end

function MenuProvider.SavePaletteSetting(var)
    Althorsemen.GetSaveData().MenuPalette = var
end

function MenuProvider.GetHudOffsetSetting()
    if not REPENTANCE then
        return Althorsemen.GetSaveData().HudOffset
    else
        return Options.HUDOffset * 10
    end
end

function MenuProvider.SaveHudOffsetSetting(var)
    if not REPENTANCE then
        Althorsemen.GetSaveData().HudOffset = var
    end
end

function MenuProvider.GetGamepadToggleSetting()
    return Althorsemen.GetSaveData().MenuControllerToggle
end

function MenuProvider.SaveGamepadToggleSetting(var)
    Althorsemen.GetSaveData().MenuControllerToggle = var
end

function MenuProvider.GetMenuKeybindSetting()
    return Althorsemen.GetSaveData().MenuKeybind
end

function MenuProvider.SaveMenuKeybindSetting(var)
    Althorsemen.GetSaveData().MenuKeybind = var
end

function MenuProvider.GetMenusNotified()
    return Althorsemen.GetSaveData().MenusNotified
end

function MenuProvider.SaveMenusNotified(var)
    Althorsemen.GetSaveData().MenusNotified = var
end

function MenuProvider.GetMenusPoppedUp()
    return Althorsemen.GetSaveData().MenusPoppedUp
end

function MenuProvider.SaveMenusPoppedUp(var)
    Althorsemen.GetSaveData().MenusPoppedUp = var
end

local DSSInitializerFunction = include("ahscripts.DSS.AHMenuCore")
local dssmod = DSSInitializerFunction(DSSModName, DSSCoreVersion, MenuProvider)

local ahdirectory = {
    main = {
        title = 'alt horsemen',
        noscroll = true,
        buttons = {
            {str = 'resume game', action = 'resume'},
            {str = 'settings', dest = 'settings'},
        },
        tooltip = dssmod.menuOpenToolTip
    },
    settings = {
        title = 'settings',
        buttons = {
            dssmod.hudOffsetButton,
            dssmod.gamepadToggleButton,
            dssmod.menuKeybindButton,
            {
                str = '% horse chance',
                increment = 5, max = 100,
                variable = 'HorseChance',
                setting = 15,
                load = function()
                    return Althorsemen.GetSaveData().HorseChance or Althorsemen.HorseChanceDefault
                end,
                store = function(var)
                    Althorsemen.GetSaveData().HorseChance = var
                end,
                tooltip = {strset = {'% chance','for horseman','to appear'}}
            },
            {
                str = 'wad of tumors',
                choices = {'on', 'off'},
                variable = 'EnableItemDrop',
                setting = 1,
                load = function()
                    return Althorsemen.GetSaveData().EnableItemDrop or Althorsemen.EnableItemDropDefault
                end,
                store = function(var)
                    Althorsemen.GetSaveData().EnableItemDrop = var
                end,
                tooltip = {strset = {'alt horsemen','drop','wad of tumors'}}
            },
            dssmod.paletteButton
        },
        tooltip = dssmod.menuOpenToolTip
    }
}

local ahdirectorykey = {
    Item = ahdirectory.main,
    Main = 'main',
    Idle = false,
    MaskAlpha = 1,
    Settings = {},
    SettingsChanged = false,
    Path = {},
}

DeadSeaScrollsMenu.AddMenu("Alt horsemen", {Run = dssmod.runMenu, Open = dssmod.openMenu, Close = dssmod.closeMenu, Directory = ahdirectory, DirectoryKey = ahdirectorykey})