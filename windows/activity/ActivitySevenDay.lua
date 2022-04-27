local ActivityContent = import(".ActivityContent")
local ActivitySevenDay = class("ActivitySevenDay", ActivityContent)
local ActivitySevenDayAward = class("ActivitySevenDayAward", import("app.components.BaseComponent"))
local ActivitySevenDaysAwardsTable = xyd.tables.activitySevenDaysAwardsTable
local Activity = xyd.models.activity
local json = require("cjson")
local GambleRewardsWindow = import("app.windows.GambleRewardsWindow")

function ActivitySevenDay:ctor(parentGO, params, parent)
	self.awardItemList = {}
	self.itemTable = xyd.tables.itemTable
	self.partnerTable = xyd.tables.partnerTable
	self.effectName_ = "fx_sevendays_partner"
	self.effectMode = 1
	self.callbacks_1 = {
		hit = function ()
			self.img_0.depth = 5
			self.img_1.depth = 3
		end
	}
	self.callbacks_2 = {
		hit = function ()
			self.img_0.depth = 3
			self.img_1.depth = 5
		end
	}

	ActivityContent.ctor(self, parentGO, params, parent)
end

function ActivitySevenDay:getPrefabPath()
	return "Prefabs/Windows/activity/activity_seven_day"
end

function ActivitySevenDay:getUIComponent()
	local go = self.go
	self.desImg = go:ComponentByName("desImg", typeof(UISprite))
	self.effectGroup = go:NodeByName("effectGroup").gameObject
	self.touchGroup = go:NodeByName("touchGroup").gameObject
	self.desGroup = go:NodeByName("desGroup").gameObject
	self.starGroup = go:NodeByName("desGroup/starGroup").gameObject
	self.desLabel = go:ComponentByName("desGroup/desLabel", typeof(UILabel))
	self.nameLabel = go:ComponentByName("desGroup/nameLabel", typeof(UILabel))
	self.awardsGroup = go:NodeByName("awardsGroup").gameObject
	self.award_item_1 = self.awardsGroup:NodeByName("award_item_1").gameObject
	self.award_item_2 = self.awardsGroup:NodeByName("award_item_2").gameObject
	self.award_item_3 = self.awardsGroup:NodeByName("award_item_3").gameObject
	self.award_item_4 = self.awardsGroup:NodeByName("award_item_4").gameObject
	self.award_item_5 = self.awardsGroup:NodeByName("award_item_5").gameObject
	self.award_item_6 = self.awardsGroup:NodeByName("award_item_6").gameObject
	self.award_item_7 = self.awardsGroup:NodeByName("award_item_7").gameObject
	self.node0 = go:NodeByName("effectGroup/node0").gameObject
	self.node1 = go:NodeByName("effectGroup/node1").gameObject
	self.img_0 = go:ComponentByName("effectGroup/node0/img_0", typeof(UISprite))
	self.img_1 = go:ComponentByName("effectGroup/node1/img_1", typeof(UISprite))
end

function ActivitySevenDay:initUIComponent()
	xyd.setUISpriteAsync(self.desImg, nil, "activity_sevenday_text01_" .. xyd.Global.lang, nil, , true)
	self.go:SetLocalPosition(0, -530, 0)

	local parent = self.go.transform.parent:GetComponent(typeof(UIPanel))

	self.awardsGroup:SetLocalPosition(-360, 415 - parent.height, 0)
	self.desGroup:SetLocalPosition(130, 973 - parent.height, 0)

	if parent.height < 1000 then
		self.img_1:Y(115)
		self.img_0:Y(165)
	end

	self.img_1:SetActive(false)
	self.img_0:SetActive(false)
end

function ActivitySevenDay:initUI()
	ActivityContent.initUI(self)
	self:getUIComponent()
	self:initUIComponent()
	self:euiComplete()
end

