local Maps= {}
NoMaps = {}
local Voted = false
local Nominate = false
local MapList = {}
local LastVote = ""
local teal = Color( 98, 176, 255, 255 )
local DFrame

function MapsHook( len )
	local decoded = net.ReadTable()
	for k, v in pairs(decoded) do
		table.insert(Maps, string.Trim(v))
	end
end
net.Receive( "MapsHook", MapsHook )

function MapsHook2( len )
	local decoded = net.ReadTable()
	for k, v in pairs(decoded) do
		table.insert(NoMaps, string.Trim(v))
	end
end
net.Receive( "MapsHook2", MapsHook2 )

surface.CreateFont( "default_popup", {
	font = "Arial",
	size = 23,
	weight = 500,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false } )

function RTVHud()
	if Voted == true then
		draw.RoundedBox( 6, -10, ScrH()/2-20, 355, 40, Color( 50, 10, 10, 190 ) )
		draw.SimpleTextOutlined("Press F4 to open your voting menu.", "default_popup", 10, ScrH()/2, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0, Color(255,255,255,255))
	elseif Nominate == true then
		draw.RoundedBox( 6, -10, ScrH()/2-20, 375, 40, Color( 50, 10, 10, 190 ) )
		draw.SimpleTextOutlined("Press F4 to open your nominate menu.", "default_popup", 10, ScrH()/2, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 0, Color(255,255,255,255))
	end
end
hook.Add("HUDPaint", "RTVHudHook", RTVHud)


function RTVHook( len )
	local decoded = net.ReadTable()
	Nominate = false
	LastVote = ""
	if ValidPanel(DFrame) then
		DFrame:SetVisible(false)
		DFrame:Remove()
	end
	if Voted == false then
		Voted = true
		for k, v in pairs(decoded) do
			MapList[k] = v
		end
	else
		Voted = false
	end
end
net.Receive( "RTVHook", RTVHook )


function NominateHook( len )
	Nominate = true
end
net.Receive( "NominateHook", NominateHook )


function F4Hook( len )
	if Voted == true then
		CreateRTVDerma()
	elseif Nominate == true then
		CreateNominateDerma()
	end
end
net.Receive( "F4Hook", F4Hook )


function CreateRTVDerma()
	local Next
	local Previous
	
	DFrame = vgui.Create( "DFrame" )
	DFrame:SetSize( 300,400 )
	DFrame:SetPos( 30, 30 )
	DFrame:SetTitle( "Rock The Vote" )
	DFrame:MakePopup()
	
	local Grid = vgui.Create( "DGrid", DFrame )
	Grid:SetPos( 10, 50 )
	Grid:SetCols( 1 )
	Grid:SetColWide( 280 )
	
	for k, v in pairs(MapList) do
		local Button = vgui.Create( "DButton", Grid )
		Button:SetSize( 280, 30 )
		Button:SetText( v )
		Button.DoClick = function( Button )
			local Changed = false
			if LastVote != "" then
				Changed = true
				net.Start( "LastMap" )
				net.WriteString( LastVote )
				net.SendToServer()
			end
			LastVote = v
			net.Start( "SendVote" )
			net.WriteTable( {LastVote, Changed} )
			net.SendToServer()
			if ValidPanel(DFrame) then
				DFrame:SetVisible(false)
				DFrame:Remove()
			end
		end
		Grid:AddItem( Button )
	end
	
	local Button2 = vgui.Create( "DButton", Grid )
	Button2:SetSize( 280, 30 )
	Button2:SetText( "Close" )
	Button2.DoClick = function( Button2 )
		if ValidPanel(DFrame) then
			DFrame:SetVisible(false)
			DFrame:Remove()
		end
	end
	Grid:AddItem( Button2 )
end


