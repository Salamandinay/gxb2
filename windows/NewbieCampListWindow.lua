local NewbieCampListWindow = class("NewbieCampListWindow", import(".BaseWindow"))
local NewbieCampListItem = class("NewbieCampListItem", import("app.components.BaseComponent"))
local WindowTop = import("app.components.WindowTop")

function NewbieCampListWindow:ctor(name, params)
	NewbieCampListWindow.super.ctor(self, name, params)

	self.phase_id_ = params.phase_id
	self.need_req_ = params.need_req
end

function NewbieCampListWindow:initWindow()
	NewbieCampListWindow.super.initWindow(self)
	self:getComponent()
	self:initResItem()
	self:initAward()
	self.eventProxy_:addEventListener(xyd.event.GET_ROOKIE_MISSION_AWARD, function ()
		self:updateData()
	end)
	self.eventProxy_:addEventListener(xyd.event.GET_ROOKIE_MISSION_LIST, function ()
		self:updateData()
	end)

	if self.need_req_ then
		xyd.models.newbieCamp:reqData()
	else
		self:updateData(true)
	end
end

function NewbieCampListWindow:getComponent()
	local goTrans = self.window_:NodeByName("content")
	self.awardItems_ = goTrans:ComponentByName("awardItems", typeof(UIGrid))
	self.awradLabel_ = goTrans:ComponentByName("awardLabel", typeof(UILabel))
	self.scrollView_ = goTrans:ComponentByName("scrollGroup/scrollView", typeof(UIScrollView))
	self.grid_ = goTrans:ComponentByName("scrollGroup/scrollView/grid", typeof(MultiRowWrapContent))
	local AchievementItem = goTrans:NodeByName("AchievementItem").gameObject
	self.floatRoot_ = goTrans:NodeByName("floatRoot").gameObject
	self.wrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.grid_, AchievementItem, NewbieCampListItem, self)
end

