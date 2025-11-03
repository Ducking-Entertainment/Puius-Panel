--[[
-- Shared module must not have global variables which are specific to the graphical / non graphical environment.
--]]

local module = {};
local LocalCommands = {};
local PluginsMetadata = {};

local Remote = game:GetService("ReplicatedStorage"):WaitForChild("PanelRemote");
module.Remote = Remote;

local function ContainsOnlyPlayers(PlayerTable)
  for _, v in pairs(PlayerTable) do
    if ((typeof(v) ~= "Instance") or not v:IsA("Player")) then return false; end;
  end;

  return true;
end;

--[[
-- RunCommand(Command, Arguments) accepts Command string and Arguments table, and it is the function which handles preparing
-- and invoking the RemoteFunction to execute the command (or in some cases, run the command only locally). Cleanup is done manually.
--]]
module.RunCommand = function(Command, PlayersSelected, Arguments)
  if not ContainsOnlyPlayers(PlayersSelected) then return; end;

  Command = string.lower(Command)

  if LocalCommands[Command] then 
    LocalCommands[Command](PlayersSelected)
    return;
  end;

  print(Remote:InvokeServer({Command = Command, Targets = PlayersSelected, Arguments = Arguments}));
end;

--[[
-- SetDisplayOrder() is the function that handles AlwaysOnTop setting. Basically, when called, finds the highest DisplayOrder 
-- existing within the player's GUI and sets the panel's DisplayOrder to +1 that.
--]]
module.SetHighestDisplayOrder = function()
  local HighestDisplayOrder = 1

  for _, v in pairs(game.Players.LocalPlayer.PlayerGui:GetChildren()) do
    if (v == script.Parent.Parent) then
      continue;
    end;

    if (v.DisplayOrder > HighestDisplayOrder) then 
      HighestDisplayOrder = v.DisplayOrder 
    end;
  end;

  script.Parent.Parent.DisplayOrder = HighestDisplayOrder + 1;
end;

--[[
-- Unimplemented.
--]]
module.GetArgumentsEx = function(...)
  -- TODO
  local TypesNeeded = {...}
end

--[[
-- GetArgument(Folder, AllowedType) accepts Folder Instance and AllowedType string as arguments and serves as basic input functionality
-- for additional arguments. If more arguments are needed, GetArgumentsEx(...) should be called.
--]]
module.GetArgument = function(Folder, AllowedType)
  local Panel = game.Players.LocalPlayer.PlayerGui:WaitForChild("PanelUI")
  local ArgumentsFrame = Panel.MainFrame.Arguments

  local i = 0
  local Argument

  for _, Button in pairs(ArgumentsFrame:GetChildren()) do
    if Button.Name == "TextButton" or Button:IsA("UIListLayout") then continue end

    Button:Destroy()
  end

  for _, v in pairs(Folder) do
    if not v:IsA(AllowedType) then continue end
    i = i + 1

    local ArgButton = ArgumentsFrame.TextButton:Clone()
    ArgButton.Parent = ArgumentsFrame
    ArgButton.Text = v.Name
    ArgButton.Name = v.Name
    ArgButton.Visible = true

    ArgButton.MouseButton1Up:Connect(function()
      ArgumentsFrame.Visible = false
      Argument = {v.Name}
    end)
  end

  if i == 0 then return end
  ArgumentsFrame.Visible = true

  ArgumentsFrame.CanvasSize = UDim2.new(0, ArgumentsFrame.UIListLayout.AbsoluteContentSize.X,
    0, ArgumentsFrame.UIListLayout.AbsoluteContentSize.Y)
  repeat task.wait() until ArgumentsFrame.Visible == false or Argument

  return Argument
end

--[[
-- GetPluginsMetadata() is a shared function whose scope is to centralize requests for PluginsName.
--]]
module.GetPluginsMetadata = function()
  local ClientCommands = script.Parent:WaitForChild("Client");
  PluginsMetadata = Remote:InvokeServer({Type = "RequestPlugins"});
  
  for _, Module in pairs(ClientCommands:GetChildren()) do
    local RequiredModule = require(Module);
    
    if not PluginsMetadata[RequiredModule.Name] then
      PluginsMetadata[RequiredModule.Name] = {};
      PluginsMetadata[RequiredModule.Name]["Name"] = RequiredModule.Name;
    end;

    for Name, Command in pairs(RequiredModule) do
      LocalCommands[string.lower(Name)] = Command;
      PluginsMetadata[RequiredModule.Name][Name] = Name;
    end;
  end;

  return PluginsMetadata;
end;

return module;
