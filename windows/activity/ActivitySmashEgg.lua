local ActivitySmashEgg = class("ActivitySmashEgg", import(".ActivityContent"))

function ActivitySmashEgg:ctor(parentGO, params, parent)
	self.itemIDs = xyd.tables.activitySmashEggTable:getItemIDs()

	ActivitySmashEgg.super.ctor(self, parentGO, params, parent)
end

function ActivitySmashEgg:getPrefabPath()
	return "Prefabs/Windows/activity/activity_smash_egg"
end

function ActivitySmashEgg:initUI()
	self:getUIComponent()
	ActivitySmashEgg.super.initUI(self)
	self:initUIComponent()
	self:updateResGroup()
end

function ActivitySmashEgg:getUIComponent()
	local goTrans = self.go.transform
	self.Bg_ = goTrans:NodeByName("Bg_")
	self.Mb_ = goTrans:NodeByName("Mb_")
	self.model_ = goTrans:NodeByName("model_")
	self.titleImg_ = goTrans:ComponentByName("titleImg_", typeof(UISprite))
	self.timeGroup = goTrans:NodeByName("timeGroup").gameObject
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.tipLabel_ = goTrans:ComponentByName("tipLabel_", typeof(UILabel))
	self.helpBtn_ = goTrans:NodeByName("helpBtn_").gameObject
	self.checkBtn_ = goTrans:NodeByName("checkBtn_").gameObject
	self.mask_ = goTrans:NodeByName("mask_").gameObject
	self.bottomGroup = goTrans:NodeByName("bottomGroup")
	self.awardBtn_ = self.bottomGroup:NodeByName("awardBtn_").gameObject
	self.awardBtnLabel = self.awardBtn_:ComponentByName("label", typeof(UILabel))
	self.eggGroup = self.bottomGroup:NodeByName("eggGroup").gameObject

	for i = 1, 3 do
		self["group" .. i] = self.eggGroup:NodeByName("group" .. i).gameObject
		self["img" .. i] = self["group" .. i]:ComponentByName("img_", typeof(UITexture))
		self["resIcon" .. i] = self["group" .. i]:ComponentByName("resGroup/icon_", typeof(UISprite))
		self["resLabel" .. i] = self["group" .. i]:ComponentByName("resGroup/label_", typeof(UILabel))
		self["resBtn" .. i] = self["group" .. i]:NodeByName("resGroup/addBtn_").gameObject
		self["useBtn" .. i] = self["group" .. i]:NodeByName("useBtn_").gameObject
		self["useIcon" .. i] = self["group" .. i]:ComponentByName("useBtn_/icon_", typeof(UISprite))
		self["useNumLabel" .. i] = self["group" .. i]:ComponentByName("useBtn_/icon_/num_", typeof(UILabel))
		self["useLabel" .. i] = self["group" .. i]:ComponentByName("useBtn_/label_", typeof(UILabel))
		self["useBtnRedMark" .. i] = self["group" .. i]:NodeByName("useBtn_/redPoint").gameObject
	end

	self.desLabel_ = self.bottomGroup:ComponentByName("desLabel_", typeof(UILabel))
end

function ActivitySmashEgg:initUIComponent()
	xyd.setUISpriteAsync(self.titleImg_, nil, "activity_smash_egg_text_" .. xyd.Global.lang, nil, , true)

	self.tipLabel_.text = __("DRIFT_BOTTLE_TEXT_09")
	self.awardBtnLabel.text = __("DRIFT_BOTTLE_TEXT_01")
	self.desLabel_.text = __("DRIFT_BOTTLE_TEXT_08")
	self.endLabel_.text = __("TEXT_END")

	import("app.components.CountDown").new(self.timeLabel_, {
		duration = self.activityData:getEndTime() - xyd.getServerTime()
	})

	for i = 1, 3 do
		local cost = xyd.tables.activitySmashEggTable:getCost(i)
		local icon = xyd.tables.itemTable:getSmallIcon(cost[1])

		xyd.setUISpriteAsync(self["resIcon" .. i], nil, icon)
		xyd.setUISpriteAsync(self["useIcon" .. i], nil, icon)

		self["useNumLabel" .. i].text = cost[2]
		self["useLabel" .. i].text = __("DRIFT_BOTTLE_TEXT_02")
		self["effect" .. i] = xyd.Spine.new(self["img" .. i].gameObject)

		self["effect" .. i]:setInfo("valentine_box0" .. i, function ()
			self["effect" .. i]:play("idle", 0)
			self["effect" .. i]:SetLocalScale(0.5, 0.5, 1)
			self["effect" .. i]:SetLocalPosition(0, 0, 0)
		end)
	end

	self.modelEffect_ = xyd.Spine.new(self.model_.gameObject)

	self.modelEffect_:setInfo("monika_pifu03_lihui01", function ()
		self.modelEffect_:play("animation", -1, 1)
		self.modelEffect_:SetLocalScale(0.6, 0.6, 1)
		self.modelEffect_:SetLocalPosition(0, -515, 0)
	end)
