local cjson = require("cjson")
local ActivityContent = import(".ActivityContent")
local NewYearWelfare = class("NewYearWelfare", ActivityContent)
local NewYearWelfareItem = class("NewYearWelfareItem", import("app.components.CopyComponent"))

function NewYearWelfare:ctor(parentGO, params, parent)
	NewYearWelfare.super.ctor(self, parentGO, params, parent)

	local time = xyd.db.misc:getValue("activity_newyear_welfare_time")

	if not time or not xyd.isSameDay(tonumber(time), xyd.getServerTime()) then
		xyd.db.misc:setValue({
			key = "activity_newyear_welfare_time",
			value = xyd.getServerTime()
		})
	end
end

function NewYearWelfare:getPrefabPath()
	return "Prefabs/Windows/activity/newyear_welfare"
end

function NewYearWelfare:initUI()
	self:getUIComponent()
	NewYearWelfare.super.initUI(self)
	self:initLayout()
	self:initItem()
	self:initNav()
	self:registerEvent()
end

function NewYearWelfare:initNav()
	for i = 1, 8 do
		if self.activityData.detail.buy_times[i] < xyd.tables.newyearWelfareTable:getLimit(i) then
			self:setCurChoose(1)

			return
		end
	end

	for i = 9, 16 do
		if self.activityData.detail.buy_times[i] < xyd.tables.newyearWelfareTable:getLimit(i) then
			self:setCurChoose(2)

			return
		end
	end

	self:setCurChoose(1)
end

function NewYearWelfare:getUIComponent()
	local goTrans = self.go.transform
	self.bg_ = goTrans:ComponentByName("bg", typeof(UISprite))
	self.textImg = goTrans:ComponentByName("textImg", typeof(UISprite))
	self.helpBtn = goTrans:NodeByName("helpBtn").gameObject
	self.buttomGroup = goTrans:NodeByName("buttomGroup").gameObject
	self.navGroup = self.buttomGroup:NodeByName("navGroup").gameObject
	self.nav1 = self.navGroup:NodeByName("nav1").gameObject
	self.nav1Label = self.nav1:ComponentByName("label", typeof(UILabel))
	self.nav1Chosen = self.nav1:ComponentByName("chosen", typeof(UISprite))
	self.nav1ChosenLabel = self.nav1Chosen:ComponentByName("label", typeof(UILabel))
	self.nav2 = self.navGroup:NodeByName("nav2").gameObject
	self.nav2Label = self.nav2:ComponentByName("label", typeof(UILabel))
	self.nav2Chosen = self.nav2:ComponentByName("chosen", typeof(UISprite))
	self.nav2ChosenLabel = self.nav2Chosen:ComponentByName("label", typeof(UILabel))
	self.timeLabel_ = self.buttomGroup:ComponentByName("timeGroup/timeLabel", typeof(UILabel))
	self.clockNode = self.buttomGroup:NodeByName("timeGroup/clockNode").gameObject
	self.groupItem = self.buttomGroup:NodeByName("groupItem").gameObject
	self.itemCell = goTrans:NodeByName("itemCell").gameObject
end

function NewYearWelfare:resizeToParent()
	NewYearWelfare.super.resizeToParent(self)

	local allHeight = self.go:GetComponent(typeof(UIWidget)).height

	self.bg_:Y(-allHeight * 0.146 + 152.9)
	self.textImg:Y(-0.2 * allHeight + 167.8)
	self.buttomGroup:Y(-allHeight + 281)
end

function NewYearWelfare:initLayout()
	xyd.setUISpriteAsync(self.textImg, nil, "newyear_welfare_bg_" .. xyd.Global.lang)

	self.nav1Label.text = __("ACTIVITY_NEWYEAR_WELFARE_TEXT02")
	self.nav1ChosenLabel.text = __("ACTIVITY_NEWYEAR_WELFARE_TEXT02")
	self.nav2Label.text = __("ACTIVITY_NEWYEAR_WELFARE_TEXT03")
	self.nav2ChosenLabel.text = __("ACTIVITY_NEWYEAR_WELFARE_TEXT03")

	if xyd.Global.lang == "ja_jp" then
		self.nav2Label.width = 108
		self.nav2Label.height = 36

		self.nav2Label:X(4)

		self.nav2ChosenLabel.width = 108
		self.nav2ChosenLabel.height = 36

		self.nav2ChosenLabel:X(4)
	end

	local duration = self.activityData:getUpdateTime() - xyd.getServerTime()

	if duration > 0 then
		self.timeLabel_:SetActive(true)

		self.timeCount_ = import("app.components.CountDown").new(self.timeLabel_)

		self.timeCount_:setInfo({
			duration = duration
		})
	else
		self.timeLabel_:SetActive(false)
	end

	self.clockEffect = xyd.Spine.new(self.clockNode)

	self.clockEffect:setInfo("fx_ui_shizhong", function ()
		self.clockEffect:play("texiao1", 0, 1, nil, true)
	end)
