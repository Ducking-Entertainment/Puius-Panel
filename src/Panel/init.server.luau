local Event           = game:GetService("ReplicatedStorage"):FindFirstChild("PanelRemote");

local Settings        = require(script.Settings);
local Permissions     = {Administrators = Settings.Administrators, Moderators = Settings.Moderators};
local PluginMetadata  = {};
local Plugins         = {};
local Logs            = {};
local Internal        = {};

local function ContainsOnlyPlayers(PlayerTable): boolean
  for _, v in pairs(PlayerTable) do
    if ((typeof(v) ~= "Instance") or not v:IsA("Player")) then
      return false;
    end;
  end;

  return true;
end;

local function GivePanel(Player)
  if (Player.PlayerGui:FindFirstChild("PanelUI")) then
    return;
  end;

  if (not Permissions.Administrators[Player.UserId] and not Permissions.Moderators[Player.UserId]) then
    return;
  end;

  local Panel = script.PanelUI:Clone();
  local ClientCommands = script.Plugins.Client:Clone();
  ClientCommands.Parent = Panel.Framework;

  for _, v in script.Framework:GetChildren() do
    local Clone = v:Clone();
    Clone.Parent = Panel.Framework;

    if (Clone:IsA("LocalScript")) then
      Clone.Enabled = true;
    end;
  end;

  Panel.Parent = Player.PlayerGui;
end;

if (not Event) then
  Event = Instance.new("RemoteFunction");
  Event.Parent = game:GetService("ReplicatedStorage");
  Event.Name = "PanelRemote";
end;

Internal.RequestPlugins = function()
  return PluginMetadata;
end;

Internal.RequestLogs = function()
  return Logs;
end;

Internal.Default = function(Player, Data)
  if (not Data) then
    return "No data passed.";
  end;

  local Command = Data.Command;
  local Targets = Data.Targets;
  local Arguments = Data.Arguments;

  local Status, AdditionalResponse = pcall(function()
    if (not Arguments) then
      Arguments = {};
    end;

    if (type(Command) ~= "string" or type(Targets) ~= "table") then
      return "Unknown data type(s) passed.";
    end;

    if (not ContainsOnlyPlayers(Targets)) then
      return "Table doesn't contain only players.";
    end;

    local NewLog = {
      ExecutedBy = Player.Name,
      Arguments = Arguments,
      Command = Command,
      Targets = Targets
    };

    table.insert(Logs, NewLog);

    return Plugins[Command](Player, Targets, Arguments) or `Executed {Command} command!`;
  end);

  return AdditionalResponse or Status;
end;

script.PanelUI:SetAttribute("AlwaysOnTop", Settings.AlwaysOnTop);

Event.OnServerInvoke = function(Player, Data)
  if not (Permissions.Administrators[Player.UserId] and not Permissions.Moderators[Player.UserId]) then
    return "User is not authorized to invoke the remote function.";
  end;

  if (Internal[Data.Type]) then
    return Internal[Data.Type]();
  else
    return Internal.Default(Player, Data);
  end;
end;

for _, Plugin in script.Plugins.Server:GetChildren() do
  local Commands = require(Plugin);
  PluginMetadata[Commands.Name] = {};
  PluginMetadata[Commands.Name]["Name"] = Commands.Name;
  PluginMetadata[Commands.Name]["RequireExArguments"] = Commands.RequireExArguments;
  PluginMetadata[Commands.Name]["Descriptions"] = Commands.Descriptions;

  for Name, Func in Commands do
    if (typeof(Func) ~= "function") then
      continue;
    end;

    Plugins[string.lower(Name)] = Func;
    PluginMetadata[Commands.Name][Name] = Name;
  end;
end;

game:GetService("Players").PlayerAdded:Connect(function(Player)
  GivePanel(Player);
end);

for _, Player in game:GetService("Players"):GetPlayers() do
  GivePanel(Player);
end;
