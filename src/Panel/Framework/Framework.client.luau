-- Handles the 'graphical' part of the panel.
local PlayersSelected: {Player} = {};

local Players = game:GetService("Players");
local UIS = game:GetService("UserInputService");
local TweenService = game:GetService("TweenService");

local Theme = require(script.Parent.Theme);
local Shared = require(script.Parent.Shared);

local Panel = script.Parent.Parent;
local DisplayFrame = Panel.MainFrame.ContentDisplay;
local PlayerList = Panel.MainFrame.PlayerList;
local PluginsList = Panel.MainFrame.Plugins.Container;
local ItemSelector = Panel.MainFrame.ItemSelector;
local Scrollable = Panel.Scrollable;

local DraggableObject = require(script.Parent.DraggableUI);
local Drag = DraggableObject.new(Panel.MainFrame);
Drag:Enable();

local PluginsName = Shared.GetPluginsMetadata(); -- {PluginName = {Name = Name}}
local SectionDisplayed: Frame, CommandVisible: string, CurrentCommand: TextButton = nil, nil, nil;

--[[
  ChangePluginShown handles the hiding of an old panel section, then the unhiding of another section.
  @param: Frame to be set as the new visible section.
  @return: Nothing.
--]]
local function ChangePluginShown(NewSection: Frame): ()
  if (SectionDisplayed) then
    SectionDisplayed.Visible = false;
  end;

  NewSection.Visible = true;
  SectionDisplayed = NewSection;
end;

--[[
-- CreatePlayerButton(Player) accepts a Player instance as argument and based on it and based on the provided settings it creates
-- a new button or updates an existing button within PlayerList ScrollingFrame.
  CreatePlayerButton creates a new button within PlayerList.
  @param: Player to use to create new button.
  @return: Nothing.
--]]
local function CreatePlayerButton(Player: Player): ()
  local Template: Frame = PlayerList.Container:FindFirstChild(Player.Name);

  if (not Template) then
    -- If there isn't any existing button, simply create a new one with the template found within PlayerList and update its elements.
    Template = PlayerList.Container.Template:Clone();
    Template.ImageLabel.Image = Players:GetUserThumbnailAsync(Player.UserId,
                                Enum.ThumbnailType.HeadShot,
                                Enum.ThumbnailSize.Size60x60);
    Template.PlayerName.Text = Player.Name;

    Template.Interact.MouseButton1Up:Connect(function()
      -- Holding down CTRL allows you to select multiple players at once. This implements the functionality.
      if (UIS:IsKeyDown(Enum.KeyCode.LeftControl)) then
        if (not table.find(PlayersSelected, Player)) then
          table.insert(PlayersSelected, Player);
        else
          local Index = table.find(PlayersSelected, Player);
          if (Index) then table.remove(PlayersSelected, Index); end;
        end;
      else
        PlayersSelected = {[1] = Player};
      end;
    end);

    Template.Parent = PlayerList.Container;
    Template.Name = Player.Name;

    Template.Visible = true;
  end;
end;

--[[
  RefreshPlayerList can be called freely whenever the `PlayerList` ScrollingFrame has to be updated. Normally it's called
  whenever a new player joins or a command is fired, after PlayersSelected table is cleared.
  @return: Nothing.
--]]
local function RefreshPlayerList(): ()
  for _, v in PlayerList.Container:GetChildren() do
    if (not Players:FindFirstChild(v.Name) and v.Name ~= "Template" and v:IsA("Frame")) then
      v:Destroy();
    end;
  end;

  for _, Player in Players:GetPlayers() do
    CreatePlayerButton(Player);
  end;

  -- In the end, update the PlayerList CanvasSize based on information given by the UIListLayout
  PlayerList.CanvasSize = UDim2.fromOffset(PlayerList.Container.UIListLayout.AbsoluteContentSize.X, PlayerList.Container.UIListLayout.AbsoluteContentSize.Y);
end;

--[[
  HandleVisibilityAnimation based on the provided arguments, play the popup / close animation, whose properties
  are defined in Theme module. The function yields until animation is finished. In argument is true when Scaling
  should go to 0 and false when scaling should go to 1.

  @param: Frame to animate.
  @param: Boolean denoting if the frame will close or open.
  @return: Nothing.
--]]
local function HandleVisibilityAnimation(Frame: Frame, In: boolean): ()
  local Tween = TweenService:Create(Frame.UIScale, In and Theme.WindowClose or Theme.WindowPopup, {Scale = In and 0 or 1});
  Tween:Play();

  if (not In) then
    Frame.Visible = true;
  end;

  Tween.Completed:Wait();

  if (In) then
    Frame.Visible = false;
  end;
end;

