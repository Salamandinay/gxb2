local PushActivityWindow = class("PushActivityWindow", import(".BaseWindow"))

function PushActivityWindow:ctor(name, params)
	PushActivityWindow.super.ctor(self, name, params)

	self.push_list_ = params or {}

	xyd.models.advertiseComplete:pushWindowOpen()
end

function PushActivityWindow:playOpenAnimation(callback)
	PushActivityWindow.super.playOpenAnimation(self, function ()
		if callback then
			callback()
		end
	end)
end

function PushActivityWindow:initWindow()
	PushActivityWindow.super.initWindow(self)
	self:getComponent()
	self:registerEvent()
	self:addEffect()

	self.labelBubble.text = __("ACTIVITY_PROPEL_TALK_TEXT")

	self:updateLayout()
end

function PushActivityWindow:getComponent()
	self.groupAction = self.window_:NodeByName("groupAction")
	self.touchGroup = self.window_:NodeByName("groupAction/touchGroup").gameObject
	local conTrans = self.window_:NodeByName("groupAction/groupContent")
	self.imageTexture = conTrans:ComponentByName("imageTexture", typeof(UITexture))
	self.labelBubble = conTrans:ComponentByName("labelBubble", typeof(UILabel))
	self.buyBtn = conTrans:NodeByName("buyBtn").gameObject
	self.buyBtnLabel = conTrans:ComponentByName("buyBtn/label", typeof(UILabel))
	self.titleImgTable = conTrans:ComponentByName("group", typeof(UITable))
	self.imgTitle1 = conTrans:ComponentByName("group/imgTitle1", typeof(UISprite))
	self.groupNumRoot = conTrans:ComponentByName("group/groupNum", typeof(UILayout))
	self.imgTitle2 = conTrans:ComponentByName("group/imgTitle2", typeof(UISprite))
	self.groupTime = conTrans:NodeByName("groupTime").gameObject
	self.labelTime = conTrans:ComponentByName("groupTime/labelTime", typeof(UILabel))
	self.labelEnd = conTrans:ComponentByName("groupTime/labelEnd", typeof(UILabel))
	self.itemGroup = conTrans:ComponentByName("itemGroup", typeof(UIGrid))
	self.labelVIP = conTrans:ComponentByName("labelVIP", typeof(UILabel))
	self.labelLimit = conTrans:ComponentByName("labelLimit", typeof(UILabel))
end

function PushActivityWindow:registerEvent()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_INFO_BY_ID, function ()
		self:updateLayout()
	end)
	self.eventProxy_:addEventListener(xyd.event.RECHARGE, function ()
		if self.cur_push_.activity_id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY or self.cur_push_.activity_id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER then
			local activityData = xyd.models.activity:getActivity(self.cur_push_.activity_id)

			activityData:setSelectAwards(self.cur_push_.giftbag_id, self.selectAwards_215)
		end

		self:checkClose()
	end)

	UIEventListener.Get(self.buyBtn).onClick = function ()
		if self.cur_push_ and self.cur_push_.giftbag_id then
			if self.cur_push_.activity_id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY or self.cur_push_.activity_id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER then
				if #self.selectAwards_215 < self.optionalNum_215 then
					xyd.showToast(__("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE"))
				else
					local msg = messages_pb.set_attach_index_req()
					msg.activity_id = self.cur_push_.activity_id

					for i = 1, self.optionalNum_215 do
						table.insert(msg.indexs, self.selectAwardIndexs_215[i])
					end

					msg.giftbag_id = self.cur_push_.giftbag_id

					xyd.Backend.get():request(xyd.mid.SET_ATTACH_INDEX, msg)
					xyd.SdkManager.get():showPayment(self.cur_push_.giftbag_id)
				end
			else
				xyd.SdkManager.get():showPayment(self.cur_push_.giftbag_id)
			end
		end
	end

	UIEventListener.Get(self.touchGroup).onClick = function ()
		self:checkClose()
	end
end

function PushActivityWindow:addEffect()
end

