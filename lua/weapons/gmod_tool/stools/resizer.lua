TOOL.Category = "Posing"
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
    language.Add("Tool.resizer.desc", "Resizes props")
    language.Add("Tool.resizer.left", "Resize a prop")
    language.Add("Tool.resizer.right", "Copy prop size")
    language.Add("Tool.resizer.reload", "Reset to default size")
    CreateClientConVar("resizer_xsize", "1", false, true, "", -50, 50)
    CreateClientConVar("resizer_ysize", "1", false, true, "", -50, 50)
    CreateClientConVar("resizer_zsize", "1", false, true, "", -50, 50)
    CreateClientConVar("resizer_xyzsize", "1", false, false, "", -50, 50)

    cvars.AddChangeCallback("resizer_xyzsize", function(_, _, newValue)
        RunConsoleCommand("resizer_xsize", newValue)
        RunConsoleCommand("resizer_ysize", newValue)
        RunConsoleCommand("resizer_zsize", newValue)
    end)

    net.Receive("resizer_getsize", function()
        local x, y, z = net.ReadFloat(), net.ReadFloat(), net.ReadFloat()
        RunConsoleCommand("resizer_xsize", x)
        RunConsoleCommand("resizer_ysize", y)
        RunConsoleCommand("resizer_zsize", z)
    end)
end

if SERVER then
    util.AddNetworkString("resizer_getsize")
end

local function resize(_, Entity, Data)
    if not SERVER then return end
    if not IsValid(Entity) then return end

    for i = 0, Entity:GetBoneCount() do
        Entity:ManipulateBoneScale(i, Data.propResizerSize)
    end

    Entity.propResizerSize = Data.propResizerSize
    duplicator.StoreEntityModifier(Entity, "PropResizerData", Data)
end

duplicator.RegisterEntityModifier("PropResizerData", resize)

function TOOL:LeftClick(trace)
    local ent = trace.Entity

    if IsValid(ent) and ent:GetClass() == "prop_physics" then
        if SERVER then
            local owner = self:GetOwner()
            local scale = Vector(tonumber(owner:GetInfo("resizer_xsize")), tonumber(owner:GetInfo("resizer_ysize")), tonumber(owner:GetInfo("resizer_zsize")))

            resize(owner, ent, {
                propResizerSize = scale
            })
        end

        return true
    end

    return false
end

function TOOL:RightClick(trace)
    local ent = trace.Entity

    if IsValid(ent) and ent:GetClass() == "prop_physics" then
        if SERVER then
            local scale = ent.propResizerSize or Vector(1, 1, 1)

            net.Start("resizer_getsize")
            net.WriteFloat(scale.x)
            net.WriteFloat(scale.y)
            net.WriteFloat(scale.z)
            net.Send(self:GetOwner())
        end

        return true
    end

    return false
end

function TOOL:Reload(trace)
    local ent = trace.Entity

    if IsValid(ent) and ent:GetClass() == "prop_physics" then
        if SERVER then
            for i = 0, ent:GetBoneCount() do
                ent:ManipulateBoneScale(i, Vector(1, 1, 1))
            end

            ent.propResizerSize = nil
            duplicator.ClearEntityModifier(ent, "PropResizerData")
        end

        return true
    end

    return false
end

function TOOL.BuildCPanel(CPanel)
    CPanel:AddControl("Header", {
        Text = "Resizer",
        Description = "Resizes props visually - does not affect hitbox"
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

    CPanel:NumSlider("X size", "resizer_xsize", 0.01, 10, 3)
    CPanel:NumSlider("Y size", "resizer_ysize", 0.01, 10, 3)
    CPanel:NumSlider("Z size", "resizer_zsize", 0.01, 10, 3)
    CPanel:NumSlider("XYZ (change all 3)", "resizer_xyzsize", 0.01, 10, 3)
end