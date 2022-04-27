local BaseWindow = import(".BaseWindow")
local HeroChallengeFightAwardWindow = class("HeroChallengeFightAwardWindow", BaseWindow)
local BaseComponent = import("app.components.BaseComponent")
local HeroChallengeAwardItem1 = class("HeroChallengeAwardItem1", BaseComponent)
local HeroChallengeAwardItem2 = class("HeroChallengeAwardItem2", BaseComponent)
local HeroChallengeAwardItem3 = class("HeroChallengeAwardItem3", BaseComponent)
local Pet = import("app.models.Pet")
local Monster = import("app.models.Monster")
HeroChallengeFightAwardWindow.RewardType = {
	pet_ids = 3,
	partner_ids = 1,
	buff_ids = 2
}
HeroChallengeFightAwardWindow.HeroChallengeAwardItem1 = HeroChallengeAwardItem1
HeroChallengeFightAwardWindow.HeroChallengeAwardItem2 = HeroChallengeAwardItem2
HeroChallengeFightAwardWindow.HeroChallengeAwardItem3 = HeroChallengeAwardItem3

function HeroChallengeFightAwardWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curSelect_ = 1
	self.skinName = "HeroChallengeFightAwardWindowSkin"
	self.fortId = xyd.models.heroChallenge:getCurFort()
end

function HeroChallengeFightAwardWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:initItems()
	self:registerEvent()
end

function HeroChallengeFightAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject
	self.labelTips = content:ComponentByName("labelTips", typeof(UILabel))
	self.groupMain_ = content:NodeByName("groupMain_").gameObject
	self.panelDepth = self.window_:GetComponent(typeof(UIPanel)).depth
end

function HeroChallengeFightAwardWindow:setLayout()
	self.labelTips.text = __("HERO_CHALLENGE_TIPS4")
end

function HeroChallengeFightAwardWindow:initItems()
	self.curSelect_ = 1
	local awards = xyd.models.heroChallenge:getRewards(self.fortId)

	NGUITools.DestroyChildren(self.groupMain_.transform)

	if awards then
		local curAward = table.remove(awards, 1)
		local type = curAward.reward_type

		dump(curAward)

		if type == HeroChallengeFightAwardWindow.RewardType.partner_ids then
			self:initPartners(curAward.partner_ids)
		elseif type == HeroChallengeFightAwardWindow.RewardType.buff_ids then
			self:initBuffs(curAward.buff_ids)
		elseif type == HeroChallengeFightAwardWindow.RewardType.pet_ids then
			self:iniPets(curAward.pet_ids)
		end
	end
end

function HeroChallengeFightAwardWindow:initPartners(ids)
	print("+++++++++++++++++++++")
	dump(ids)
	HeroChallengeAwardItem1.new(ids, self.groupMain_)
end

function HeroChallengeFightAwardWindow:initBuffs(ids)
	HeroChallengeAwardItem2.new(ids, self.groupMain_)
end

function HeroChallengeFightAwardWindow:iniPets(ids)
	HeroChallengeAwardItem3.new(ids, self.groupMain_, self)
end

function HeroChallengeFightAwardWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.PARTNER_CHALLENGE_PICK_AWARDS, handler(self, self.onPickAward))
end

function HeroChallengeFightAwardWindow:onConfirmTouch(index)
	local select = index and index or self.curSelect_

	xyd.models.heroChallenge:reqPickAwards(self.fortId, select)
end

function HeroChallengeFightAwardWindow:onPickAward()
	local awards = xyd.models.heroChallenge:getRewards(self.fortId)

	if not awards or #awards <= 0 then
		xyd.models.heroChallenge:clearReward(self.fortId)
		xyd.WindowManager.get():closeWindow(self.name_)
	else
		self:initItems()
	end
end

function HeroChallengeFightAwardWindow:onClickEscBack()
end

function HeroChallengeFightAwardWindow:willClose()
	HeroChallengeFightAwardWindow.super.willClose(self)

	local win = xyd.WindowManager.get():getWindow("new_group_buff_detail_window")

	if win then
		xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")
	end