function PushActivityWindow:updateLayout()
	if not self.push_list_[1] then
		xyd.WindowManager.get():closeWindow(self.name_)

		return
	end

	local data = xyd.models.activity:getActivity(self.push_list_[1].activity_id)

	if not data then
		dump(self.push_list_[1].activity_id)
		xyd.models.activity:reqActivityByID(self.push_list_[1].activity_id)
	else
		self.cur_push_ = self.push_list_[1]

		table.remove(self.push_list_, 1)

		local table_id = self.cur_push_.activity_id
		local giftbag_id = self.cur_push_.giftbag_id

		self:setImgTitle(table_id, giftbag_id)
		NGUITools.DestroyChildren(self.itemGroup.transform)

		local awards = xyd.tables.giftTable:getAwards(giftbag_id)

		if not giftbag_id or not awards then
			xyd.WindowManager.get():closeWindow(self.name_)

			return
		end

		local cnt = 0

		for i = 1, #awards do
			local cur_data = awards[i]

			if cur_data[1] ~= xyd.ItemID.VIP_EXP then
				cnt = cnt + 1
			end
		end

		for j = 1, #awards do
			local cur_data = awards[j]

			if cur_data[1] ~= xyd.ItemID.VIP_EXP then
				local params = {
					itemID = cur_data[1],
					num = cur_data[2],
					uiRoot = self.itemGroup.gameObject
				}

				if cnt > 5 then
					params.scale = 0.8
				else
					params.scale = 1
				end

				xyd.getItemIcon(params)
			end
		end

		if table_id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY or table_id == xyd.ActivityID.ACTIVITY_OPTIONAL_SUPPLY_SUPER then
			self:setOptional_215()
		end

		self.itemGroup:Reposition()

		local vipExp = xyd.tables.giftBagTable:getVipExp(giftbag_id)
		self.labelVIP.text = "+ " .. vipExp .. " VIP EXP"
		self.buyBtnLabel.text = xyd.tables.giftBagTextTable:getCurrency(giftbag_id) .. " " .. xyd.tables.giftBagTextTable:getCharge(giftbag_id)
		local buyTimes = 0
		local totalTimes = xyd.tables.giftBagTable:getBuyLimit(giftbag_id)

		if data.detail[1] then
			for i = 1, #data.detail do
				if data.detail[i].charge.table_id == giftbag_id then
					buyTimes = data.detail[i].charge.buy_times

					break
				end
			end
		else
			buyTimes = data.detail.buy_times
		end

		self.labelLimit.text = __("BUY_GIFTBAG_LIMIT", tostring(totalTimes - buyTimes))
		local curTime = xyd.getServerTime()
		local lastTime = 0

		if data.detail[1] then
			for i = 1, #data.detail do
				if data.detail[i].charge.table_id == giftbag_id then
					lastTime = data.detail[i].update_time + xyd.tables.giftBagTable:getLastTime(giftbag_id)
					lastTime = lastTime or data.detail[i].end_time

					break
				end
			end
		else
			lastTime = data.detail.update_time + xyd.tables.giftBagTable:getLastTime(giftbag_id)
			lastTime = lastTime or data.detail.end_time
		end

		local severTime = xyd.getServerTime()
		local timeParams = {
			duration = lastTime - severTime
		}

		if not self.timeCountDown_ then
			self.timeCountDown_ = import("app.components.CountDown").new(self.labelTime, timeParams)
		else
			self.timeCountDown_:setInfo(timeParams)
		end

		self.labelEnd.text = __("END_TEXT")

		if table_id == 80 and xyd.Global.lang == "de_de" then
			dump(11111111)
			self.imgTitle1.transform:X(self.imgTitle1.transform.localPosition.x + 20)
		end
	end
end