function CreateNominateDerma()
	local Page = 1

	DFrame = vgui.Create( "DFrame" )
	DFrame:SetSize( 300,400 )
	DFrame:SetPos( 30, 30 )
	DFrame:SetTitle( "Nominate" )
	DFrame:ShowCloseButton(false)
	DFrame:MakePopup()
	
	local Grid = vgui.Create( "DGrid", DFrame )
	Grid:SetPos( 10, 50 )
	Grid:SetCols( 1 )
	Grid:SetColWide( 280 )
	
	local TextEntry = vgui.Create("DTextEntry", DFrame)
	TextEntry:SetText("")
	TextEntry:SetPos(10, 30)
	TextEntry:SetWide(280)
	TextEntry.OnEnter = function()
		local Found
		local Stop = false
		local No = false
		for k, v in pairs(Maps) do
			if string.find(string.Trim(string.lower(v)), TextEntry:GetValue()) and Found == nil and !table.HasValue(NoMaps, string.Trim(v)) then
				Found = v
			elseif string.find(string.Trim(string.lower(v)), TextEntry:GetValue()) and Found == nil and table.HasValue(NoMaps, string.Trim(v)) then
				Found = v
				No = true
			elseif string.find(v, TextEntry:GetValue()) and Found != nil then
				Stop = true
				break
			end
		end
		if Found != nil and Stop == false and No == false then
			local Changed = false
			if LastVote != "" then
				Changed = true
			end
			local temp = LastVote
			LastVote = Found
			net.Start( "SendNominate" )
			net.WriteString(LastVote)
			net.SendToServer()

			Nominate = false
		elseif Found == nil then
			evolve:Notify(LocalPlayer(), teal, "That is not a valid map.")
		elseif Stop == true then
			evolve:Notify(LocalPlayer(), teal, "There are multiple maps with that name.")
		elseif No == true then
			evolve:Notify(LocalPlayer(), teal, "That map has been played recently.")
		end
	end
	
	local Button1 = vgui.Create( "DButton", Grid )
	Button1:SetSize( 280, 30 )
	Button1:SetText( "Nominate Above Text" )
	Button1.DoClick = function( Button1 )
		local Found
		local Stop = false
		local No = false
		for k, v in pairs(Maps) do
			if string.find(string.Trim(string.lower(v)), TextEntry:GetValue()) and Found == nil and !table.HasValue(NoMaps, string.Trim(v)) then
				Found = v
			elseif string.find(string.Trim(string.lower(v)), TextEntry:GetValue()) and Found == nil and table.HasValue(NoMaps, string.Trim(v)) then
				Found = v
				No = true
			elseif string.find(v, TextEntry:GetValue()) and Found != nil then
				Stop = true
				break
			end
		end
		if Found != nil and Stop == false and No == false then
			local Changed = false
			if LastVote != "" then
				Changed = true
			end
			local temp = LastVote
			LastVote = Found
			net.Start( "SendNominate" )
			net.WriteString(LastVote)
			net.SendToServer()

			if ValidPanel(DFrame) then
				DFrame:SetVisible(false)
				DFrame:Remove()
			end
			Nominate = false
		elseif Found == nil then
			evolve:Notify(LocalPlayer(), teal, "That is not a valid map.")
		elseif Stop == true then
			evolve:Notify(LocalPlayer(), teal, "There are multiple maps with that name.")
		elseif No == true then
			evolve:Notify(LocalPlayer(), teal, "That map has been played recently.")
		end
	end
	Grid:AddItem( Button1 )
	
	local ButtonList = {}
	for i = 1, 5 do
		ButtonList[i] = vgui.Create( "DButton", Grid )
		ButtonList[i]:SetSize( 280, 30 )
		ButtonList[i]:SetText( Maps[i+5*(Page-1)] )
		if table.HasValue(NoMaps, string.Trim(Maps[i+5*(Page-1)])) then
			ButtonList[i]:SetDisabled(true)
		end
		ButtonList[i].DoClick = function(  )
			local Changed = false
			if LastVote != "" then
				Changed = true
			end
			local temp = LastVote
			LastVote = Maps[i+5*(Page-1)]
			net.Start( "SendNominate" )
			net.WriteString(LastVote)
			net.SendToServer()

			if ValidPanel(DFrame) then
				DFrame:SetVisible(false)
				DFrame:Remove()
			end
			Nominate = false
		end
		Grid:AddItem( ButtonList[i] )
	end
	
	Next = vgui.Create( "DButton", Grid )
	Next:SetSize( 280, 30 )
	Next:SetText( "Next" )
	Next.DoClick = function( Next )
		Page = Page + 1
		Previous:SetDisabled(false)
		for i = 1, 5 do
			if Maps[i+5*(Page-1)] != nil then
				ButtonList[i]:SetText( Maps[i+5*(Page-1)] )
				ButtonList[i]:SetDisabled(false)
				if table.HasValue(NoMaps, string.Trim(Maps[i+5*(Page-1)])) then
					ButtonList[i]:SetDisabled(true)
				end
				ButtonList[i].DoClick = function(  )
					local Changed = false
					if LastVote != "" then
						Changed = true
					end
					local temp = LastVote
					LastVote = Maps[i+5*(Page-1)]
					net.Start( "SendNominate" )
					net.WriteString(LastVote)
					net.SendToServer()

					if ValidPanel(DFrame) then
						DFrame:SetVisible(false)
						DFrame:Remove()
					end
					Nominate = false
				end
			else
				ButtonList[i]:SetText( "" )
				ButtonList[i]:SetDisabled(true)
				Next:SetDisabled(true)
			end
		end
	end
	Grid:AddItem( Next )
	
	Previous = vgui.Create( "DButton", Grid )
	Previous:SetSize( 280, 30 )
	Previous:SetText( "Previous" )
	Previous:SetDisabled(true)
	Previous.DoClick = function( Previous )
		Page = Page - 1
		if Page == 1 then
			Previous:SetDisabled(true)
		end
		Next:SetDisabled(false)
		for i = 1, 5 do
			ButtonList[i]:SetText( Maps[i+5*(Page-1)] )
			ButtonList[i]:SetDisabled(false)
			if table.HasValue(NoMaps, string.Trim(Maps[i+5*(Page-1)])) then
				ButtonList[i]:SetDisabled(true)
			end
			ButtonList[i].DoClick = function(  )
				local Changed = false
				if LastVote != "" then
					Changed = true
				end
				local temp = LastVote
				LastVote = Maps[i+5*(Page-1)]
				net.Start( "SendNominate" )
				net.WriteString(LastVote)
				net.SendToServer()

				Nominate = false
				if ValidPanel(DFrame) then
					DFrame:SetVisible(false)
					DFrame:Remove()
				end
			end
		end
	end
	Grid:AddItem( Previous )
	
	local Button2 = vgui.Create( "DButton", Grid )
	Button2:SetSize( 280, 30 )
	Button2:SetText( "Close" )
	Button2.DoClick = function( Button2 )
		if ValidPanel(DFrame) then
			DFrame:SetVisible(false)
			DFrame:Remove()
		end
		Nominate = false
	end
	Grid:AddItem( Button2 )
end