function ActivitySevenDay:euiComplete()
	local detail = self.activityData.detail
	local count = detail.count
	local onlineDays = detail.online_days
	local awardsIDs = ActivitySevenDaysAwardsTable:getIDs()

	for id in pairs(awardsIDs) do
		local parent = self["award_item_" .. tostring(id)]
		local awardItem = ActivitySevenDayAward.new(parent)

		awardItem:setInfo({
			id = id
		})

		if onlineDays < id then
			awardItem:setNormal()
		elseif count < id then
			awardItem:setAvailable()
		else
			awardItem:setAwarded()
		end

		table.insert(self.awardItemList, awardItem)
	end

	if self:isAvailable() then
		UIEventListener.Get(self.touchGroup).onClick = function ()
			self:getAward()
		end
	else
		UIEventListener.Get(self.touchGroup).onClick = nil

		self.touchGroup:SetActive(false)
	end

	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, handler(self, function (____, event)
		local id = event.data.activity_id
		local data = event.data

		if id ~= self.id then
			return
		end

		local detail = json.decode(data.detail)
		local count = tonumber(detail.count)
		local awardData = ActivitySevenDaysAwardsTable:getAward(count)
		local itemID = awardData[1]
		local itemNum = awardData[2]
		local itemType = self.itemTable:getType(itemID)

		local function showAward()
			if itemType == xyd.ItemType.HERO_DEBRIS then
				local partnerInfo = detail.partner_info

				if not partnerInfo then
					return
				end

				local tableID = partnerInfo.table_id

				xyd.models.slot:addPartners({
					partnerInfo
				})
				xyd.onGetNewPartnersOrSkins({
					destory_res = false,
					partners = {
						tableID
					},
					callback = function ()
					end,
					closeCallBack = function ()
						local evaluate_have_closed = xyd.db.misc:getValue("evaluate_have_closed") or false
						local lastTime = xyd.db.misc:getValue("evaluate_last_time") or 0

						if not evaluate_have_closed and lastTime and xyd.getServerTime() - lastTime > 3 * xyd.DAY_TIME then
							local win = xyd.getWindow("main_window")

							win:setHasEvaluateWindow(true, xyd.EvaluateFromType.SEVENDAY)
						end
					end
				})
			elseif itemType == xyd.ItemType.SKIN then
				xyd.onGetNewPartnersOrSkins({
					destory_res = false,
					skins = {
						itemID
					},
					callback = function ()
					end
				})
			else
				local tmpItems = {
					{
						cool = 0,
						item_id = itemID,
						item_num = itemNum
					}
				}
				local params = {
					data = tmpItems,
					wnd_type = GambleRewardsWindow.WindowType.NORMAL,
					callback = function ()
					end
				}

				xyd.openWindow("gamble_rewards_window", params)
			end
		end

		self:refreshLayout(true, showAward)
	end))
	self:initEffect()

	UIEventListener.Get(self.effectGroup).onClick = function ()
		if not self.effect_flag then
			return
		end

		if self.effectMode == 1 then
			self.effect:playWithEvent("texiao01", 1, 1, self.callbacks_1, true)

			self.desLabel.text = __("SEVEN_DAY_DES2")
			self.nameLabel.text = __("SEVEN_DAY_DES4")

			self.nameLabel:Y(2)
			self.starGroup:SetActive(false)

			self.effectMode = 0
		else
			self.effect:playWithEvent("texiao02", 1, 1, self.callbacks_2, true)

			self.desLabel.text = __("SEVEN_DAY_DES1")
			self.nameLabel.text = __("SEVEN_DAY_DES3")

			self.nameLabel:Y(-10)
			self.starGroup:SetActive(true)

			self.effectMode = 1
		end
	end

	self.desLabel.text = __("SEVEN_DAY_DES1")

	if xyd.Global.lang == "de_de" then
		self.desLabel.fontSize = 18
		self.desLabel.width = 230
		self.desLabel.height = 60

		self.desLabel:SetLeftAnchor(self.desGroup, 0, 20)
		self.desLabel:ResetAndUpdateAnchors()
	end

	self.nameLabel.text = __("SEVEN_DAY_DES3")
end

function ActivitySevenDay:initEffect()
	self.effect = xyd.Spine.new(self.effectGroup)

	self.effect:setInfo(self.effectName_, function ()
		self.effect_flag = 1

		self.img_1:SetActive(true)
		self.img_0:SetActive(true)
		self.effect:followBone("hou1", self.node0)
		self.effect:followBone("qian2", self.node1)
		self.effect:followSlot("xiangsu_0", self.img_0)
		self.effect:followSlot("xiangsu_00000", self.img_1)
		self.effect:playWithEvent("texiao01", 1, 0, self.callbacks_1)
	end)
