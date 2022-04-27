local ActivityContent = import(".ActivityContent")
local ActivityWine = class("ActivityWine", ActivityContent)
local json = require("cjson")

function ActivityWine:ctor(parentGO, params, parent)
	ActivityWine.super.ctor(self, parentGO, params, parent)
end

function ActivityWine:getPrefabPath()
	return "Prefabs/Windows/activity/activity_wine"
end

function ActivityWine:initUI()
	self:getUIComponent()
	ActivityWine.super.initUI(self)
	self:initUIComponent()
end

function ActivityWine:getUIComponent()
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.bgImg = self.groupAction:ComponentByName("bgImg", typeof(UITexture))
	self.btnGroup = self.groupAction:NodeByName("btnGroup").gameObject
	self.helpBtn = self.btnGroup:NodeByName("helpBtn").gameObject
	self.awardBtn = self.btnGroup:NodeByName("awardBtn").gameObject
	self.redPoint_loupe = self.awardBtn:ComponentByName("redPoint", typeof(UISprite))
	self.resCon = self.groupAction:NodeByName("resCon").gameObject
	self.resGroup1 = self.resCon:NodeByName("resGroup1").gameObject
	self.icon1 = self.resGroup1:ComponentByName("icon1", typeof(UISprite))
	self.label1 = self.resGroup1:ComponentByName("label1", typeof(UILabel))
	self.btn1 = self.resGroup1:NodeByName("btn1").gameObject
	self.bg1 = self.resGroup1:ComponentByName("bg1", typeof(UISprite))
	self.resGroup2 = self.resCon:NodeByName("resGroup2").gameObject
	self.icon2 = self.resGroup2:ComponentByName("icon2", typeof(UISprite))
	self.label2 = self.resGroup2:ComponentByName("label2", typeof(UILabel))
	self.btn2 = self.resGroup2:NodeByName("btn2").gameObject
	self.bg2 = self.resGroup2:ComponentByName("bg2", typeof(UISprite))
	self.logoImg = self.groupAction:ComponentByName("logoImg", typeof(UISprite))
	self.useCon = self.groupAction:NodeByName("useCon").gameObject
	self.useGroup1 = self.useCon:NodeByName("useGroup1").gameObject
	self.useBg1 = self.useGroup1:ComponentByName("useBg1", typeof(UISprite))
	self.useIcon1 = self.useGroup1:ComponentByName("useBg1/useIcon1", typeof(UISprite))
	self.useLabel1 = self.useGroup1:ComponentByName("useLabel1", typeof(UILabel))
	self.useMultipleLabel1 = self.useGroup1:ComponentByName("useBg1/useMultipleLabel1", typeof(UILabel))
	self.useGroup2 = self.useCon:NodeByName("useGroup2").gameObject
	self.useBg2 = self.useGroup2:ComponentByName("useBg2", typeof(UISprite))
	self.useIcon2 = self.useGroup2:ComponentByName("useBg2/useIcon2", typeof(UISprite))
	self.useLabel2 = self.useGroup2:ComponentByName("useLabel2", typeof(UILabel))
	self.useMultipleLabel2 = self.useGroup2:ComponentByName("useBg2/useMultipleLabel2", typeof(UILabel))
	self.downCon = self.groupAction:NodeByName("downCon").gameObject
	self.downConBg = self.downCon:ComponentByName("downConBg", typeof(UISprite))
	self.downConBg_UIWidget = self.downCon:ComponentByName("downConBg", typeof(UIWidget))
	self.downLabel = self.downCon:ComponentByName("downLabel", typeof(UILabel))
	self.downIcon = self.downCon:ComponentByName("downIcon", typeof(UISprite))
	self.redPoint = self.downIcon:ComponentByName("redPoint", typeof(UISprite))
	self.downIconEffectCon = self.downCon:ComponentByName("downIconEffectCon", typeof(UITexture))
	self.extraText = self.groupAction:ComponentByName("extraText", typeof(UILabel))
end

