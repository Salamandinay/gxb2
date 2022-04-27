local ActivityContent = import(".ActivityContent")
local ActivityLasso = class("ActivityLasso", ActivityContent)
local FixedWrapContent = import("app.common.ui.FixedWrapContent")
local CountDown = import("app.components.CountDown")
local json = require("cjson")
local AwardItem = class("AwardItem", import("app.components.CopyComponent"))
local AdvanceIcon = import("app.components.AdvanceIcon")

function ActivityLasso:ctor(parentGO, params, parent)
	ActivityLasso.super.ctor(self, parentGO, params, parent)
end

function ActivityLasso:getPrefabPath()
	return "Prefabs/Windows/activity/activity_lasso"
end

function ActivityLasso:initUI()
	self:getUIComponent()
	ActivityLasso.super.initUI(self)
	self:registListener()
	self:initUIComponent()
end

function ActivityLasso:getUIComponent()
	self.bg = self.go:NodeByName("bg").gameObject
	self.logoImg = self.go:ComponentByName("logoImg", typeof(UISprite))
	self.helpBtn = self.go:NodeByName("helpBtn").gameObject
	self.searchBtn = self.go:NodeByName("searchBtn").gameObject
	self.itemNode = self.go:NodeByName("itemNode").gameObject
	self.topSource = self.go:NodeByName("topSource").gameObject
	self.sourceNumText = self.topSource:ComponentByName("sourceNumText", typeof(UILabel))
	self.addBtn = self.topSource:NodeByName("addBtn").gameObject
	self.bottomNode = self.go:NodeByName("bottomNode").gameObject
	self.listContainer = self.bottomNode:NodeByName("listContainer").gameObject
	self.btnNode = self.bottomNode:NodeByName("btnNode").gameObject
	self.numText = self.btnNode:ComponentByName("numText", typeof(UILabel))
	self.btnWords = self.btnNode:ComponentByName("btnWords", typeof(UILabel))
	self.btn = self.btnNode:NodeByName("btn").gameObject
	self.noClickNode = self.go:NodeByName("noClickNode").gameObject

	self.noClickNode:SetActive(false)

	self.isPlaying = false
	self.midNode = self.go:NodeByName("midNode").gameObject
	self.effectStartPos = self.midNode:NodeByName("effectStartPos").gameObject
	self.rankListContainer_UIWrapContent = self.listContainer:ComponentByName("listContainer", typeof(UIWrapContent))
	self.scroller = self.bottomNode:ComponentByName("listContainer", typeof(UIScrollView))
	self.wrapContent = FixedWrapContent.new(self.scroller, self.rankListContainer_UIWrapContent, self.itemNode, AwardItem, self)
end

function ActivityLasso:resizeToParent()
	ActivityLasso.super.resizeToParent(self)
	self:resizePosY(self.bg, -439, -530)
	self:resizePosY(self.bottomNode, -808, -961)
	self:resizePosY(self.btnNode, 11, 29)
	self:resizePosY(self.midNode, -450, -541)
	self:resizePosY(self.topSource, -126, -218)
	self:resizePosY(self.logoImg, -96, -127)
	self:resizePosY(self.btnWords, -63, -89)
	self:resizePosY(self.numText, -33, -55)
	self:resizePosY(self.noClickNode, -439, -530)
	self:resizePosY(self.effectStartPos, -335, -377)
end

