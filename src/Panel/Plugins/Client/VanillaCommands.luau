local module = {};
local Assets = script.Parent.Parent.Parent.Assets;
local Watching, SeeAllActive = false, false;
local SeeAllConnections = {};

module.Name = "Vanilla Commands";

local function UpdateBillboard(Billboard)
  local Humanoid = Billboard.Parent.Humanoid;
  Billboard.TextLabel.Text = string.format("%s: %.02f / %.02f", Billboard.Parent.Name, Humanoid.Health, Humanoid.MaxHealth);
end;

module["See All"] = function()
  local Players = game.Players:GetPlayers();
  local Billboard = Assets.Puius_Billboard;

  if (SeeAllActive) then
    for _, v in pairs(SeeAllConnections) do
      v:Disconnect();
    end;

    for _, v in pairs(Players) do
      if not v.Character or not v.Character:FindFirstChild("Puius_Billboard") then continue; end;
      v.Character.Puius_Billboard:Destroy();
    end;
  else
    for _, v in pairs(Players) do
      table.insert(SeeAllConnections, v.CharacterAdded:Connect(function(Character)
        local Clone = Billboard:Clone();
        Clone.Enabled = true;
        Clone.Parent = Character;
        UpdateBillboard(Clone);
      end));

      local Clone = Billboard:Clone()
      Clone.Enabled = true;
      Clone.Parent = v.Character;
      UpdateBillboard(Clone);
    end;
  end;

  SeeAllActive = not SeeAllActive;
end;

module.Watch = function(Targets)
  if #Targets == 0 then return; end;

  workspace.CurrentCamera.CameraSubject = not Watching and Targets[1].Character.Humanoid or game.Players.LocalPlayer.Character.Humanoid;
  Watching = not Watching;
end;

return module;