function ActivityWine:initUIComponent()
	xyd.setUISpriteAsync(self.logoImg, nil, "activity_wine_text_" .. xyd.Global.lang, nil, , )

	local str1 = __("ACTIVITY_3BIRTHDAY_TEXT01")
	str1 = string.gsub(str1, "0x(%w+)", "%1")
	str1 = string.gsub(str1, " size=(%w+)", "][size=%1")
	self.useLabel1.text = str1
	local str2 = __("ACTIVITY_3BIRTHDAY_TEXT02")
	str2 = string.gsub(str2, "0x(%w+)", "%1")
	str2 = string.gsub(str2, " size=(%w+)", "][size=%1")
	self.useLabel2.text = str2
	self.downLabel.text = __("ACTIVITY_3BIRTHDAY_TEXT03")

	if self.downLabel.height > 82 then
		self.downConBg_UIWidget.height = 114 + self.downLabel.height - 82
	end

	self.useMultipleLabel1.text = "x" .. xyd.tables.activity3BirthdayDinnerTable:getCost(1)[2]
	self.useMultipleLabel2.text = "x" .. xyd.tables.activity3BirthdayDinnerTable:getCost(2)[2]
	local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(1)
	self.label1.text = xyd.models.backpack:getItemNumByID(item_data[1])

	if xyd.Global.lang == "ja_jp" then
		self.extraText.gameObject:SetActive(true)

		self.extraText.text = "*作中の戦姫は全員お酒が飲める年齢です"
	else
		self.extraText.gameObject:SetActive(false)
	end

	self.activityData:getRedMarkState()
	self.redPoint.gameObject:SetActive(self:getBagRedPoint())
	self.redPoint_loupe.gameObject:SetActive(self.activityData:getFirstToLoupeBtn(false))

	self.label2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ROSE_BROOCH)

	if self.down_icon_effect == nil then
		self.down_icon_effect = xyd.Spine.new(self.downIconEffectCon.gameObject)

		self.down_icon_effect:setInfo("fx_act_icon_2", function ()
			self.down_icon_effect:play("texiao01", 0)
		end)
	end
end

function ActivityWine:resizeToParent()
	ActivityWine.super.resizeToParent(self)
	self:resizePosY(self.bgImg.gameObject, -463, -526)
	self:resizePosY(self.btnGroup.gameObject, -37, -42)
	self:resizePosY(self.resCon.gameObject, -57, -64)
	self:resizePosY(self.logoImg.gameObject, -73, -97)
	self:resizePosY(self.useCon.gameObject, -610, -701)
	self:resizePosY(self.downCon.gameObject, -771, -900)

	if xyd.Global.lang == "ja_jp" then
		self:resizePosY(self.extraText.gameObject, -852, -1036)

		self.downLabel.width = 460
		self.useLabel1.fontSize = 24
		self.useLabel2.fontSize = 24
		self.useLabel2.width = 245

		self.useLabel2.gameObject:X(5)
	end

	if xyd.Global.lang ~= "zh_tw" and xyd.Global.lang ~= "ja_jp" then
		self.downLabel.fontSize = 20
		self.downLabel.width = 450

		self.downLabel.gameObject:X(-65)
	end
end

