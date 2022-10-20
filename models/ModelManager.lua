local ModelManager = class("ModelManager")

function ModelManager.get()
	if ModelManager.INSTANCE == nil then
		ModelManager.INSTANCE = ModelManager.new()
	end

	return ModelManager.INSTANCE
end

function ModelManager:ctor()
	xyd = xyd or {}
	xyd.models = {}
	local metatable = nil
	metatable = {
		__index = function (t, k)
			if metatable[k] then
				local model = require(metatable[k]).new()

				rawset(t, k, model)
			end

			return rawget(t, k)
		end
	}

	setmetatable(xyd.models, metatable)

	metatable.acDFA = "app.models.ACDFA"
	metatable.selfPlayer = "app.models.SelfPlayer"
	metatable.backpack = "app.models.Backpack"
	metatable.slot = "app.models.Slot"
	metatable.map = "app.models.Map"
	metatable.functionOpen = "app.models.FunctionOpen"
	metatable.redMark = "app.models.RedMark"
	metatable.midas = "app.models.Midas"
	metatable.heroAttr = "app.models.HeroAttr"
	metatable.reportPetAttr = "app.models.ReportPetAttr"
	metatable.achievement = "app.models.Achievement"
	metatable.activity = "app.models.Activity"
	metatable.shop = "app.models.Shop"
	metatable.summon = "app.models.Summon"
	metatable.tavern = "app.models.Tavern"
	metatable.shenxue = "app.models.ShenXue"
	metatable.gamble = "app.models.Gamble"
	metatable.prophet = "app.models.Prophet"
	metatable.mission = "app.models.Mission"
	metatable.towerMap = "app.models.TowerMap"
	metatable.friend = "app.models.Friend"
	metatable.trial = "app.models.Trial"
	metatable.house = "app.models.House"
	metatable.heroChallenge = "app.models.HeroChallenge"
	metatable.vip = "app.models.Vip"
	metatable.guild = "app.models.Guild"
	metatable.guildWar = "app.models.GuildWar"
	metatable.friendTeamBoss = "app.models.FriendTeamBoss"
	metatable.petSlot = "app.models.PetSlot"
	metatable.arena = "app.models.Arena"
	metatable.arena3v3 = "app.models.Arena3v3"
	metatable.background = "app.models.Background"
	metatable.settingUp = "app.models.SettingUp"
	metatable.chat = "app.models.Chat"
	metatable.arenaTeam = "app.models.ArenaTeam"
	metatable.dungeon = "app.models.Dungeon"
	metatable.arenaAllServer = "app.models.ArenaAllServer"
	metatable.comic = "app.models.Comic"
	metatable.dailyQuiz = "app.models.DailyQuiz"
	metatable.mail = "app.models.Mail"
	metatable.academyAssessment = "app.models.AcademyAssessment"
	metatable.partnerDataStation = "app.models.PartnerDataStation"
	metatable.gMcommand = "app.models.GMcommand"
	metatable.newbieCamp = "app.models.NewbieCamp"
	metatable.textInput = "app.models.TextInput"
	metatable.partnerComment = "app.models.PartnerComment"
	metatable.imgGuide = "app.models.ImgGuide"
	metatable.deviceNotify = "app.models.DeviceNotify"
	metatable.selfShader = "app.models.SelfShader"
	metatable.collection = "app.models.Collection"
	metatable.error = "app.models.ErrorModel"
	metatable.advertiseComplete = "app.models.AdvertiseComplete"
	metatable.floatMessage = "app.models.FloatMessage"
	metatable.floatMessage2 = "app.models.FloatMessage2"
	metatable.itemFloatModel = "app.models.ItemFloatModel"
	metatable.oldSchool = "app.models.OldSchool"
	metatable.exploreModel = "app.models.ExploreModel"
	metatable.storyListModel = "app.models.StoryListModel"
	metatable.activityPointTips = "app.models.ActivityPointTips"
	metatable.fairArena = "app.models.FairArena"
	metatable.petTraining = "app.models.PetTraining"
	metatable.dress = "app.models.Dress"
	metatable.dressShow = "app.models.DressShow"
	metatable.shrine = "app.models.Shrine"
	metatable.community = "app.models.Community"
	metatable.timeCloisterModel = "app.models.TimeCloisterModel"
	metatable.arenaAllServerScore = "app.models.ArenaAllServerScore"
	metatable.arenaAllServerNew = "app.models.ArenaAllServerNew"
	metatable.shrineHurdleModel = "app.models.ShrineHurdleModel"
	metatable.gameAssistant = "app.models.GameAssistant"
	metatable.quickFormation = "app.models.QuickFormation"
	metatable.growthDiary = "app.models.GrowthDiary"
	metatable.galaxyTrip = "app.models.GalaxyTrip"
	metatable.soulLand = "app.models.SoulLand"
end

function ModelManager:reset()
	for _, v in pairs(xyd.models) do
		if v then
			v:disposeAll()
		end
	end

	xyd.models = {}
	ModelManager.INSTANCE = nil
end

return ModelManager
