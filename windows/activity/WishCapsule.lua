local ActivityContent = import(".ActivityContent")
local WishCapsule = class("WishCapsule", ActivityContent)
local WishCapsuleItem = class("WishCapsuleItem", import("app.common.ui.FixedMultiWrapContentItem"))
local FixedMultiWrapContent = import("app.common.ui.FixedMultiWrapContent")
local ActivityWishGachaTable = xyd.tables.activityWishGachaTable
local WISH_SUMMON_TYPE = {
	xyd.SummonType.WISH_CRYSTAL,
	xyd.SummonType.WISH_CRYSTAL_TEN,
	xyd.SummonType.WISH_SCROLL,
	xyd.SummonType.WISH_SCROLL_TEN,
	xyd.SummonType.WISH_FREE
}

function WishCapsule:ctor(parentGO, params, parent)
	ActivityContent.ctor(self, parentGO, params, parent)
end

function WishCapsule:getPrefabPath()
	return "Prefabs/Windows/activity/wish_capsule"
end

function WishCapsule:initUI()
	self:getUIComponent()
	ActivityContent.initUI(self)

	self.mission_infos = xyd.models.activity:getActivity(xyd.ActivityID.WISH_CAPSULE).detail.mission_infos

	self:initUIComponent()
	self:setItem()
end

function WishCapsule:getUIComponent()
	local go = self.go
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))
	self.textLabel = go:ComponentByName("textGroup/textLabel", typeof(UILabel))
	self.mainGroup = go:NodeByName("mainGroup").gameObject
	self.psLabel = self.mainGroup:ComponentByName("psLabel", typeof(UILabel))
	self.partnerInfoBtn = self.mainGroup:NodeByName("partnerInfoBtn").gameObject
	self.bottomBg_ = self.mainGroup:ComponentByName("bottomBg_", typeof(UISprite))
	self.scrollView = self.mainGroup:ComponentByName("scroller", typeof(UIScrollView))
	self.WishItem = self.mainGroup:NodeByName("scroller/wish_capsule_item").gameObject
	self.itemGroup = self.mainGroup:NodeByName("scroller/itemGroup").gameObject
end

function WishCapsule:initUIComponent()
	xyd.setUISpriteAsync(self.textImg, nil, "wish_capsule_text01_" .. xyd.Global.lang, function ()
		self.textImg:MakePixelPerfect()
	end)

	self.textLabel.text = __("WISH_GACHA_TIPS_1")
	self.psLabel.text = __("WISH_GACHA_PS")
	self.partnerInfoBtn:ComponentByName("button_label", typeof(UILabel)).text = __("WISH_GACHA_GOTOGACHA")
	local wrapContent = self.itemGroup:GetComponent(typeof(MultiRowWrapContent))
	self.wrapContent = FixedMultiWrapContent.new(self.scrollView, wrapContent, self.WishItem, WishCapsuleItem, self)
end

function WishCapsule:onRegister()
	ActivityContent:onRegister()

	UIEventListener.Get(self.partnerInfoBtn).onClick = function ()
		if self.activityData:getEndTime() < xyd.getServerTime() then
			xyd.alertTips(__("ACTIVITY_END_YET"))
		else
			xyd.openWindow("summon_window")
		end
	end

	self:registerEvent(xyd.event.SUMMON_WISH, handler(self, self.updateItem))
end

function WishCapsule:updateItem(event)
	local summon_id = event.data.summon_id
	local num = #event.data.summon_result.partners

	for _, i in ipairs(WISH_SUMMON_TYPE) do
		if summon_id == i then
			local ids = ActivityWishGachaTable:getIDs()

			for i = 1, #ids do
				local id = ids[i]
				local limit = ActivityWishGachaTable:getLimit(id)
				self.mission_infos[id].value = self.mission_infos[id].value + num

				if limit <= self.mission_infos[id].value then
					if ActivityWishGachaTable:getType(id) == 1 then
						self.mission_infos[id].value = self.mission_infos[id].value - limit
					else
						self.mission_infos[id].value = limit
						self.mission_infos[id].is_completed = 1
					end
				end
			end

			self:setItem()

			break
		end
	end