function ActivityWine:onRegister()
	UIEventListener.Get(self.helpBtn.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_3BIRTHDAY_HELP"
		})
	end)
	UIEventListener.Get(self.useBg1.gameObject).onClick = handler(self, function ()
		local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(1)
		local num = xyd.models.backpack:getItemNumByID(item_data[1])
		num = math.floor(num / item_data[2])

		if num < 1 then
			xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(item_data[1])))

			return
		end

		if num < xyd.tables.miscTable:getNumber("activity_3birthday_dinner_batch", "value") then
			self:sureNotTips(1)

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = num,
			show_max_num = xyd.models.backpack:getItemNumByID(item_data[1]),
			select_multiple = item_data[2],
			icon_info = {
				height = 45,
				width = 45,
				name = "icon_" .. item_data[1]
			},
			title_text = __("ACTIVITY_3BIRTHDAY_TEXT07"),
			explain_text = __("ACTIVITY_3BIRTHDAY_TEXT08"),
			sure_callback = function (num)
				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end

				self:sendUseMessage(1, num)
			end
		})
	end)
	UIEventListener.Get(self.useBg2.gameObject).onClick = handler(self, function ()
		local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(2)
		local num = xyd.models.backpack:getItemNumByID(item_data[1])
		num = math.floor(num / item_data[2])

		if num < 1 then
			xyd.alertTips(__("SPIRIT_NOT_ENOUGH", xyd.tables.itemTable:getName(item_data[1])))

			return
		end

		if num < xyd.tables.miscTable:getNumber("activity_3birthday_dinner_batch", "value") then
			self:sureNotTips(2)

			return
		end

		xyd.WindowManager.get():openWindow("common_use_cost_window", {
			select_max_num = num,
			show_max_num = xyd.models.backpack:getItemNumByID(item_data[1]),
			select_multiple = item_data[2],
			icon_info = {
				height = 45,
				width = 45,
				name = "icon_" .. item_data[1]
			},
			title_text = __("ACTIVITY_3BIRTHDAY_TEXT07"),
			explain_text = __("ACTIVITY_3BIRTHDAY_TEXT09"),
			sure_callback = function (num)
				local common_use_cost_window_wd = xyd.WindowManager.get():getWindow("common_use_cost_window")

				if common_use_cost_window_wd then
					xyd.WindowManager.get():closeWindow("common_use_cost_window")
				end

				self:sendUseMessage(2, num)
			end
		})
	end)
	UIEventListener.Get(self.btn1.gameObject).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("activity_item_getway_window", {
			itemID = tonumber(xyd.tables.activity3BirthdayDinnerTable:getCost(1)[1])
		})
	end)
	UIEventListener.Get(self.btn2.gameObject).onClick = handler(self, self.goWay)
	UIEventListener.Get(self.awardBtn.gameObject).onClick = handler(self, function ()
		local data_awards = xyd.tables.dropboxShowTable:getIdsByBoxId(xyd.tables.activity3BirthdayDinnerTable:getDropboxId(1))

		table.sort(data_awards.list)

		local probability_awards = {}

		for i in pairs(data_awards.list) do
			local items = xyd.tables.dropboxShowTable:getItem(data_awards.list[i])
			local weight = xyd.tables.dropboxShowTable:getWeight(data_awards.list[i])

			if weight then
				items[3] = math.floor(weight * 100 / data_awards.all_weight * 10) / 10
				items[3] = tostring(items[3]) .. "%"
			end

			table.insert(probability_awards, items)
		end

		xyd.WindowManager.get():openWindow("common_item_award_window", {
			fixed_awards = xyd.tables.activity3BirthdayDinnerTable:getAwards(1),
			probability_awards = probability_awards,
			title_text = __("ACTIVITY_AWARD_PREVIEW_TITLE"),
			explain1_text = __("ACTIVITY_3BIRTHDAY_TEXT04"),
			explain2_text = __("ACTIVITY_3BIRTHDAY_TEXT05")
		})
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_WINE, function ()
			xyd.db.misc:setValue({
				value = 1,
				key = "activity_wine_first_to_loupe_btn"
			})
			self.redPoint_loupe.gameObject:SetActive(self.activityData:getFirstToLoupeBtn(false))
		end)
	end)

	self:registerEvent(xyd.event.ACTIVITY_WINE_COST, handler(self, function ()
		local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(1)
		self.label1.text = xyd.models.backpack:getItemNumByID(item_data[1])
		local activityData = xyd.models.activity:getActivity(self.id)

		self.activityData:getRedMarkState()
		self.redPoint.gameObject:SetActive(self:getBagRedPoint())

		self.label2.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.ROSE_BROOCH)
	end))

	UIEventListener.Get(self.downIcon.gameObject).onClick = handler(self, function ()
		local item_data = xyd.tables.activity3BirthdayDinnerTable:getCost(1)
		local activityData = xyd.models.activity:getActivity(self.id)
		local all_info = {}
		local ids = xyd.tables.activity3BirthdayDinnerPointTable:getIDs()

		for i in pairs(ids) do
			local data = {
				id = ids[i],
				max_value = xyd.tables.activity3BirthdayDinnerPointTable:getPoint(ids[i]) / item_data[2]
			}
			data.name = __("ACTIVITY_3BIRTHDAY_TEXT06", math.floor(data.max_value))
			data.cur_value = tonumber(activityData.detail.point) / item_data[2]

			if data.max_value < data.cur_value then
				data.cur_value = data.max_value
			end

			data.items = xyd.tables.activity3BirthdayDinnerPointTable:getAwards(ids[i])

			if activityData.detail.awards[i] == 0 then
				if data.cur_value == data.max_value then
					data.state = 1
				else
					data.state = 2
				end
			else
				data.state = 3
			end

			table.insert(all_info, data)
		end

		xyd.WindowManager.get():openWindow("common_progress_award_window", {
			if_sort = true,
			all_info = all_info,
			title_text = __("MAIL_AWAED_TEXT"),
			click_callBack = function (info)
				if self.activityData:getEndTime() <= xyd.getServerTime() then
					xyd.alertTips(__("ACTIVITY_END_YET"))

					return
				end

				xyd.models.activity:reqAwardWithParams(self.id, json.encode({
					table_id = info.id
				}))
			end,
			wnd_type = xyd.CommonProgressAwardWindowType.ACTIVITY_WINE
		})
		xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_WINE, function ()
			xyd.db.misc:setValue({
				value = 1,
				key = "activity_wine_first_to_bag_btn"
			})
			self.redPoint.gameObject:SetActive(self:getBagRedPoint())
		end)
	end)

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (_, event)
		if event.data.activity_id ~= xyd.ActivityID.ACTIVITY_WINE then
			return
		end

		local activityData = xyd.models.activity:getActivity(self.id)

		activityData:getRedMarkState()
		self.redPoint.gameObject:SetActive(self:getBagRedPoint())
	end))
