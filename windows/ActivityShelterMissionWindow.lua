local BaseWindow = import(".BaseWindow")
local ActivityShelterMissionWindow = class("ActivityShelterMissionWindow", BaseWindow)
local ActivityShelterGiftBagItem = class("ActivityShelterGiftBagItem", import("app.components.BaseComponent"))
local cjson = require("cjson")

function ActivityShelterMissionWindow:ctor(name, params)
	ActivityShelterMissionWindow.super.ctor(self, name, params)

	self.table_id_ = params.id
	self.shelterGiftbagContent_ = params.parentContent
	self.heroIDList_ = xyd.tables.activityShelterGiftBagTable:getHeroCost(self.table_id_)
	self.itemIDList_ = xyd.tables.activityShelterGiftBagTable:getItemCost(self.table_id_)
	self.isEnough_ = false
	self.itemList_ = {}
end

function ActivityShelterMissionWindow:initWindow()
	ActivityShelterMissionWindow.super.initWindow(self)
	self:getComponent()
	self:register()

	self.lineGrouplabel_.text = __("MAIL_AWAED_TEXT")

	if xyd.Global.lang == "fr_fr" then
		self.lineGrouplabel_.width = 180

		self.window_:NodeByName("groupAction"):NodeByName("lineGroup/line1"):X(-90)
		self.window_:NodeByName("groupAction"):NodeByName("lineGroup/line2"):X(90)
	end

	self.labelText01_.text = __("SHELTER_GIFTBAG_INPUT")
	self.labelTitle_.text = __("SHELTER_GIFTBAG_TITLE")
	self.confirmBtnLabel_.text = __("CONFIRM")
	self.confirmBtnLabel_.effectStyle = UILabel.Effect.Outline
	self.confirmBtnLabel_.effectColor = Color.New2(1012112383)
	self.confirmBtnLabel_.color = Color.New2(4278124287.0)

	self:setPrize()
	self:setCost()
	self:refreshOptionalList()
	self:initItemStatus()
end

function ActivityShelterMissionWindow:getComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.closeBtn_ = goTrans:NodeByName("closeBtn").gameObject
	self.prizeItemGroup_ = goTrans:NodeByName("prizeItemGroup").gameObject
	self.costItemGroup_ = goTrans:NodeByName("costItemGroup").gameObject
	self.labelText01_ = goTrans:ComponentByName("labelText01", typeof(UILabel))
	self.lineGrouplabel_ = goTrans:ComponentByName("lineGroup/label", typeof(UILabel))
	self.labelTitle_ = goTrans:ComponentByName("labelTitle", typeof(UILabel))
	self.confirmBtn_ = goTrans:NodeByName("confirmBtn").gameObject
	self.confirmBtnLabel_ = goTrans:ComponentByName("confirmBtn/label", typeof(UILabel))
end

function ActivityShelterMissionWindow:register()
	self.eventProxy_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onActivityAward))

	UIEventListener.Get(self.closeBtn_).onClick = function ()
		xyd.WindowManager.get():closeWindow(self.name_)
	end

	UIEventListener.Get(self.confirmBtn_).onClick = function ()
		if not self.isEnough_ then
			xyd.showToast(__("SHELTER_NOT_ENOUGH_MATERIAL"))

			return
		end

		local material_ids = {}

		for i = 1, #self.itemList_ do
			for j = 1, #self.itemList_[i].materialList do
				table.insert(material_ids, tonumber(self.itemList_[i].materialList[j].partnerID))
			end
		end

		local data = cjson.encode({
			award_id = self.table_id_,
			material_ids = material_ids
		})

		xyd.alertYesNo(__("CONFIRM_CHANGE"), function (yes_no)
			if yes_no then
				local msg = messages_pb.get_activity_award_req()
				msg.activity_id = xyd.ActivityID.SHELTER_GIFTBAG
				msg.params = data

				xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
			end
		end)
	end
end

function ActivityShelterMissionWindow:onActivityAward(event)
	if event.data.activity_id ~= xyd.ActivityID.SHELTER_GIFTBAG then
		return
	end

	local realData = cjson.decode(event.data.detail)

	if self.table_id_ ~= realData.award_id then
		return
	end

	xyd.WindowManager.get():closeWindow(self.name_)