function PushActivityWindow:setImgTitle(tableId, giftbagId)
	NGUITools.DestroyChildren(self.groupNumRoot.gameObject.transform)

	local paramShow = {
		imgTitle2 = false,
		imgTitle1 = true
	}

	local function onLoadOver()
		for key, show in pairs(paramShow) do
			self[key].gameObject:SetActive(show)
		end

		self.titleImgTable:Reposition()

		if xyd.Global.lang == "de_de" then
			self.groupTime:X(-65)
		end

		if xyd.Global.lang == "fr_fr" then
			self.groupTime:X(-30)
		end
	end

	local switch = {
		[77] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text01_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[76] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text02_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[111] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text03_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[110] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text03_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[107] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text03_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[82] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text03_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[81] = function ()
			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text03_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[80] = function ()
			local level = xyd.tables.giftBagTable:getParams(giftbagId)[1]
			local params = {}

			while level > 0 do
				local num = level % 10

				table.insert(params, 1, num)

				level = math.floor(level / 10)
			end

			for idx, num in ipairs(params) do
				local numImg = NGUITools.AddChild(self.groupNumRoot.gameObject, "numImg")
				local sprite = numImg:AddComponent(typeof(UISprite))
				sprite.depth = 8

				xyd.setUISpriteAsync(sprite, nil, "push_activity_num_" .. num, function ()
					sprite:MakePixelPerfect()

					if idx == #params then
						onLoadOver()
						self.groupNumRoot:Reposition()
					end
				end)
			end

			if xyd.Global.lang == "fr_fr" then
				paramShow.imgTitle2 = false
				paramShow.imgTitle1 = true

				xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text04_" .. xyd.Global.lang, function ()
					self.imgTitle1:MakePixelPerfect()
					onLoadOver()
				end)
			elseif xyd.Global.lang == "en_en" then
				paramShow.imgTitle2 = true
				paramShow.imgTitle1 = true

				xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text04_" .. xyd.Global.lang, function ()
					self.imgTitle1:MakePixelPerfect()
				end)
				xyd.setUISpriteAsync(self.imgTitle2, nil, "push_activity_text041_" .. xyd.Global.lang, function ()
					self.imgTitle2:MakePixelPerfect()
					onLoadOver()
				end)
			elseif xyd.Global.lang == "ja_jp" then
				paramShow.imgTitle2 = true
				paramShow.imgTitle1 = true

				xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text04_" .. xyd.Global.lang, function ()
					self.imgTitle1:MakePixelPerfect()
				end)
				xyd.setUISpriteAsync(self.imgTitle2, nil, "push_activity_text041_" .. xyd.Global.lang, function ()
					self.imgTitle2:MakePixelPerfect()
					onLoadOver()
				end)
			elseif xyd.Global.lang == "zh_tw" then
				paramShow.imgTitle2 = true
				paramShow.imgTitle1 = false

				xyd.setUISpriteAsync(self.imgTitle2, nil, "push_activity_text04_" .. xyd.Global.lang, function ()
					self.imgTitle2:MakePixelPerfect()
					onLoadOver()
				end)
			elseif xyd.Global.lang == "ko_kr" then
				paramShow.imgTitle2 = true
				paramShow.imgTitle1 = true

				xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text04_" .. xyd.Global.lang, function ()
					self.imgTitle1:MakePixelPerfect()
				end)
				xyd.setUISpriteAsync(self.imgTitle2, nil, "push_activity_text041_" .. xyd.Global.lang, function ()
					self.imgTitle2:MakePixelPerfect()
					onLoadOver()
				end)
			elseif xyd.Global.lang == "de_de" then
				paramShow.imgTitle2 = true
				paramShow.imgTitle1 = true

				xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text04_" .. xyd.Global.lang, function ()
					self.imgTitle1:MakePixelPerfect()
				end)
				xyd.setUISpriteAsync(self.imgTitle2, nil, "push_activity_text041_" .. xyd.Global.lang, function ()
					self.imgTitle2:MakePixelPerfect()
					onLoadOver()
				end)
				self.groupNumRoot:X(-85)
			end
		end,
		[78] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text05_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[79] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text06_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[151] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text151_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[152] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text152_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[153] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text153_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
				self.imgTitle1:Y(20)
			end)
		end,
		[154] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text154_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
				self.imgTitle1:SetLocalPosition(5, 10, 0)
			end)
		end,
		[215] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text215_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
		end,
		[241] = function ()
			paramShow.imgTitle2 = false
			paramShow.imgTitle1 = true

			xyd.setUISpriteAsync(self.imgTitle1, nil, "push_activity_text215_" .. xyd.Global.lang, function ()
				self.imgTitle1:MakePixelPerfect()
				onLoadOver()
			end)
			xyd.db.misc:setValue({
				key = "activity_optional_supply_super_push",
				value = xyd.getServerTime()
			})
		end
	}

	if switch[tableId] then
		switch[tableId]()
	end
end

function PushActivityWindow:checkClose()
	if #self.push_list_ > 0 then
		self:updateLayout()
	else
		xyd.GiftbagPushController.get():checkIndependentPopUpWindow()
		xyd.WindowManager.get():closeWindow(self.name_)
	end
end

function PushActivityWindow:setOptional_215()
	local ReplaceIcon = import("app.components.ReplaceIcon")
	local giftBagID = self.cur_push_.giftbag_id
	self.optionalNum_215 = xyd.tables.activityLevelPushOptionalTable:getNum(giftBagID)
	local optionalList = {}

	for i = 1, self.optionalNum_215 do
		table.insert(optionalList, xyd.tables.activityLevelPushOptionalTable:getAwards(giftBagID, i))
	end

	self.selectAwards_215 = {}
	self.selectAwardIndexs_215 = {}
	self.selectIcons_215 = {}

	local function openSelectWindow(selectIndex)
		local exAwards = {}

		if next(self.selectAwards_215) then
			for i = 1, self.optionalNum_215 do
				table.insert(exAwards, self.selectAwards_215[i])
			end
		end

		xyd.WindowManager.get():openWindow("activity_optional_award_window", {
			optionalList = optionalList,
			opNum = self.optionalNum_215,
			curIndex = selectIndex,
			exAwards = exAwards,
			titleText = __("ACTIVITY_DRAGON_BOAT_AWARD_SELECT_WINDOW_SECOND_TITLE"),
			callback = function (exAwards, exAwardIndexs)
				for i = 1, self.optionalNum_215 do
					self.selectAwards_215[i] = exAwards[i]
					self.selectAwardIndexs_215[i] = exAwardIndexs[i]

					self.selectIcons_215[i]:setIcon(self.selectAwards_215[i][1], self.selectAwards_215[i][2])
				end
			end
		})
	end

	for i = 1, self.optionalNum_215 do
		local opIcon = ReplaceIcon.new(self.itemGroup.gameObject, {
			callback = function ()
				openSelectWindow(i)
			end
		})

		UIEventListener.Get(opIcon:getGameObject()).onClick = function ()
			openSelectWindow(i)
		end

		table.insert(self.selectIcons_215, opIcon)
	end
end

return PushActivityWindow