end

function ActivitySevenDay:refreshLayout(showAnimation, callback)
	local detail = self.activityData.detail
	local count = tonumber(detail.count)
	local onlineDays = tonumber(detail.online_days)
	local awardItem = self.awardItemList[count]

	awardItem:setAwarded(showAnimation, callback)

	if not self:isAvailable() then
		self.touchGroup:SetActive(false)

		UIEventListener.Get(self.touchGroup).onClick = nil
	end
end

function ActivitySevenDay:isAvailable()
	local detail = self.activityData.detail
	local count = tonumber(detail.count)
	local onlineDays = tonumber(detail.online_days)

	if onlineDays <= count then
		return false
	end

	return true
end

function ActivitySevenDay:getAward()
	if not self:isAvailable() then
		return
	end

	local detail = self.activityData.detail
	local count = tonumber(detail.count)

	if count + 1 == 2 and xyd.models.slot:getCanSummonNum() < 1 then
		xyd.openWindow("partner_slot_increase_window")

		return
	end

	Activity:reqAward(self.id)
end

function ActivitySevenDayAward:ctor(parentGO)
	self.itemTable = xyd.tables.itemTable
	self.partnerTable = xyd.tables.partnerTable
	self.playEffectName = "texiao01"
	self.rotationList = {
		Vector3(0, 0, -12.2),
		Vector3(0, 0, 0),
		Vector3(0, 0, -18),
		Vector3(0, 0, -8),
		Vector3(0, 0, 0),
		Vector3(0, 0, -4),
		Vector3(0, 0, -4)
	}
	self.numLabelPosList = {
		{
			15,
			-65
		},
		{
			35,
			-60
		},
		{
			-10,
			-60
		},
		{
			0,
			-60
		},
		{
			0,
			-60
		},
		{
			20,
			-55
		},
		{
			30,
			-125
		}
	}
	self.desLabelPosList = {
		{
			5,
			35
		},
		{
			0,
			35
		},
		{
			10,
			35
		},
		{
			0,
			35
		},
		{
			0,
			35
		},
		{
			0,
			35
		},
		{
			-3,
			70
		}
	}
	self.mainGroupPosList = {
		{
			width = 183,
			height = 205
		},
		{
			width = 177,
			height = 186
		},
		{
			width = 183,
			height = 212
		},
		{
			width = 186,
			height = 215
		},
		{
			width = 193,
			height = 191
		},
		{
			width = 193,
			height = 197
		},
		{
			width = 212,
			height = 333
		}
	}

	ActivitySevenDayAward.super.ctor(self, parentGO)
end

function ActivitySevenDayAward:getPrefabPath()
	return "Prefabs/Windows/activity/activity_seven_day_award"
end

function ActivitySevenDayAward:getUIComponent()
	local go = self.go
	self.mainGroup = go:ComponentByName("mainGroup", typeof(UIWidget))
	self.img1 = self.mainGroup:ComponentByName("img1", typeof(UISprite))
	self.imgMask = self.mainGroup:ComponentByName("imgMask", typeof(UISprite))
	self.labelGroup = self.mainGroup:NodeByName("labelGroup").gameObject
	self.desLabel = self.labelGroup:ComponentByName("desLabel", typeof(UILabel))
	self.numLabel = self.labelGroup:ComponentByName("numLabel", typeof(UILabel))
	self.eff = go:NodeByName("eff").gameObject
end

function ActivitySevenDayAward:initUI()
	ActivitySevenDayAward.super.initUI(self)
	self:getUIComponent()
end