end

local PartnerCard = import("app.components.PartnerCard")

function HeroChallengeAwardItem1:ctor(params, partentGo)
	self.ids = {}
	self.skinName = "HeroChallengeAwardItem1Skin"
	self.ids = params

	HeroChallengeAwardItem1.super.ctor(self, partentGo)
end

function HeroChallengeAwardItem1:getPrefabPath()
	return "Prefabs/Components/hero_challenge_award_item1"
end

function HeroChallengeAwardItem1:initUI()
	HeroChallengeAwardItem1.super.initUI(self)

	local cardGroup = self.go:NodeByName("cardGroup").gameObject
	local btnGroup = self.go:NodeByName("btnGroup").gameObject

	for i = 1, 3 do
		self["group" .. i] = cardGroup:NodeByName("group" .. i).gameObject
		self["btn" .. i] = btnGroup:NodeByName("btn" .. i).gameObject
		self["btn" .. i .. "Label"] = self["btn" .. i]:ComponentByName("button_label", typeof(UILabel))
	end

	for i = 1, 3 do
		xyd.setBgColorType(self["btn" .. i], xyd.ButtonBgColorType.blue_btn_65_65)
	end

	self:createChildren()
end

function HeroChallengeAwardItem1:createChildren()
	self:layout()
	self:registerEvent()
end

function HeroChallengeAwardItem1:getInfoByID(id)
	local itemID = xyd.tables.monsterTable:getPartnerLink(id)
	local params = {
		tableID = itemID,
		table_id = itemID,
		star = xyd.tables.partnerTable:getStar(itemID),
		lev = xyd.tables.monsterTable:getLv(id),
		grade = xyd.tables.monsterTable:getGrade(id),
		group = xyd.tables.partnerTable:getGroup(itemID)
	}

	return params
end

function HeroChallengeAwardItem1:layout()
	local ids = self.ids

	for i = 1, #ids do
		local id = ids[i]
		local params = self:getInfoByID(id)
		local card = PartnerCard.new(self["group" .. i])

		card:setInfo(params)
	end

	for i = 1, 3 do
		self["btn" .. i .. "Label"].text = __("GET")
	end
end

function HeroChallengeAwardItem1:registerEvent()
	for i = 1, 3 do
		UIEventListener.Get(self["btn" .. tostring(i)]).onClick = function ()
			self:onItemTouch(i)
		end

		UIEventListener.Get(self["group" .. tostring(i)]).onClick = function ()
			self:onCardTouch(i)
		end
	end
end

function HeroChallengeAwardItem1:onCardTouch(index)
	local id = self.ids[index]
	local pInfo = Monster.new()

	pInfo:populateWithTableID(id)
	xyd.WindowManager.get():openWindow("partner_info", {
		notShowWays = true,
		partner = pInfo
	})
end

function HeroChallengeAwardItem1:onItemTouch(index)
	local win = xyd.WindowManager.get():getWindow("hero_challenge_fight_award_window")

	if win then
		win:onConfirmTouch(index)
	end
end

local GroupBuffIcon = import("app.components.GroupBuffIcon")

function HeroChallengeAwardItem2:ctor(params, partentGo)
	self.ids = {}
	self.curSelect_ = 1
	self.skinName = "HeroChallengeAwardItem2Skin"
	self.ids = params

	HeroChallengeAwardItem2.super.ctor(self, partentGo)
end

function HeroChallengeAwardItem2:getPrefabPath()
	return "Prefabs/Components/hero_challenge_award_item2"
end