end

function NewYearWelfare:initItem()
	self.items = {}

	for i = 1, 8 do
		local awardItem = NGUITools.AddChild(self.groupItem, self.itemCell)
		local item = NewYearWelfareItem.new(awardItem)

		table.insert(self.items, item)
	end

	self.groupItem:GetComponent(typeof(UILayout)):Reposition()
	self.itemCell:SetActive(false)
end

function NewYearWelfare:updateItem()
	for i = 1, #self.items do
		local params = {
			id = i + 8 * (self.choseIndex - 1),
			buy_times = self.activityData.detail.buy_times,
			parnent = self
		}

		self.items[i]:setInfo(params)
	end
end

function NewYearWelfare:registerEvent()
	UIEventListener.Get(self.helpBtn).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ZHONGQIU_FESTIVAL_TEXT"
		})
	end

	UIEventListener.Get(self.nav1).onClick = function ()
		self:setCurChoose(1)
	end

	UIEventListener.Get(self.nav2).onClick = function ()
		self:setCurChoose(2)
	end

	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
end

function NewYearWelfare:setCurChoose(index)
	if self.choseIndex and index == self.choseIndex then
		return
	end

	self.choseIndex = index

	if index == 1 then
		self.nav1Chosen:SetActive(true)
		self.nav2Chosen:SetActive(false)
	else
		self.nav1Chosen:SetActive(false)
		self.nav2Chosen:SetActive(true)
	end

	self:updateItem()
end

function NewYearWelfare:onAward(event)
	if event.data.activity_id == xyd.ActivityID.NEWYEAR_WELFARE and self.boughtId then
		self.activityData.detail.buy_times[self.boughtId] = self.activityData.detail.buy_times[self.boughtId] + 1
		local award = xyd.tables.newyearWelfareTable:getAward(self.boughtId)

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = award[1],
				item_num = award[2]
			}
		})
		self:updateItem()

		self.boughtId = nil
	end
end

function NewYearWelfareItem:ctor(go)
	NewYearWelfareItem.super.ctor(self, go)
	self:getUIComponent()
	self:register()
end

function NewYearWelfareItem:getUIComponent()
	self.itemGroup = self.go:NodeByName("itemGroup").gameObject
	self.confirmBtn = self.go:NodeByName("confirmBtn").gameObject
	self.btnLabel = self.confirmBtn:ComponentByName("label", typeof(UILabel))
	self.costImg = self.confirmBtn:ComponentByName("costImg", typeof(UISprite))
	self.boughtBtn = self.go:NodeByName("boughtBtn").gameObject
	self.boughtLabel = self.boughtBtn:ComponentByName("label", typeof(UILabel))
	self.limitLabel = self.go:ComponentByName("limitLabel", typeof(UILabel))
end

function NewYearWelfareItem:register()
	UIEventListener.Get(self.confirmBtn).onClick = function ()
		if self.id and self.parent and not self.parent.boughtId then
			local cost = xyd.tables.newyearWelfareTable:getCost(self.id)

			if cost[2] <= xyd.models.backpack:getItemNumByID(cost[1]) then
				xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_CHANGE"), function (yes_no)
					if yes_no then
						self.parent.boughtId = self.id
						local data = cjson.encode({
							num = 1,
							award_id = self.id
						})
						local msg = messages_pb.get_activity_award_req()
						msg.activity_id = xyd.ActivityID.NEWYEAR_WELFARE
						msg.params = data

						xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
					end
				end)
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))
			end
		end
	end
end

function NewYearWelfareItem:setInfo(params)
	self.id = params.id
	self.parent = params.parnent
	local limit = xyd.tables.newyearWelfareTable:getLimit(self.id) - params.buy_times[self.id]
	self.limitLabel.text = __("BUY_GIFTBAG_LIMIT", limit)
	self.boughtLabel.text = __("ALREADY_BUY")

	NGUITools.DestroyChildren(self.itemGroup.transform)

	local award = xyd.tables.newyearWelfareTable:getAward(self.id)
	local icon = xyd.getItemIcon({
		itemID = award[1],
		num = award[2],
		scale = Vector3(1, 1, 1),
		uiRoot = self.itemGroup.gameObject,
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	if limit <= 0 then
		self.confirmBtn:SetActive(false)
		self.boughtBtn:SetActive(true)
		icon:setBlueMask(true)
	else
		self.confirmBtn:SetActive(true)

		local cost = xyd.tables.newyearWelfareTable:getCost(self.id)
		self.btnLabel.text = xyd.getRoughDisplayNumber(cost[2], 100000)

		xyd.setUISpriteAsync(self.costImg, nil, "icon_" .. cost[1] .. "_small")
		self.boughtBtn:SetActive(false)
	end
end

return NewYearWelfare
