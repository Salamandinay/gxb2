local CountDown = import("app.components.CountDown")
local ActivityContent = import(".ActivityContent")
local ShenXueGiftBag = class("ShenXueGiftBag", ActivityContent)
local ShenXueGiftBagItem = class("ShenXueGiftBagItem", import("app.components.CopyComponent"))

function ShenXueGiftBag:ctor(parentGO, params)
	ActivityContent.ctor(self, parentGO, params)

	self.currentState = xyd.Global.lang

	self:getUIComponent()
	self:euiComplete()
end

function ShenXueGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/shengxue_giftBag"
end

function ShenXueGiftBag:getUIComponent()
	local go = self.go
	self.imgBg = go:ComponentByName("imgBg", typeof(UISprite))

	xyd.setUISpriteAsync(self.imgBg, nil, "shenxue_giftbag_bg01")

	self.labelTime = go:ComponentByName("labelTime", typeof(UILabel))
	self.endLabel = go:ComponentByName("endLabel", typeof(UILabel))
	self.itemBg = go:ComponentByName("itemBg", typeof(UISprite))
	self.e_Scroller = go:ComponentByName("e:Scroller", typeof(UIScrollView))
	self.e_Scroller_uiPanel = self.e_Scroller:GetComponent(typeof(UIPanel))
	self.e_Scroller_uiPanel.depth = self.e_Scroller_uiPanel.depth + 1
	self.groupItems = self.e_Scroller:NodeByName("groupItems").gameObject
	self.groupItems_uiGrid = self.groupItems:GetComponent(typeof(UIGrid))
	self.textImg = go:ComponentByName("textImg", typeof(UISprite))

	xyd.setUISpriteAsync(self.textImg, nil, "shenxue_giftbag_text01_" .. tostring(xyd.Global.lang), nil, , true)

	self.labelText01 = go:ComponentByName("groupText_/labelText01", typeof(UILabel))
	self.shengxue_item = go:NodeByName("shengxue_item").gameObject
end

function ShenXueGiftBag:euiComplete()
	self:setText()
	self:setItems()
end

function ShenXueGiftBag:setText()
	if xyd.getServerTime() < self.activityData:getUpdateTime() then
		local countdown = CountDown.new(self.labelTime, {
			duration = self.activityData:getUpdateTime() - xyd.getServerTime()
		})
	else
		self.labelTime:SetActive(false)
		self.endLabel:SetActive(false)
	end

	self.endLabel.text = __("TEXT_END")
	self.labelText01.text = __("SHENXUE_GIFTBAG_TEXT01")

	if xyd.Global.lang == "de_de" then
		self.labelText01.width = 330
		self.labelText01.spacingY = 5
	end
end

function ShenXueGiftBag:setItems()
	local ids = xyd.tables.activityComposeTable:getIDs()

	NGUITools.DestroyChildren(self.groupItems.transform)

	for i in pairs(ids) do
		local id = ids[i]
		local params = {
			cur_times = self.activityData.detail.times[i],
			limit_times = xyd.tables.activityComposeTable:getLimit(id),
			star = xyd.tables.activityComposeTable:getStar(id),
			awards = xyd.tables.activityComposeTable:getAwards(id),
			type = xyd.tables.activityComposeTable:getType(id),
			get_way = xyd.tables.activityComposeTable:getJumpWay(id)
		}
		local tmp = NGUITools.AddChild(self.groupItems.gameObject, self.shengxue_item.gameObject)
		local item = ShenXueGiftBagItem.new(tmp, params)
	end

	self.shengxue_item:SetActive(false)
end

function ShenXueGiftBagItem:ctor(goItem, params)
	self.goItem_ = goItem
	local transGo = goItem.transform
	self.awards = {}
	self.cur_times = params.cur_times
	self.getWayId_ = params.get_way
	self.limit_times = params.limit_times
	self.star = params.star
	self.awards = params.awards
	self.type = params.type
	self.bgImg = transGo:ComponentByName("bgImg", typeof(UISprite))
	self.groupItems = transGo:NodeByName("groupItems").gameObject
	self.labelText01 = transGo:ComponentByName("labelText01", typeof(UILabel))
	self.labelText02 = transGo:ComponentByName("e:Group/labelText02", typeof(UILabel))
	self.labelText03 = transGo:ComponentByName("e:Group/labelText03", typeof(UILabel))

	self:createChildren()

	if self.getWayId_ and tonumber(self.getWayId_) > 0 then
		local function onClick()
			xyd.goWay(self.getWayId_, nil, , )
		end

		UIEventListener.Get(self.goItem_.gameObject).onClick = onClick
	end
end

function ShenXueGiftBagItem:createChildren()
	self:setText()
	self:setIcons()
end

function ShenXueGiftBagItem:setText()
	if self.type == 1 then
		self.labelText01.text = __("SHENXUE_GIFTBAG_WITH_STAR", self.star)
	else
		self.labelText01.text = __("AWAKE_GIFTBAG_WITH_STAR", self.star)
	end

	self.labelText02.text = __("SHENXUE_GIFTBAG_ITEM_TEXT01")
	self.labelText03.text = __("SHENXUE_GIFTBAG_TIMES", self.cur_times, self.limit_times)
end

function ShenXueGiftBagItem:setIcons()
	for i in pairs(self.awards) do
		local data = self.awards[i]

		if data[0] ~= xyd.ItemID.VIP_EXP then
			local item = {
				isAddUIDragScrollView = true,
				show_has_num = true,
				isShowSelected = false,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				scale = Vector3(0.75, 0.75, 1),
				uiRoot = self.groupItems.gameObject
			}
			local icon = xyd.getItemIcon(item)

			icon:labelNumScale(1.2)

			if self.cur_times == self.limit_times then
				icon:setChoose(true)
			end
		end
	end
end

return ShenXueGiftBag