function HeroChallengeAwardItem2:initUI()
	HeroChallengeAwardItem2.super.initUI(self)

	local cardGroup = self.go:NodeByName("cardGroup").gameObject

	for i = 1, 3 do
		local group = cardGroup:NodeByName("group" .. i).gameObject
		self["imgSelect" .. i] = group:ComponentByName("imgSelect" .. i, typeof(UISprite))
		self["groupIcon" .. i] = group:NodeByName("groupIcon" .. i).gameObject
		self["label" .. i] = group:ComponentByName("label" .. i, typeof(UILabel))
		self["group" .. i] = group

		xyd.setUISpriteAsync(group:ComponentByName("imgBg" .. i, typeof(UISprite)), nil, "h_challenge_card_bg")
		xyd.setUISpriteAsync(self["imgSelect" .. i], nil, "h_challenge_icon1")
	end

	self.labelTips = self.go:ComponentByName("labelTips", typeof(UILabel))
	self.btnSure = self.go:NodeByName("btnSure").gameObject

	xyd.setBgColorType(self.btnSure, xyd.ButtonBgColorType.blue_btn_65_65)

	self.btnSureLabel = self.btnSure:ComponentByName("button_label", typeof(UILabel))

	self:createChildren()
end

function HeroChallengeAwardItem2:createChildren()
	self:layout()
	self:registerEvent()
	self:updateSelect(self.curSelect_, true)
end

function HeroChallengeAwardItem2:layout()
	local ids = self.ids

	for i = 1, #ids do
		local id = ids[i]
		local icon = GroupBuffIcon.new(self["groupIcon" .. tostring(i)])

		icon:SetLocalScale(1.54, 1.54, 1)
		icon:setInfo(id, true, xyd.GroupBuffIconType.HERO_CHALLENGE)

		local name_ = xyd.tables.partnerChallengeBuffTable:getName(id)
		self["label" .. i].text = name_
	end

	self.btnSureLabel.text = __("SURE")
end

function HeroChallengeAwardItem2:registerEvent()
	for i = 1, 3 do
		UIEventListener.Get(self["group" .. tostring(i)]).onClick = function ()
			self:updateSelect(i)
		end
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		self:onItemTouch()
	end
end

function HeroChallengeAwardItem2:onItemTouch()
	local win = xyd.WindowManager.get():getWindow("hero_challenge_fight_award_window")

	if win then
		win:onConfirmTouch(self.curSelect_)
	end
end

function HeroChallengeAwardItem2:updateSelect(index, isFirst)
	local win = xyd.WindowManager.get():getWindow("new_group_buff_detail_window")

	if not isFirst and self.curSelect_ == index and win then
		xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")

		return
	elseif not isFirst and self.curSelect_ == index then
		self:showInfo(index)

		return
	end

	local tips_ = ""

	for i = 1, 3 do
		local imgSelect = self["imgSelect" .. tostring(i)]

		if index == i then
			imgSelect:SetActive(true)

			tips_ = xyd.tables.partnerChallengeBuffTable:getName(self.ids[i])

			if not isFirst then
				self:showInfo(index)
			end
		else
			imgSelect:SetActive(false)
		end
	end

	self.curSelect_ = index
	self.labelTips.text = __("HERO_CHALLENGE_TIPS5", tips_)
end

function HeroChallengeAwardItem2:showInfo(index)
	local id = self.ids[index]

	xyd.WindowManager.get():openWindow("new_group_buff_detail_window", {
		contenty = 220,
		buffID = id,
		type = xyd.GroupBuffIconType.HERO_CHALLENGE
	})
end

function HeroChallengeAwardItem3:ctor(params, partentGo, parent)
	self.ids = {}
	self.parent_ = parent
	self.skinName = "HeroChallengeAwardItem3Skin"
	self.ids = params

	HeroChallengeAwardItem3.super.ctor(self, partentGo)
end

function HeroChallengeAwardItem3:getPrefabPath()
	return "Prefabs/Components/hero_challenge_award_item3"
end

