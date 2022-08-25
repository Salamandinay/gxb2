local ActivityContent = import(".ActivityContent")
local ActivityLengarySkin = class("ActivityLengarySkin", ActivityContent)
local lengaryProgressPart = class("lengaryProgressPart", import("app.components.CopyComponent"))
local cjson = require("cjson")
local girlsModel = import("app.components.GirlsModel")
local ParnterImg = import("app.components.PartnerImg")

function lengaryProgressPart:ctor(go, parent)
	self.parent_ = parent

	lengaryProgressPart.super.ctor(self, go)
end

function lengaryProgressPart:initUI()
	self.itemRoot_ = self.go:NodeByName("itemRoot").gameObject
	self.progressBar = self.go:ComponentByName("progressBar", typeof(UIProgressBar))
	self.progressLabel = self.go:ComponentByName("progressBar/label", typeof(UILabel))
	self.effectRoot_ = self.go:NodeByName("progressBar/effectRoot").gameObject
	local awardItem = xyd.tables.activityLengarySkinTable:getSkinAward(self.parent_.lengarySkinID_)

	xyd.getItemIcon({
		notShowGetWayBtn = true,
		scale = 0.8,
		uiRoot = self.itemRoot_,
		itemID = awardItem[1],
		wndType = xyd.ItemTipsWndType.ACTIVITY
	})
end

function lengaryProgressPart:playEffect(frameCount)
	local effect = xyd.Spine.new(self.effectRoot_)

	effect:setInfo("jindutiao_legendary_skin", function ()
		effect:SetLocalPosition(0, 0, 0)
		effect:SetLocalScale(1, 1, 1)
		effect:play("texiao01", 1, 1, function ()
			effect:play("texiao02", frameCount, 1, function ()
				effect:play("texiao03", 1)
			end)
		end)
	end)

	local sequence = self:getSequence()

	sequence:Append(self.progressLabel.transform:DOScale(Vector3(1.3, 1.3, 1.3), 0.08333333333333333))
	sequence:AppendInterval(frameCount * 5 / 60)
	sequence:Append(self.progressLabel.transform:DOScale(Vector3(1.33, 1.33, 1.33), 0.16666666666666666))
	sequence:Append(self.progressLabel.transform:DOScale(Vector3(1, 1, 1), 0.08333333333333333))
end

function lengaryProgressPart:updateProgress(valueNow, maxValue)
	if not valueNow then
		return
	end

	if not self.progressLabel or tolua.isnull(self.progressLabel) then
		return
	end

	self.progressLabel.text = valueNow .. "/" .. maxValue
	self.progressBar.value = valueNow / maxValue
end

function ActivityLengarySkin:ctor(parentGO, params, parent)
	self.lengarySkinID_ = 1

	ActivityLengarySkin.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN, function ()
		xyd.db.misc:setValue({
			key = "activity_legendary_time",
			value = xyd.getServerTime()
		})
	end)
	dump(self.activityData.detail)
end

function ActivityLengarySkin:getPrefabPath()
	return "Prefabs/Windows/activity/activity_legendary_skin"
end

function ActivityLengarySkin:initUI()
	self:initUIComponent()
	self:register()
	self:layout()
	self:updateShopRed()
	self:updateItemNum()
	self:updateProgressNum()
end

function ActivityLengarySkin:initUIComponent()
	local goTrans = self.go.transform
	self.shopBtn_ = goTrans:NodeByName("shopBtn").gameObject
	self.shopBtnRed_ = goTrans:NodeByName("shopBtn/redPoint").gameObject
	self.btnHelp_ = goTrans:NodeByName("btnHelp").gameObject
	self.btnDetail_ = goTrans:NodeByName("btnDetail").gameObject
	self.btnGet_ = goTrans:NodeByName("btnGet").gameObject
	self.resItem1 = goTrans:NodeByName("resItem1").gameObject
	self.resItem1Label_ = goTrans:ComponentByName("resItem1/label", typeof(UILabel))
	self.resItem2_ = goTrans:NodeByName("resItem2").gameObject
	self.resItem2Label_ = goTrans:ComponentByName("resItem2/label", typeof(UILabel))
	self.effectRoot_ = goTrans:NodeByName("effectRoot").gameObject
	self.effectTouch_ = goTrans:NodeByName("effectTouch").gameObject
	self.content = goTrans:NodeByName("content").gameObject
	self.partnerImg = ParnterImg.new(self.effectRoot_)
	self.labelTips_ = self.content:ComponentByName("labelTips", typeof(UILabel))
	self.summon1 = self.content:NodeByName("summon1").gameObject
	self.summon1Label = self.content:ComponentByName("summon1/label", typeof(UILabel))
	self.summon10 = self.content:NodeByName("summon2").gameObject
	self.summon10Label = self.content:ComponentByName("summon2/label", typeof(UILabel))
	self.progressPart = self.content:NodeByName("progressPart").gameObject

	self:resizePosY(self.content.transform, -531, -709)
	self:resizePosY(self.resItem2_.transform, -499, -677)
