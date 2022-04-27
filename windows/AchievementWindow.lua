local BaseWindow = import(".BaseWindow")
local AchievementWindow = class("AchievementWindow", BaseWindow)
local OldSize = {
	w = 720,
	h = 1280
}
local AchievementModel = xyd.models.achievement
local JSON = require("cjson")
local AchievementTable = xyd.tables.achievementTable
local AchievementTypeTable = xyd.tables.achievementTypeTable
local AchievementItem = class("achievementItem", import("app.components.BaseComponent"))

function AchievementItem:ctor(go, parent)
	self.uiRoot_ = go
	self.parent_ = parent
	self.itemsRootList_ = {}
	self.itemID_ = {}
	self.itemNum_ = {}
	local itemTrans = self.uiRoot_.transform
	self.baseWi_ = itemTrans:GetComponent(typeof(UIWidget))
	self.progressBar_ = itemTrans:ComponentByName("progress", typeof(UIProgressBar))
	self.progressDesc_ = itemTrans:ComponentByName("progress/labelDesc", typeof(UILabel))
	self.btnAward_ = itemTrans:NodeByName("btnAward").gameObject
	self.btnAwardImg_ = self.btnAward_:GetComponent(typeof(UISprite))
	self.btnAwardLabel_ = itemTrans:ComponentByName("btnAward/button_label", typeof(UILabel))
	self.missionDesc_ = itemTrans:ComponentByName("missionDesc", typeof(UILabel))
	self.Bg_ = itemTrans:NodeByName("bg").gameObject
	self.imgAward_ = itemTrans:ComponentByName("imgAward", typeof(UISprite))
	self.iconRoot1_ = itemTrans:Find("itemIcon1").gameObject
	self.iconRoot0_ = itemTrans:Find("itemIcon0").gameObject
	self.itemsRootList_[1] = self.iconRoot0_
	self.itemsRootList_[2] = self.iconRoot1_
	self.collectionBefore_ = {}

	self:layout()
	self:registerEvent()
end

function AchievementItem:registerEvent()
	UIEventListener.Get(self.btnAward_).onClick = handler(self, self.onClickAward)
end

function AchievementItem:onClickAward()
	if self.data_.achieve_type == xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT and xyd.models.slot:getCanSummonNum() < 1 then
		xyd.openWindow("partner_slot_increase_window")

		return
	end

	if self.data_ and self.data_.achieve_type == 37 and self.data_.value <= 0 then
		local url = ""
		local key = "CONCERN_SNS_HTTP"

		if xyd.isH5() then
			key = "CONCERN_SNS_HTTP_H5"
		end

		url = __(key)

		if url ~= "" and url ~= key then
			UnityEngine.Application.OpenURL(url)

			local msg = messages_pb.follow_community_req()

			xyd.Backend.get():request(xyd.mid.FOLLOW_COMMUNITY, msg)
			xyd.models.achievement:setRefreshAfterTime(30)
		end

		return
	end

	xyd.models.achievement:getAward(self.data_.achieve_type)
end

function AchievementItem:getAchievementInfo()
	return self.data_
end

function AchievementItem:layout()
	xyd.setUISpriteAsync(self.imgAward_, nil, "mission_awarded_" .. tostring(xyd.Global.lang) .. "_png", nil, )
end

