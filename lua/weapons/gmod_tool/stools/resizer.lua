TOOL.Category = "Poser"
TOOL.Name = "#Resizer"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
    TOOL.Information = {
        {
            name = "left"
        },
        {
            name = "right"
        },
        {
            name = "reload"
        }
    }

    language.Add("Tool.resizer.name", "Resizer")
    language.Add("Tool.resizer.desc", "Resizes props/ragdolls/NPCs")
    language.Add("Tool.resizer.left", "Resize a prop")
    language.Add("Tool.resizer.right", "Copy prop size")
    language.Add("Tool.resizer.reload", "Reset to default size")
    CreateClientConVar("resizer_xsize", "1", false, true, "", -50, 50)
    CreateClientConVar("resizer_ysize", "1", false, true, "", -50, 50)
    CreateClientConVar("resizer_zsize", "1", false, true, "", -50, 50)
    CreateClientConVar("resizer_xyzsize", "1", false, false, "", -50, 50)
    CreateClientConVar("resizer_allbones", "0", false, true, "", 0, 1)

    local function _resizer_xyzcallback(cvar, prevValue, newValue)
        RunConsoleCommand("resizer_xsize", newValue)
        RunConsoleCommand("resizer_ysize", newValue)
        RunConsoleCommand("resizer_zsize", newValue)
    end

    cvars.AddChangeCallback("resizer_xyzsize", _resizer_xyzcallback)

    net.Receive("resizer_getsize", function()
        local x, y, z = net.ReadInt(14) / 100, net.ReadInt(14) / 100, net.ReadInt(14) / 100
        RunConsoleCommand("resizer_xsize", x)
        RunConsoleCommand("resizer_ysize", y)
        RunConsoleCommand("resizer_zsize", z)
    end)
end

if SERVER then
    util.AddNetworkString("resizer_getsize")
end

local function resize(Player, Entity, Data)
    if not SERVER then return end
    if not Entity:IsValid() then return end

    for i = 0, Entity:GetBoneCount() do
        Entity:ManipulateBoneScale(i, Data.propResizerSize)
    end

    Entity.propResizerSize = Data.propResizerSize
    duplicator.StoreEntityModifier(Entity, "PropResizerData", Data)
end

duplicator.RegisterEntityModifier("PropResizerData", resize)

function TOOL:LeftClick(trace)
    if trace.HitNonWorld and trace.Entity ~= nil and trace.Entity ~= 0 then
        if SERVER then
            local scale = Vector(tonumber(self:GetOwner():GetInfo("resizer_xsize")), tonumber(self:GetOwner():GetInfo("resizer_ysize")), tonumber(self:GetOwner():GetInfo("resizer_zsize")))

            --props
            if trace.Entity:GetClass() == "prop_physics" then
                resize(self:GetOwner(), trace.Entity, {
                    propResizerSize = scale
                })
            end

            --ragdolls and npcs
            if trace.Entity:GetClass() == "prop_ragdoll" or trace.Entity:IsNPC() then
                if tonumber(self:GetOwner():GetInfo("resizer_allbones")) > 0 then
                    resize(self:GetOwner(), trace.Entity, {
                        propResizerSize = scale
                    })
                else
                    local Bone = trace.Entity:TranslatePhysBoneToBone(trace.PhysicsBone)
                    trace.Entity:ManipulateBoneScale(Bone, scale)
                end
            end
        end

        return true
    end

    return false
end

function TOOL:RightClick(trace)
    if trace.HitNonWorld and trace.Entity ~= nil and trace.Entity ~= 0 then
        if SERVER and trace.Entity:GetClass() == "prop_physics" then
            local scale = trace.Entity.propResizerSize or Vector(1, 1, 1)
            net.Start("resizer_getsize")
            net.WriteInt(scale.x * 100, 14) --Using ints because writeVector + low decimals ends in weird floating point errors
            net.WriteInt(scale.y * 100, 14)
            net.WriteInt(scale.z * 100, 14)
            net.Send(self:GetOwner())
        end

        return true
    end

    return false
end

function TOOL:Reload(trace)
    if trace.HitNonWorld and trace.Entity ~= nil and trace.Entity ~= 0 then
        if SERVER and (trace.Entity:GetClass() == "prop_physics" or trace.Entity:GetClass() == "prop_ragdoll" or trace.Entity:IsNPC()) then
            for i = 0, trace.Entity:GetBoneCount() do
                trace.Entity:ManipulateBoneScale(i, Vector(1, 1, 1))
            end

            trace.Entity.propResizerSize = nil
            duplicator.ClearEntityModifier(trace.Entity, "PropResizerData")
        end

        return true
    end

    return false
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", {
        Text = "Resizer",
        Description = "Does not resize the hitbox or shadow."
    })

    CPanel:AddControl("ComboBox", {
        Label = "#tool.presets",
        MenuButton = 1,
        Folder = "resizer",
        Options = {
            Default = {
                resizer_xsize = '1',
                resizer_ysize = '1',
                resizer_zsize = '1',
                resizer_xyzsize = '1'
            }
        },
        CVars = {"resizer_xsize", "resizer_ysize", "resizer_zsize", "resizer_xyzsize"}
    })

    CPanel:AddControl("Slider", {
        Label = "X size",
        Type = "Float",
        Command = "resizer_xsize",
        Min = "0.01",
        Max = "10"
    })

    CPanel:AddControl("Slider", {
        Label = "Y size",
        Type = "Float",
        Command = "resizer_ysize",
        Min = "0.01",
        Max = "10"
    })

    CPanel:AddControl("Slider", {
        Label = "Z size",
        Type = "Float",
        Command = "resizer_zsize",
        Min = "0.01",
        Max = "10"
    })

    CPanel:AddControl("Slider", {
        Label = "XYZ",
        Type = "Float",
        Command = "resizer_xyzsize",
        Min = "0.01",
        Max = "10"
    })

    CPanel:AddControl("Checkbox", {
        Label = "Resize all bones of ragdolls/NPCs at once",
        Command = "resizer_allbones"
    })
end