function ActivitySevenDayAward:setInfo(params)
	self.params = params
	self.id_ = params.id

	xyd.setUISpriteAsync(self.img1, nil, "day_" .. tostring(self.id_) .. "_1")

	if self.id_ == 7 then
		self.playEffectName = "texiao02"
	end

	local awardData = ActivitySevenDaysAwardsTable:getAward(self.id_)
	local itemID = awardData[1]
	local itemType = self.itemTable:getType(itemID)
	local num = awardData[2]

	if itemType == xyd.ItemType.HERO_DEBRIS then
		local partnerCostData = self.itemTable:partnerCost(itemID)
		num = num / partnerCostData[2]
	end

	local mainGroupPosData = self.mainGroupPosList[self.id_]

	for key in pairs(mainGroupPosData) do
		self.mainGroup[key] = mainGroupPosData[key]
	end

	local desLabelPos = self.desLabelPosList[self.id_]
	local numLabelPos = self.numLabelPosList[self.id_]
	self.numLabel.text = "×" .. tostring(xyd.getRoughDisplayNumber(num))
	self.numLabel.gameObject.transform.localEulerAngles = self.rotationList[self.id_]
	self.desLabel.gameObject.transform.localEulerAngles = self.rotationList[self.id_]

	self.desLabel:SetLocalPosition(desLabelPos[1], desLabelPos[2], 0)
	self.numLabel:SetLocalPosition(numLabelPos[1], numLabelPos[2], 0)
	self.numLabel:MakePixelPerfect()
	self.desLabel:MakePixelPerfect()

	UIEventListener.Get(self.mainGroup.gameObject).onClick = function ()
		self:showGetWay()
	end
end

function ActivitySevenDayAward:showGetWay()
	if not self.id_ then
		return
	end

	local awardData = ActivitySevenDaysAwardsTable:getAward(self.id_)
	local itemID = awardData[1]
	local itemNum = awardData[2]
	local itemType = self.itemTable:getType(itemID)

	if itemType == xyd.ItemType.HERO_DEBRIS then
		local partnerCostData = self.itemTable:partnerCost(itemID)
		local tableID = partnerCostData[1]

		xyd.openWindow("partner_info", {
			table_id = tableID,
			grade = self.partnerTable:getMaxGrade(tableID),
			lev = self.partnerTable:getMaxlev(tableID)
		})
	elseif itemType == xyd.ItemType.SKIN then
		xyd.openWindow("skin_tip_window", {
			skin_id = itemID
		})
	else
		local params = {
			itemID = itemID,
			itemNum = itemNum
		}

		xyd.openWindow("item_tips_window", params)
	end
end

function ActivitySevenDayAward:setNormal()
	self.img1:SetActive(true)
	xyd.setUISpriteAsync(self.img1, nil, "day_" .. tostring(self.id_) .. "_1")
	xyd.applyOrigin(self.img1)

	if self.effect then
		self.effect:SetActive(false)
	end

	self.imgMask:SetActive(false)

	self.desLabel.text = __("SEVENDAY_NORMAL", self.id_)
end

function ActivitySevenDayAward:setAvailable()
	self.img1:SetActive(true)
	xyd.setUISpriteAsync(self.img1, nil, "day_" .. tostring(self.id_) .. "_2")
	self.imgMask:SetActive(false)

	if not self.effect then
		self.effect = xyd.Spine.new(self.eff)

		self.effect:setInfo("fx_sevendays_star", function ()
			self.effect:play(nil, 0)
		end)
	else
		self.effect:SetActive(true)
	end

	self.desLabel.text = __("SEVENDAY_AVAILABEL", self.id_)
end

function ActivitySevenDayAward:setAwarded(showAnimation, callback)
	self.img1:SetActive(true)
	xyd.setUISpriteAsync(self.img1, nil, "day_" .. tostring(self.id_) .. "_1")
	self.imgMask:SetActive(true)

	if self.effect then
		self.effect:SetActive(false)
	end

	xyd.applyGrey(self.img1)

	self.desLabel.text = __("SEVENDAY_NORMAL", self.id_)

	if showAnimation then
		self.imgMask.alpha = 0.01

		self.imgMask:SetLocalScale(4, 4, 0)

		local seq = self:getSequence(function ()
			if callback then
				callback()
			end
		end)

		seq:Append(self.imgMask.transform:DOScale(Vector3(1, 1, 0), 0.3)):Join(xyd.getTweenAlpha(self.imgMask, 1, 0.3))
	end
end

return ActivitySevenDay