end

function ActivitySmashEgg:onRegister()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onAward))
	self:registerEvent(xyd.event.BOSS_BUY, handler(self, self.updateResGroup))
	self:registerEvent(xyd.event.ITEM_CHANGE, handler(self, self.updateResGroup))

	UIEventListener.Get(self.checkBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("smash_egg_drop_probability_window", {})
	end)
	UIEventListener.Get(self.helpBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("help_window", {
			key = "DRIFT_BOTTLE_HELP"
		})
	end)
	UIEventListener.Get(self.awardBtn_).onClick = handler(self, function ()
		xyd.WindowManager.get():openWindow("smash_egg_award_window", {
			values = self.activityData.detail.values,
			is_completeds = self.activityData.detail.is_completeds
		})
	end)

	for i = 1, 3 do
		UIEventListener.Get(self["resBtn" .. i]).onClick = handler(self, function ()
			self:onClickResBtn(i)
		end)
		UIEventListener.Get(self["useBtn" .. i]).onClick = handler(self, function ()
			self:onClickUseBtn(i)
		end)
		UIEventListener.Get(self["img" .. i].gameObject).onClick = handler(self, function ()
			xyd.WindowManager.get():openWindow("smash_egg_drop_probability_window", {
				type = i
			})
		end)
	end
end

function ActivitySmashEgg:onClickResBtn(index)
	xyd.WindowManager:get():openWindow("activity_item_getway_window", {
		activityData = self.activityData.detail_,
		itemID = self.itemIDs[index],
		activityID = xyd.ActivityID.ACTIVITY_SMASH_EGG,
		openItemBuyWnd = function ()
			local limit = xyd.tables.miscTable:getNumber("activity_smash_egg_limit", "value")

			if limit <= self.activityData.detail.limit then
				xyd.alertTips(__("FULL_BUY_SLOT_TIME"))

				return
			end

			xyd.WindowManager.get():openWindow("item_buy_window", {
				hide_min_max = false,
				item_no_click = false,
				cost = xyd.tables.miscTable:split2Cost("activity_smash_egg_cost", "value", "|#")[1],
				max_num = limit - self.activityData.detail.limit,
				itemParams = {
					itemID = 291,
					num = 1
				},
				buyCallback = function (num)
					xyd.alertYesNo(__("CONFIRM_BUY"), function (yes)
						if yes then
							local msg = messages_pb.boss_buy_req()
							msg.activity_id = xyd.ActivityID.ACTIVITY_SMASH_EGG
							msg.num = num

							xyd.Backend.get():request(xyd.mid.BOSS_BUY, msg)
						end
					end)
				end,
				limitText = __("BUY_GIFTBAG_LIMIT", self.activityData.detail.limit .. "/" .. limit)
			})
		end
	})
end

function ActivitySmashEgg:onClickUseBtn(index)
	local hasNum = xyd.models.backpack:getItemNumByID(self.itemIDs[index])
	local costNum = 1

	if hasNum < costNum then
		xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(self.itemIDs[index])))
	else
		self.mask_:SetActive(true)

		self.index = index

		self["effect" .. index]:play("open", 1, nil, function ()
			local params = require("cjson").encode({
				num = 1,
				table_id = index
			})

			xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SMASH_EGG, params)
			self["effect" .. index]:play("idle", 0)
		end)
	end
end