end

function WishCapsule:setItem()
	local function sort_func(a, b)
		if a.isCompleted == b.isCompleted then
			return a.id < b.id
		elseif a.isCompleted then
			return false
		else
			return true
		end
	end

	self.items = {}
	local ids = ActivityWishGachaTable:getIDs()

	for i = 1, #ids do
		local id = ids[i]
		local is_completed = self.mission_infos[id] and self.mission_infos[id].is_completed == 1
		local point = self.mission_infos[id] and self.mission_infos[id].value or 0
		local item = {
			id = tonumber(id),
			isCompleted = is_completed,
			point = point,
			type = ActivityWishGachaTable:getType(id)
		}

		table.insert(self.items, item)
	end

	table.sort(self.items, sort_func)
	self.wrapContent:setInfos(self.items, {})
	self:updateRedMark()
end

function WishCapsule:resizeToParent()
	ActivityContent:resizeToParent()
	self.go:Y(-440)

	local partenHeight = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if partenHeight < 1000 then
		self.bottomBg_.height = 520

		self.mainGroup:Y(-160)
	end

	if xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.textLabel.fontSize = 20
	end
end

function WishCapsule:updateRedMark()
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.WISH_CAPSULE, function ()
		xyd.db.misc:setValue({
			value = "true",
			key = "wish_capsule_redmark"
		})
	end)
end

function WishCapsuleItem:ctor(go, parent)
	self.items = {}

	WishCapsuleItem.super.ctor(self, go, parent)
end

function WishCapsuleItem:initUI()
	local go = self.go
	self.itemGroup = go:NodeByName("itemGroup").gameObject
	self.labelText = go:ComponentByName("labelText", typeof(UILabel))
	self.progress = go:ComponentByName("progress", typeof(UISlider))
	self.progressLabel = go:ComponentByName("progress/labelDisplay", typeof(UILabel))
end

function WishCapsuleItem:updateInfo()
	self.id = tonumber(self.data.id)
	self.isCompleted = self.data.isCompleted
	self.point = self.data.point or 0
	self.type = self.data.type

	self:setText()
	self:setIcon()
	self:setProgress()
end

function WishCapsuleItem:setText()
	local limit = ActivityWishGachaTable:getLimit(self.id)

	if self.type == 1 then
		self.labelText.text = __("WISH_GACHA_TEXT_1", limit)
		self.isCompleted = false
	else
		self.labelText.text = __("WISH_GACHA_TEXT_2", limit)
	end
end

function WishCapsuleItem:setIcon()
	local awards = ActivityWishGachaTable:getAward(self.id)

	NGUITools.DestroyChildren(self.itemGroup.transform)

	for i = 1, #awards do
		local itemID = awards[i][1]
		local num = awards[i][2]

		if itemID == xyd.ItemID.UNKNOWN_GIRL then
			local partnerId = self.parent.activityData.detail and self.parent.activityData.detail.select_id

			if partnerId ~= 0 then
				itemID = xyd.tables.partnerTable:getPartnerShard(partnerId)
			end
		end

		local item = xyd.getItemIcon({
			show_has_num = true,
			labelNumScale = 1.2,
			scale = 0.7,
			uiRoot = self.itemGroup,
			itemID = itemID,
			num = num,
			wndType = xyd.ItemTipsWndType.ACTIVITY
		})

		if itemID == xyd.ItemID.UNKNOWN_GIRL then
			item:setStarsState(false)
		end

		xyd.setDragScrollView(item.go, self.scrollView)
		table.insert(self.items, item)

		if self.isCompleted then
			item:setChoose(true)
		end
	end

	self.itemGroup:GetComponent(typeof(UILayout)):Reposition()
end

function WishCapsuleItem:setProgress()
	local target = ActivityWishGachaTable:getLimit(self.id)
	local gotten = math.min(self.point, target)
	self.progress.value = gotten / target
	self.progressLabel.text = tostring(gotten) .. "/" .. tostring(target)
end

return WishCapsule
