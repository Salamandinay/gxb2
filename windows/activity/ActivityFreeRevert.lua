local ActivityContent = import(".ActivityContent")
local ActivityFreeRevert = class("ActivityFreeRevert", ActivityContent)
local AdvanceIcon = import("app.components.AdvanceIcon")
local PartnerCard = import("app.components.PartnerCard")
local json = require("cjson")

function ActivityFreeRevert:ctor(parentGO, params, parent)
	ActivityFreeRevert.super.ctor(self, parentGO, params, parent)
end

function ActivityFreeRevert:getPrefabPath()
	return "Prefabs/Windows/activity/activity_free_reverge"
end

function ActivityFreeRevert:initUI()
	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.ACTIVITY_FREE_REVERGE)
	self.effectList = {}

	self:getUIComponent()
	ActivityFreeRevert.super.initUI(self)
	self:initUIComponent()
	self:register()
end

function ActivityFreeRevert:resizeToParent()
	ActivityFreeRevert.super.resizeToParent(self)
end

function ActivityFreeRevert:getUIComponent()
	local go = self.go
	self.groupAction = self.go:NodeByName("groupAction").gameObject
	self.bg = self.groupAction:ComponentByName("bg", typeof(UISprite))
	self.imgLogo = self.groupAction:ComponentByName("imgLogo", typeof(UISprite))
	self.btnHelp = self.groupAction:NodeByName("btnHelp").gameObject
	self.btnDetail = self.groupAction:NodeByName("btnDetail").gameObject
	self.bottomGroup = self.groupAction:NodeByName("bottomGroup").gameObject
	self.timeGroup = self.bottomGroup:NodeByName("timeGroup").gameObject
	self.timeGroupLayout = self.bottomGroup:ComponentByName("timeGroup", typeof(UILayout))
	self.endLabel_ = self.timeGroup:ComponentByName("endLabel_", typeof(UILabel))
	self.timeLabel_ = self.timeGroup:ComponentByName("timeLabel_", typeof(UILabel))
	self.CardPos = self.bottomGroup:ComponentByName("CardPos", typeof(UITexture))
	self.CardBgGroup = self.bottomGroup:NodeByName("CardBgGroup").gameObject
	self.cardClickMask1 = self.CardBgGroup:NodeByName("cardClickMask").gameObject
	self.cardBg = self.CardBgGroup:ComponentByName("cardBg", typeof(UISprite))
	self.defaultCard = self.CardBgGroup:ComponentByName("defaultCard", typeof(UISprite))
	self.imgBoder = self.CardBgGroup:ComponentByName("imgBoder", typeof(UISprite))
	self.groupIcon = self.CardBgGroup:ComponentByName("groupIcon", typeof(UISprite))
	self.btnSure = self.bottomGroup:NodeByName("btnSure_").gameObject
	self.labelSure = self.btnSure:ComponentByName("button_label", typeof(UILabel))
	self.rolePos = self.bottomGroup:ComponentByName("rolePos", typeof(UITexture))
	self.cardClickMask2 = self.bottomGroup:NodeByName("cardClickMask2").gameObject
end