function HeroChallengeAwardItem3:initUI()
	HeroChallengeAwardItem3.super.initUI(self)

	local cardGroup = self.go:NodeByName("cardGroup").gameObject

	for i = 1, 3 do
		local group = cardGroup:NodeByName("group" .. i).gameObject
		self["group" .. i] = group
		self["gScrollRect" .. i] = group:ComponentByName("gScrollRect" .. i, typeof(UIPanel))
		self["groupModel" .. i] = self["gScrollRect" .. i]:NodeByName("groupModel" .. i).gameObject
		self["labelLevel" .. i] = group:ComponentByName("gScrollRect" .. i .. "/labelLevel" .. i, typeof(UILabel))
		self["border0" .. i] = group:ComponentByName("gScrollRect" .. i .. "/border0" .. i, typeof(UISprite))
		self["border1" .. i] = group:ComponentByName("gScrollRect" .. i .. "/border1" .. i, typeof(UISprite))
		self["btnCheck" .. i] = group:NodeByName("gScrollRect" .. i .. "/btnCheck" .. i).gameObject
		self["label" .. i] = group:ComponentByName("gScrollRect" .. i .. "/label" .. i, typeof(UILabel))
		self["gScrollRect" .. i].depth = self.parent_.panelDepth + 1
		local bg = self["gScrollRect" .. i].gameObject:ComponentByName("bg" .. i, typeof(UISprite))

		xyd.setUISpriteAsync(bg, nil, "pet_kind01")
	end

	local btnGroup = self.go:NodeByName("btnGroup").gameObject

	for i = 1, 3 do
		local btn = btnGroup:NodeByName("btn" .. i).gameObject
		self["btn" .. i] = btn
		self["btn" .. i .. "Label"] = btn:ComponentByName("button_label", typeof(UILabel))

		xyd.setBgColorType(btn, xyd.ButtonBgColorType.blue_btn_65_65)
	end

	self:createChildren()
end

function HeroChallengeAwardItem3:createChildren()
	for i = 1, 3 do
		local group = self["gScrollRect" .. tostring(i)]
	end

	self:layout()
	self:registerEvent()
end

function HeroChallengeAwardItem3:layout()
	local ids = self.ids

	for i = 1, #ids do
		local id = ids[i]

		self:initItem(id, i)
	end

	for i = 1, 3 do
		self["btn" .. tostring(i) .. "Label"].text = __("GET")
	end
end

function HeroChallengeAwardItem3:initItem(petId, index)
	local pet = Pet.new()
	local skills = xyd.tables.miscTable:split2num("challenge_pet_skill", "value", "|")

	pet:populate({
		pet_id = petId,
		lev = xyd.tables.miscTable:getNumber("challenge_pet_lv", "value"),
		grade = xyd.tables.petTable:getMaxGrade(petId),
		skills = skills
	})

	self["labelLevel" .. tostring(index)].text = "Lv." .. tostring(pet:getLevel())
	self["label" .. tostring(index)].text = pet:getName()
	local grade = pet:getGrade()
	local strs = xyd.tables.miscTable:split("pet_frame_use", "value", "|")

	xyd.setUISpriteAsync(self["border0" .. tostring(index)], nil, strs[grade])
	xyd.setUISpriteAsync(self["border1" .. tostring(index)], nil, strs[grade])

	local modelName = pet:getModelName()
	local pos = xyd.tables.modelTable:getPetCardPos(pet:getModelID())
	local db = xyd.Spine.new(self["groupModel" .. tostring(index)])

	db:setInfo(modelName, function ()
		db:SetLocalPosition(pos[2], -pos[3] * 0.6, 0)
		db:SetLocalScale(pos[1] * 0.6, pos[1] * 0.6, 1)
		db:play("idle", 0)
		db:setRenderPanel(self["gScrollRect" .. tostring(index)])
	end)
end

function HeroChallengeAwardItem3:registerEvent()
	for i = 1, 3 do
		UIEventListener.Get(self["btnCheck" .. tostring(i)]).onClick = function ()
			self:onDisplay(i)
		end

		UIEventListener.Get(self["btn" .. tostring(i)]).onClick = function ()
			self:onItemTouch(i)
		end
	end
end

function HeroChallengeAwardItem3:onItemTouch(index)
	local win = xyd.WindowManager.get():getWindow("hero_challenge_fight_award_window")

	if win then
		win:onConfirmTouch(index)
	end
end

function HeroChallengeAwardItem3:onDisplay(index)
	local id = self.ids[index]

	xyd.WindowManager:get():openWindow("pet_info_window", {
		id = id
	})
end

return HeroChallengeFightAwardWindow