function ActivityLasso:registListener()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("help_window", {
			key = "ACTIVITY_LASSO_HELP"
		})
	end

	UIEventListener.Get(self.searchBtn).onClick = function ()
		xyd.WindowManager:get():openWindow("activity_lasso_awards_window")
	end

	UIEventListener.Get(self.btn).onClick = function ()
		local itemLeftNum = xyd.models.backpack:getItemNumByID(xyd.ItemID.LASSO)

		if itemLeftNum <= 0 then
			xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTextTable:getName(xyd.ItemID.LASSO)))

			return
		end

		local leftCircle = self.activityData:getLeftCircle()
		local maxNum = 15

		if itemLeftNum < 15 then
			maxNum = itemLeftNum
		end

		if leftCircle < maxNum then
			maxNum = leftCircle
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_multiple = 1,
			select_max_num = maxNum,
			show_max_num = maxNum,
			icon_info = {
				height = 45,
				width = 45,
				name = "icon_" .. xyd.ItemID.LASSO
			},
			title_text = __("ACTIVITY_LASSO_TITLE"),
			explain_text = __("ACTIVITY_LASSO_TEXT01"),
			sure_callback = function (num)
				self:useLasso(num)

				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end
			end
		})
	end

	UIEventListener.Get(self.addBtn).onClick = function ()
		local params = {
			showGetWays = true,
			itemID = xyd.ItemID.LASSO,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end

	for i = 1, 15 do
		local theNode = self.midNode:NodeByName("awardNode" .. i).gameObject
		local clickNode = theNode:NodeByName("clickNode").gameObject

		UIEventListener.Get(clickNode).onClick = function ()
			xyd.WindowManager.get():openWindow("halloween_show_award_window", {
				currentRound = i
			})
		end
	end

	self:registerEvent(xyd.event.ITEM_CHANGE, function ()
		self:updateTopSource()
	end)
	self:registerEvent(xyd.event.ACTIVITY_LASSO_GET_AWARD, handler(self, self.getAward))
end

function ActivityLasso:getAward(event)
	local params = event.params
	local hasBig = false

	for k, v in ipairs(params.ids) do
		if v == -1 then
			hasBig = true

			break
		end
	end

	local firstK = nil

	for k, v in ipairs(params.ids) do
		local index = v
		local itemId = 1
		local itemNum = 1

		if v == -1 then
			index = 15
		else
			local dropsArr = xyd.tables.miscTable:split2num("activity_lasso_gamble", "value", "|")
			local infoId = self.activityData.detail.awards[index]
			local dropId = dropsArr[index]
			local showDropId = dropId .. "00" .. infoId
			local award = xyd.tables.dropboxShowTable:getItem(showDropId)

			if award then
				itemId = award[1]
				itemNum = award[2]
			end
		end

		local theNode = self.midNode:NodeByName("awardNode" .. index).gameObject

		self.noClickNode:SetActive(true)

		self.isPlaying = true
		local theEffect = xyd.Spine.new(self.effectStartPos.gameObject)

		theEffect:setInfo("fx_lasso", function ()
			theEffect:setRenderTarget(self.effectStartPos:GetComponent(typeof(UITexture)), 2)
			theEffect:SetLocalScale(0.5)
			theEffect:play("hit", 5, 3, function ()
				theEffect:SetLocalScale(1)
				theEffect:play("unit", 0)

				local action = self:getSequence(function ()
					theEffect:play("texiao01", 1, 1, function ()
						theEffect:destroy()

						if not firstK then
							xyd.itemFloat(params.items)
						end

						firstK = k

						if not hasBig then
							local container = theNode:NodeByName("iconContainer").gameObject
							local item = xyd.getItemIcon({
								show_has_num = true,
								showGetWays = false,
								notShowGetWayBtn = true,
								scale = 0.7037037037037037,
								itemID = itemId,
								num = itemNum,
								uiRoot = container,
								wndType = xyd.ItemTipsWndType.ACTIVITY
							})

							item:setChoose(true)
						elseif index == 15 then
							self:updateNewRound()
						end

						self.noClickNode:SetActive(false)

						self.isPlaying = false
					end)

					local circle = theNode:NodeByName("circle").gameObject

					circle:SetActive(true)
				end, true)
				local posX = theNode.transform.localPosition.x - self.effectStartPos.transform.localPosition.x
				local posY = theNode.transform.localPosition.y - self.effectStartPos.transform.localPosition.y

				action:Append(theEffect.go.transform:DOLocalMove(Vector3(posX, posY, 0), 0.5))
			end)
		end)
	end
end

function ActivityLasso:updateNewRound()
	for index = 1, 15 do
		local theNode = self.midNode:NodeByName("awardNode" .. index).gameObject
		local container = theNode:NodeByName("iconContainer").gameObject

		NGUITools.DestroyChildren(container.transform)

		local circle = theNode:NodeByName("circle").gameObject

		circle:SetActive(false)
	end

	local nowRound = self.activityData.detail.round
	local selectIndex = self.activityData.detail.finished_ids[nowRound - 1]
	local awards = xyd.tables.activityLassoAwardsTable:getAwards(nowRound - 1)
	local theAward = awards[selectIndex]
	local items = {}

	table.insert(items, {
		item_id = theAward[1],
		item_num = theAward[2]
	})
	xyd.WindowManager.get():openWindow("gamble_rewards_window", {
		wnd_type = 2,
		data = items
	})
	self:updateWrap()
end

function ActivityLasso:updateWrap()
	local round = self.activityData.detail.round
	local ids = xyd.tables.activityLassoAwardsTable:getIDs()
	local ids_ = {}
	local idsNum = #ids

	if round > #ids then
		idsNum = round
	end

	for i = 1, idsNum do
		table.insert(ids_, i)
	end

	self.wrapContent:setInfos(ids_, {})

	if round > #ids_ - 3 then
		round = #ids_ - 3
	end

	local moveX = -round * 94 - 52
	local sp = SpringPanel.Begin(self.scroller.gameObject, Vector3(moveX, 22, 0), 10)
end

function ActivityLasso:updateMidNodeAwards()
	for index = 1, 14 do
		local theNode = self.midNode:NodeByName("awardNode" .. index).gameObject
		local circle = theNode:NodeByName("circle").gameObject
		local container = theNode:NodeByName("iconContainer").gameObject
		local infoId = self.activityData.detail.awards[index]

		if infoId == 0 then
			circle:SetActive(false)
			NGUITools.DestroyChildren(container.transform)
		else
			local itemId = 1
			local itemNum = 1
			local dropsArr = xyd.tables.miscTable:split2num("activity_lasso_gamble", "value", "|")
			local dropId = dropsArr[index]
			local showDropId = dropId .. "00" .. infoId
			local award = xyd.tables.dropboxShowTable:getItem(showDropId)

			if award then
				itemId = award[1]
				itemNum = award[2]
			end

			local item = xyd.getItemIcon({
				show_has_num = true,
				showGetWays = false,
				notShowGetWayBtn = true,
				scale = 0.7037037037037037,
				itemID = itemId,
				num = itemNum,
				uiRoot = container,
				wndType = xyd.ItemTipsWndType.ACTIVITY
			})

			circle:SetActive(true)
			item:setChoose(true)
		end
	end
end

function ActivityLasso:useLasso(num)
	local selectIndex = 0
	local round = self.activityData.detail.round

	if round > 26 then
		round = 26
	end

	local selectIndexs = xyd.db.misc:getValue("activity_lasso_select_index")
	local selectIndexsArr = {}

	if selectIndexs then
		selectIndexsArr = json.decode(selectIndexs)
		selectIndex = selectIndexsArr[round .. ""] or 0
	end

	local awards = xyd.tables.activityLassoAwardsTable:getAwards(round)

	if #awards == 1 then
		selectIndex = 1
	end

	if selectIndex == 0 or #awards ~= 1 and selectIndexsArr.start_time and selectIndexsArr.start_time ~= self.activityData.start_time then
		xyd.alertTips(__("ACTIVITY_LASSO_TIPS"))

		return
	end

	local msg = messages_pb.get_activity_award_req()
	msg.activity_id = xyd.ActivityID.ACTIVITY_LASSO
	msg.params = json.encode({
		index = selectIndex,
		num = num
	})

	xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
end

function ActivityLasso:initUIComponent()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_lasso_logo_" .. xyd.Global.lang, nil, , true)

	self.btnWords.text = __("ACTIVITY_LASSO_BUTTON")

	self:updateMidNodeAwards()
	self:updateWrap()
	self:updateTopSource()
end

function ActivityLasso:updateTopSource()
	self.sourceNumText.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LASSO)
