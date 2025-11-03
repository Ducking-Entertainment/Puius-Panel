local module = {};
local Settings = require(script.Parent.Parent.Parent.Settings);

local Replicated = game:GetService("ReplicatedStorage");
local Storage = game:GetService("ServerStorage");

local TeleportOffset = CFrame.new(0, 0, -3);

local function GetTools(): {Tool}
  local Tools = {};

  for _, v in Replicated:GetDescendants() do
    if (v:IsA("Tool")) then
      table.insert(Tools, v.Name);
    end;
  end;

  for _, v in Storage:GetDescendants() do
    if (v:IsA("Tool")) then
      table.insert(Tools, v.Name);
    end;
  end;

  return Tools;
end;

-- Metadata
module.Name = "Vanilla Commands" -- This gives the panel button a custom name. Not adding it will result in the usage of the module's name.
module.Descriptions = {
  ["Kick"] = "kick <players> <message>", -- Use the same name which you used to implement the functionality of the said command.
  ["Ban"] = "ban <player> <message>",
  ["Unban"] = "unban <userid>",
  ["Team"] = "team <players> <team>",
  ["Give"] = "give <players> <tool>",
  ["Remove_tool"] = "remove tool <players> <tool>",
  ["To"] = "to <player>",
  ["Bring"] = "bring <players>",
  ["Freeze"] = "freeze <players>",
  ["Respawn"] = "respawn <players"
}

module.RequireExArguments = {
  ["Kick"] = {
    {["Message"] = "string"}
  },

  ["Give"] = {
    {["Tool"] = {
        Type = "itemselector",
        Instances = {table.unpack(GetTools())}
      }
    }
  },

  ["Remove_tool"] = {
    {["Tool"] = "string"}
  },

  ["Ban"] = {
    {["DisplayReason"] = "string"},
    {["PrivateReason"] = "string"},
    {["Duration"] = "number"},
    {["ExcludeAltAccounts"] = "bool"},
  },

  ["Unban"] = {
    {["UserId"] = "number"}
  },

  ["Team"] = {
    {["Team"] = {
        Type = "itemselector",
        Instances = {table.unpack(game.Teams:GetTeams())}
      },
      ["Respawn after teaming"] = "bool",
    }
  }
}

function module.Remove_tool(_, Targets: {Player}, Arguments: {[string]: any}): ()
  if (not Arguments) then
    return;
  end;

  for _, Player in Targets do
    if (Player.Backpack:FindFirstChild(Arguments.Tool or "")) then
      Player.Backpack[Arguments.Tool]:Destroy();
    end;
  end;
end;

function module.To(Executor: Player, Targets: {Player}): ()
  local Player = Targets[1];
  Executor.Character:PivotTo(Player.Character:GetPivot() * TeleportOffset);
end;

function module.Kick(_, Targets: {Player}, Arguments: {[string]: any}): ()
  for _, Player in Targets do
    Player:Kick(Arguments.Message or "You have been kicked by a moderator.")
  end
end

function module.Ban(Executor: Player, Targets: {Player}, Arguments: {[string]: any}): ()
  -- Supports only single-target to prevent possible abuse.
  if (game.PrivateServerId ~= nil and game.PrivateServerOwnerId ~= 0) then
    return "Unable to run BAN within a private server.";
  end;

  if (not Settings.Administrators[Executor.UserId]) then
    return "You must be an administrator to execute this command.";
  end;

  local Target = Targets[1];
  if (not Target) then
    return "Invalid target passed to BAN command.";
  end;

  local BanConfiguration = {
    UserIds = {Target.UserId},
    Duration = -1, -- Infinite ban.
    DisplayReason = Arguments.DisplayReason or "",
    PrivateReason = Arguments.PrivateReason or "",
    ExcludeAltAccounts = Arguments.ExcludeAltAccounts or true,
    ApplyToUniverse = true
  };

  game:GetService("Players"):BanAsync(BanConfiguration);
  Target:Kick("You have been banned.");
end;

function module.Unban(Executor: Player, Targets: {Player}): ()
  if (game.PrivateServerId ~= nil and game.PrivateServerOwnerId ~= 0) then
    return "Unable to run UNBAN within a private server.";
  end;

  if (not Settings.Administrators[Executor.UserId]) then
    return "You must be an administrator to execute this command.";
  end;

  local Target = Targets[1]
  if (tonumber(Target) == nil) then
    return "Invalid target passed to UNBAN command.";
  end;

  local UnbanConfig = {
    UserIds = {Target},
    ApplyToUniverse = true,
  };

  game:GetService("Players"):UnbanAsync(UnbanConfig);
end;

function module.Respawn(_, Targets: {Player}): ()
  for _, Player in (Targets) do
    Player:LoadCharacter();
  end;
end;

function module.Bring(Executor: Player, Targets: {Player}): ()
  for _, Player in Targets do
    Player.Character:PivotTo(Executor.Character:GetPivot() * TeleportOffset);
  end;
end;

function module.Team(_, Targets: {Player}, Arguments: {[string]: any}): ()
  if (not Arguments) then
    return "No arguments passed for TEAM command.";
  end;

  if (typeof(Arguments.Team) ~= "string") then
    return "Argument 1 isn't a string for TEAM command. Type is: "..typeof(Arguments.Team);
  end;

  local Team = game:GetService("Teams"):FindFirstChild(Arguments.Team or "");

  if (not Team) then
    return "Argument 1 doesn't exist for TEAM command.";
  end;

  if (Arguments["Respawn after teaming"]) then
    for _, Player: Player in Targets do
      Player.Team = Team;
      Player:LoadCharacter();
    end;
  else
    for _, Player: Player in Targets do
      Player.Team = Team;
    end;
  end;
end;

function module.Give(_, Targets: {Player}, Arguments: {[string]: any}): ()
  local Tool = Replicated:FindFirstChild(Arguments.Tool or "", true);

  if (not Tool or not Tool:IsA("Tool")) then
    Tool = game:GetService("ServerStorage"):FindFirstChild(Arguments.Tool or "", true);
  else
    for _, Player in Targets do
      Tool:Clone().Parent = Player.Backpack;
    end;

    Tool = game:GetService("ServerStorage"):FindFirstChild(Arguments.Tool or "", true);
  end;

  if (not Tool or not Tool:IsA("Tool")) then
    return;
  end;

  for _, Player in Targets do
    Tool:Clone().Parent = Player.Backpack;
  end;
end;

function module.Freeze(_, Targets: {Player}): ()
  for _, Player in Targets do
    if not Player.Character then
      continue;
    end;

    if (not Player.Character:FindFirstChild("HumanoidRootPart")) then
      continue;
    end;

    Player.Character.HumanoidRootPart.Anchored = not Player.Character.HumanoidRootPart.Anchored;
  end;
end;

return module;
