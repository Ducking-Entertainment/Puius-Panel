local module = {};
local SeeAllConnections = {};

local Shared = require("../Shared");

local Assets = script.Parent.Parent.Parent.Assets;
local Scrollable = script.Parent.Parent.Parent.Scrollable;

local Watching, SeeAllActive = false, false;

module.Name = "Vanilla Commands";

local function UpdateBillboard(Billboard)
  local Humanoid = Billboard.Parent.Humanoid;
  Billboard.TextLabel.Text = string.format("%s: %.02f / %.02f", Billboard.Parent.Name, Humanoid.Health, Humanoid.MaxHealth);
end;

module["See All"] = function()
  local Players = game.Players:GetPlayers();
  local Billboard = Assets.Puius_Billboard;

  if (SeeAllActive) then
    for _, v in (SeeAllConnections) do
      v:Disconnect();
    end;

    for _, v: Player in Players do
      if (not v.Character or not v.Character:FindFirstChild("Puius_Billboard")) then
        continue;
      end;

      v.Character.Puius_Billboard:Destroy();
    end;
  else
    for _, v: Player in Players do
      table.insert(SeeAllConnections, v.CharacterAdded:Connect(function(Character)
        local Clone = Billboard:Clone();
        Clone.Enabled = true;
        Clone.Parent = Character;
        UpdateBillboard(Clone);

        Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
          UpdateBillboard(Clone);
        end);
      end));

      local Clone = Billboard:Clone()
      Clone.Enabled = true;
      Clone.Parent = v.Character;
      UpdateBillboard(Clone);

      if (not v.Character) then
        continue;
      end;

      v.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
        UpdateBillboard(Clone);
      end);
    end;
  end;

  SeeAllActive = not SeeAllActive;
end;

function module.Logs()
  local LogsData = Shared.Remote:InvokeServer({Type = "RequestLogs"});

  for _, Command in pairs(LogsData) do
    local Concated = "";
    local ConcatedArgs = "";
    local TotalTargets = #Command.Targets;

    for i, Target in pairs(Command.Targets) do
      if (i == TotalTargets) then
        Concated ..= Target.Name;
      else
        Concated ..= Target.Name..", ";
      end;
    end;

    for _, Arg in Command.Arguments do
      ConcatedArgs ..= " "..tostring(Arg) or "<CAN'T CONVERT>";
    end;

    local Template = Scrollable.Container.Template:Clone();
    Template.Parent = Scrollable.Container;
    Template.Name = "Command";
    Template.Text = `<b>Executed by: </b> {Command.ExecutedBy} <b>Command:</b> {Command.Command}, <b>targets</b>: {Concated}, <b>arguments</b>: {ConcatedArgs}`;
    Template.Visible = true;
  end;

  Scrollable.Title.Text = "Logs";
  Scrollable.Visible = true;
end;

function module.Watch(Targets)
  if (#Targets == 0) then
    return;
  end;

  workspace.CurrentCamera.CameraSubject = not Watching and Targets[1].Character.Humanoid or game.Players.LocalPlayer.Character.Humanoid;
  Watching = not Watching;
end;

return module;