function AchievementItem:update(index, realIndex, info)
	if not info then
		self.uiRoot_:SetActive(false)

		return
	end

	self.uiRoot_:SetActive(true)

	local hasChange = false

	if not self.data_ or info.achieve_id ~= self.data_.achieve_id then
		hasChange = true
	end

	self.data_ = info
	local achieve_id = info.achieve_id

	if achieve_id == 0 then
		achieve_id = AchievementTypeTable:getEndAchievement(info.achieve_type)
	end

	local complete_value = AchievementTable:getCompleteValue(achieve_id) or 0
	local text = AchievementTypeTable:getDesc(info.achieve_type, complete_value)
	self.missionDesc_.text = text
	local progressMaxNum = AchievementTable:getCompleteValue(achieve_id) or 0
	local progressValue = info.value
	local numericType = AchievementTypeTable:getType(info.achieve_type)

	if numericType == 3 then
		if progressMaxNum <= info.value then
			progressValue = progressMaxNum
		else
			progressValue = info.sub_value
		end
	end

	if info.achieve_type == 44 then
		text = AchievementTypeTable:getAllServerText(info.achieve_type, complete_value)
		self.missionDesc_.text = text

		if progressValue < progressMaxNum then
			progressValue = 0
			progressMaxNum = 1
		else
			progressValue = 1
			progressMaxNum = 1
		end
	end

	self.progressDesc_.text = progressValue .. "/" .. progressMaxNum
	self.progressBar_.value = tonumber(progressValue) / tonumber(progressMaxNum)
	self.itemsInfo_ = AchievementTable:getAward(achieve_id)

	self.iconRoot1_:SetActive(false)
	self.iconRoot0_:SetActive(false)

	for idx, itemInfo in ipairs(self.itemsInfo_) do
		local itemRoot = self.itemsRootList_[idx]

		itemRoot:SetActive(true)

		if not self.itemID_[idx] or not self.itemNum_[idx] or self.itemID_[idx] ~= itemInfo[1] and self.itemID_[idx] ~= xyd.tables.itemTable:partnerCost(itemInfo[1])[1] or self.itemNum_[idx] ~= itemInfo[2] then
			for i = 0, itemRoot.transform.childCount - 1 do
				local child = itemRoot.transform:GetChild(i).gameObject

				NGUITools.Destroy(child)
			end

			self.itemNum_[idx] = itemInfo[2]
			local type_ = xyd.tables.itemTable:getType(itemInfo[1])

			if type_ ~= xyd.ItemType.HERO_DEBRIS and type_ ~= xyd.ItemType.HERO and type_ ~= xyd.ItemType.HERO_RANDOM_DEBRIS then
				self.itemID_[idx] = itemInfo[1]
				self.iconItem_ = xyd.getItemIcon({
					noClickSelected = true,
					labelNumScale = 1.6,
					hideText = true,
					scale = 0.7,
					uiRoot = itemRoot,
					itemID = itemInfo[1],
					num = itemInfo[2],
					dragScrollView = self.parent_.scrollView_
				})
			else
				local itemID, itemNum = nil

				if info.achieve_type == xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT then
					itemID = xyd.tables.itemTable:partnerCost(itemInfo[1])[1]
					itemNum = nil
				else
					itemID = itemInfo[1]
					itemNum = itemInfo[2]
				end

				self.itemID_[idx] = itemID
				self.iconItem_ = xyd.getItemIcon({
					noClickSelected = true,
					labelNumScale = 1.6,
					hideText = true,
					scale = 0.7,
					uiRoot = itemRoot,
					itemID = itemID,
					num = itemNum,
					dragScrollView = self.parent_.scrollView_
				})
			end
		end
	end

	if info.achieve_id == 0 then
		self.btnAward_:SetActive(false)
		self.imgAward_.gameObject:SetActive(true)

		self.btnAwardLabel_.text = __("GET2")
	elseif info.value <= 0 and info.achieve_type == 37 then
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setEnabled(self.btnAward_, true)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "white_btn_54_54")

		self.btnAwardLabel_.effectStyle = UILabel.Effect.None
		self.btnAwardLabel_.color = Color.New2(1012112383)
		self.btnAwardLabel_.text = __("GO")
	elseif complete_value <= info.value then
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setEnabled(self.btnAward_, true)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "blue_btn_54_54")

		self.btnAwardLabel_.text = __("GET2")
		self.btnAwardLabel_.effectStyle = UILabel.Effect.Outline
		self.btnAwardLabel_.effectColor = Color.New2(1012112383)
		self.btnAwardLabel_.color = Color.New2(4278124287.0)
	else
		self.btnAward_:SetActive(true)
		self.imgAward_.gameObject:SetActive(false)
		xyd.setUISpriteAsync(self.btnAwardImg_, nil, "blue_btn_54_54")
		xyd.setEnabled(self.btnAward_, false)

		self.btnAwardLabel_.text = __("GET2")
		self.btnAwardLabel_.effectStyle = UILabel.Effect.None
		self.btnAwardLabel_.color = Color.New2(4278124287.0)
	end
end

function AchievementItem:getGameObject()
	return self.uiRoot_
end

AchievementWindow.AchievementItem = AchievementItem

function AchievementWindow:ctor(name, params)
	AchievementWindow.super.ctor(self, name, params)

	self.isActionDone_ = false
	self.interval_ = {
		end__ = 0,
		start = 0
	}
	self.firstIn_ = true
end

function AchievementWindow:initWindow()
	BaseWindow.initWindow(self)

	local winTrans = self.window_.transform
	local main = winTrans:Find("main").gameObject
	local activeHeight = xyd.WindowManager.get():getActiveHeight()
	local activeWidth = xyd.WindowManager.get():getActiveWidth()
	local contentTrans = main.transform
	local sWidth, sHeight = xyd.getScreenSize()

	if sHeight / sWidth <= 1.4 then
		contentTrans.localScale = Vector3(1.15, 1.15, 1.15) * 0.95
		contentTrans.localPosition = Vector3(0, main.transform.localPosition.y * 1.15, 0)
	else
		contentTrans.localScale = Vector3(activeWidth / OldSize.w, activeHeight / OldSize.h, 1) * 0.95
		contentTrans.localPosition = Vector3(0, main.transform.localPosition.y * activeHeight / OldSize.h, 0)
	end

	self.groupNone_ = main:NodeByName("groupNone").gameObject
	self.textureTop_ = main:ComponentByName("texture", typeof(UITexture))
	self.scrollView_ = main:ComponentByName("mid/scrollview", typeof(UIScrollView))
	self.wrapContent_ = main:ComponentByName("mid/scrollview/grid", typeof(MultiRowWrapContent))
	local achievementItemRoot = main:ComponentByName("mid/AchievementItem", typeof(UIWidget)).gameObject

	achievementItemRoot:SetActive(false)

	self.multiWrap_ = require("app.common.ui.FixedMultiWrapContent").new(self.scrollView_, self.wrapContent_, achievementItemRoot, AchievementItem, self)

	self:layout()
	self:initResItem()