end

function ActivityLengarySkin:layout()
	local skin_id = xyd.tables.activityLengarySkinTable:getShowSkin(self.lengarySkinID_)
	self.progress_ = lengaryProgressPart.new(self.progressPart, self)
	local cost = xyd.tables.activityLengarySkinTable:getCost(self.lengarySkinID_)
	self.labelTips_.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT10", cost[2], xyd.tables.itemTable:getName(skin_id))
	self.summon1Label.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT11")
	self.summon10Label.text = __("ACTIVITY_LEGENDARY_SKIN_TEXT12")

	self.partnerImg:setImg({
		girl_model_height = 2000,
		showResLoading = true,
		windowName = self.name_,
		itemID = skin_id
	})

	local offset = xyd.tables.activityLengarySkinTable:getSkinOffest(self.lengarySkinID_)
	local scale = xyd.tables.activityLengarySkinTable:getSkinScale(self.lengarySkinID_)
	self.effectRoot_.transform.localPosition = Vector3(offset[1], offset[2], 0)
	self.effectRoot_.transform.localScale = Vector3(scale, scale, scale)
end

function ActivityLengarySkin:updateShopRed()
	local flag = self.activityData:checkShopRed()

	self.shopBtnRed_:SetActive(flag)
end

function ActivityLengarySkin:updateItemNum()
	self.resItem1Label_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON2)
	self.resItem2Label_.text = xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON1)
end

function ActivityLengarySkin:updateProgressNum()
	self.valueNow = xyd.models.backpack:getItemNumByID(xyd.ItemID.LEGENDARY_SKIN_ICON3)
	local cost = xyd.tables.activityLengarySkinTable:getCost(self.lengarySkinID_)
	local maxValue = cost[2]

	self.progress_:updateProgress(self.valueNow, maxValue)
end

function ActivityLengarySkin:register()
	UIEventListener.Get(self.btnHelp_).onClick = function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "ACTIVITY_LEGENDARY_SKIN_HELP"
		})
	end

	UIEventListener.Get(self.btnDetail_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_legendary_skin_detail_window", {})
	end

	UIEventListener.Get(self.summon1).onClick = function ()
		self:summon(1)
	end

	UIEventListener.Get(self.summon10).onClick = function ()
		self:summon(10)
	end

	UIEventListener.Get(self.btnGet_.gameObject).onClick = handler(self, function ()
		local items = xyd.cloneTable(self.activityData:getItems())

		xyd.WindowManager.get():openWindow("activity_space_explore_awarded_window", {
			data = items,
			winTitle = __("ACTIVITY_PARY_ALL_AWARDS")
		})
	end)

	UIEventListener.Get(self.shopBtn_).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_legendary_skin_shop_window", {
			buy_times = self.activityData.detail.buy_times
		})
	end

	UIEventListener.Get(self.effectTouch_).onClick = function ()
		self.partnerImg:effectClickFunction()
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onGetAward))

	UIEventListener.Get(self.resItem2_).onClick = function ()
		xyd.WindowManager.get():openWindow("item_tips_window", {
			show_has_num = true,
			itemID = xyd.ItemID.LEGENDARY_SKIN_ICON1,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})
	end
end

function ActivityLengarySkin:summon(times)
	if self.isReqing_ then
		return
	end

	local cost = xyd.split(xyd.tables.miscTable:getVal("activity_legendary_skin_cost"), "#", true)

	if xyd.models.backpack:getItemNumByID(cost[1]) < cost[2] * times then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(cost[1])))

		return
	end

	local info = {
		type = 1,
		num = times
	}
	local params = cjson.encode(info)
	self.isReqing_ = true

	xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN, params)
end

