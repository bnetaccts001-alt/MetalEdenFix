local UEHelpers = require("UEHelpers")

-- Construct CheatManager on PlayerController spawn
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

local isNoclip = false

-- F3 Keybind
RegisterKeyBind(Key.F3, function()
    -- Get PlayerController via RE-UE4SS built-in helper
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
        
        -- 2. Turn off Actor Collision
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