end

function AchievementWindow:initResItem()
	self.windowTop = import("app.components.WindowTop").new(self.window_, self.name_)
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

function AchievementWindow:layout()
	xyd.setUITextureAsync(self.textureTop_, "Textures/achieve_web/achieve_top_bg", nil, )
	self:register()
	AchievementModel:getData()

	self.interval_.start = xyd.getServerTime()
end

function AchievementWindow:onUpdateWindow()
	self.groupNone_:SetActive(false)
	self:initMissions()

	if self.interval_.start ~= 0 then
		self.interval_.end__ = xyd.getServerTime()
		self.interval_ = {
			end__ = 0,
			start = 0
		}
	end
end

function AchievementWindow:initMissions()
	local achievements = AchievementModel:getAchievementList()

	if self.firstIn_ then
		local tempList = {}
		self.firstIn_ = false

		for idx, achievement in ipairs(achievements) do
			XYDCo.WaitForFrame(idx, function ()
				table.insert(tempList, achievement)
				self.multiWrap_:setInfos(tempList, {})

				if (idx == #achievements or idx == 1) and self.wrapContent_ and not self.wrapContent_.gameObject:Equals(nil) then
					self.multiWrap_:resetScrollView()
				end
			end, nil)
		end

		return
	end

	self.multiWrap_:setInfos(achievements, {
		keepPosition = true
	})
end

function AchievementWindow:register()
	AchievementWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.GET_ACHIEVEMENT_LIST, self.onUpdateWindow, self)
	self.eventProxy_:addEventListener(xyd.event.SUMMON, self.onBindSummon, self)
end

function AchievementWindow:onBindSummon(event)
	local items = event.data.summon_result.items
	local partners = event.data.summon_result.partners
	local params = {}
	local flag = false
	local itemID_ = 0
	local callback = nil
	local hasFive = false

	local function checkMore(itemID)
		if itemID_ ~= 0 and itemID_ ~= itemID then
			flag = true
		else
			itemID_ = itemID
		end
	end

	if #items > 0 then
		for idx, info in ipairs(items) do
			table.insert(params, info)
			checkMore(info.item_id)
		end
	end

	local new5stars = {}

	if #partners > 0 then
		new5stars = xyd.isHasNew5Stars(event, self.collectionBefore_)

		for idx, partner in ipairs(partners) do
			table.insert(params, {
				item_num = 1,
				item_id = partner.table_id
			})
			checkMore(partner.table_id)

			if not hasFive then
				local star = xyd.tables.partnerTable:getStar(partner.table_id)

				if star >= 5 then
					hasFive = true
				end
			end
		end
	end

	if hasFive then
		function callback()
			xyd.EventDispatcher.loader():dispatchEvent({
				name = xyd.event.HIGH_PRAISE,
				params = {}
			})
		end
	end

	local function effectCallBack()
		xyd.WindowManager.get():closeWindow("summon_res_window")

		self.collectionBefore_ = xyd.models.slot:getCollectionCopy()

		if flag then
			xyd.WindowManager.get():oepnWindow("alert_heros_window", {
				data = params,
				callback = callback
			})
		else
			xyd.alertItems(params, callback, __("SUMMON"))
		end
	end

	if #new5stars > 0 then
		xyd.WindowManager.get():openWindow("summon_effect_res_window", {
			partners = {
				new5stars[1].table_id
			},
			callback = effectCallBack
		})
	else
		effectCallBack()
	end
end

function AchievementWindow:onGetAward(event)
	if event.data.achieve_type == xyd.ACHIEVEMENT_TYPE.BINDING_ACCOUNT then
		self:onUpdateWindow()

		local achieveID = event.data.old_id
		local awards = AchievementTable:getAward(achieveID)
		self.collectionBefore_ = xyd.models.slot:getCollectionCopy()

		xyd.models.summon:summonPartner(xyd.tables.itemTable:getSummonID(awards[1][1]), 1)

		local win = xyd.getWindow("main_window")

		if win then
			win:updateLimitEventImg()
		end
	else
		self:showReward(event)
		self:onUpdateWindow()
	end
end

function AchievementWindow:showReward(event)
	local achieveID = event.data.old_id
	local awrads = AchievementTable:getAward(achieveID)
	local items = {}

	for _, info in ipairs(awrads) do
		local item = {
			item_id = info[1],
			item_num = info[2]
		}

		table.insert(items, item)
	end

	xyd.alertItems(items)
end

function AchievementWindow:willClose()
	AchievementWindow.super.willClose(self)
end

return AchievementWindow