function ActivityLengarySkin:onGetAward(event)
	local data = xyd.decodeProtoBuf(event.data)

	if data.activity_id == xyd.ActivityID.ACTIVITY_LEGENDARY_SKIN then
		local detail = {}

		if data.detail and tostring(data.detail) ~= "" then
			detail = cjson.decode(data.detail)
		end

		local type_id = detail.type

		if type_id == 1 then
			local params = {
				btnLabelText = __("ACTIVITY_LEGENDARY_SKIN_TEXT11"),
				btnLabelText2 = __("ACTIVITY_LEGENDARY_SKIN_TEXT12"),
				cost = {
					xyd.ItemID.LEGENDARY_SKIN_ICON1,
					1
				},
				cost2 = {
					xyd.ItemID.LEGENDARY_SKIN_ICON1,
					10
				},
				wnd_type = 4,
				data = {},
				buyCallback = function (_, _, is_cost2)
					if is_cost2 then
						self:summon(10)
					else
						self:summon(1)
					end
				end
			}
			local addItemNum = 0
			local awards = detail.awards
			local alertItems = {}
			local card_item = {
				item_num = 0,
				item_id = xyd.ItemID.LEGENDARY_SKIN_ICON2
			}

			for i = 1, #awards do
				local id = awards[i]
				local type = xyd.tables.activityLengarySkinAwardTable:getType(id)
				local award = xyd.tables.activityLengarySkinAwardTable:getAward(id)

				if type == 2 then
					card_item.item_num = card_item.item_num + award[2]
				elseif type == 1 then
					table.insert(alertItems, {
						item_id = award[1],
						item_num = award[2]
					})
				elseif type == 3 then
					local itemInfo = {
						item_id = award[1],
						item_num = award[2]
					}
					addItemNum = addItemNum + award[2]
					itemInfo.cool = xyd.tables.activityLengarySkinAwardTable:getIsSpecial(id)

					table.insert(params.data, itemInfo)
				end
			end

			self.isReqing_ = false

			xyd.itemFloat(alertItems)
			self:waitForTime(0.8, function ()
				xyd.itemFloat({
					card_item
				})
			end)
			xyd.WindowManager.get():openWindow("gamble_rewards_window", params, function ()
				local win = xyd.WindowManager.get():getWindow("gamble_rewards_window")

				if win then
					win:setBtnEnable(false)

					local addRoot = win:getAddComponentRoot()

					addRoot.transform:Y(-400)

					local newProgress = NGUITools.AddChild(addRoot, self.progressPart)
					local newProgressItem = lengaryProgressPart.new(newProgress, self)
					local cost = xyd.tables.activityLengarySkinTable:getCost(self.lengarySkinID_)
					local maxValue = cost[2]
					local startNum = self.valueNow
					local targValue = xyd.checkCondition(maxValue < startNum + addItemNum, maxValue, startNum + addItemNum)

					newProgressItem:updateProgress(self.valueNow, maxValue)

					local frameCount = 1

					if #params.data > 5 then
						frameCount = 2
					end

					self:waitForTime(0.1 * #params.data - 0.1, function ()
						newProgressItem:playEffect(frameCount)
					end)

					for i = 1, 5 + frameCount * 5 do
						self:waitForTime(0.1 * #params.data + i / 60, function ()
							newProgressItem:updateProgress(math.floor(startNum + (targValue - startNum) / (5 + frameCount * 5) * i), maxValue)
						end)
					end

					self:waitForTime(0.1 * #params.data + 1.33, function ()
						win:setBtnEnable(true)
					end)
					self:waitForTime(0.1 * #params.data + 0.33, function ()
						self:updateProgressNum()

						if maxValue <= startNum + addItemNum then
							local awardItem = xyd.tables.activityLengarySkinTable:getSkinAward(self.lengarySkinID_)

							local function effect_callback()
								xyd.alertItems({
									{
										item_num = 1,
										item_id = tonumber(awardItem[1])
									}
								})
							end

							if xyd.tables.itemTable:getType(awardItem[1]) == xyd.ItemType.SKIN then
								xyd.onGetNewPartnersOrSkins({
									destory_res = false,
									skins = {
										tonumber(awardItem[1])
									},
									callback = effect_callback
								})
							else
								effect_callback()
							end

							newProgressItem:updateProgress(self.valueNow, maxValue)
						end
					end)
				end
			end)
		end
	end

	self:updateItemNum()
	self:updateShopRed()
end

return ActivityLengarySkin
