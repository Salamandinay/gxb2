local ActivityNewTrialFightAwardWindow = class("ActivityNewTrialFightAwardWindow", import(".BaseWindow"))
local ActivityNewTrialFightBuffItem = class("ActivityNewTrialFightBuffItem", import("app.components.BaseComponent"))
local GroupBuffIcon = import("app.components.GroupBuffIcon")
ActivityNewTrialFightAwardWindow.ActivityNewTrialFightBuffItem = ActivityNewTrialFightBuffItem

function ActivityNewTrialFightAwardWindow:ctor(name, params)
	ActivityNewTrialFightAwardWindow.super.ctor(self, name, params)

	self.info = params.info
end

function ActivityNewTrialFightAwardWindow:initWindow()
	ActivityNewTrialFightAwardWindow.super.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:initItems()
	self:registerEvent()
end

function ActivityNewTrialFightAwardWindow:getUIComponent()
	local trans = self.window_.transform
	local content = trans:NodeByName("content").gameObject
	self.labelTips = content:ComponentByName("labelTips", typeof(UILabel))
	self.groupMain_ = content:NodeByName("groupMain_").gameObject
end

function ActivityNewTrialFightAwardWindow:initItems()
	self.curSelect_ = 0
	local awards = self.info.buff_rewards

	if awards then
		self:initBuffs(awards)
	end
end

function ActivityNewTrialFightAwardWindow:initBuffs(awards)
	ActivityNewTrialFightBuffItem.new(awards, self.groupMain_)
end

function ActivityNewTrialFightAwardWindow:setLayout()
	self.labelTips.text = __("HERO_CHALLENGE_TIPS4")
end

function ActivityNewTrialFightAwardWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.NEW_TRIAL_PICK_BUFF, handler(self, self.onPickAward))
end

function ActivityNewTrialFightAwardWindow:onPickAward(event)
	xyd.BattleController.get().newTrialInfo = event.data.info
	local win = xyd.WindowManager.get():getWindow("battle_window")

	if not win then
		local win2 = xyd.WindowManager.get():getWindow("trial_window")

		if win2 then
			win2:onNextPoint({
				data = event.data.info
			}, true)
		end
	end

	local win = xyd.WindowManager.get():getWindow("new_group_buff_detail_window")

	if win then
		xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityNewTrialFightAwardWindow:onConfirmTouch(index)
	local select_ = xyd.checkCondition(index, index, self.curSelect_)
	local msg = messages_pb.new_trial_pick_buff_req()
	msg.index = select_

	xyd.Backend.get():request(xyd.mid.NEW_TRIAL_PICK_BUFF, msg)
end

function ActivityNewTrialFightBuffItem:ctor(params, partentGo)
	self.ids = {}
	self.curSelect_ = 0
	self.ids = params

	ActivityNewTrialFightBuffItem.super.ctor(self, partentGo)
end

function ActivityNewTrialFightBuffItem.getPrefabPath()
	return "Prefabs/Components/hero_challenge_award_item2"
end

function ActivityNewTrialFightBuffItem:initUI()
	ActivityNewTrialFightBuffItem.super.initUI(self)

	local cardGroup = self.go:NodeByName("cardGroup").gameObject
	local cardTable = cardGroup:GetComponent(typeof(UITable))

	for i = 1, 3 do
		local group = cardGroup:NodeByName("group" .. i).gameObject
		self["imgSelect" .. i] = group:ComponentByName("imgSelect" .. i, typeof(UISprite))
		self["groupIcon" .. i] = group:NodeByName("groupIcon" .. i).gameObject
		self["label" .. i] = group:ComponentByName("label" .. i, typeof(UILabel))
		self["group" .. i] = group

		xyd.setUISpriteAsync(group:ComponentByName("imgBg" .. i, typeof(UISprite)), nil, "h_challenge_card_bg")
		xyd.setUISpriteAsync(self["imgSelect" .. i], nil, "h_challenge_icon1")

		if i > #self.ids then
			group:SetActive(false)
		end
	end

	cardTable:Reposition()

	self.labelTips = self.go:ComponentByName("labelTips", typeof(UILabel))
	self.btnSure = self.go:NodeByName("btnSure").gameObject

	xyd.setBgColorType(self.btnSure, xyd.ButtonBgColorType.blue_btn_65_65)

	self.btnSureLabel = self.btnSure:ComponentByName("button_label", typeof(UILabel))

	self:createChildren()
end

function ActivityNewTrialFightBuffItem:createChildren()
	self:layout()
	self:registerEvent()
	self:updateSelect(self.curSelect_, true)
end

function ActivityNewTrialFightBuffItem:layout()
	local ids = self.ids

	for i = 1, #ids do
		local id = ids[i]
		local icon = GroupBuffIcon.new(self["groupIcon" .. tostring(i)])

		icon:SetLocalScale(1.3714285714285714, 1.3714285714285714, 1)
		icon:setInfo(id, true, xyd.GroupBuffIconType.NEW_TRIAL)

		local name_ = xyd.tables.newTrialBuffTable:getName(id)
		self["label" .. i].text = name_
	end

	self.btnSureLabel.text = __("SURE")
end

function ActivityNewTrialFightBuffItem:registerEvent()
	for i = 1, 3 do
		UIEventListener.Get(self["group" .. tostring(i)]).onClick = function ()
			self:updateSelect(i)
		end
	end

	UIEventListener.Get(self.btnSure).onClick = function ()
		self:onItemTouch()
	end
end

function ActivityNewTrialFightBuffItem:onItemTouch()
	if self.curSelect_ == 0 then
		xyd.alert(xyd.AlertType.TIPS, __("NEW_TRIAL_BUFF_TIPS"))

		return
	end

	local win = xyd.WindowManager.get():getWindow("activity_new_trial_fight_award_window")

	if win then
		win:onConfirmTouch(self.curSelect_)
	end
end

function ActivityNewTrialFightBuffItem:updateSelect(index, isFirst)
	local win = xyd.WindowManager.get():getWindow("new_group_buff_detail_window")

	if not isFirst and self.curSelect_ == index and win then
		xyd.WindowManager.get():closeWindow("new_group_buff_detail_window")

		return
	elseif not isFirst and self.curSelect_ == index then
		self:showInfo(index)

		return
	end

	self.curSelect_ = index
	local tips_ = ""

	for i = 1, 3 do
		local imgSelect = self["imgSelect" .. tostring(i)]

		if self.curSelect_ == i then
			imgSelect:SetActive(true)

			tips_ = xyd.tables.newTrialBuffTable:getName(self.ids[i])

			if not isFirst then
				self:showInfo(index)
			end
		else
			imgSelect:SetActive(false)
		end
	end

	self.labelTips.text = __("HERO_CHALLENGE_TIPS5", tips_)
end

function ActivityNewTrialFightBuffItem:showInfo(index)
	local id = self.ids[index]

	xyd.WindowManager.get():openWindow("new_group_buff_detail_window", {
		contenty = 250,
		buffID = id,
		type = xyd.GroupBuffIconType.NEW_TRIAL
	})
end

return ActivityNewTrialFightAwardWindow