function ActivityFreeRevert:register()
	self:registerEvent(xyd.event.GET_ACTIVITY_AWARD, function (event)
		local data = event.data

		if data.activity_id == xyd.ActivityID.ACTIVITY_FREE_REVERGE then
			self:onRollBack(event)

			self.curPartnerID = nil

			self:initData()
			self:updateContent()
		end
	end)

	UIEventListener.Get(self.btnHelp).onClick = handler(self, function ()
		xyd.openWindow("help_window", {
			key = "ACTIVITY_FREE_REVERT_TEXT03"
		})
	end)
	UIEventListener.Get(self.btnDetail).onClick = handler(self, function ()
		local ids = xyd.tables.miscTable:split2Cost("activity_free_revert_partner", "value", "|")
		local realIDs = {}

		for index, value in ipairs(ids) do
			if xyd.tables.partnerTable:getStar(value) <= 5 then
				table.insert(realIDs, value)
			end
		end

		xyd.WindowManager:get():openWindow("common_partner_preview_window", {
			titleText = __("ACTIVITY_FREE_REVERT_TEXT06"),
			windowTitleText = __("ITEM_DETAIL"),
			partnerTableIDs = realIDs,
			tipsText = __("ACTIVITY_FREE_REVERT_TEXT08")
		})
	end)

	for i = 1, 2 do
		UIEventListener.Get(self["cardClickMask" .. i]).onClick = handler(self, function ()
			local params = {
				needNum = 1,
				noClickSelected = true,
				type = "ACTIVITY_FREE_REVERGE",
				notPlaySaoguang = true,
				isShowLovePoint = false,
				showBtnDebris = false,
				benchPartners = self.materialPartnerList,
				partners = self.curPartnerID and {
					self.curPartnerID
				} or nil
			}

			function params.confirmCallback()
				local win = xyd.WindowManager:get():getWindow("choose_partner_window")
				local selectPartnerID = (win:getSelected() or {})[1]

				if selectPartnerID then
					self.curPartnerID = selectPartnerID
				else
					self.curPartnerID = nil
				end

				self:updateContent()
			end

			xyd.WindowManager:get():openWindow("choose_partner_window", params)
		end)
	end

	UIEventListener.Get(self.btnSure).onClick = handler(self, function ()
		if self.curPartnerID and self.curPartnerID > 0 then
			local partner = xyd.models.slot:getPartner(self.curPartnerID)

			xyd.WindowManager.get():openWindow("potentiality_back_window", {
				freeActivity = true,
				partner = partner
			})
		else
			xyd.alertTips(__("ACTIVITY_FREE_REVERT_TEXT07"))
		end
	end)
end

function ActivityFreeRevert:initUIComponent()
	xyd.setUISpriteAsync(self.imgLogo, nil, "activity_free_reverge_logo_" .. xyd.Global.lang)

	self.labelSure.text = __("ACTIVITY_FREE_REVERT_TEXT05")
	self.partnerCard = PartnerCard.new(self.CardPos.gameObject)

	self.partnerCard:SetActive(false)
	self:initData()
	self:initSpine()
	self:updateContent()
end

function ActivityFreeRevert:onRollBack(event)
	local data = json.decode(event.data.detail)
	local items = data.items
	local ViwedPartnerID = nil
	local infos = {}

	for i = 1, #data.partners do
		local partner = xyd.models.slot:getPartner(data.partners[i].partner_id)
		local item = {
			item_num = 1,
			item_id = data.partners[i].table_id,
			awake = data.partners[i].awake,
			partner_id = data.partners[i].partner_id,
			star = partner:getStar()
		}

		if data.partners[i].is_vowed == 1 then
			ViwedPartnerID = data.partners[i].table_id
		end

		table.insert(infos, item)
	end

	local tmpData = {}
	local starData = {}

	for _, item in ipairs(infos) do
		local itemID = item.item_id
		local partner = xyd.models.slot:getPartner(item.partner_id)
		local star = partner:getStar()
		local key = tostring(itemID) .. "_" .. tostring(star)

		if tmpData[key] == nil then
			tmpData[key] = {
				num = 0,
				itemID = itemID,
				star = star
			}
		end

		tmpData[key].num = tmpData[key].num + 1
	end

	local datas = {}

	for k, v in pairs(tmpData) do
		table.insert(datas, {
			item_id = v.itemID,
			item_num = v.num,
			star = v.star
		})
	end

	if ViwedPartnerID ~= nil then
		for i = 1, #datas do
			if datas[i].item_id == ViwedPartnerID then
				if datas[i].item_num > 1 then
					datas[i].item_num = datas[i].item_num - 1

					table.insert(datas, {
						item_num = 1,
						is_vowed = 1,
						item_id = datas[i].item_id,
						star = datas[i].star
					})
				else
					datas[i].is_vowed = 1
				end
			end
		end
	end

	local new_items = {}

	for i = 1, #items do
		if tonumber(items[i].item_num) ~= 0 then
			local new_item = {
				item_id = items[i].item_id,
				item_num = items[i].item_num
			}

			table.insert(new_items, new_item)
		end
	end

	xyd.WindowManager.get():openWindow("alert_heros_window", {
		data = datas
	}, function ()
		xyd.alertItems(new_items, nil, __("GET_ITEMS"))
	end)