function NewbieCampListWindow:initResItem()
	self.windowTop = WindowTop.new(self.window_, self.name_)
	local items = {
		{
			id = xyd.ItemID.CRYSTAL
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
end

function NewbieCampListWindow:initAward()
	local award = xyd.tables.newbieCampBoardTable:getAward(self.phase_id_)
	self.awradLabel_.text = __("BEGINNER_QUEST_MISSION")

	if xyd.Global.lang == "fr_fr" then
		-- Nothing
	end

	for i = 1, #award do
		local data = award[i]
		local params = {
			scale = 0.7037037037037037,
			uiRoot = self.awardItems_.gameObject,
			itemID = data[1],
			num = data[2]
		}

		xyd.getItemIcon(params)
	end

	self.awardItems_:Reposition()
end

function NewbieCampListWindow:updateData(firstIn)
	local list = xyd.models.newbieCamp:getStructureDataByPhase(self.phase_id_)

	dump(list)

	if firstIn then
		self.wrap_:setInfos(list, {})
		self.wrap_:resetPosition()
	else
		self.wrap_:setInfos(list, {
			keepPosition = true
		})
	end
end

function NewbieCampListItem:ctor(go, parent)
	self.uiRoot_ = go
	self.parent_ = parent
	self.itemsRootList_ = {}
	self.itemID_ = {}
	local itemTrans = self.uiRoot_.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progressBar_ = itemTrans:ComponentByName("progress", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progress/labelDesc", typeof(UILabel))
	self.btnAward_ = itemTrans:ComponentByName("btnAward", typeof(UISprite))
	self.btnAwardMask_ = itemTrans:ComponentByName("btnAward/mask", typeof(UISprite)).gameObject
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/button_label", typeof(UILabel))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.Bg_ = itemTrans:NodeByName("bg").gameObject
	self.imgAward_ = itemTrans:ComponentByName("imgAward", typeof(UISprite))
	self.iconRoot1_ = itemTrans:Find("itemIcon1").gameObject
	self.iconRoot0_ = itemTrans:Find("itemIcon0").gameObject
	self.itemsRootList_[1] = self.iconRoot0_
	self.itemsRootList_[2] = self.iconRoot1_

	self:registerEvent()
end

function NewbieCampListItem:updateBtn()
	self.btnAwardLabel_.text = __("GET2")
end

function NewbieCampListItem:registerEvent()
	UIEventListener.Get(self.btnAward_.gameObject).onClick = handler(self, self.onClickAward)
end

function NewbieCampListItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	self.status_ = info.status
	self.value_ = info.value
	self.id_ = info.id
	local maximum = xyd.tables.newbieCampTable:getComplete(self.id_)
	self.progressBar_.value = math.min(1, self.value_ / maximum)
	local award = xyd.tables.newbieCampTable:getAward(self.id_)
	self.missionDesc_.text = xyd.tables.newbieCampTextTable:getDesc(self.id_)
	self.progressDesc_.text = info.value .. "/" .. maximum

	self.itemsRootList_[1]:SetActive(false)
	self.itemsRootList_[2]:SetActive(false)

	for i = 1, #award do
		local data = award[i]

		if not self.itemID_[data[1]] or self.itemID_[data[1]] ~= data[2] then
			self.itemsRootList_[i]:SetActive(true)
			NGUITools.DestroyChildren(self.itemsRootList_[i].transform)

			local params = {
				scale = 0.7037037037037037,
				uiRoot = self.itemsRootList_[i],
				itemID = data[1],
				num = data[2],
				dragScrollView = self.parent_.scrollView_
			}

			xyd.getItemIcon(params)
		end
	end

	xyd.setUISpriteAsync(self.imgAward_, nil, "mission_awarded_" .. tostring(xyd.Global.lang))
	self:updateBtn()
end

function NewbieCampListItem:onClickAward()
	if self.status_ == 0 then
		local limit_params = xyd.tables.newbieCampTable:getGoLimit(self.id_)
		local level_limit = limit_params[1]
		local vip_limit = limit_params[2]

		if level_limit and #limit_params == 1 and xyd.models.backpack:getLev() < level_limit then
			xyd.alertTips(__("FUNC_OPEN_LEV", level_limit))

			return
		elseif level_limit and xyd.models.backpack:getLev() < level_limit and xyd.models.backpack:getVipLev() < vip_limit then
			xyd.alertTips(__("GAMBLE_DOOR_TIPS", level_limit, vip_limit))

			return
		end

		local goWin = xyd.tables.newbieCampTable:getGoWindow(self.id_)
		local params = xyd.tables.newbieCampTable:getGoParams(self.id_)

		if xyd.tables.windowTable:getLayerType(goWin) < xyd.UILayerType.FLOATING_UI or goWin == "trial_enter_window" or goWin == "slot_window" then
			local function callback()
				if goWin == "tower_window" or goWin == "campaign_window" then
					xyd.models.newbieCamp:reqData()

					return
				end

				xyd.WindowManager.get():openWindow("newbie_camp_list_window", {
					need_req = true,
					phase_id = xyd.tables.newbieCampTable:getPhaseId(self.id_)
				})

				if xyd.WindowManager.get():getWindow("slot_window") then
					xyd.WindowManager.get():closeWindow("slot_window")
				end
			end

			params.closeCallBack = callback

			xyd.WindowManager.get():closeWindow("newbie_camp_list_window", function ()
				xyd.WindowManager.get():openWindow(goWin, params)
			end)
		else
			local function callback()
				xyd.models.newbieCamp:reqData()
			end

			params.closeCallBack = callback

			xyd.WindowManager.get():openWindow(goWin, params)
		end

		return
	end

	if self.status_ == 1 then
		xyd.models.newbieCamp:reqAward(self.id_)
	end
end

function NewbieCampListItem:updateBtn()
	if self.status_ == 0 then
		local go_win = xyd.tables.newbieCampTable:getGoWindow(self.id_)

		if go_win ~= nil and #go_win > 0 then
			self.btnAwardLabel_.text = __("GO")
			self.btnAwardLabel_.color = Color.New2(1012112383)

			xyd.setUISpriteAsync(self.btnAward_, nil, "white_btn_60_60")
			self.btnAwardMask_:SetActive(false)
		else
			self.btnAwardLabel_.text = __("GET2")

			xyd.setUISpriteAsync(self.btnAward_, nil, "white_btn_60_60")

			self.btnAwardLabel_.color = Color.New2(1012112383)

			self.btnAwardMask_:SetActive(true)
		end

		self.btnAward_.gameObject:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
	elseif self.status_ == 1 then
		self.btnAward_.gameObject:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)

		self.btnAwardLabel_.color = Color.New2(4294967295.0)

		xyd.setUISpriteAsync(self.btnAward_, nil, "blue_btn_60_60")

		self.btnAwardLabel_.text = __("GET2")

		self.btnAwardMask_:SetActive(false)
	else
		self.btnAward_.gameObject:SetActive(false)
		self.imgAward_.gameObject:SetActive(true)
	end
end

function NewbieCampListItem:getGameObject()
	return self.uiRoot_
end

return NewbieCampListWindow