--[[
  SetupItemSelector sets up a provided FiledFrame which is of type 'itemselector'. The ItemsTable provided to it
  will result in the items that will be showed for the said item selection.

  @param: Table of instances from where the end-user will choose one or an Instance on which :GetChildren() will be used.
  @param: Frame which is of type 'itemselector'.
  @return: Nothing.
]]
local function SetupItemSelector(ItemsTable: {Instance | string} | Instance, FieldFrame: Frame & {TextLabel: TextLabel, TextButton: TextButton}): ()
  if (typeof(ItemsTable) == "Instance") then
    ItemsTable = ItemsTable:GetChildren();
  end;

  for _, v: TextButton in ItemSelector.Scrollable.Container:GetChildren() do
    if (v.Name ~= "Template" and v.Name ~= "UIListLayout") then
      v:Destroy();
    end;
  end;

  for _, v: Instance in ItemsTable do
    local Template: TextButton = ItemSelector.Scrollable.Container.Template:Clone();
    Template.Parent = ItemSelector.Scrollable.Container;
    Template.Name = tostring(v);
    Template.TextLabel.Text = tostring(v);

    Template.MouseButton1Up:Connect(function()
      FieldFrame.TextButton.Text = tostring(v);
      ItemSelector.Visible = false;
    end);

    Template.Visible = true;
  end;

  FieldFrame.TextButton.MouseButton1Up:Connect(function()
    ItemSelector.Visible = true;

    game:GetService("RunService").Heartbeat:Wait(); -- Give roblox time to calculate the new AbsoluteContentSize.

    local ListAbsSize: Vector2 = ItemSelector.Scrollable.Container.UIListLayout.AbsoluteContentSize;
    ItemSelector.Scrollable.CanvasSize = UDim2.fromOffset(ListAbsSize.X, ListAbsSize.Y + 5);
  end);
end;

Scrollable.Close.MouseButton1Up:Connect(function()
  Scrollable.Visible = false;

  for _, v in Scrollable.Container:GetChildren() do
    if (v.Name == "Template" or v.Name == "UIListLayout") then
      continue;
    end;

    v:Destroy();
  end;
end);

Scrollable.Container.ChildAdded:Connect(function()
  local Abs = Scrollable.Container.UIListLayout.AbsoluteContentSize;
  Scrollable.Container.CanvasSize = UDim2.fromOffset(Abs.X, Abs.Y);
end);

Panel.PanelButton.MouseButton1Up:Connect(function()
  HandleVisibilityAnimation(Panel.MainFrame, Panel.MainFrame.Visible);
  -- if Panel.Terminal.Visible then HandleVisibilityAnimation(Panel.Terminal, true) end
end);

Players.PlayerAdded:Connect(function()
  RefreshPlayerList();
end);

Players.PlayerRemoving:Connect(function()
  RefreshPlayerList();
end);

UIS.InputBegan:Connect(function(Input, Processed)
  if (Input.KeyCode == Enum.KeyCode.Equals and not Processed) then
    HandleVisibilityAnimation(Panel.MainFrame, Panel.MainFrame.Visible);
    if (Panel.Terminal.Visible) then HandleVisibilityAnimation(Panel.Terminal, true); end;
  end;
end);

DisplayFrame.Arguments.Execute.Interact.MouseButton1Up:Connect(function()
  local ArgumentsTable = {}

  -- Fill out ArgumentsTable with the information provided
  for _, Argument in DisplayFrame.Arguments:GetChildren() do
    if (not Argument:IsA("Frame") or Argument.Name == "InputField" or Argument.Name == "Execute" or Argument.Name == "BoolField" or Argument.Name == "ItemField") then
      continue;
    end;

    if (Argument:GetAttribute("DataType") == "string") then
      ArgumentsTable[Argument.Name] = Argument.TextBox.Text;
    elseif (Argument:GetAttribute("DataType") == "bool") then
      ArgumentsTable[Argument.Name] = Argument.TextButton:GetAttribute("Status");
    elseif (Argument:GetAttribute("DataType") == "number") then
      ArgumentsTable[Argument.Name] = tonumber(Argument.TextBox.Text);
    elseif (Argument:GetAttribute("DataType") == "itemselector") then
      ArgumentsTable[Argument.Name] = Argument.TextButton.Text;
    end;
  end;

  -- Execute command
  Shared.RunCommand(CommandVisible, PlayersSelected, ArgumentsTable);
  PlayersSelected = {};
  RefreshPlayerList();
end);

