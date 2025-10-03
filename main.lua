--[[
	DataToCode - Make DataTypes actually readable

	Created by: https://github.com/78n
	License: https://github.com/78n/Roblox/blob/main/LICENSE | Covered by MIT

	A little background about the coding style:
		I sometimes use next to avoid invoking __call/__iter in tables that I dont know the orgin of
		This has been rewritten like 3 seperate times
		The reason I don't use string interpolation is because it is very slow
		I dont use a giant if then elseif in my Serializer function as it is not as maintainable/scaleable as a dictionary of methods
]]
--!optimize 2
--!native

local assert, type, typeof, rawset, getmetatable, tostring = assert, type, typeof, rawset, getmetatable, tostring
local print, warn, pack, unpack, next = print, warn, table.pack, unpack, next

local IsSharedFrozen, SharedSize = SharedTable.isFrozen, SharedTable.size
local bufftostring, fromstring, readu8 = buffer.tostring, buffer.fromstring, buffer.readu8
local isfrozen, concat = table.isfrozen, table.concat
local info = debug.info

local DefaultMethods = {}
local Methods = setmetatable({}, {__index = DefaultMethods})
local Class = {
	Methods = Methods,
	_tostringUnsupported = false, -- whether or not to tostring unsupported types
	_Serializeinf = false,
	__VERSION = "1.0"
}

local Keywords = {
	["local"] = "\"local\"",
	["function"] = "\"function\"",
	--	["type"] = "\"type\"",
	--	["typeof"] = "\"typeof\"",
	--	["export"] = "\"export\"",
	--	["continue"] = "\"continue\"",
	["and"] = "\"and\"",
	["break"] = "\"break\"",
	["not"] = "\"not\"",
	["or"] = "\"or\"",
	["else"] = "\"else\"",
	["elseif"] = "\"elseif\"",
	["if"] = "\"if\"",
	["then"] = "\"then\"",
	["until"] = "\"until\"",
	["repeat"] = "\"repeat\"",
	["while"] = "\"while\"",
	["do"] = "\"do\"",
	["for"] = "\"for\"",
	["in"] = "\"in\"",
	["end"] = "\"end\"",
	["return"] = "\"return\"",
	["true"] = "\"true\"",
	["false"] = "\"false\"",
	["nil"] = "\"nil\""
}

local weakkeys = {__mode = "k"}

local islclosure = islclosure or function<func>(Function : func)
	return info(Function, "l") ~= -1
end

local DefaultVectors, DefaultCFrames = {}, {} do
	local function ExtractTypes<Library>(DataTypeLibrary : Library, Path : string, DataType : string, Storage : {[any] : string})
		for i,v in next, DataTypeLibrary do
			if typeof(v) == DataType and not Storage[v] and type(i) == "string" and not Keywords[i] or not i:match("[a-Z_][a-Z_0-9]") then
				Storage[v] = Path.."."..i
			end
		end
	end

	ExtractTypes(vector, "vector", "Vector3", DefaultVectors)
	ExtractTypes(Vector3, "Vector3", "Vector3", DefaultVectors)
	ExtractTypes(CFrame, "CFrame", "CFrame", DefaultCFrames)

	Class.DefaultTypes = {
		Vector3 = DefaultVectors,
		CFrame = DefaultCFrames,
	}
end

local function Serialize<Type>(DataStructure : Type, format : boolean?, indents : string, CyclicList : {[{[any] : any?}] : boolean | nil}?, InComment : boolean?)
	local DataHandler = Methods[typeof(DataStructure)]

	return if DataHandler then DataHandler(DataStructure, format, indents, CyclicList, InComment) else "nil --["..(if InComment then "" else "=").."[ Unsupported Data Type | "..typeof(DataStructure)..(if not Class._tostringUnsupported then "" else " | "..tostring(DataStructure)).." ]"..(if not InComment then "" else "=").."]"
end

local function ValidateSharedTableIndex(Index : string)
	local IsKeyword = if type(Index) == "number" then Index else Keywords[Index]

	if not IsKeyword then
		if Index ~= "" then
			local IndexBuffer = fromstring(Index)
			local FirstByte = readu8(IndexBuffer, 0)

			if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
				for i = 1, #Index-1 do
					local Byte = readu8(IndexBuffer, i)

					if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
						return "["..Methods.string(Index).."] = "
					end
				end

				return Index.." = "
			end

			return "["..Methods.string(Index).."] = "
		end

		return "[\"\"] = "
	end

	return "["..IsKeyword.."] = "
end

local function ValidateIndex(Index : any)
	local IndexType = type(Index)
	local IsNumber = IndexType == "number"

	if IsNumber or IndexType == "string" then
		local IsKeyword = if IsNumber then Index else Keywords[Index]

		if not IsKeyword then
			if Index ~= "" then
				local IndexBuffer = fromstring(Index)
				local FirstByte = readu8(IndexBuffer, 0)

				if FirstByte >= 97 and FirstByte <= 122 or FirstByte >= 65 and FirstByte <= 90 or FirstByte == 95 then
					for i = 1, #Index-1 do
						local Byte = readu8(IndexBuffer, i)

						if not ((Byte >= 97 and Byte <= 122) or (Byte >= 65 and Byte <= 90) or Byte == 95 or (Byte >= 48 and Byte <= 57)) then
							return "["..Methods.string(Index).."] = "
						end
					end

					return Index.." = "
				end

				return "["..Methods.string(Index).."] = "
			end

			return "[\"\"] = "
		end

		return "["..IsKeyword.."] = "
	end

	return "["..(if IndexType ~= "table" then Serialize(Index, false, "") else "\"<Table> (table: "..(if getmetatable(Index) == nil then tostring(Index):sub(8) else "@metatable")..")\"").."] = "
end

function DefaultMethods.Axes(Axes : Axes)
	return "Axes.new("..concat({
		if Axes.X then "Enum.Axis.X" else nil,
		if Axes.Y then "Enum.Axis.Y" else nil,
		if Axes.Z then "Enum.Axis.Z" else nil
	},", ")..")"
end

function DefaultMethods.BrickColor(Color : BrickColor)
	return "BrickColor.new("..Color.Number..")"
end

function DefaultMethods.CFrame(CFrame : CFrame)
	local Generation = DefaultCFrames[CFrame]

	if not Generation then
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = CFrame:GetComponents()
		local SerializeNumber = Methods.number

		return "CFrame.new("..SerializeNumber(x)..", "..SerializeNumber(y)..", "..SerializeNumber(z)..", "..SerializeNumber(R00)..", "..SerializeNumber(R01)..", "..SerializeNumber(R02)..", "..SerializeNumber(R10)..", "..SerializeNumber(R11)..", "..SerializeNumber(R12)..", "..SerializeNumber(R20)..", "..SerializeNumber(R21)..", "..SerializeNumber(R22)..")"
	end

	return Generation
end

