local BaseWindow = import(".BaseWindow")
local ActivityPirateSwapWindow = class("ActivityPirateSwapWindow", BaseWindow)
local SelectNum = import("app.components.SelectNum")
local cjson = require("cjson")

function ActivityPirateSwapWindow:ctor(name, params)
	ActivityPirateSwapWindow.super.ctor(self, name, params)

	self.isLandID_ = params.land_id
	self.cost_ = xyd.split(xyd.tables.miscTable:getVal("activity_pirate_explore_cost"), "#", true)
	self.itemNum_ = xyd.models.backpack:getItemNumByID(self.cost_[1])
	self.curNum_ = 1
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_PIRATE)
end

function ActivityPirateSwapWindow:initWindow()
	self:getUIComponent()
	self:layout()
end

function ActivityPirateSwapWindow:getUIComponent()
	local winTrans = self.window_.transform:NodeByName("groupAction")
	self.titleLabel_ = winTrans:ComponentByName("titleLabel", typeof(UILabel))
	self.titleLabel2_ = winTrans:ComponentByName("titleLabel2", typeof(UILabel))
	self.closeBtn_ = winTrans:NodeByName("closeBtn").gameObject
	self.itemGroupLabel1_ = winTrans:ComponentByName("tipsGroup1/labelName", typeof(UILabel))
	self.itemGroupLabel2_ = winTrans:ComponentByName("tipsGroup2/labelName", typeof(UILabel))
	self.itemGrid1_ = winTrans:ComponentByName("itemGrid1", typeof(UIGrid))
	self.itemGrid2_ = winTrans:ComponentByName("itemGrid2", typeof(UIGrid))
	self.itemRoot_ = winTrans:NodeByName("itemRoot").gameObject
	self.selectNumRoot_ = winTrans:NodeByName("selectNumRoot").gameObject
	self.labelTips_ = winTrans:ComponentByName("labelTips", typeof(UILabel))
	self.labelTips2_ = winTrans:ComponentByName("labelTips2", typeof(UILabel))
	self.btnSwap_ = winTrans:NodeByName("btnSwap").gameObject
	self.btnSwapLabel_ = winTrans:ComponentByName("btnSwap/label", typeof(UILabel))
	self.resItemNumLable_ = winTrans:ComponentByName("res_item/res_num_label", typeof(UILabel))
	self.selectNum_ = SelectNum.new(self.selectNumRoot_, "minmax")

	self.selectNum_:setMaxAndMinBtnPos(211)

	UIEventListener.Get(self.btnSwap_).onClick = handler(self, self.onClickSure)
	UIEventListener.Get(self.closeBtn_).onClick = handler(self, function ()
		self:close()
	end)
end

function ActivityPirateSwapWindow:layout()
	self.titleLabel_.text = __("ACTIVITY_PIRATE_SHOP_TEXT13", __("ACTIVITY_PIRATE_PLACE" .. self.isLandID_))
	self.titleLabel2_.text = __("ACTIVITY_PIRATE_TEXT08")
	local no_box_times = self.activityData.detail.no_box_times or 0
	local box_value = xyd.tables.miscTable:getVal("activity_pirate_explore_dropbox_guarantee")
	self.labelTips_.text = __("ACTIVITY_PIRATE_TEXT12", box_value - no_box_times + 1)
	self.labelTips2_.text = __("ACTIVITY_PIRATE_TEXT11")
	self.itemGroupLabel1_.text = __("ACTIVITY_PIRATE_TEXT09")
	self.itemGroupLabel2_.text = __("ACTIVITY_PIRATE_TEXT10")
	self.btnSwapLabel_.text = __("ACTIVITY_PIRATE_TEXT05")
	local maxItems = xyd.models.backpack:getItemNumByID(xyd.ItemID.PIRATE_SWAP_ITEM)

	local function callback(num)
		if maxItems < num then
			self.selectNum_:setCurNum(xyd.checkCondition(maxItems > 0, maxItems, 1))

			self.curNum_ = xyd.checkCondition(maxItems > 0, maxItems, 1)
			self.resItemNumLable_.text = self.curNum_ .. "/" .. self.itemNum_
		else
			self.selectNum_:setCurNum(num)

			self.curNum_ = num
			self.resItemNumLable_.text = self.curNum_ .. "/" .. self.itemNum_
		end
	end

	local param = {
		curNum = 1,
		maxNum = 100,
		callback = callback,
		minNum = 1
	}

	self.selectNum_:setInfo(param)
	self.selectNum_:setFontSize(20)
	self.selectNum_:setBtnPos(140)
	self.selectNum_:setFontSize(26, 26)
	self.selectNum_:setKeyboardPos(0, -180)
	self.selectNum_:setCurNum(1)
	self.selectNum_:changeCurNum()
	self:initItemList()
