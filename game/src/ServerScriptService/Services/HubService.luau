local Players=game:GetService("Players")
local CollectionService=game:GetService("CollectionService")
local WorldConfig=require(game.ReplicatedStorage.Shared.WorldConfig)
local Hub={}
local pending={}
local function denyReason(player,profile,now)
	local c=player.Character;local hum=c and c:FindFirstChildOfClass("Humanoid")
	if not profile or not profile.Loaded or not hum or hum.Health<=0 then return "Return is unavailable right now." end
	if player:GetAttribute("Captured") or player:GetAttribute("InPvP") then return "Finish your encounter before returning." end
	if (profile.Wanted or 0)>0 or now-(player:GetAttribute("LastThreatDamageAt") or -math.huge)<WorldConfig.ReturnCombatLock then return "Escape pursuit before returning to your nest." end
	if now-(profile.LastReturnAt or -math.huge)<WorldConfig.ReturnCooldown then return "Return to Nest is cooling down." end
	return nil
end
function Hub.RequestReturn(player,profile,feedback)
	if pending[player] then return end
	local reason=denyReason(player,profile,os.clock())
	if reason then feedback:FireClient(player,"Toast",reason);return end
	local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local start=root.Position;pending[player]=true
	feedback:FireClient(player,"Toast","Returning to Nest… hold still for 2 seconds.")
	task.delay(WorldConfig.ReturnChannel,function()
		if not player.Parent then pending[player]=nil;return end
		local blocked=denyReason(player,profile,os.clock())
		if blocked or player.Character~=character or not root.Parent or (root.Position-start).Magnitude>12 then
			pending[player]=nil;feedback:FireClient(player,"Toast",blocked or "Return cancelled because you moved.");return
		end
		-- Request destination first. The character remains at its safe source while loading.
		if workspace.StreamingEnabled then
			local ok=pcall(function() player:RequestStreamAroundAsync(WorldConfig.SpawnPosition,4) end)
			if not ok then pending[player]=nil;feedback:FireClient(player,"Toast","The sanctuary could not load. Please try again.");return end
		end
		blocked=denyReason(player,profile,os.clock())
		if blocked or player.Character~=character or not root.Parent or (root.Position-start).Magnitude>12 then pending[player]=nil;return end
		profile.LastReturnAt=os.clock();profile.Boosting=false
		-- Position the physical root explicitly; character pivots can include displaced avatar parts.
		root.CFrame=CFrame.new(WorldConfig.SpawnPosition+Vector3.new(0,4,0))*CFrame.Angles(0,math.pi,0)
		root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
		profile.LastMovementPosition=root.Position;profile.LastMovementSampleAt=os.clock();profile.MovementSuspiciousUntil=0
		feedback:FireClient(player,"FlightReset")
		feedback:FireClient(player,"Toast","Welcome back to Sky Sanctuary!")
		pending[player]=nil
	end)
end
function Hub.Bind(world,profiles,feedback)
	for _,tag in ipairs({"ReturnToHub","HubInteraction"}) do
		for _,marker in ipairs(CollectionService:GetTagged(tag)) do
			if marker:IsDescendantOf(world) then
				local prompt=Instance.new("ProximityPrompt");prompt.Name="HubPrompt";prompt.ActionText=tag=="ReturnToHub" and "Return to Nest" or "Open";prompt.ObjectText=marker:GetAttribute("Page") or "Sky Sanctuary"
				prompt.MaxActivationDistance=15;prompt.RequiresLineOfSight=false;prompt.KeyboardKeyCode=Enum.KeyCode.E;prompt.Parent=marker
				prompt.Triggered:Connect(function(player)
					local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
					if not r or not hum or hum.Health<=0 or (r.Position-marker.Position).Magnitude>17 or player:GetAttribute("Captured") then return end
					if tag=="ReturnToHub" then Hub.RequestReturn(player,profiles[player],feedback) else feedback:FireClient(player,"OpenPage",marker:GetAttribute("Page")) end
				end)
			end
		end
	end
	Players.PlayerRemoving:Connect(function(player) pending[player]=nil end)
end
return Hub