end

function ActivityFreeRevert:initData()
	self.partnerTableIDs = xyd.tables.miscTable:split2Cost("activity_free_revert_partner", "value", "|")
	self.curPartnerID = nil

	if not self.helpRecordArr then
		self.helpRecordArr = {}

		if self.activityData.detail and self.activityData.detail.partner_ids then
			local ids = self.activityData.detail.partner_ids

			for i = 1, #ids do
				self.helpRecordArr[tonumber(ids[i])] = 1
			end
		end
	end

	local partners = xyd.models.slot:getPartners()
	self.materialPartnerList = {}

	for i, partner in pairs(partners) do
		local tableID = partner:getTableID()

		for _, id in pairs(self.partnerTableIDs) do
			if id == tableID and partner:getStar() ~= 6 and partner:getLevel() > 1 and self.helpRecordArr[partner:getPartnerID()] then
				table.insert(self.materialPartnerList, partner)
			end
		end
	end

	table.sort(self.materialPartnerList, function (a, b)
		local tableIDa = a:getTableID()
		local tableIDb = b:getTableID()
		local starA = a:getStar()
		local starB = b:getStar()

		if starA ~= starB then
			return starB < starA
		elseif b:getLevel() ~= a:getLevel() then
			return b:getLevel() < a:getLevel()
		else
			return tableIDb < tableIDa
		end
	end)
end

function ActivityFreeRevert:initSpine()
	self.defaultEffect = xyd.Spine.new(self.rolePos.gameObject)

	self.defaultEffect:setInfo("fx_guanghuan", function ()
		self.defaultEffect:play("texiao01", 0)
	end)
end

function ActivityFreeRevert:updateContent()
	if self.curPartnerID and self.curPartnerID > 0 then
		local partner = xyd.models.slot:getPartner(self.curPartnerID)
		local partnerTableID = partner:getTableID()
		local modelID = xyd.tables.partnerTable:getModelID(partnerTableID)
		local name = xyd.tables.modelTable:getModelName(modelID)
		local scale = xyd.tables.modelTable:getScale(modelID)

		self.defaultEffect:SetActive(false)

		if self.curModelEffect then
			self.curModelEffect:SetActive(false)
		end

		if not self.effectList[partnerTableID] then
			self.effectList[partnerTableID] = xyd.Spine.new(self.rolePos.gameObject)

			self.effectList[partnerTableID]:setInfo(name, function ()
				self.effectList[partnerTableID]:SetLocalPosition(0, -98, 0)
				self.effectList[partnerTableID]:SetLocalScale(scale, scale, 1)
				self.effectList[partnerTableID]:play("idle", 0)
			end, true)
		else
			self.effectList[partnerTableID]:SetActive(true)
		end

		self.curModelEffect = self.effectList[partnerTableID]
		local info = {
			tableID = partnerTableID,
			star = partner:getStar(),
			lev = partner:getLevel(),
			grade = partner:getGrade()
		}

		self.partnerCard:setInfo(info)
		self.partnerCard:SetActive(true)

		return
	end

	self.partnerCard:SetActive(false)
	self.defaultEffect:SetActive(true)

	if self.curModelEffect then
		self.curModelEffect:SetActive(false)
	end
end

return ActivityFreeRevert