end

function ActivityPirateSwapWindow:initItemList()
	local award = xyd.split(xyd.tables.miscTable:getVal("activity_pirate_drop_awards"), "#", true)
	local newItemRoot = NGUITools.AddChild(self.itemGrid1_.gameObject, self.itemRoot_)

	newItemRoot:SetActive(true)

	local labelRate = newItemRoot:ComponentByName("showRate", typeof(UILabel))

	labelRate.gameObject:SetActive(true)

	labelRate.text = "100%"

	labelRate.transform:Y(-64)
	xyd.getItemIcon({
		show_has_num = true,
		scale = 0.8981481481481481,
		uiRoot = newItemRoot,
		itemID = award[1],
		num = award[2],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})

	local dropBoxID = xyd.tables.activityPirateLandAwardTable:getDropBoxID(self.isLandID_)
	local DropboxShowTable = xyd.tables.dropboxShowTable
	local info = DropboxShowTable:getIdsByBoxId(dropBoxID)
	local all_proba = info.all_weight
	local list = info.list

	table.sort(list, function (a, b)
		return a < b
	end)

	for i = 1, #list do
		local table_id = list[i]
		local newItemRoot = NGUITools.AddChild(self.itemGrid1_.gameObject, self.itemRoot_)

		newItemRoot:SetActive(true)

		local labelRate = newItemRoot:ComponentByName("showRate", typeof(UILabel))

		labelRate.gameObject:SetActive(true)
		labelRate.transform:Y(-64)

		local data = xyd.tables.dropboxShowTable:getItem(list[i])
		local proba = xyd.tables.dropboxShowTable:getWeight(table_id)
		local show_proba = math.ceil(proba * 1000000 / all_proba)
		show_proba = show_proba / 10000
		labelRate.text = tostring(show_proba) .. "%"

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.8981481481481481,
			uiRoot = newItemRoot,
			itemID = data[1],
			num = data[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.itemGrid1_:Reposition()

	local awardList2 = xyd.tables.activityPirateRandomAwardTable:getIDs()

	for index, id in ipairs(awardList2) do
		local newItemRoot = NGUITools.AddChild(self.itemGrid2_.gameObject, self.itemRoot_)

		newItemRoot:SetActive(true)

		local labelRate = newItemRoot:ComponentByName("showRate", typeof(UILabel))

		labelRate.gameObject:SetActive(true)

		labelRate.text = xyd.tables.activityPirateRandomAwardTable:getRate(id) * 100 .. "%"
		local awardItem = xyd.tables.activityPirateRandomAwardTable:getAward(id)[1]

		xyd.getItemIcon({
			show_has_num = true,
			scale = 0.8981481481481481,
			uiRoot = newItemRoot,
			itemID = awardItem[1],
			num = awardItem[2],
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end

	self.itemGrid2_:Reposition()
end

function ActivityPirateSwapWindow:onClickSure()
	local costNum = self.curNum_ * self.cost_[2]

	if xyd.models.backpack:getItemNumByID(self.cost_[1]) < costNum then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.cost_[1])))

		return
	end

	local timeStamp = xyd.db.misc:getValue("pirate_swap_time_stamp")

	local function buyFunction()
		local params = cjson.encode({
			type = 1,
			pos = tonumber(self.isLandID_),
			num = self.curNum_
		})

		xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_PIRATE, params)
		self:close()
	end

	if not timeStamp or not xyd.isSameDay(timeStamp, xyd.getServerTime()) then
		xyd.WindowManager.get():openWindow("gamble_tips_window", {
			type = "pirate_swap",
			callback = buyFunction,
			text = __("ACTIVITY_PIRATE_TEXT13", self.curNum_, __("ACTIVITY_PIRATE_PLACE" .. self.isLandID_))
		})
	else
		buyFunction()
	end
end

return ActivityPirateSwapWindow