end

function AwardItem:ctor(go, parent)
	AwardItem.super.ctor(self, go, parent)

	self.go = go
	self.parent = parent
	self.itemInfo = {}
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_LASSO)
end

function AwardItem:initUI()
	self:getUIComponent()
	self:register()
end

function AwardItem:getUIComponent()
	self.iconContainer = self.go:NodeByName("iconContainer").gameObject
	self.lock = self.go:NodeByName("lock").gameObject
	self.exchange = self.go:NodeByName("exchange").gameObject
end

function AwardItem:register()
	UIEventListener.Get(self.go).onClick = handler(self, function ()
		if self.parent.isPlaying then
			return
		end

		local awards = xyd.tables.activityLassoAwardsTable:getAwards(self.info)
		local round = self.activityData.detail.round

		if #awards == 1 or self.info < round then
			return
		end

		local timeStamp = xyd.db.misc:getValue("activity_lasso_time_stamp")
		local showAlert = false

		if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime(), true) then
			showAlert = true
		end

		if round < self.info and #self.itemInfo == 0 and showAlert then
			xyd.WindowManager.get():openWindow("gamble_tips_window", {
				type = "activity_lasso",
				callback = function ()
					xyd.WindowManager:get():openWindow("activity_lasso_select_window", {
						parentItem = self
					})
				end,
				text = __("ACTIVITY_LASSO_TEXT03", self.info),
				btnNoText_ = __("NO"),
				btnYesText_ = __("YES"),
				labelNeverText = __("GAMBLE_REFRESH_NOT_SHOW_TODAY")
			})

			return
		end

		xyd.WindowManager:get():openWindow("activity_lasso_select_window", {
			parentItem = self
		})
	end)
	UIEventListener.Get(self.go).onLongPress = handler(self, function ()
		if #self.itemInfo == 0 then
			return
		end

		local params = {
			notShowGetWayBtn = true,
			show_has_num = true,
			itemID = self.itemInfo[1],
			itemNum = self.itemInfo[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		}

		xyd.WindowManager.get():openWindow("item_tips_window", params)
	end)
end

function AwardItem:updateLayout()
	local awards = xyd.tables.activityLassoAwardsTable:getAwards(self.info)
	local round = self.activityData.detail.round
	local selectIndex = 0

	self.lock:SetActive(false)

	local preId = self.info

	if preId > 26 then
		preId = 26
	end

	if self.info < round then
		selectIndex = self.activityData.detail.finished_ids[self.info] or 1
	else
		local selectIndexs = xyd.db.misc:getValue("activity_lasso_select_index")

		if selectIndexs then
			local selectIndexsArr = json.decode(selectIndexs)

			if selectIndexsArr.start_time == self.activityData.start_time then
				selectIndex = selectIndexsArr[preId .. ""] or 0
			end
		end

		if round < self.info then
			self.lock:SetActive(true)
		end
	end

	self.exchange:SetActive(#awards > 1)

	local drag = self.go:GetComponent(typeof(UIDragScrollView))
	drag = drag or self.go:AddComponent(typeof(UIDragScrollView))
	drag.scrollView = self.parent.scroller

	if #awards == 1 then
		selectIndex = 1
	end

	self.iconContainer:SetActive(false)

	if selectIndex == 0 then
		return
	end

	local theAward = awards[selectIndex]

	self.iconContainer:SetActive(true)

	local params = {
		noClick = true,
		noClickSelected = true,
		notShowGetWayBtn = true,
		show_has_num = true,
		scale = 0.6944444444444444,
		uiRoot = self.iconContainer,
		itemID = theAward[1],
		num = theAward[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY,
		dragScrollView = self.parent.scroller
	}

	if self.icon == nil then
		params.preGenarate = true
		self.icon = AdvanceIcon.new(params)
	else
		self.icon:setInfo(params)
	end

	self.icon:setMask(false)
	self.icon:setChoose(self.info < round)

	if round < self.info then
		self.icon:setMask(true)
	end

	self.itemInfo = theAward
end

function AwardItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.go:SetActive(true)

	self.itemInfo = {}
	self.info = info

	self:updateLayout()
end

return ActivityLasso