end

function ActivityWine:sureNotTips(state)
	local tipsStr = __("ACTIVITY_3BIRTHDAY_TEXT10")

	if state == 2 then
		tipsStr = __("ACTIVITY_3BIRTHDAY_TEXT11")
	end

	local timeStamp = xyd.db.misc:getValue("activity_wine_tips_use_time_stamp")

	if not timeStamp or not xyd.isSameDay(tonumber(timeStamp), xyd.getServerTime()) then
		xyd.openWindow("gamble_tips_window", {
			type = "activity_wine_tips_use",
			tipsTextY = 51,
			text = tipsStr,
			callback = function ()
				self:sendUseMessage(state, 1)
			end
		})
	else
		self:sendUseMessage(state, 1)
	end
end

function ActivityWine:sendUseMessage(state, num)
	if self.activityData:getEndTime() <= xyd.getServerTime() then
		xyd.alertTips(__("ACTIVITY_END_YET"))

		return
	end

	local msg = messages_pb:activity_wine_cost_req()
	msg.activity_id = self.id
	msg.table_id = state
	msg.num = num

	xyd.Backend.get():request(xyd.mid.ACTIVITY_WINE_COST, msg)
end

function ActivityWine:goWay()
	local win = xyd.WindowManager.get():getWindow("activity_window")
	local newParams = xyd.tables.activityTable:getWindowParams(self.id)
	local params = {}

	if newParams ~= nil then
		params.onlyShowList = newParams.activity_ids
		params.activity_type = tonumber(newParams.activity_type)
		params.select = xyd.ActivityID.ACTIVITY_TREASURE
	end

	if win then
		xyd.WindowManager.get():closeWindow("activity_window", function ()
			xyd.WindowManager.get():openWindow("activity_window", params)
		end)
	else
		xyd.WindowManager.get():openWindow("activity_window", params)
	end
end

function ActivityWine:getBagRedPoint()
	local activityData = xyd.models.activity:getActivity(self.id)
	local flag = false
	local ids = xyd.tables.activity3BirthdayDinnerPointTable:getIDs()

	for i in pairs(ids) do
		local max_value = xyd.tables.activity3BirthdayDinnerPointTable:getPoint(ids[i])

		if activityData.detail.awards[i] == 0 and max_value <= activityData.detail.point then
			flag = true

			break
		end
	end

	flag = flag or activityData:getFirstToBagBtn(flag)

	return flag
end

return ActivityWine
