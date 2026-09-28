# Metal Eden (UE 5.3) RE-UE4SS & CheatManager Setup Guide

This guide documents the complete setup, configuration fixes, and custom Lua scripting required to enable console commands, fix GUI rendering, and achieve full Flight/Noclip in **Metal Eden** (Unreal Engine 5.3) using **RE-UE4SS**.

[!IMPORTANT] When you complete this guide and F3 activates no clip, use noclip to fly in the air over the wall that is blocking you.  IMMEDIATELY disable noclip/fly with f3 to fall, otherwise you will fly away out of bounds.

## 1. Overview & Common Misconceptions

* **RE-UE4SS** (the active, maintained fork of `UE4SS-RE/RE-UE4SS`) **does support `CheatManager`**.

* In many shipping UE 5.3 games (like *Metal Eden*), executing `fly`, `ghost`, or `god` in the console will register without errors, but the character won't move or clip. This occurs because release binaries often strip or override the default character physics functions.

* Modifying internal components directly via console `set` commands often fails due to complex types (e.g., `CollisionEnabled` enums). A custom Lua script using RE-UE4SS API functions bypasses this entirely.

## 2. Directory Structure & Settings

Ensure your game directory under `...\MetalEden\Binaries\Win64\` is structured as follows:

```
MetalEden\Binaries\Win64\
│
├── dwmapi.dll (or version.dll / dxgi.dll)
├── UE4SS-settings.ini
├── UE4SS.log
└── Mods\
    ├── mods.txt
    └── CheatManagerEnablerMod\
        └── scripts\
            └── main.lua

```

### `UE4SS-settings.ini` Configuration

To fix the white screen GUI crash and ensure proper console logging and overlay support, set your configuration as follows:

```
[Debug]
ConsoleEnabled = 1
GuiConsoleEnabled = 0
GuiConsoleVisible = 0
EnableInGameGUI = 1

```

> **Note:** Setting `GuiConsoleEnabled = 0` forces RE-UE4SS to use the native Windows Command Prompt terminal, preventing the blank/white rendering bug caused by overlay conflicts.

## 3. Mods Load Order (`Mods\mods.txt`)

Due to a line-parsing quirk in RE-UE4SS, always include a dummy mod at Line 1 to guarantee all listed mods are parsed correctly:

```
DummyMod : 0
CheatManagerEnablerMod : 1
ConsoleEnablerMod : 1
ConsoleCommandsMod : 1
Keybinds : 1

```

## 4. Complete Lua Script (`main.lua`)

Place this script in `Binaries\Win64\Mods\CheatManagerEnablerMod\scripts\main.lua`. It hooks into `PlayerController` initialization to enable `CheatManager` and binds **F3** to a rock-solid Noclip/Flight toggle using the `UEHelpers` module.

```
local UEHelpers = require("UEHelpers")

-- -------------------------------------------------------------------
-- 1. Construct UCheatManager on PlayerController Spawn
-- -------------------------------------------------------------------
RegisterHook("/Script/Engine.PlayerController:ClientRestart", function(self, NewPawn)
    local PlayerController = self:get()
    if not PlayerController:IsValid() then return end
    
    local CheatManagerClass = PlayerController.CheatClass
    if not CheatManagerClass:IsValid() then
        CheatManagerClass = StaticFindObject("/Script/Engine.CheatManager")
    end
    
    if not CheatManagerClass:IsValid() then
        print("[CheatManager Creator] Could not find default CheatClass\n")
        return
    end
    
    local CreatedCheatManager = StaticConstructObject(CheatManagerClass, PlayerController, 0, 0, 0, nil, false, false, nil)
    if CreatedCheatManager:IsValid() then
        PlayerController.CheatManager = CreatedCheatManager
        print("[CheatManager Creator] Enabled CheatManager successfully\n")
    end
end)

-- -------------------------------------------------------------------
-- 2. F3 Keybind: Flight & Noclip Toggle
-- -------------------------------------------------------------------
local isNoclip = false

RegisterKeyBind(Key.F3, function()
    -- Safely acquire local PlayerController via UEHelpers
    local PC = UEHelpers.GetPlayerController()
    
    if not PC:IsValid() then 
        print("[UE4SS] Error: PlayerController is invalid!\n")
        return 
    end

    local Pawn = PC.Pawn
    if not Pawn:IsValid() then 
        print("[UE4SS] Error: Player Pawn is invalid!\n")
        return 
    end

    local MoveComp = Pawn.CharacterMovement
    if not MoveComp:IsValid() then
        print("[UE4SS] Error: CharacterMovement component not found!\n")
        return
    end

    isNoclip = not isNoclip

    if isNoclip then
        -- 1. Enable Flight Physics
        MoveComp.MaxFlySpeed = 3000.0
        MoveComp.GravityScale = 0.0
        MoveComp.MovementMode = 4 -- MOVE_Flying
        
        -- 2. Disable Actor Collision
        Pawn.bActorEnableCollision = false
        Pawn:SetActorEnableCollision(false)
        
        print("[UE4SS] Noclip & Flight ENABLED\n")
    else
        -- 1. Restore Walking Physics
        MoveComp.GravityScale = 1.0
        MoveComp.MovementMode = 1 -- MOVE_Walking
        
        -- 2. Restore Actor Collision
        Pawn.bActorEnableCollision = true
        Pawn:SetActorEnableCollision(true)
        
        print("[UE4SS] Noclip & Flight DISABLED\n")
    end
end)

```

## 5. In-Game Controls & Keybindings Summary

| Key | Action | 
 | ----- | ----- | 
| **`F10`** or **`\`** | Toggle UE5 Engine Drop-Down Console | 
| **`Ctrl + F10`** / **`Insert`** | Toggle RE-UE4SS In-Game Tabbed GUI | 
| **`F3`** | Toggle Flight & Noclip (Pass through walls) | 

### Useful Console Fallbacks

If you want to manually run standard overrides directly from the engine console (**F10**):

* **God Mode:** `set PlayerPawn bCanBeDamaged False`

* **Force Flight:** `set CharacterMovementComponent MovementMode 4`

* **Reset Movement:** `set CharacterMovementComponent MovementMode 1`

* **Toggle All Collision:** `DisableActorCollision` / `EnableActorCollision`