end

function ActivityShelterMissionWindow:initItemStatus()
	for i = 1, #self.itemList_ do
		self.itemList_[i]:setMask(true)
		self.itemList_[i]:setPlus(true)

		if self.itemList_[i]:getNeedNum() <= #self.itemList_[i].optionalList then
			self.itemList_[i]:setRedPoint(true)
		end
	end
end

function ActivityShelterMissionWindow:setPrize()
	local items = xyd.tables.activityShelterGiftBagTable:getAwards(self.table_id_)

	for i = 1, #items do
		local data = items[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local item = {
				labelNumScale = 1.2,
				hideText = true,
				itemID = data[1],
				num = data[2],
				uiRoot = self.prizeItemGroup_
			}
			local icon = xyd.getItemIcon(item)
		end
	end
end

function ActivityShelterMissionWindow:setCost()
	for i = 1, #self.heroIDList_ do
		local data = self.heroIDList_[i]
		local id = data[1]
		local num = data[2]
		local job = xyd.tables.partnerIDRuleTable:getJob(tostring(id))
		local group = xyd.tables.partnerIDRuleTable:getGroup(tostring(id))
		local star = xyd.tables.partnerIDRuleTable:getStar(tostring(id))

		if job == 0 then
			job = nil
		end

		if group == 0 then
			group = nil
		end

		if star == 0 then
			star = nil
		end

		local iconImg = xyd.tables.partnerIDRuleTable:getIcon(tostring(id))
		local params = {
			needRedPoint = false,
			noClick = true,
			itemID = data[1],
			job = job,
			group = group,
			star = star,
			missionID = self.table_id_
		}
		local allData = {
			data = params,
			refreshCallBack = function ()
				self:refreshOptionalList()
			end,
			needNum = num
		}
		local ic = ActivityShelterGiftBagItem.new(self.costItemGroup_)

		ic:setInfo(allData)
		table.insert(self.itemList_, ic)
		ic:setMask(true)
		ic:setIconSource(iconImg)
	end

	for i = 1, #self.itemIDList_ do
		local data = self.itemIDList_[i]
		local params = {
			hideText = true,
			scale = 0.8888888888888888,
			uiRoot = self.costItemGroup_,
			itemID = data[1],
			num = data[2]
		}
		local icon = xyd.getItemIcon(params)

		if xyd.isItemAbsence(data[1], data[2], false) then
			icon:setLabelNumRed()
		end
	end
end

function ActivityShelterMissionWindow:refreshOptionalList()
	self.isEnough_ = true

	for i = 1, #self.itemList_ do
		self.itemList_[i].optionalList = {}
		local data = self.heroIDList_[i]
		local job = xyd.tables.partnerIDRuleTable:getJob(data[1])
		local group = xyd.tables.partnerIDRuleTable:getGroup(data[1])
		local star = xyd.tables.partnerIDRuleTable:getStar(data[1])
		local tempList = xyd.models.slot:getListByGroupAndStar(group, star)

		for j = 1, #tempList do
			if self:judgeIsOptional(job, tempList[j], i) then
				table.insert(self.itemList_[i].optionalList, tempList[j])
			end
		end

		if self.itemList_[i] then
			local labelNum = self.itemList_[i]:getLabelNum()
			local needNum = self.itemList_[i]:getNeedNum()
			local item = self.itemList_[i]
			labelNum.text = #self.itemList_[i].materialList .. "/" .. needNum

			if needNum <= #self.itemList_[i].materialList then
				item:setMask(false)
				item:setRedPoint(false)
				item:setPlus(false)
			else
				self.isEnough_ = false

				item:setPlus(true)
				item:setMask(true)

				if needNum <= #self.itemList_[i].optionalList + #self.itemList_[i].materialList then
					item:setRedPoint(true)
				else
					item:setRedPoint(false)
				end
			end
		end
	end

	for i = 1, #self.itemIDList_ do
		local data = self.itemIDList_[i]
		local cur_num = xyd.models.backpack:getItemNumByID(data[1])

		if cur_num < data[2] then
			self.isEnough_ = false

			break
		end
	end
end

function ActivityShelterMissionWindow:judgeIsOptional(job, partner, id)
	for i = 1, #self.itemList_ do
		for j = 1, #self.itemList_[i].materialList do
			if partner:getPartnerID() == self.itemList_[i].materialList[j]:getPartnerID() then
				return false
			end
		end
	end

	if job == 0 then
		return true
	end

	if partner:getJob() == job then
		return true
	end

	return false
end

function ActivityShelterGiftBagItem:ctor(parentGo)
	self.optionalList = {}
	self.materialList = {}

	ActivityShelterGiftBagItem.super.ctor(self, parentGo)
end

function ActivityShelterGiftBagItem:getPrefabPath()
	return "Prefabs/Components/activity_shelter_giftBag_item"
end

function ActivityShelterGiftBagItem:initUI()
	ActivityShelterGiftBagItem.super.initUI(self)

	local goTrans = self.go.transform
	self.labelNum_ = goTrans:ComponentByName("labelNum", typeof(UILabel))
	self.iconContainer_ = goTrans:NodeByName("iconContainer0").gameObject
	self.redPointImg_ = goTrans:NodeByName("redPointImg0").gameObject
	self.plusImg_ = goTrans:NodeByName("plusImg").gameObject
	self.touchGroup = goTrans:NodeByName("touchGroup").gameObject
end

function ActivityShelterGiftBagItem:setInfo(params)
	self.data_ = params.data
	self.refreshCallBack_ = params.refreshCallBack
	self.needNum_ = params.needNum
	self.ic = import("app.components.HeroIcon").new(self.iconContainer_)

	self.ic:setInfo(self.data_)
	self.ic:setScale(0.8888888888888888)

	self.labelNum_.text = #self.materialList .. "/" .. self.needNum_
	UIEventListener.Get(self.touchGroup).onClick = handler(self, self.onClickIC)
end

function ActivityShelterGiftBagItem:onClickIC()
	self.tempMaterialList = {}
	self.tempOptionalList = {}

	for i = 1, #self.materialList do
		table.insert(self.tempMaterialList, self.materialList[i])
	end

	for i = 1, #self.optionalList do
		table.insert(self.tempOptionalList, self.optionalList[i])
	end

	local windowParams = {
		confirmCallback = function (optionalList, materialList)
			self:confirmCallback(optionalList, materialList)
		end,
		selectCallback = function ()
		end,
		optionalList = self.tempOptionalList,
		materialList = self.tempMaterialList,
		needNum = self.needNum_,
		missionID = self.data_.missionID,
		itemID = self.data_.itemID
	}

	xyd.WindowManager.get():openWindow("activity_shelter_mission_select_window", windowParams)
end

function ActivityShelterGiftBagItem:setMask(flag)
	if not self.ic or tolua.isnull(self.ic:getIconRoot()) then
		return
	end

	if flag then
		xyd.applyChildrenGrey(self.ic:getIconRoot())
	else
		xyd.applyChildrenOrigin(self.ic:getIconRoot())
	end
end

function ActivityShelterGiftBagItem:setRedPoint(flag)
	if self.redPointImg_ and not tolua.isnull(self.redPointImg_) then
		self.redPointImg_:SetActive(flag)
	end
end

function ActivityShelterGiftBagItem:setPlus(flag)
	self.plusImg_:SetActive(flag)
end

function ActivityShelterGiftBagItem:setIconSource(iconName)
	self.ic:setIconSource(iconName)
end

function ActivityShelterGiftBagItem:confirmCallback(optionalList, materialList)
	self.optionalList = {}
	self.materialList = {}

	for i = 1, #optionalList do
		table.insert(self.optionalList, optionalList[i])
	end

	for i = 1, #materialList do
		table.insert(self.materialList, materialList[i])
	end

	self.labelNum_.text = #self.materialList .. "/" .. self.needNum_

	if self.needNum_ <= #self.materialList then
		self:setMask(false)
		self:setRedPoint(false)
	else
		self:setMask(true)

		if self.needNum_ <= #self.optionalList + #self.materialList then
			self:setRedPoint(true)
		else
			self:setRedPoint(false)
		end
	end

	self:refreshCallBack_()
end

function ActivityShelterGiftBagItem:getLabelNum()
	return self.labelNum_
end

function ActivityShelterGiftBagItem:getNeedNum()
	return self.needNum_
end

return ActivityShelterMissionWindow
