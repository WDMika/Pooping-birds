-- Populate only districts near live birds, with global caps and despawn hysteresis.
local Players=game:GetService("Players")
local WorldConfig=require(game.ReplicatedStorage.Shared.WorldConfig)
local Population={}
function Population.Start(world,makeNPC,makeDog)
	local settings=WorldConfig.Population
	local routes={};local dogMarkers={}
	for _,marker in ipairs(world.Gameplay.NPCSpawns:GetChildren()) do
		local name=marker:GetAttribute("District");routes[name]=routes[name] or {};table.insert(routes[name],marker)
	end
	for _,route in pairs(routes) do table.sort(route,function(a,b) return a:GetAttribute("RouteIndex")<b:GetAttribute("RouteIndex") end) end
	for _,marker in ipairs(world.Gameplay.DogSpawns:GetChildren()) do
		local name=marker:GetAttribute("District");dogMarkers[name]=dogMarkers[name] or {};table.insert(dogMarkers[name],marker)
	end
	local active={};local serial=0
	local colors={Color3.fromRGB(239,137,116),Color3.fromRGB(92,164,211),Color3.fromRGB(240,191,86),Color3.fromRGB(133,185,127)}
	local function spawnCitizen(district,index,route)
		serial+=1;local marker=route[(index-1)%#route+1]
		local model,hum,root=makeNPC(world.Citizens,"Citizen_"..serial,marker.Position,"Citizen",colors[(index-1)%#colors+1])
		model:SetAttribute("District",district);root:SetNetworkOwner(nil)
		task.spawn(function()
			local step=(index-1)%#route+1
			while model.Parent and hum.Health>0 do
				step=step%#route+1;hum:MoveTo(route[step].Position);task.wait(5+(index%3))
			end
		end)
		return model
	end
	task.spawn(function()
		while world.Parent do
			local positions={}
			for _,p in ipairs(Players:GetPlayers()) do
				local c=p.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
				if r and h and h.Health>0 and not WorldConfig.IsHub(r.Position) then table.insert(positions,r.Position) end
			end
			local candidates={}
			for _,name in ipairs(WorldConfig.DistrictOrder) do
				local nearest=math.huge
				for _,pos in ipairs(positions) do
					for _,marker in ipairs(routes[name] or {}) do nearest=math.min(nearest,(marker.Position-pos).Magnitude) end
				end
				if active[name] and nearest>settings.DespawnRange then
					for _,npc in ipairs(active[name]) do if npc.Parent then npc:Destroy() end end;active[name]=nil
				end
				if nearest<=settings.ActivationRange then table.insert(candidates,{Name=name,Distance=nearest}) end
			end
			table.sort(candidates,function(a,b) return a.Distance<b.Distance end)
			local citizenCount=#world.Citizens:GetChildren();local dogCount=#world.Dogs:GetChildren()
			for _,candidate in ipairs(candidates) do
				local name=candidate.Name
				if not active[name] then
					local population={};local d=WorldConfig.Districts[name];local route=routes[name]
					for i=1,math.min(d.Citizens,settings.CitizenCap-citizenCount) do
						if route and #route>0 then table.insert(population,spawnCitizen(name,i,route));citizenCount+=1 end
					end
					for i,marker in ipairs(dogMarkers[name] or {}) do
						if dogCount>=settings.DogCap then break end
						serial+=1;local dog=makeDog(marker.Position,serial);dog:SetAttribute("District",name);table.insert(population,dog);dogCount+=1
					end
					-- Keep a full-cap district eligible for a later attempt.
					if #population>0 then active[name]=population end
				end
			end
			task.wait(settings.UpdateInterval)
		end
	end)
end
function Population.Flee(model)
	local hum=model:FindFirstChildOfClass("Humanoid");local root=model:FindFirstChild("HumanoidRootPart")
	if hum and root then
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={model}
		local destination=root.Position+Vector3.new(math.random(-30,30),0,math.random(-30,30))
		if not workspace:Raycast(root.Position,destination-root.Position,params) then hum:MoveTo(destination) end
	end
end
return Population