function ActivitySmashEgg:updateResGroup(event)
	if event and event.data.activity_id and event.data.activity_id ~= xyd.ActivityID.ACTIVITY_SMASH_EGG then
		return
	end

	if event and event.data.buy_times then
		local buyTimesBefore = self.activityData.detail.limit
		self.activityData.detail.limit = event.data.buy_times

		xyd.models.itemFloatModel:pushNewItems({
			{
				item_id = 291,
				item_num = self.activityData.detail.limit - buyTimesBefore
			}
		})
	end

	for i = 1, 3 do
		self["resLabel" .. i].text = xyd.models.backpack:getItemNumByID(self.itemIDs[i])
	end

	self:updateRedPoint()
end

function ActivitySmashEgg:updateRedPoint()
	for i = 1, 3 do
		local hasNum = xyd.models.backpack:getItemNumByID(self.itemIDs[i])

		self["useBtnRedMark" .. i]:SetActive(hasNum > 0)
	end

	xyd.models.redMark:setMark(xyd.RedMarkType.ACTIVITY_SMASH_EGG, self.activityData:getRedMarkState())
end

function ActivitySmashEgg:onAward(event)
	local items = require("cjson").decode(event.data.detail).items
	local skinIds = {}

	for i = 1, #items do
		if items[i].item_id == 292 or items[i].item_id == 293 then
			items[i].cool = 1
		end

		if xyd.tables.itemTable:getType(items[i].item_id) == xyd.ItemType.SKIN then
			table.insert(skinIds, items[i].item_id)
		end
	end

	local params = {
		wnd_type = 4,
		data = items,
		cost = {
			self.itemIDs[self.index],
			1
		},
		cost2 = self.index == 1 and {
			self.itemIDs[self.index],
			5
		} or nil,
		btnLabelText = self.index == 1 and "DRIFT_BOTTLE_TEXT_07" or "DRIFT_BOTTLE_TEXT_10",
		buyCallback = function (cost, cost2, isCost2)
			local itemID = cost[1]
			local num = cost[2]

			if cost2 and isCost2 then
				itemID = cost2[1]
				num = cost2[2]
			end

			local hasNum = xyd.models.backpack:getItemNumByID(itemID)

			if num <= hasNum then
				local params = require("cjson").encode({
					table_id = itemID - 290,
					num = num
				})

				xyd.models.activity:reqAwardWithParams(xyd.ActivityID.ACTIVITY_SMASH_EGG, params)
			else
				xyd.alertTips(__("NOT_ENOUGH", xyd.tables.itemTable:getName(itemID)))

				return false
			end
		end
	}

	if #skinIds > 0 then
		xyd.onGetNewPartnersOrSkins({
			destory_res = false,
			skins = skinIds,
			callback = function ()
				xyd.openWindow("gamble_rewards_window", params)
			end
		})
	else
		xyd.openWindow("gamble_rewards_window", params)
	end

	self.mask_:SetActive(false)
end

function ActivitySmashEgg:resizeToParent()
	ActivitySmashEgg.super.resizeToParent(self)
	self:resizePosY(self.bottomGroup, -661, -833)
	self:resizePosY(self.titleImg_, -197, -251)
	self:resizePosY(self.timeGroup, -384.5, -438.5)
	self:resizePosY(self.awardBtn_, 274.5, 282)
	self:resizePosY(self.tipLabel_, -300, -396)
	self:resizePosY(self.Mb_, -639.5, -791.5)

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" or xyd.Global.lang == "ko_kr" then
		self.useLabel1:X(15)
		self.useLabel2:X(15)
		self.useLabel3:X(15)
	elseif xyd.Global.lang == "ja_jp" then
		self.useLabel1:X(18)
		self.useLabel2:X(18)
		self.useLabel3:X(18)
	elseif xyd.Global.lang == "de_de" then
		self.useLabel1:X(18)
		self.useLabel2:X(18)
		self.useLabel3:X(18)

		self.useLabel1.fontSize = 18
		self.useLabel2.fontSize = 18
		self.useLabel3.fontSize = 18
	end

	if xyd.Global.lang == "fr_fr" then
		self.awardBtn_:X(270)

		self.awardBtnLabel.width = 150
	end
end

return ActivitySmashEgg
