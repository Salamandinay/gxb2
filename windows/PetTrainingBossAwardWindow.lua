local BaseWindow = import(".BaseWindow")
local PetTrainingBossAwardWindow = class("PetTrainingBossAwardWindow", BaseWindow)
local PetTrainingBossKillAwardItem = class("PetTrainingBossKillAwardItem")

function PetTrainingBossAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)
end

function PetTrainingBossAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:initUIComponent()
	self:register()
end

function PetTrainingBossAwardWindow:getUIComponent()
	local go = self.window_:NodeByName("e:Group").gameObject
	self.labelTitle = go:ComponentByName("labelTitle", typeof(UILabel))
	self.closeBtn = go:NodeByName("closeBtn").gameObject
	self.scroller = go:ComponentByName("bGroup/e:Scroller", typeof(UIScrollView))
	self.awardContainer = go:NodeByName("bGroup/e:Scroller/awardContainer").gameObject
	self.labelAward1 = go:ComponentByName("bGroup/labelAward1", typeof(UILabel))
	self.labelAward2 = go:ComponentByName("bGroup/labelAward2", typeof(UILabel))
	self.item = go:NodeByName("bGroup/item").gameObject
	self.itemTitle = self.item:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = self.item:NodeByName("itemGroup").gameObject
	self.rankImg = self.item:ComponentByName("rankImg", typeof(UISprite))
end

function PetTrainingBossAwardWindow:initUIComponent()
	self.labelAward1.text = tostring(__("GUILD_BOSS_AWARD_1")) .. " :"
	self.labelAward2.text = tostring(__("GUILD_BOSS_AWARD_2")) .. " :"

	if xyd.Global.lang == "fr_fr" then
		self.labelAward1:X(-180)
		self.labelAward2:X(-155)
	end

	self.labelTitle.text = __("GUILD_BOSS_AWARD_2")

	self:initKillAward()
	self:initBattleAward()
end

function PetTrainingBossAwardWindow:initBattleAward()
	self.itemTitle.text = __("ACTIVITY_COURSE_LEARNING_TEXT07") .. " :"

	if xyd.Global.lang == "fr_fr" then
		self.itemTitle:X(-165)
	end

	local awardsDataList = xyd.tables.petTrainingBossTable:getBattleAwards(1)

	for i = 1, #awardsDataList do
		local itemData = awardsDataList[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end
end

function PetTrainingBossAwardWindow:initKillAward()
	local ids = xyd.tables.petTrainingBossTable:getIds()

	for i = 1, #ids do
		local awardsData = xyd.tables.petTrainingBossTable:getFinalAwards(ids[i])
		local go = NGUITools.AddChild(self.awardContainer, self.item)
		local awardItem = PetTrainingBossKillAwardItem.new(go, {
			awardsData = awardsData,
			rank = ids[i],
			id = ids[i]
		}, self)
	end

	self.awardContainer:GetComponent(typeof(UILayout)):Reposition()
end

function PetTrainingBossKillAwardItem:ctor(go, params, parent)
	self.parent_ = parent
	self.go = go
	self.awardsData = params.awardsData
	self.rank = params.rank
	self.id = params.id

	self:getUIComponent()
	self:initUIComponent()
end

function PetTrainingBossKillAwardItem:getUIComponent()
	local go = self.go
	self.itemTitle = go:ComponentByName("itemTitle", typeof(UILabel))
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.rankImg = go:ComponentByName("rankImg", typeof(UISprite))
end

function PetTrainingBossKillAwardItem:initUIComponent()
	self.itemTitle.text = xyd.tables.petTrainingTextTable:getBoss(self.rank)

	xyd.setUISpriteAsync(self.rankImg, nil, "quiz_diff_" .. self.rank)

	for i = 1, #self.awardsData do
		local itemData = self.awardsData[i]
		local itemId = itemData[1]
		local itemNum = itemData[2]
		local itemIcon = xyd.getItemIcon({
			showSellLable = false,
			uiRoot = self.itemGroup,
			itemID = itemId,
			dragScrollView = self.parent_.scroller,
			num = itemNum
		})

		itemIcon:SetLocalScale(0.72, 0.72, 1)
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

return PetTrainingBossAwardWindow