do
	local DefaultCatalogSearchParams = CatalogSearchParams.new()
	function DefaultMethods.CatalogSearchParams(Params : CatalogSearchParams, format : boolean?, indents : string)
		if DefaultCatalogSearchParams ~= Params then
			local formatspace = if format then "\n"..indents else " "
			local SerializeString = Methods.string
			local SearchKeyword = Params.SearchKeyword
			local MinPrice = Params.MinPrice
			local MaxPrice = Params.MaxPrice
			local SortType = Params.SortType
			local SortAggregation = Params.SortAggregation
			local CategoryFilter = Params.CategoryFilter
			local SalesTypeFilter = Params.SalesTypeFilter
			local BundleTypes = Params.BundleTypes
			local AssetTypes = Params.AssetTypes
			local CreatorName = Params.CreatorName
			local CreatorType = Params.CreatorType
			local CreatorId = Params.CreatorId
			local Limit = Params.Limit

			return "(function(Param : CatalogSearchParams)"..formatspace..(if SearchKeyword ~= "" then "\tParam.SearchKeyword = "..SerializeString(SearchKeyword)..formatspace else "")..(if MinPrice ~= 0 then "\tParam.MinPrice = "..MinPrice..formatspace else "")..(if MaxPrice ~= 2147483647 then "\tParam.MaxPrice = "..MaxPrice..formatspace else "")..(if SortType ~= Enum.CatalogSortType.Relevance then "\tParam.SortType = Enum.CatalogSortType."..SortType.Name..formatspace else "")..(if SortAggregation ~= Enum.CatalogSortAggregation.AllTime then "\tParam.SortAggregation = Enum.CatalogSortAggregation."..SortAggregation.Name..formatspace else "")..(if CategoryFilter ~= Enum.CatalogCategoryFilter.None then "\tParam.CategoryFilter = Enum.CatalogCategoryFilter."..CategoryFilter.Name..formatspace else "")..(if SalesTypeFilter ~= Enum.SalesTypeFilter.All then "\tParam.SalesTypeFilter = Enum.SalesTypeFilter."..SalesTypeFilter.Name..formatspace else "")..(if #BundleTypes > 0 then "\tParam.BundleTypes = "..Methods.table(BundleTypes, false, "")..formatspace else "")..(if #AssetTypes > 0 then "\tParam.AssetTypes = "..Methods.table(AssetTypes, false, "")..formatspace else "")..(if Params.IncludeOffSale then "\tParams.IncludeOffSale = true"..formatspace else "")..(if CreatorName ~= "" then "\tParams.CreatorName = "..SerializeString(CreatorName)..formatspace else "")..(if CreatorType ~= Enum.CreatorTypeFilter.All then "\tParam.CreatorType = Enum.CreatorTypeFilter."..CreatorType.Name..formatspace else "")..(if CreatorId ~= 0 then "\tParams.CreatorId = "..CreatorId..formatspace else "")..(if Limit ~= 30 then "\tParams.Limit = "..Limit..formatspace else "").."\treturn Params"..formatspace.."end)(CatalogSearchParams.new())"
		end

		return "CatalogSearchParams.new()"
	end
end

function DefaultMethods.Color3(Color : Color3)
	local SerializeNumber = Methods.number

	return "Color3.new("..SerializeNumber(Color.R)..", "..SerializeNumber(Color.G)..", "..SerializeNumber(Color.B)..")"
end

function DefaultMethods.ColorSequence(Sequence : ColorSequence)
	local SerializeColorSequenceKeypoint = Methods.ColorSequenceKeypoint
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= SerializeColorSequenceKeypoint(Keypoints[i])..", "
	end

	return "ColorSequence.new({"..Serialized..SerializeColorSequenceKeypoint(Keypoints[Size]).."})"
end

function DefaultMethods.ColorSequenceKeypoint(KeyPoint : ColorSequenceKeypoint)
	return "ColorSequenceKeypoint.new("..Methods.number(KeyPoint.Time)..", "..Methods.Color3(KeyPoint.Value)..")"
end

function DefaultMethods.Content(content : Content)
	local Uri = content.Uri

	return if Uri then "Content.fromUri("..Uri..")" else "Content.none"
end

function DefaultMethods.DateTime(Date : DateTime)
	return "DateTime.fromUnixTimestampMillis("..Date.UnixTimestampMillis..")"
end

function DefaultMethods.DockWidgetPluginGuiInfo(Dock : DockWidgetPluginGuiInfo)
	local ArgumentFunction = tostring(Dock):gmatch(":([%w%-]+)")

	return "DockWidgetPluginGuiInfo.new(Enum.InitialDockState."..ArgumentFunction()..", "..(if ArgumentFunction() == "1" then "true" else "false")..", "..(if ArgumentFunction() == "1" then "true" else "false")..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..", "..ArgumentFunction()..")"
end

function DefaultMethods.Enum(Enum : Enum)
	return "Enums."..tostring(Enum)
end

do
	local Enums = {}

	for i,v in Enum:GetEnums() do
		Enums[v] = "Enum."..tostring(v)
	end

	function DefaultMethods.EnumItem(Item : EnumItem)
		return Enums[Item.EnumType].."."..Item.Name
	end
end

function DefaultMethods.Enums()
	return "Enums"
end

function DefaultMethods.Faces(Faces : Faces)
	return "Faces.new("..concat({
		if Faces.Top then "Enum.NormalId.Top" else nil,
		if Faces.Bottom then "Enum.NormalId.Bottom" else nil,
		if Faces.Left then "Enum.NormalId.Left" else nil,
		if Faces.Right then "Enum.NormalId.Right" else nil,
		if Faces.Back then "Enum.NormalId.Back" else nil,
		if Faces.Front then "Enum.NormalId.Front" else nil,
	}, ", ")..")"
end

function DefaultMethods.FloatCurveKey(CurveKey : FloatCurveKey)
	local SerializeNumber = Methods.number

	return "FloatCurveKey.new("..SerializeNumber(CurveKey.Time)..", "..SerializeNumber(CurveKey.Value)..", Enum.KeyInterpolationMode."..CurveKey.Interpolation.Name..")"
end

function DefaultMethods.Font(Font : Font)
	return "Font.new("..Methods.string(Font.Family)..", Enum.FontWeight."..Font.Weight.Name..", Enum.FontStyle."..Font.Style.Name..")"
end

do
	local Players = game:GetService("Players")
	local FindService = game.FindService

	local Services = {
		Workspace = "workspace",
		Lighting = "game.lighting",
		GlobalSettings = "settings()",
		Stats = "stats()",
		UserSettings = "UserSettings()",
		PluginManagerInterface = "PluginManager()",
		DebuggerManager = "DebuggerManager()"
	}

	if game:GetService("RunService"):IsClient() then
		local LocalPlayer = Players.LocalPlayer

		if not LocalPlayer then
			Players:GetPropertyChangedSignal("LocalPlayer"):Once(function()
				LocalPlayer = Players.LocalPlayer
			end)
		end

		-- Not garenteed to return the correct generation
		function DefaultMethods.Instance(obj : Instance) -- Client
			local ObjectParent = obj.Parent
			local ObjectClassName = obj.ClassName

			if ObjectParent then
				local ObjectName = Methods.string(obj.Name)

				if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
					local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

					return if not (IsService and Output) then Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" else Services[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
				elseif ObjectClassName == "Model" then
					local Player = Players:GetPlayerFromCharacter(obj)

					return if not Player then Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" else "game:GetService(\"Players\")".. (if Player == LocalPlayer then ".LocalPlayer.Character" else ":WaitForChild("..ObjectName..").Character")
				end

				return "game:GetService(\"Players\")".. (if obj == LocalPlayer then ".LocalPlayer" else ":WaitForChild("..ObjectName..")") 
			end

			return if ObjectClassName == "DataModel" then "game" else "Instance.new(\""..ObjectClassName.."\", nil)"
		end
	else
		function DefaultMethods.Instance(obj : Instance) -- Server
			local ObjectParent = obj.Parent
			local ObjectClassName = obj.ClassName

			if ObjectParent then
				local ObjectName = Methods.string(obj.Name)

				if ObjectClassName ~= "Model" and ObjectClassName ~= "Player" then
					local IsService, Output = pcall(FindService, game, ObjectClassName) -- Generation can and will break when presented with noncreatable Instances such as Path (which is created by PathService:CreateAsync())

					return if not (IsService and Output) then Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" else Services[ObjectClassName] or "game:GetService(\""..ObjectClassName.."\")"
				elseif ObjectClassName == "Model" then
					local Player = Players:GetPlayerFromCharacter(obj)

					return if not Player then Methods.Instance(ObjectParent)..":WaitForChild("..ObjectName..")" else "game:GetService(\"Players\"):WaitForChild("..ObjectName..").Character"
				end

				return "game:GetService(\"Players\"):WaitForChild("..ObjectName..")"
			end

			return if ObjectClassName == "DataModel" then "game" else "Instance.new(\""..ObjectClassName.."\", nil)"
		end
	end

	Class.Services = Services
end

function DefaultMethods.NumberRange(Range : NumberRange)
	local SerializeNumber = Methods.number

	return "NumberRange.new("..SerializeNumber(Range.Min)..", "..SerializeNumber(Range.Max)..")"
end

function DefaultMethods.NumberSequence(Sequence : NumberSequence)
	local SerializeNumberSequenceKeypoint = Methods.NumberSequenceKeypoint
	local Keypoints = Sequence.Keypoints
	local Size = #Keypoints
	local Serialized = ""

	for i = 1, Size-1 do
		Serialized ..= SerializeNumberSequenceKeypoint(Keypoints[i])..", "
	end

	return "NumberSequence.new({"..Serialized..SerializeNumberSequenceKeypoint(Keypoints[Size]).."})"
end

do
	local DefaultOverlapParams = OverlapParams.new()
	function DefaultMethods.OverlapParams(Params : OverlapParams, format : boolean?, indents : string)
		if DefaultOverlapParams ~= Params then
			local formatspace = format and "\n"..indents or " "
			local FilterDescendantsInstances = Params.FilterDescendantsInstances
			local FilterType = Params.FilterType
			local CollisionGroup = Params.CollisionGroup

			return "(function(Param : OverlapParams)"..formatspace..(if #FilterDescendantsInstances > 0 then "\tParam.FilterDescendantsInstances = "..Methods.table(FilterDescendantsInstances, false, "")..formatspace else "")..(if FilterType ~= Enum.RaycastFilterType.Exclude then "\tParam.FilterType = Enum.RaycastFilterType."..FilterType.Name..formatspace else "")..(if CollisionGroup ~= "Default" then "\tParam.CollisionGroup = "..Methods.string(CollisionGroup)..formatspace else "")..(if Params.RespectCanCollide then "\tParam.RespectCanCollide = true"..formatspace else "")..(if Params.BruteForceAllSlow then "\tParam.BruteForceAllSlow = true"..formatspace else "").."\treturn Params"..formatspace.."end)(OverlapParams.new())"
		end

		return "OverlapParams.new()"
	end
end

function DefaultMethods.NumberSequenceKeypoint(Keypoint : NumberSequenceKeypoint)
	local SerializeNumber = Methods.number

	return "NumberSequenceKeypoint.new("..SerializeNumber(Keypoint.Time)..", "..SerializeNumber(Keypoint.Value)..", "..SerializeNumber(Keypoint.Envelope)..")"
end

function DefaultMethods.PathWaypoint(Waypoint : PathWaypoint)
	return "PathWaypoint.new("..Methods.Vector3(Waypoint.Position)..", Enum.PathWaypointAction."..Waypoint.Action.Name..", "..Methods.string(Waypoint.Label)..")"
end

do
	local function nanToString(num : number)
		return if num == num then num else "0/0"
	end

	function DefaultMethods.PhysicalProperties(Properties : PhysicalProperties)
		return "PhysicalProperties.new("..(nanToString(Properties.Density))..", "..nanToString(Properties.Friction)..", "..nanToString(Properties.Elasticity)..", "..nanToString(Properties.FrictionWeight)..", "..nanToString(Properties.ElasticityWeight)..")"
	end
end

function DefaultMethods.RBXScriptConnection(Connection : RBXScriptConnection, _, _, _, InComment : boolean?)
	local CommentSeperator = if not InComment then "" else "="

	return "(nil --["..CommentSeperator.."[ RBXScriptConnection | IsConnected: "..(if Connection.Connected then "true" else "false").." ]"..CommentSeperator.."])" -- Can't support this
end

do
	local Signals = { -- You theoretically could serialize the api to retrieve most of the Signals but I don't believe that its worth it
		GraphicsQualityChangeRequest = "game.GraphicsQualityChangeRequest",
		AllowedGearTypeChanged = "game.AllowedGearTypeChanged",
		ScreenshotSavedToAlbum = "game.ScreenshotSavedToAlbum",
		UniverseMetadataLoaded = "game.UniverseMetadataLoaded",
		ScreenshotReady = "game.ScreenshotReady",
		ServiceRemoving = "game.ServiceRemoving",
		ServiceAdded = "game.ServiceAdded",
		ItemChanged = "game.ItemChanged",
		CloseLate = "game.CloseLate",
		Loaded = "game.Loaded",
		Close = "game.Close",

		RobloxGuiFocusedChanged = "game:GetService(\"RunService\").RobloxGuiFocusedChanged",
		PostSimulation = "game:GetService(\"RunService\").PostSimulation",
		RenderStepped = "game:GetService(\"RunService\").RenderStepped",
		PreSimulation = "game:GetService(\"RunService\").PreSimulation",
		PreAnimation = "game:GetService(\"RunService\").PreAnimation",
		PreRender = "game:GetService(\"RunService\").PreRender",
		Heartbeat = "game:GetService(\"RunService\").Heartbeat",
		Stepped = "game:GetService(\"RunService\").Stepped"
	}

	function DefaultMethods.RBXScriptSignal(Signal : RBXScriptSignal, _, _, _, InComment : boolean?)
		local CommentSeperator = if not InComment then "" else "="
		local SignalName = tostring(Signal):match("Signal ([A-z]+)")

		return Signals[SignalName] or "(nil --["..CommentSeperator.."[ RBXScriptSignal | "..SignalName.." is not supported ]"..CommentSeperator.."])"
	end

	Class.Signals = Signals
end

function DefaultMethods.Random(_, _, _, _, InComment : boolean?) -- Random cant be supported because I cant get the seed
	local CommentSeperator = if not InComment then "" else "="

	return "Random.new(--["..CommentSeperator.."[ <Seed> ]"..CommentSeperator.."])"
end

function DefaultMethods.Ray(Ray : Ray)
	local SerializeVector3 = Methods.Vector3

	return "Ray.new("..SerializeVector3(Ray.Origin)..", "..SerializeVector3(Ray.Direction)..")"
end

do
	local DefaultRaycastParams = RaycastParams.new()
	function DefaultMethods.RaycastParams(Params : RaycastParams, format : boolean?, indents : string)
		if DefaultRaycastParams ~= Params then
			local formatspace = format and "\n"..indents or " "
			local FilterDescendantsInstances = Params.FilterDescendantsInstances
			local FilterType = Params.FilterType
			local CollisionGroup = Params.CollisionGroup

			return "(function(Param : RaycastParams)"..formatspace..(if #FilterDescendantsInstances > 0 then "\tParam.FilterDescendantsInstances = "..Methods.table(FilterDescendantsInstances, false, "")..formatspace else "")..(if FilterType ~= Enum.RaycastFilterType.Exclude then "\tParam.FilterType = Enum.RaycastFilterType."..FilterType.Name..formatspace else "")..(if Params.IgnoreWater then "\tParam.IgnoreWater = true"..formatspace else "")..(if CollisionGroup ~= "Default" then "\tParam.CollisionGroup = "..Methods.string(CollisionGroup)..formatspace else "")..(if Params.RespectCanCollide then "\tParam.RespectCanCollide = true"..formatspace else "")..(if Params.BruteForceAllSlow then "\tParam.BruteForceAllSlow = true"..formatspace else "").."\treturn Params"..formatspace.."end)(RaycastParams.new())"
		end

		return "RaycastParams.new()"
	end
end

function DefaultMethods.Rect(Rect : Rect)
	local SerializeVector2 = Methods.Vector2

	return "Rect.new("..SerializeVector2(Rect.Min)..", "..SerializeVector2(Rect.Max)..")"
end

function DefaultMethods.Region3(Region : Region3)
	local SerializeVector3 = Methods.Vector3
	local Center = Region.CFrame.Position
	local Size = Region.Size/2

	return "Region3.new("..SerializeVector3(Center - Size)..", "..SerializeVector3(Center + Size)..")"
end

function DefaultMethods.Region3int16(Region : Region3int16)
	local SerializeVector3int16 = Methods.Vector3int16

	return "Region3int16.new("..SerializeVector3int16(Region.Min)..", "..SerializeVector3int16(Region.Max)..")"
end

function DefaultMethods.RotationCurveKey(Curve : RotationCurveKey)
	return "RotationCurveKey.new("..Methods.number(Curve.Time)..", "..Methods.CFrame(Curve.Value)..", Enum.KeyInterpolationMode."..Curve.Interpolation.Name..")"
end

function DefaultMethods.SharedTable(Shared : SharedTable, format : boolean?, indents : string, _, InComment : boolean?)
	local isreadonly = IsSharedFrozen(Shared)

	if SharedSize(Shared) ~= 0 then
		local stackindent = indents..(if format then "\t" else "")
		local CurrentIndex = 1
		local Serialized = {}

		for i,v in Shared do
			Serialized[CurrentIndex] = (if CurrentIndex ~= i then ValidateSharedTableIndex(i) else "")..Serialize(v, format, stackindent, nil, InComment)
			CurrentIndex += 1	
		end

		local formatspace = if format then "\n" else ""
		local Contents = formatspace..stackindent..concat(Serialized, (if format then ",\n" else ", ")..stackindent)..formatspace..indents

		return if not isreadonly then "SharedTable.new({"..Contents.."})" else "SharedTable.cloneAndFreeze(SharedTable.new({"..Contents.."}))"
	end

	return if not isreadonly then "SharedTable.new()" else "SharedTable.cloneAndFreeze(SharedTable.new())"
end

function DefaultMethods.TweenInfo(Info : TweenInfo)
	return "TweenInfo.new("..Methods.number(Info.Time)..", Enum.EasingStyle."..Info.EasingStyle.Name..", Enum.EasingDirection."..Info.EasingDirection.Name..", "..Info.RepeatCount..", "..(if Info.Reverses then "true" else "false")..", "..Methods.number(Info.DelayTime)..")"
end

function DefaultMethods.UDim(UDim : UDim)
	return "UDim.new("..Methods.number(UDim.Scale)..", "..UDim.Offset..")"
end

function DefaultMethods.UDim2(UDim2 : UDim2)
	local SerializeNumber = Methods.number
	local Width = UDim2.X
	local Height = UDim2.Y

	return "UDim2.new("..SerializeNumber(Width.Scale)..", "..Width.Offset..", "..SerializeNumber(Height.Scale)..", "..Height.Offset..")"
end

function DefaultMethods.Vector2(Vector : Vector2)
	local SerializeNumber = Methods.number

	return "Vector2.new("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..")"
end

function DefaultMethods.Vector2int16(Vector : Vector2int16)
	return "Vector2int16.new("..Vector.X..", "..Vector.Y..")"
end

function DefaultMethods.Vector3(Vector : Vector3)
	local SerializeNumber = Methods.number

	return DefaultVectors[Vector] or "vector.create("..SerializeNumber(Vector.X)..", "..SerializeNumber(Vector.Y)..", "..SerializeNumber(Vector.Z)..")" -- vector library is more efficent/accurate
end

function DefaultMethods.Vector3int16(Vector : Vector3int16)
	return "Vector3int16.new("..Vector.X..", "..Vector.Y..", "..Vector.Z..")"
end

function DefaultMethods.boolean(bool : boolean)
	return if bool then "true" else "false"
end

function DefaultMethods.buffer(buff : buffer)
	return "buffer.fromstring("..Methods.string(bufftostring(buff))..")"
end

do
	local GlobalFunctions = {} do
		local getrenv = getrenv or (function() -- support for studio executors
			local env = { -- I could be missing a couple libraries
				bit32 = bit32,
				buffer = buffer,
				coroutine = coroutine,
				debug = debug,
				math = math,
				os = os,
				string = string,
				table = table,
				utf8 = utf8,
				Content = Content,
				Axes = Axes,
				AdReward = AdReward, --Empty
				BrickColor = BrickColor,
				CatalogSearchParams = CatalogSearchParams,
				CFrame = CFrame,
				Color3 = Color3,
				ColorSequence = ColorSequence,
				ColorSequenceKeypoint = ColorSequenceKeypoint,
				DateTime = DateTime,
				DockWidgetPluginGuiInfo = DockWidgetPluginGuiInfo,
				Faces = Faces,
				FloatCurveKey = FloatCurveKey,
				Font = Font,
				Instance = Instance,
				NumberRange = NumberRange,
				NumberSequence = NumberSequence,
				NumberSequenceKeypoint = NumberSequenceKeypoint,
				OverlapParams = OverlapParams,
				PathWaypoint = PathWaypoint,
				PhysicalProperties = PhysicalProperties,
				Random = Random,
				Ray = Ray,
				RaycastParams = RaycastParams,
				Rect = Rect,
				Region3 = Region3,
				Region3int16 = Region3int16,
				RotationCurveKey = RotationCurveKey,
				SharedTable = SharedTable,
				task = task,
				TweenInfo = TweenInfo,
				UDim = UDim,
				UDim2 = UDim2,
				Vector2 = Vector2,
				Vector2int16 = Vector2int16,
				Vector3 = Vector3,
				vector = vector,
				Vector3int16 = Vector3int16,
				CellId = CellId, -- Undocumented
				PluginDrag = PluginDrag,
				SecurityCapabilities = SecurityCapabilities,

				assert = assert,
				error = error,
				getfenv = getfenv,
				getmetatable = getmetatable,
				ipairs = ipairs,
				loadstring = loadstring,
				newproxy = newproxy,
				next = next,
				pairs = pairs,
				pcall = pcall,
				print = print,
				rawequal = rawequal,
				rawget = rawget,
				rawlen = rawlen,
				rawset = rawset,
				select = select,
				setfenv = setfenv,
				setmetatable = setmetatable,
				tonumber = tonumber,
				tostring = tostring,
				unpack = unpack,
				xpcall = xpcall,
				collectgarbage = collectgarbage,
				delay = delay,
				gcinfo = gcinfo,
				PluginManager = PluginManager,
				DebuggerManager = DebuggerManager,
				require = require,
				settings = settings,
				spawn = spawn,
				tick = tick,
				time = time,
				UserSettings = UserSettings,
				wait = wait,
				warn = warn,
				Delay = Delay,
				ElapsedTime = ElapsedTime,
				elapsedTime = elapsedTime,
				printidentity = printidentity,
				Spawn = Spawn,
				Stats = Stats,
				stats = stats,
				Version = Version,
				version = version,
				Wait = Wait
			}

			return function()
				return env
			end
		end)()

		local Visited = setmetatable({}, weakkeys) -- support for people who actually modify the roblox env

		for i,v in getrenv() do
			local ElementType = type(i) == "string" and type(v) -- I'm not supporting numbers

			if ElementType then
				if ElementType == "table" then
					local function LoadLibrary(Path : string, tbl : {[string] : any})
						if not Visited[tbl] then
							Visited[tbl] = true

							for i,v in next, tbl do
								local Type = type(i) == "string" and not Keywords[i] and i:match("[A-z_][A-z_0-9]") and type(v)
								local NewPath = Type and (Type == "function" or Type == "table") and Path.."."..i

								if NewPath then
									if Type == "function" then
										GlobalFunctions[v] = NewPath
									else
										LoadLibrary(NewPath, v)
									end
								end
							end

							Visited[tbl] = nil
						end
					end

					LoadLibrary(i, v)
					table.clear(Visited)
				elseif ElementType == "function" then
					GlobalFunctions[v] = i
				end
			end
		end

		Class.GlobalFunctions = GlobalFunctions
	end

	DefaultMethods["function"] = function(Function : (...any?) -> ...any?, format : boolean?, indents : string, _, InComment : boolean?)
		local IsGlobal = GlobalFunctions[Function]

		if not IsGlobal then
			if format then
				local SerializeString = Methods.string

				local CommentSeperator = if not InComment then "" else "="
				local tempindents = indents.."\t\t\t"
				local newlineindent = ",\n"..tempindents
				local source, line, name, numparams, vargs = info(Function, "slna")
				local lclosure = line ~= -1

				return (if lclosure then "" else "coroutine.wrap(").."function()\n\t"..indents.."--["..CommentSeperator.."[\n\t\t"..indents.."info = {\n"..tempindents.."source = "..SerializeString(source)..newlineindent.."line = "..line..newlineindent.."what = "..(if lclosure then "\"Lua\"" else "\"C\"")..newlineindent.."name = "..SerializeString(name)..newlineindent.."numparams = "..numparams..newlineindent.."vargs = "..(if vargs then "true" else "false")..newlineindent.."function = "..tostring(Function).."\n\t\t"..indents.."}\n\t"..indents.."]"..CommentSeperator.."]\n"..indents.."end"..(if lclosure then "" else ")")
			end

			return if islclosure(Function) then "function() end" else "coroutine.wrap(function() end)"
		end

		return IsGlobal
	end
end

function DefaultMethods.table(tbl : {[any] : any}, format : boolean?, indents : string, CyclicList : {[{[any] : any?}] : boolean | nil}?, InComment : boolean?)
	if not CyclicList then
		CyclicList = setmetatable({}, weakkeys)
	end

	if not CyclicList[tbl] then
		local isreadonly = isfrozen(tbl)
		local Index, Value = next(tbl)

		if Index ~= nil then
			local Indents = indents..(if format then "\t" else "")
			local Ending = (if format then ",\n" else ", ")
			local formatspace = if format then "\n" else ""
			local Generation = "{"..formatspace
			local CurrentIndex = 1

			CyclicList[tbl] = true
			repeat
				Generation ..= Indents..(if CurrentIndex ~= Index then ValidateIndex(Index) else "")..Serialize(Value, format, Indents, CyclicList, InComment)
				Index, Value = next(tbl, Index)
				Generation ..= if Index ~= nil then Ending else formatspace..indents.."}"
				CurrentIndex += 1
			until Index == nil
			CyclicList[tbl] = nil

			return if not isreadonly then Generation else "table.freeze("..Generation..")"
		end

		return if not isreadonly then "{}" else "table.freeze({})"
	else
		return "*** cycle table reference detected ***" -- I am NOT supporting cyclic tables as its a huge pain
	end
end

DefaultMethods["nil"] = function()
	return "nil"
end

function DefaultMethods.number(num : number)
	return if num < 1/0 and num > -1/0 then tostring(num) elseif num == 1/0 then (if Class._Serializeinf then "math.huge" else "1/0") elseif num == num then (if Class._Serializeinf then "-math.huge" else "-1/0") else "0/0"
end

do
	local ByteList = {
		["\a"] = "\\a",
		["\b"] = "\\b",
		["\t"] = "\\t",
		["\n"] = "\\n",
		["\v"] = "\\v",
		["\f"] = "\\f",
		["\r"] = "\\r",
		["\""] = "\\\"",
		["\\"] = "\\\\"
	}

	for i = 0, 255 do
		local Character = (i < 32 or i > 126) and string.char(i)

		if Character and not ByteList[Character] then
			ByteList[Character] = ("\\%03d"):format(i)
		end
	end

	function DefaultMethods.string(RawString : string)
		return "\""..RawString:gsub("[\0-\31\34\92\127-\255]", ByteList).."\""
	end
end

function DefaultMethods.thread(thread : thread)
	return "coroutine.create(function() end)"
end

function DefaultMethods.userdata(userdata : any)
	return getmetatable(userdata) ~= nil and "newproxy(true)" or "newproxy(false)"
end

do
	local SecurityCapabilityEnums = Enum.SecurityCapability:GetEnumItems()
	function DefaultMethods.SecurityCapabilities(Capabilities : SecurityCapabilities, format : boolean?, _, _, InComment : boolean?)
		local ContainedCapabilities = {}
		local CurrentIndex = 1

		for i,v in SecurityCapabilityEnums do
			if Capabilities:Contains(v) then
				ContainedCapabilities[CurrentIndex] = "Enum.SecurityCapability."..v.Name
				CurrentIndex += 1
			end
		end

		return "SecurityCapabilities.new("..concat(ContainedCapabilities, ", ")..")"
	end
end

function DefaultMethods.PluginDrag(Drag : PluginDrag)
	local SerializeString = Methods.string

	return "PluginDrag.new("..SerializeString(Drag.Sender)..", "..SerializeString(Drag.MimeType)..", "..SerializeString(Drag.Data)..", "..SerializeString(Drag.MouseIcon)..", "..SerializeString(Drag.DragIcon)..", "..Methods.Vector2(Drag.HotSpot)..")"
end

-- CellId constructor: CellId.new(isNil: boolean, x: number, y: number, z: number, terrainPart: Terrain?): CellId https://devforum.roblox.com/t/nuke-the-cellid-datatype-low-priority-trivia/360115
function DefaultMethods.CellId(Cell : CellId)
	local ArgumentFunction = tostring(Cell):gmatch("%w+")
	local SerializeNumber = Methods.number
	local function SerializeStringToNumber(number : string)
		return SerializeNumber(tonumber(number))
	end
	
	return "CellId.new("..ArgumentFunction()..", "..SerializeStringToNumber(ArgumentFunction())..", "..SerializeStringToNumber(ArgumentFunction())..", "..SerializeStringToNumber(ArgumentFunction())..")" -- Undocumented so I have no idea if there are even accessors
end

local function Serializevargs(... : any)
	local tbl = pack(...) -- Thank you https://github.com/sown0000 for pointing out that nils arent printed
	local GenerationSize = 0

	for i = 1, #tbl do
		local Generation = Serialize(tbl[i], true, "")
		tbl[i] = Generation
		GenerationSize += #Generation

		if GenerationSize > 100000 then -- output functions will trim the generation
			break
		end
	end

	return unpack(tbl, 1, tbl.n)
end

-- Safe parallel
function Class.Convert<Type>(DataStructure : Type, format : boolean?)
	return Serialize(DataStructure, format, "")
end

-- Safe parallel
function Class.ConvertKnown<Type>(DataType : string, DataStructure : Type, format : boolean?)
	return Methods[DataType](DataStructure, format, "")
end

-- Safe parallel
function Class.print(... : any?)
	print(Serializevargs(...))
end

-- Safe Parallel
function Class.warn(... : any?)
	warn(Serializevargs(...))
end

if type(setclipboard) == "function" then
	local setclipboard = setclipboard
	-- Safe Parallel
	function Class.setclipboard<Type>(DataStructure : Type, format : boolean?)
		setclipboard(Serialize(DataStructure, format, ""))
	end
end

Class.Internals = table.freeze({
	Serialize = Serialize
})

return setmetatable(Class, {
	__tostring = function(self)
		return "DataToCode "..self.__VERSION
	end
})
([[This file was protected with MoonSec V3]]):gsub('.+', (function(a) _ImZaWHQvOSld = a; end)); return(function(c,...)local f;local h;local r;local o;local t;local d;local e=24915;local n=0;local l={};while n<836 do n=n+1;while n<0x31f and e%0xc7a<0x63d do n=n+1 e=(e+161)%40519 local a=n+e if(e%0x271e)<0x138f then e=(e*0x225)%0x3b2e while n<0x280 and e%0x1fac<0xfd6 do n=n+1 e=(e*1020)%3436 local d=n+e if(e%0x16d8)>=0xb6c then e=(e*0x1ab)%0x3668 local e=26257 if not l[e]then l[e]=0x1 t=getfenv and getfenv();end elseif e%2~=0 then e=(e*0x1e2)%0xb8e8 local e=76504 if not l[e]then l[e]=0x1 end else e=(e-0x1fc)%0x3eb6 n=n+1 local e=59590 if not l[e]then l[e]=0x1 t=(not t)and _ENV or t;end end end elseif e%2~=0 then e=(e-0x3b2)%0x591 while n<0x2b0 and e%0x3574<0x1aba do n=n+1 e=(e+50)%42698 local f=n+e if(e%0x4b24)<0x2592 then e=(e*0x1ad)%0xa542 local e=72244 if not l[e]then l[e]=0x1 o={};end elseif e%2~=0 then e=(e-0x16)%0xa292 local e=50036 if not l[e]then l[e]=0x1 d=function(d)local e=0x01 local function l(n)e=e+n return d:sub(e-n,e-0x01)end while true do local n=l(0x01)if(n=="\5")then break end local e=r.byte(l(0x01))local e=l(e)if n=="\2"then e=o.lgTSxyOU(e)elseif n=="\3"then e=e~="\0"elseif n=="\6"then t[e]=function(n,e)return c(8,nil,c,e,n)end elseif n=="\4"then e=t[e]elseif n=="\0"then e=t[e][l(r.byte(l(0x01)))];end local n=l(0x08)o[n]=e end end end else e=(e-0x8b)%0x5d37 n=n+1 local e=17290 if not l[e]then l[e]=0x1 r=string;end end end else e=(e-0x24e)%0xbe30 n=n+1 while n<0x106 and e%0x1736<0xb9b do n=n+1 e=(e-573)%34324 local t=n+e if(e%0x1f52)>=0xfa9 then e=(e+0x203)%0x64b6 local e=64899 if not l[e]then l[e]=0x1 f="\4\8\116\111\110\117\109\98\101\114\108\103\84\83\120\121\79\85\0\6\115\116\114\105\110\103\4\99\104\97\114\104\110\117\101\90\83\69\109\0\6\115\116\114\105\110\103\3\115\117\98\81\105\115\122\100\80\107\97\0\6\115\116\114\105\110\103\4\98\121\116\101\72\97\79\76\116\77\110\103\0\5\116\97\98\108\101\6\99\111\110\99\97\116\85\86\71\119\120\110\112\82\0\5\116\97\98\108\101\6\105\110\115\101\114\116\81\110\122\118\117\88\68\112\5";end elseif e%2~=0 then e=(e-0x353)%0x92b3 local e=39453 if not l[e]then l[e]=0x1 h=tonumber;end else e=(e+0x378)%0xac7f n=n+1 local e=66718 if not l[e]then l[e]=0x1 end end end end end e=(e+705)%43621 end d(f);local n={};for e=0x0,0xff do local l=o.hnueZSEm(e);n[e]=l;n[l]=e;end local function u(e)return n[e];end local r=(function(a,d)local f,l=0x01,0x10 local n={{},{},{}}local t=-0x01 local e=0x01 local r=a while true do n[0x03][o.QiszdPka(d,e,(function()e=f+e return e-0x01 end)())]=(function()t=t+0x01 return t end)()if t==(0x0f)then t=""l=0x000 break end end local t=#d while e<t+0x01 do n[0x02][l]=o.QiszdPka(d,e,(function()e=f+e return e-0x01 end)())l=l+0x01 if l%0x02==0x00 then l=0x00 o.QnzvuXDp(n[0x01],(u((((n[0x03][n[0x02][0x00]]or 0x00)*0x10)+(n[0x03][n[0x02][0x01]]or 0x00)+r)%0x100)));r=a+r;end end return o.UVGwxnpR(n[0x01])end);d(r(91,"_,TpKdBOo)uz2 E0uu"));d(r(3,"}_w0bje(:-1pxIvEEIXQe1e:e0j(j-bEv-bejbb-b-wpb(bb_Ew00(+v_0xwx w:_:_0_p_:_j_v_e_bZEvEEE>e-w-0EpE1vvEyE0vjxevPvjvwv(1xx-ebe(I_xEx1pvxMpej_pe1(p(101j(E1(:r(b:I:v(0-vwww0:-(1:1(p_j(-evex(x(_b:b(e(bw0be_0wbxv1vEj0bwbvbb0-bjwE0Ew-w(wvwbUpw_EIEEw_wjvI=E1:1:EblDEpX-r_f_pEIXvpxIv0x1pxI:Ij(j(wvwx-xvIexv10pE1x1bp:p(:Ib-bj(1:v-j(I:x:e(_:p-jw1wp-b:x:I:p:e(1(x(w:_jjjjbeex0EbIe1EPEwjvb:bebIb0v_bIb0bw0%wE0bSxr(900e_ww(wpDjpwp__I_0_wtVEEDbv:Q:EwIbEIx-I1vw:w:Cv:v(IpIIvMx0xxI_pjIjx_11xIjjjbpv1Ip_1(1wpQ(x:v-w1e(::0eIe(w_ww::(-:-(1_b(w(j(j(w(wjEjwj_0Ej0b0010_v1"));local e=(-2426+(function()local d,n=0,1;(function(l,e,n)n(l(l,n and e,e)and l(e and n,n,l),e(e,e,e),e(n,e,e))end)(function(t,e,l)if d>205 then return l end d=d+1 n=(n+840)%39352 if(n%472)<236 then n=(n-724)%34638 return e(t(e,t,e),e(l,l,t),t(l,e,l))else return e end return t end,function(t,l,e)if d>265 then return l end d=d+1 n=(n+229)%21532 if(n%512)<=256 then n=(n*101)%4530 return l else return e(t(t,l,t)and e(e,t,t and l),e(e,e,t)and t(l,e,e),l(e,l and e,l))end return e(t(e,t,t),l(e,l,e),e(e and l,e and e,l and t))end,function(t,e,l)if d>472 then return t end d=d+1 n=(n+670)%14114 if(n%750)<375 then n=(n*658)%20007 return l(l(l,l,e),e(e,l,t and e),e(e,e,t))else return e end return e end)return n;end)())local u=o.RubGsBVa or o.FDCyXpwT;local ne=(getfenv)or(function()return _ENV end);local t=2;local ee=1;local d=3;local a=4;local function g(j,...)local f=r(e,";uFt9/J8br %jU!OOOOR!b!4U%!rjbjv%bOUu8)OgJ!t!U!tU8jtUjUFju%! O%tb<rrbjb98U8!9r89JjJF!%!9UbUwjbF8uruU?U t Fr2bbbA!9UOjrj9j%j9%  r Jr8F%FUubuh,b/O9u/U9F9uFOuburtJS8ftu9^9r%%Nbbb=8bUbUjU9jbjtbFJOJ8 Qbrrtbj8/J!8rFJ/u/b/_d8FFpr6%u%Duu8U/UO%OO !u!O8tbOJ1/b/)rj b u t9bbJbu8jJUF1JO/u/%+39b9Ft8t9uUutuj_/Oj%3OO!r!jUbbb Uj8%O%JrtrUrt9b8J9%uteO0:ObOQtZ/99j9Q*OF/Fj%B b 3rbr>rJb(8b8+Jb8J/b/f9b9utbtNFbtFu u?nbL}OrOH!b!h! UOjbj_%b%9 b =rb%JbUbs8b8nJ!J)/r/v9!9Ttjt%FbFxubuJ0bhuObOyOu!6UbU1jrj:%b%R% %urbrhbbbt8b8:Jb8FJb/o9r9Xt txFbF)tbFrebcuObOu!b!8Ub!FUOj&%%%Y U Wrbr(bbr*8b8uJbJt/b/g9b9Wt!tYFbF}ubuTT paObBU!b!DUbUujbju%b%D j grbr<brbL8b8V");local n=0;o.lxstrUhr(function()o.oGfVQhjC()n=n+1 end)local function e(l,e)if e then return n end;n=l+n;end local l,n,b=c(0,c,e,f,o.HaOLtMng);local function r()local n,l=o.HaOLtMng(f,e(1,3),e(5,6)+2);e(2);return(l*256)+n;end;local s=true;local s=0 local function k()local t=n();local e=n();local d=1;local t=(l(e,1,20)*(2^32))+t;local n=l(e,21,31);local e=((-1)^l(e,32));if(n==0)then if(t==s)then return e*0;else n=1;d=0;end;elseif(n==2047)then return(t==0)and(e*(1/0))or(e*(0/0));end;return o.JLoMBrFc(e,n-1023)*(d+(t/(2^52)));end;local _=n;local function p(n)local l;if(not n)then n=_();if(n==0)then return'';end;end;l=o.QiszdPka(f,e(1,3),e(5,6)+n-1);e(n)local e=""for n=(1+s),#l do e=e..o.QiszdPka(l,n,n)end return e;end;local s=#o.yPSGpFWw(h('\49.\48'))~=1 local e=n;local function m(...)return{...},o.CX_vKYFC('#',...)end local function g()local c={};local u={};local e={};local h={u,c,nil,e};local e=n()local f={}for t=1,e do local l=b();local e;if(l==1)then e=(b()~=#{});elseif(l==0)then local n=k();if s and o.EpLC_cKy(o.yPSGpFWw(n),'.(\48+)$')then n=o.bXZKbUOI(n);end e=n;elseif(l==3)then e=p();end;f[t]=e;end;h[3]=b();for e=1,n()do c[e-(#{1})]=g();end;for h=1,n()do local e=b();if(l(e,1,1)==0)then local o=l(e,2,3);local c=l(e,4,6);local e={r(),r(),nil,nil};if(o==0)then e[d]=r();e[a]=r();elseif(o==#{1})then e[d]=n();elseif(o==j[2])then e[d]=n()-(2^16)elseif(o==j[3])then e[d]=n()-(2^16)e[a]=r();end;if(l(c,1,1)==1)then e[t]=f[e[t]]end if(l(c,2,2)==1)then e[d]=f[e[d]]end if(l(c,3,3)==1)then e[a]=f[e[a]]end u[h]=e;end end;return h;end;local function y(l,e,n)local t=e;local t=n;return h(o.EpLC_cKy(o.EpLC_cKy(({o.lxstrUhr(l)})[2],e),n))end local function z(p,e,b)local function y(...)local r,y,s,g,j,l,f,_,h,k,z,n;local e=0;while-1<e do if 3>e then if e<=0 then r=c(6,18,1,85,p);y=c(6,57,2,4,p);else if-2<=e then for n=39,74 do if 1~=e then l=-41;f=-1;break;end;s=c(6,26,3,35,p);j=m g=0;break;end;else l=-41;f=-1;end end else if e>=5 then if 3<=e then for l=14,94 do if 5<e then e=-2;break;end;n=c(7);break;end;else n=c(7);end else if 0<=e then for n=17,83 do if e>3 then k=o.CX_vKYFC('#',...)-1;z={};break;end;_={};h={...};break;end;else _={};h={...};end end end e=e+1;end;for e=0,k do if(e>=s)then _[e-s]=h[e+1];else n[e]=h[e+1];end;end;local e=k-s+1 local e;local o;local function c(...)while true do end end while true do if l<-40 then l=l+42 end e=r[l];o=e[ee];if 12<=o then if o<=17 then if 14>=o then if 13>o then local o,f,r,c,a;local l=0;while l>-1 do if l>=3 then if l>4 then if l==5 then n(a,c);else l=-2;end else if 3==l then c=o[r];else a=o[f];end end else if l>0 then if 2==l then r=d;else f=t;end else o=e;end end l=l+1 end else if 12~=o then repeat if o<14 then l=e[d];break;end;local e=e[t]n[e]=n[e](u(n,e+1,f))until true;else l=e[d];end end else if o<=15 then n[e[t]]=(e[d]~=0);else if o~=17 then local o,h,_,s,c;n[e[t]]=b[e[d]];l=l+1;e=r[l];o=e[t];h=n[e[d]];n[o+1]=h;n[o]=h[e[a]];l=l+1;e=r[l];n(e[t],e[d]);l=l+1;e=r[l];o=e[t]_,s=j(n[o](u(n,o+1,e[d])))f=s+o-1 c=0;for e=o,f do c=c+1;n[e]=_[c];end;l=l+1;e=r[l];o=e[t]n[o]=n[o](u(n,o+1,f))l=l+1;e=r[l];n[e[t]]();l=l+1;e=r[l];do return end;else n[e[t]]=b[e[d]];end end end else if 21>o then if 19<=o then if o==19 then local l=e[t]local t,e=j(n[l](u(n,l+1,e[d])))f=e+l-1 local e=0;for l=l,f do e=e+1;n[l]=t[e];end;else local l=e[t]local t,e=j(n[l](u(n,l+1,e[d])))f=e+l-1 local e=0;for l=l,f do e=e+1;n[l]=t[e];end;end else n[e[t]]=b[e[d]];end else if o>21 then if o>21 then repeat if 22<o then n[e[t]]();break;end;for o=0,3 do if 1<o then if-2<=o then for f=23,94 do if o<3 then n[e[t]]=b[e[d]];l=l+1;e=r[l];break;end;if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;break;end;else n[e[t]]=b[e[d]];l=l+1;e=r[l];end else if-1<=o then for f=17,59 do if o~=1 then n[e[t]]=(e[d]~=0);l=l+1;e=r[l];break;end;b[e[d]]=n[e[t]];l=l+1;e=r[l];break;end;else n[e[t]]=(e[d]~=0);l=l+1;e=r[l];end end end until true;else n[e[t]]();end else n[e[t]]=(e[d]~=0);end end end else if 5>=o then if 3>o then if o<=0 then local a,o,c,r,f;local l=0;while l>-1 do if l>=3 then if 5<=l then if 4<=l then repeat if 5~=l then l=-2;break;end;n(f,r);until true;else n(f,r);end else if 3==l then r=a[c];else f=a[o];end end else if 1>l then a=e;else if-1~=l then for e=41,88 do if l~=1 then c=d;break;end;o=t;break;end;else o=t;end end end l=l+1 end else if-1~=o then repeat if 2>o then if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;break;end;local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];until true;else local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];end end else if 4<=o then if o==4 then b[e[d]]=n[e[t]];else do return end;end else if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;end end else if o<9 then if 6<o then if 8>o then local e=e[t]n[e]=n[e](u(n,e+1,f))else b[e[d]]=n[e[t]];end else n[e[t]]();end else if o<10 then do return end;else if 10<o then l=e[d];else local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];end end end end end l=1+l;end;end;return y end;local d=0xff;local c={};local f=(1);local t='';(function(n)local l=n local r=0x00 local e=0x00 l={(function(a)if r>0x28 then return a end r=r+1 e=(e+0xb7b-a)%0x49 return(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xe1);end return true end)'SKETJ'and l[0x2](0x25c+a))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x18);t={t..'\58 a',t};c[f]=g();f=f+((not o.UttRYpJR)and 1 or 0);t[1]='\58'..t[1];d[2]=0xff;end return true end)'Uozuk'and l[0x3](a+0x178))or(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xc2);end return true end)'lfEQM'and l[0x1](a+0x2a9))or a end),(function(t)if r>0x2b then return t end r=r+1 e=(e+0xa93-t)%0x46 return(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xe8);end return true end)'PfOMZ'and l[0x2](0x296+t))or(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xbf);end return true end)'ODWcx'and l[0x3](t+0x1f7))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x26);end return true end)'cInqq'and l[0x1](t+0x1ce))or t end),(function(o)if r>0x23 then return o end r=r+1 e=(e+0x950-o)%0x49 return(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xa0);t='\37';d={function()d()end};t=t..'\100\43';end return true end)'AjmUg'and l[0x1](0x7d+o))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x96);c[f]=ne();f=f+d;end return true end)'xoPuy'and l[0x2](o+0x338))or(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xf4);d[2]=(d[2]*(y(function()c()end,u(t))-y(d[1],u(t))))+1;c[f]={};d=d[2];f=f+d;end return true end)'dEmlY'and l[0x3](o+0x150))or o end)}l[0x3](0x16ef)end){};local e=z(u(c));return e(...);end return g((function()local n={}local e=0x01;local l;if o.UttRYpJR then l=o.UttRYpJR(g)else l=''end if o.EpLC_cKy(l,o.iMjrrzBb)then e=e+0;else e=e+1;end n[e]=0x02;n[n[e]+0x01]=0x03;return n;end)(),...)end)((function(e,n,l,t,d,o)local o;if 3>=e then if e>1 then if 3~=e then do return 16777216,65536,256 end;else do return n(1),n(4,d,t,l,n),n(5,d,t,l)end;end else if e==0 then do return n(1),n(4,d,t,l,n),n(5,d,t,l)end;else do return function(l,e,n)if n then local e=(l/2^(e-1))%2^((n-1)-(e-1)+1);return e-e%1;else local e=2^(e-1);return(l%(e+e)>=e)and 1 or 0;end;end;end;end end else if 5<e then if e>=7 then if e>=5 then for n=32,74 do if e~=8 then do return setmetatable({},{['__\99\97\108\108']=function(e,d,t,l,n)if n then return e[n]elseif l then return e else e[d]=t end end})end break;end;do return l(e,nil,l);end break;end;else do return setmetatable({},{['__\99\97\108\108']=function(e,l,t,d,n)if n then return e[n]elseif d then return e else e[l]=t end end})end end else do return d[l]end;end else if 3~=e then repeat if 5~=e then local e=t;local t,d,f=d(2);do return function()local r,o,n,l=n(l,e(e,e),e(e,e)+3);e(4);return(l*t)+(n*d)+(o*f)+r;end;end;break;end;local e=t;do return function()local n=n(l,e(e,e),e(e,e));e(1);return n;end;end;until true;else local e=t;local d,o,t=d(2);do return function()local n,l,f,r=n(l,e(e,e),e(e,e)+3);e(4);return(r*d)+(f*o)+(l*t)+n;end;end;end end end end),...)

([[This file was protected with MoonSec V3]]):gsub('.+', (function(a) _ImZaWHQvOSld = a; end)); return(function(c,...)local f;local h;local r;local o;local t;local d;local e=24915;local n=0;local l={};while n<836 do n=n+1;while n<0x31f and e%0xc7a<0x63d do n=n+1 e=(e+161)%40519 local a=n+e if(e%0x271e)<0x138f then e=(e*0x225)%0x3b2e while n<0x280 and e%0x1fac<0xfd6 do n=n+1 e=(e*1020)%3436 local d=n+e if(e%0x16d8)>=0xb6c then e=(e*0x1ab)%0x3668 local e=26257 if not l[e]then l[e]=0x1 t=getfenv and getfenv();end elseif e%2~=0 then e=(e*0x1e2)%0xb8e8 local e=76504 if not l[e]then l[e]=0x1 end else e=(e-0x1fc)%0x3eb6 n=n+1 local e=59590 if not l[e]then l[e]=0x1 t=(not t)and _ENV or t;end end end elseif e%2~=0 then e=(e-0x3b2)%0x591 while n<0x2b0 and e%0x3574<0x1aba do n=n+1 e=(e+50)%42698 local f=n+e if(e%0x4b24)<0x2592 then e=(e*0x1ad)%0xa542 local e=72244 if not l[e]then l[e]=0x1 o={};end elseif e%2~=0 then e=(e-0x16)%0xa292 local e=50036 if not l[e]then l[e]=0x1 d=function(d)local e=0x01 local function l(n)e=e+n return d:sub(e-n,e-0x01)end while true do local n=l(0x01)if(n=="\5")then break end local e=r.byte(l(0x01))local e=l(e)if n=="\2"then e=o.lgTSxyOU(e)elseif n=="\3"then e=e~="\0"elseif n=="\6"then t[e]=function(n,e)return c(8,nil,c,e,n)end elseif n=="\4"then e=t[e]elseif n=="\0"then e=t[e][l(r.byte(l(0x01)))];end local n=l(0x08)o[n]=e end end end else e=(e-0x8b)%0x5d37 n=n+1 local e=17290 if not l[e]then l[e]=0x1 r=string;end end end else e=(e-0x24e)%0xbe30 n=n+1 while n<0x106 and e%0x1736<0xb9b do n=n+1 e=(e-573)%34324 local t=n+e if(e%0x1f52)>=0xfa9 then e=(e+0x203)%0x64b6 local e=64899 if not l[e]then l[e]=0x1 f="\4\8\116\111\110\117\109\98\101\114\108\103\84\83\120\121\79\85\0\6\115\116\114\105\110\103\4\99\104\97\114\104\110\117\101\90\83\69\109\0\6\115\116\114\105\110\103\3\115\117\98\81\105\115\122\100\80\107\97\0\6\115\116\114\105\110\103\4\98\121\116\101\72\97\79\76\116\77\110\103\0\5\116\97\98\108\101\6\99\111\110\99\97\116\85\86\71\119\120\110\112\82\0\5\116\97\98\108\101\6\105\110\115\101\114\116\81\110\122\118\117\88\68\112\5";end elseif e%2~=0 then e=(e-0x353)%0x92b3 local e=39453 if not l[e]then l[e]=0x1 h=tonumber;end else e=(e+0x378)%0xac7f n=n+1 local e=66718 if not l[e]then l[e]=0x1 end end end end end e=(e+705)%43621 end d(f);local n={};for e=0x0,0xff do local l=o.hnueZSEm(e);n[e]=l;n[l]=e;end local function u(e)return n[e];end local r=(function(a,d)local f,l=0x01,0x10 local n={{},{},{}}local t=-0x01 local e=0x01 local r=a while true do n[0x03][o.QiszdPka(d,e,(function()e=f+e return e-0x01 end)())]=(function()t=t+0x01 return t end)()if t==(0x0f)then t=""l=0x000 break end end local t=#d while e<t+0x01 do n[0x02][l]=o.QiszdPka(d,e,(function()e=f+e return e-0x01 end)())l=l+0x01 if l%0x02==0x00 then l=0x00 o.QnzvuXDp(n[0x01],(u((((n[0x03][n[0x02][0x00]]or 0x00)*0x10)+(n[0x03][n[0x02][0x01]]or 0x00)+r)%0x100)));r=a+r;end end return o.UVGwxnpR(n[0x01])end);d(r(91,"_,TpKdBOo)uz2 E0uu"));d(r(3,"}_w0bje(:-1pxIvEEIXQe1e:e0j(j-bEv-bejbb-b-wpb(bb_Ew00(+v_0xwx w:_:_0_p_:_j_v_e_bZEvEEE>e-w-0EpE1vvEyE0vjxevPvjvwv(1xx-ebe(I_xEx1pvxMpej_pe1(p(101j(E1(:r(b:I:v(0-vwww0:-(1:1(p_j(-evex(x(_b:b(e(bw0be_0wbxv1vEj0bwbvbb0-bjwE0Ew-w(wvwbUpw_EIEEw_wjvI=E1:1:EblDEpX-r_f_pEIXvpxIv0x1pxI:Ij(j(wvwx-xvIexv10pE1x1bp:p(:Ib-bj(1:v-j(I:x:e(_:p-jw1wp-b:x:I:p:e(1(x(w:_jjjjbeex0EbIe1EPEwjvb:bebIb0v_bIb0bw0%wE0bSxr(900e_ww(wpDjpwp__I_0_wtVEEDbv:Q:EwIbEIx-I1vw:w:Cv:v(IpIIvMx0xxI_pjIjx_11xIjjjbpv1Ip_1(1wpQ(x:v-w1e(::0eIe(w_ww::(-:-(1_b(w(j(j(w(wjEjwj_0Ej0b0010_v1"));local e=(-2426+(function()local d,n=0,1;(function(l,e,n)n(l(l,n and e,e)and l(e and n,n,l),e(e,e,e),e(n,e,e))end)(function(t,e,l)if d>205 then return l end d=d+1 n=(n+840)%39352 if(n%472)<236 then n=(n-724)%34638 return e(t(e,t,e),e(l,l,t),t(l,e,l))else return e end return t end,function(t,l,e)if d>265 then return l end d=d+1 n=(n+229)%21532 if(n%512)<=256 then n=(n*101)%4530 return l else return e(t(t,l,t)and e(e,t,t and l),e(e,e,t)and t(l,e,e),l(e,l and e,l))end return e(t(e,t,t),l(e,l,e),e(e and l,e and e,l and t))end,function(t,e,l)if d>472 then return t end d=d+1 n=(n+670)%14114 if(n%750)<375 then n=(n*658)%20007 return l(l(l,l,e),e(e,l,t and e),e(e,e,t))else return e end return e end)return n;end)())local u=o.RubGsBVa or o.FDCyXpwT;local ne=(getfenv)or(function()return _ENV end);local t=2;local ee=1;local d=3;local a=4;local function g(j,...)local f=r(e,";uFt9/J8br %jU!OOOOR!b!4U%!rjbjv%bOUu8)OgJ!t!U!tU8jtUjUFju%! O%tb<rrbjb98U8!9r89JjJF!%!9UbUwjbF8uruU?U t Fr2bbbA!9UOjrj9j%j9%  r Jr8F%FUubuh,b/O9u/U9F9uFOuburtJS8ftu9^9r%%Nbbb=8bUbUjU9jbjtbFJOJ8 Qbrrtbj8/J!8rFJ/u/b/_d8FFpr6%u%Duu8U/UO%OO !u!O8tbOJ1/b/)rj b u t9bbJbu8jJUF1JO/u/%+39b9Ft8t9uUutuj_/Oj%3OO!r!jUbbb Uj8%O%JrtrUrt9b8J9%uteO0:ObOQtZ/99j9Q*OF/Fj%B b 3rbr>rJb(8b8+Jb8J/b/f9b9utbtNFbtFu u?nbL}OrOH!b!h! UOjbj_%b%9 b =rb%JbUbs8b8nJ!J)/r/v9!9Ttjt%FbFxubuJ0bhuObOyOu!6UbU1jrj:%b%R% %urbrhbbbt8b8:Jb8FJb/o9r9Xt txFbF)tbFrebcuObOu!b!8Ub!FUOj&%%%Y U Wrbr(bbr*8b8uJbJt/b/g9b9Wt!tYFbF}ubuTT paObBU!b!DUbUujbju%b%D j grbr<brbL8b8V");local n=0;o.lxstrUhr(function()o.oGfVQhjC()n=n+1 end)local function e(l,e)if e then return n end;n=l+n;end local l,n,b=c(0,c,e,f,o.HaOLtMng);local function r()local n,l=o.HaOLtMng(f,e(1,3),e(5,6)+2);e(2);return(l*256)+n;end;local s=true;local s=0 local function k()local t=n();local e=n();local d=1;local t=(l(e,1,20)*(2^32))+t;local n=l(e,21,31);local e=((-1)^l(e,32));if(n==0)then if(t==s)then return e*0;else n=1;d=0;end;elseif(n==2047)then return(t==0)and(e*(1/0))or(e*(0/0));end;return o.JLoMBrFc(e,n-1023)*(d+(t/(2^52)));end;local _=n;local function p(n)local l;if(not n)then n=_();if(n==0)then return'';end;end;l=o.QiszdPka(f,e(1,3),e(5,6)+n-1);e(n)local e=""for n=(1+s),#l do e=e..o.QiszdPka(l,n,n)end return e;end;local s=#o.yPSGpFWw(h('\49.\48'))~=1 local e=n;local function m(...)return{...},o.CX_vKYFC('#',...)end local function g()local c={};local u={};local e={};local h={u,c,nil,e};local e=n()local f={}for t=1,e do local l=b();local e;if(l==1)then e=(b()~=#{});elseif(l==0)then local n=k();if s and o.EpLC_cKy(o.yPSGpFWw(n),'.(\48+)$')then n=o.bXZKbUOI(n);end e=n;elseif(l==3)then e=p();end;f[t]=e;end;h[3]=b();for e=1,n()do c[e-(#{1})]=g();end;for h=1,n()do local e=b();if(l(e,1,1)==0)then local o=l(e,2,3);local c=l(e,4,6);local e={r(),r(),nil,nil};if(o==0)then e[d]=r();e[a]=r();elseif(o==#{1})then e[d]=n();elseif(o==j[2])then e[d]=n()-(2^16)elseif(o==j[3])then e[d]=n()-(2^16)e[a]=r();end;if(l(c,1,1)==1)then e[t]=f[e[t]]end if(l(c,2,2)==1)then e[d]=f[e[d]]end if(l(c,3,3)==1)then e[a]=f[e[a]]end u[h]=e;end end;return h;end;local function y(l,e,n)local t=e;local t=n;return h(o.EpLC_cKy(o.EpLC_cKy(({o.lxstrUhr(l)})[2],e),n))end local function z(p,e,b)local function y(...)local r,y,s,g,j,l,f,_,h,k,z,n;local e=0;while-1<e do if 3>e then if e<=0 then r=c(6,18,1,85,p);y=c(6,57,2,4,p);else if-2<=e then for n=39,74 do if 1~=e then l=-41;f=-1;break;end;s=c(6,26,3,35,p);j=m g=0;break;end;else l=-41;f=-1;end end else if e>=5 then if 3<=e then for l=14,94 do if 5<e then e=-2;break;end;n=c(7);break;end;else n=c(7);end else if 0<=e then for n=17,83 do if e>3 then k=o.CX_vKYFC('#',...)-1;z={};break;end;_={};h={...};break;end;else _={};h={...};end end end e=e+1;end;for e=0,k do if(e>=s)then _[e-s]=h[e+1];else n[e]=h[e+1];end;end;local e=k-s+1 local e;local o;local function c(...)while true do end end while true do if l<-40 then l=l+42 end e=r[l];o=e[ee];if 12<=o then if o<=17 then if 14>=o then if 13>o then local o,f,r,c,a;local l=0;while l>-1 do if l>=3 then if l>4 then if l==5 then n(a,c);else l=-2;end else if 3==l then c=o[r];else a=o[f];end end else if l>0 then if 2==l then r=d;else f=t;end else o=e;end end l=l+1 end else if 12~=o then repeat if o<14 then l=e[d];break;end;local e=e[t]n[e]=n[e](u(n,e+1,f))until true;else l=e[d];end end else if o<=15 then n[e[t]]=(e[d]~=0);else if o~=17 then local o,h,_,s,c;n[e[t]]=b[e[d]];l=l+1;e=r[l];o=e[t];h=n[e[d]];n[o+1]=h;n[o]=h[e[a]];l=l+1;e=r[l];n(e[t],e[d]);l=l+1;e=r[l];o=e[t]_,s=j(n[o](u(n,o+1,e[d])))f=s+o-1 c=0;for e=o,f do c=c+1;n[e]=_[c];end;l=l+1;e=r[l];o=e[t]n[o]=n[o](u(n,o+1,f))l=l+1;e=r[l];n[e[t]]();l=l+1;e=r[l];do return end;else n[e[t]]=b[e[d]];end end end else if 21>o then if 19<=o then if o==19 then local l=e[t]local t,e=j(n[l](u(n,l+1,e[d])))f=e+l-1 local e=0;for l=l,f do e=e+1;n[l]=t[e];end;else local l=e[t]local t,e=j(n[l](u(n,l+1,e[d])))f=e+l-1 local e=0;for l=l,f do e=e+1;n[l]=t[e];end;end else n[e[t]]=b[e[d]];end else if o>21 then if o>21 then repeat if 22<o then n[e[t]]();break;end;for o=0,3 do if 1<o then if-2<=o then for f=23,94 do if o<3 then n[e[t]]=b[e[d]];l=l+1;e=r[l];break;end;if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;break;end;else n[e[t]]=b[e[d]];l=l+1;e=r[l];end else if-1<=o then for f=17,59 do if o~=1 then n[e[t]]=(e[d]~=0);l=l+1;e=r[l];break;end;b[e[d]]=n[e[t]];l=l+1;e=r[l];break;end;else n[e[t]]=(e[d]~=0);l=l+1;e=r[l];end end end until true;else n[e[t]]();end else n[e[t]]=(e[d]~=0);end end end else if 5>=o then if 3>o then if o<=0 then local a,o,c,r,f;local l=0;while l>-1 do if l>=3 then if 5<=l then if 4<=l then repeat if 5~=l then l=-2;break;end;n(f,r);until true;else n(f,r);end else if 3==l then r=a[c];else f=a[o];end end else if 1>l then a=e;else if-1~=l then for e=41,88 do if l~=1 then c=d;break;end;o=t;break;end;else o=t;end end end l=l+1 end else if-1~=o then repeat if 2>o then if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;break;end;local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];until true;else local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];end end else if 4<=o then if o==4 then b[e[d]]=n[e[t]];else do return end;end else if(n[e[t]]~=e[a])then l=l+1;else l=e[d];end;end end else if o<9 then if 6<o then if 8>o then local e=e[t]n[e]=n[e](u(n,e+1,f))else b[e[d]]=n[e[t]];end else n[e[t]]();end else if o<10 then do return end;else if 10<o then l=e[d];else local t=e[t];local l=n[e[d]];n[t+1]=l;n[t]=l[e[a]];end end end end end l=1+l;end;end;return y end;local d=0xff;local c={};local f=(1);local t='';(function(n)local l=n local r=0x00 local e=0x00 l={(function(a)if r>0x28 then return a end r=r+1 e=(e+0xb7b-a)%0x49 return(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xe1);end return true end)'SKETJ'and l[0x2](0x25c+a))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x18);t={t..'\58 a',t};c[f]=g();f=f+((not o.UttRYpJR)and 1 or 0);t[1]='\58'..t[1];d[2]=0xff;end return true end)'Uozuk'and l[0x3](a+0x178))or(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xc2);end return true end)'lfEQM'and l[0x1](a+0x2a9))or a end),(function(t)if r>0x2b then return t end r=r+1 e=(e+0xa93-t)%0x46 return(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xe8);end return true end)'PfOMZ'and l[0x2](0x296+t))or(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xbf);end return true end)'ODWcx'and l[0x3](t+0x1f7))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x26);end return true end)'cInqq'and l[0x1](t+0x1ce))or t end),(function(o)if r>0x23 then return o end r=r+1 e=(e+0x950-o)%0x49 return(e%0x03==0x2 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xa0);t='\37';d={function()d()end};t=t..'\100\43';end return true end)'AjmUg'and l[0x1](0x7d+o))or(e%0x03==0x0 and(function(l)if not n[l]then e=e+0x01 n[l]=(0x96);c[f]=ne();f=f+d;end return true end)'xoPuy'and l[0x2](o+0x338))or(e%0x03==0x1 and(function(l)if not n[l]then e=e+0x01 n[l]=(0xf4);d[2]=(d[2]*(y(function()c()end,u(t))-y(d[1],u(t))))+1;c[f]={};d=d[2];f=f+d;end return true end)'dEmlY'and l[0x3](o+0x150))or o end)}l[0x3](0x16ef)end){};local e=z(u(c));return e(...);end return g((function()local n={}local e=0x01;local l;if o.UttRYpJR then l=o.UttRYpJR(g)else l=''end if o.EpLC_cKy(l,o.iMjrrzBb)then e=e+0;else e=e+1;end n[e]=0x02;n[n[e]+0x01]=0x03;return n;end)(),...)end)((function(e,n,l,t,d,o)local o;if 3>=e then if e>1 then if 3~=e then do return 16777216,65536,256 end;else do return n(1),n(4,d,t,l,n),n(5,d,t,l)end;end else if e==0 then do return n(1),n(4,d,t,l,n),n(5,d,t,l)end;else do return function(l,e,n)if n then local e=(l/2^(e-1))%2^((n-1)-(e-1)+1);return e-e%1;else local e=2^(e-1);return(l%(e+e)>=e)and 1 or 0;end;end;end;end end else if 5<e then if e>=7 then if e>=5 then for n=32,74 do if e~=8 then do return setmetatable({},{['__\99\97\108\108']=function(e,d,t,l,n)if n then return e[n]elseif l then return e else e[d]=t end end})end break;end;do return l(e,nil,l);end break;end;else do return setmetatable({},{['__\99\97\108\108']=function(e,l,t,d,n)if n then return e[n]elseif d then return e else e[l]=t end end})end end else do return d[l]end;end else if 3~=e then repeat if 5~=e then local e=t;local t,d,f=d(2);do return function()local r,o,n,l=n(l,e(e,e),e(e,e)+3);e(4);return(l*t)+(n*d)+(o*f)+r;end;end;break;end;local e=t;do return function()local n=n(l,e(e,e),e(e,e));e(1);return n;end;end;until true;else local e=t;local d,o,t=d(2);do return function()local n,l,f,r=n(l,e(e,e),e(e,e)+3);e(4);return(r*d)+(f*o)+(l*t)+n;end;end;end end end end),...)