for Name, PluginTable in PluginsName do
  local ButtonList;

  if not PluginsList:FindFirstChild(Name) then
    local DisplayButton = PluginsList.Settings:Clone();
    DisplayButton.Parent = PluginsList;
    DisplayButton.TextLabel.Text = Name;
    DisplayButton.Name = Name;

    ButtonList = DisplayFrame.Buttons.Template:Clone();
    ButtonList.Name = Name;
    ButtonList.Parent = DisplayFrame.Buttons;
  end;

  for P_Name, Plugin in PluginTable do
    if (P_Name == "Name" or P_Name == "Descriptions" or P_Name == "RequireExArguments") then
      continue;
    end;

    local PluginButton = ButtonList.TextButton:Clone();
    PluginButton.Name = Plugin;
    PluginButton.Text = string.gsub(Plugin, "_", " ");
    PluginButton.Parent = ButtonList;
    PluginButton.Visible = true;

    PluginButton.MouseButton1Up:Connect(function()
      if (CurrentCommand) then
        CurrentCommand.BackgroundColor3 = Color3.fromRGB(47, 47, 47);
        CurrentCommand.BackgroundTransparency = 0;
      end;

      CurrentCommand = PluginButton;
      PluginButton.BackgroundColor3 = Color3.fromRGB(0, 255, 127);
      PluginButton.BackgroundTransparency = 0.8;

      for _, v in DisplayFrame.Arguments:GetChildren() do
        if (v.Name ~= "Execute" and v:IsA("Frame") and v.Name ~= "InputField" and v.Name ~= "BoolField" and v.Name ~= "ItemField") then
          v:Destroy();
        end;
      end;

      if (PluginTable.RequireExArguments[Plugin]) then
        for Index, RequiredData in PluginTable.RequireExArguments[Plugin] do
          for FieldName, FieldType in RequiredData do
            local FieldTemplate;

            if (FieldType == "string" or FieldType == "number") then
              FieldTemplate = DisplayFrame.Arguments.InputField:Clone();
            elseif (FieldType == "bool") then
              FieldTemplate = DisplayFrame.Arguments.BoolField:Clone();

              FieldTemplate.TextButton.MouseButton1Up:Connect(function()
                FieldTemplate.TextButton:SetAttribute("Status", not FieldTemplate.TextButton:GetAttribute("Status"));
                local NewColor = FieldTemplate.TextButton:GetAttribute("Status") and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0);
                FieldTemplate.TextButton.BackgroundColor3 = NewColor;
              end);
            elseif (typeof(FieldType) == "table" and FieldType.Type == "itemselector") then
              FieldTemplate = DisplayFrame.Arguments.ItemField:Clone();
              SetupItemSelector(FieldType.Instances, FieldTemplate);
            end;

            FieldTemplate:SetAttribute("DataType", typeof(FieldType) == "table" and FieldType.Type or FieldType);
            FieldTemplate.Parent = DisplayFrame.Arguments;
            FieldTemplate.TextLabel.Text = FieldName;
            FieldTemplate.Name = FieldName;
            FieldTemplate.Visible = true;
          end;
        end;
      end;

      CommandVisible = Plugin;
      DisplayFrame.Arguments.Execute.Visible = true;

      DisplayFrame.Arguments.CanvasSize = UDim2.fromOffset(0, DisplayFrame.Arguments.UIListLayout.AbsoluteContentSize.Y);
    end);
  end;
end;

for _, Button in PluginsList:GetChildren() do
  if (not Button:IsA("TextButton")) then
    continue;
  end;

  Button.MouseButton1Up:Connect(function()
    --[[Shared.RunCommand(Button.Name, PlayersSelected)
    PlayersSelected = {}
    RefreshPlayerList()]]
    ChangePluginShown(DisplayFrame.Buttons[Button.Name]);
    game:GetService("RunService").RenderStepped:Wait();
    DisplayFrame.Buttons.CanvasSize = UDim2.fromOffset(0, DisplayFrame.Buttons[Button.Name].UIListLayout.AbsoluteContentSize.Y);
  end);
end;

if (Panel:GetAttribute("AlwaysOnTop")) then
  Shared.SetHighestDisplayOrder();
end;

Panel:SetAttribute("ResizingEnabled", true);
Panel:SetAttribute("OutputOnExecution", true);

PluginsList.Parent.CanvasSize = UDim2.new(UDim2.fromOffset(0, PluginsList.UIListLayout.AbsoluteContentSize.Y));
RefreshPlayerList();

while task.wait(1 / 30) do
  for _, v in Panel.MainFrame.PlayerList.Container:GetChildren() do
    if (not v:IsA("Frame") or v.Name == "Template") then
      continue;
    end;

    v.BackgroundTransparency = table.find(PlayersSelected, Players:FindFirstChild(v.Name)) and 0.8 or 1;
  end;
end;
