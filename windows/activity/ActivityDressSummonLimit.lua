local ActivityDressSummonLimit = class("ActivityDressSummonLimit", import(".ActivityContent"))
local ValueGiftBagItem = class("ValueGiftBagItem", import("app.components.CopyComponent"))
local Dress = xyd.models.dress
local CommonTabBar = import("app.common.ui.CommonTabBar")

function ValueGiftBagItem:ctor(go, parent)
	self.go = go

	self:getUIComponent()
	self:setDragScrollView(parent:getScrollView())

	self.parent = parent
	self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher.inner(), self)

	self.eventProxy_:addEventListener("updateBt", handler(self, self.updateFreeBtn))
	self.eventProxy_:addEventListener("updateBtCrystal", handler(self, self.updateCrystalBtn))

	self.isFirstInit = true
end

function ValueGiftBagItem:getGiftBagID()
	return self.giftBagID
end

function ValueGiftBagItem:update(index, info)
	if not info then
		self.go:SetActive(false)

		return
	end

	self.info = info
	self.data = info.data

	if self.giftBagID ~= info.giftBagID then
		self.isFirstInit = true
	end

	self.giftBagID = info.giftBagID
	self.parentScroller = info.parentScroller

	self.go:SetActive(true)
	self:initUIComponent()
end

function ValueGiftBagItem:getUIComponent()
	local go = self.go
	self.itemBg = go:ComponentByName("itemBg", typeof(UITexture))
	self.groupIcon = go:NodeByName("groupIcon").gameObject
	self.groupIcon2 = go:NodeByName("groupIcon2").gameObject
	self.groupIcon_uigrid = self.groupIcon:GetComponent(typeof(UIGrid))
	self.groupIcon2_uigrid = self.groupIcon2:GetComponent(typeof(UIGrid))
	self.labelItemText01 = go:ComponentByName("labelItemText01", typeof(UILabel))
	self.labelItemText02 = go:ComponentByName("labelItemText02", typeof(UILabel))
	self.labelItemLimit = go:ComponentByName("labelItemLimit", typeof(UILabel))
	self.btnPurchase = go:NodeByName("btnPurchase").gameObject
	self.btnPurchase_label = go:ComponentByName("btnPurchase/button_label", typeof(UILabel))
	self.redMark = self.btnPurchase:ComponentByName("redMark", typeof(UISprite))
	self.prop_buy_con = self.btnPurchase:NodeByName("prop_buy_con").gameObject
	self.prop_buy_con_layout = self.btnPurchase:ComponentByName("prop_buy_con", typeof(UILayout))
	self.prop_icon = self.prop_buy_con:ComponentByName("prop_icon", typeof(UISprite))
	self.prop_text = self.prop_buy_con:ComponentByName("prop_text", typeof(UILabel))

	self.btnPurchase:GetComponent(typeof(UIWidget)).onDispose = function ()
		self.eventProxy_:removeAllEventListeners()
	end
end

function ValueGiftBagItem:initUIComponent()
	if self.isFirstInit then
		self:setIcon()
		self:setTextures()

		self.isFirstInit = false
	end

	self:setText()
	self:setBtn()

	self.groupIcon_uigrid.enabled = true
	self.groupIcon2_uigrid.enabled = true
end

function ValueGiftBagItem:setTextures()
	xyd.setUITextureAsync(self.itemBg, "Textures/activity_web/weekly_monthly_giftbag/weekly_monthly_giftbag_bg01", function ()
	end)
end

function ValueGiftBagItem:setText()
	if self.info.isFree ~= nil and self.info.isFree == true then
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", 1)
		self.labelItemText02.text = "+" .. 0
	elseif self.info.isCrystal ~= nil and self.info.isCrystal == true then
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", tonumber(self.info.limit) - tonumber(self.info.data))
		self.labelItemText02.text = "+" .. 0
	else
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) - self.data.buy_times)
		self.labelItemText02.text = "+" .. tostring(xyd.tables.giftBagTable:getVipExp(self.giftBagID))
	end

	self.labelItemText01.text = "VIP EXP"

	if self.info.isShowVipExp ~= nil and self.info.isShowVipExp == false then
		self.labelItemText01.text = ""
		self.labelItemText02.text = ""
	end
end

function ValueGiftBagItem:setIcon()
	local giftID = xyd.tables.giftBagTable:getGiftID(self.giftBagID)
	local awards = xyd.tables.giftTable:getAwards(giftID)

	if self.info.isFree ~= nil then
		awards = xyd.tables.giftTable:getAwards(self.giftBagID)
	end

	if self.info.isCrystal ~= nil then
		awards = self.info.award
	end

	NGUITools.DestroyChildren(self.groupIcon.transform)

	if not awards then
		return
	end

	if #awards >= 5 then
		self.groupIcon2:SetActive(true)
	else
		self.groupIcon2:SetActive(false)
	end

	local awardNewArr = {}

	for i = 1, #awards do
		local data = awards[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			table.insert(awardNewArr, data)
		end
	end

	for i = 1, #awardNewArr do
		local data = awardNewArr[i]

		if data[1] ~= xyd.ItemID.VIP_EXP then
			local scale = 0.7129629629629629
			local icaonGroup = self.groupIcon

			if #awardNewArr >= 5 and i >= 4 then
				scale = 0.6388888888888888
				icaonGroup = self.groupIcon2
			end

			local item = {
				show_has_num = true,
				labelNumScale = 1.2,
				itemID = data[1],
				num = data[2],
				wndType = xyd.ItemTipsWndType.ACTIVITY,
				uiRoot = icaonGroup,
				scale = Vector3(scale, scale, scale),
				dragScrollView = self.parentScroller
			}
			local icon = xyd.getItemIcon(item)
		end
	end
end

function ValueGiftBagItem:setBtn()
	self.redMark:SetActive(false)

	if self.info.isFree ~= nil then
		UIEventListener.Get(self.btnPurchase.gameObject).onClick = handler(self, function ()
			local msg = messages_pb:daily_giftbag_free_req()
			msg.activity_id = self.info.activityid

			xyd.Backend.get():request(xyd.mid.DAILY_GIFTBAG_FREE, msg)
		end)
		self.btnPurchase_label.text = __("FREE2")

		if self.info.isFreeCan == 0 then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)
			self.redMark:SetActive(true)
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
			self.redMark:SetActive(false)
		end
	end

	if self.info.isCrystal ~= nil then
		self.btnPurchase_label.text = ""
		UIEventListener.Get(self.btnPurchase.gameObject).onClick = handler(self, function ()
			if xyd.models.backpack:getItemNumByID(xyd.ItemID.CRYSTAL) < tonumber(self.info.cost[2]) then
				xyd.alertConfirm(__("CRYSTAL_NOT_ENOUGH"), function (yes)
					if yes then
						xyd.WindowManager.get():closeWindow("item_buy_window")
						xyd.WindowManager.get():openWindow("vip_window")
					end
				end, __("BUY"))

				return
			end

			xyd.alert(xyd.AlertType.YES_NO, __("CONFIRM_BUY"), function (yes)
				if yes then
					local msg = messages_pb:get_activity_award_req()
					msg.activity_id = tonumber(self.info.activityid)
					local data = {
						award_id = tonumber(self.info.giftBagID)
					}
					local cjson = require("cjson")
					msg.params = cjson.encode(data)

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_AWARD, msg)
				end
			end)
		end)

		self.prop_buy_con:SetActive(true)
		xyd.setUISpriteAsync(self.prop_icon, nil, "icon_" .. self.info.cost[1], nil, )

		self.prop_text.text = self.info.cost[2]

		self.prop_buy_con_layout:Reposition()

		if self.info.isCrystalCan == true then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
		end
	else
		self.prop_buy_con:SetActive(false)
	end

	if self.info.isFree == nil and self.info.isCrystal == nil then
		self.btnPurchase_label.text = tostring(xyd.tables.giftBagTextTable:getCurrency(self.giftBagID)) .. " " .. tostring(xyd.tables.giftBagTextTable:getCharge(self.giftBagID))

		xyd.setDarkenBtnBehavior(self.btnPurchase, self, function ()
			xyd.SdkManager.get():showPayment(self.giftBagID)
		end)

		if xyd.tables.giftBagTable:getBuyLimit(self.giftBagID) <= self.data.buy_times then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
		else
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = true

			xyd.applyChildrenOrigin(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(true)
		end
	end
end

function ValueGiftBagItem:updateFreeBtn()
	if self ~= nil and self.info ~= nil and self.info.isFree ~= nil and self.btnPurchase then
		self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

		xyd.applyChildrenGrey(self.btnPurchase.gameObject)
		self.labelItemLimit:SetActive(false)
		self.redMark:SetActive(false)
		self.parent:updateFreeList({
			giftbag_id = self.info.giftBagID
		})
	end
end

function ValueGiftBagItem:updateCrystalBtn()
	if self ~= nil and self.info ~= nil and self.info.isCrystal ~= nil and self.btnPurchase then
		self.info.data = tonumber(self.info.data) + 1
		self.labelItemLimit.text = __("BUY_GIFTBAG_LIMIT", tonumber(self.info.limit) - tonumber(self.info.data))
		local items = {}

		for i in pairs(self.info.award) do
			local dataArward = {
				item_id = self.info.award[i][1],
				item_num = self.info.award[i][2]
			}

			table.insert(items, dataArward)
		end

		xyd.itemFloat(items, nil, , self.info.parentScroller:GetComponent(typeof(UIPanel)).depth + 1)

		if tonumber(self.info.limit) <= tonumber(self.info.data) then
			self.btnPurchase:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = false

			xyd.applyChildrenGrey(self.btnPurchase.gameObject)
			self.labelItemLimit:SetActive(false)
			self.redMark:SetActive(false)
			self.parent:updateCrystalList({
				giftbag_id = self.info.giftBagID
			})
		end
	end
end

function ActivityDressSummonLimit:ctor(parentGO, params, parent)
	self.chooseIndex_ = 0
	self.useScroll_ = xyd.models.dress:isNewClipShaderOpen()

	ActivityDressSummonLimit.super.ctor(self, parentGO, params, parent)
	xyd.models.activity:updateRedMarkCount(xyd.ActivityID.DRESS_SUMMON_LIMIT, function ()
		self.activityData.isTouched = true
	end)
end

function ActivityDressSummonLimit:getPrefabPath()
	return "Prefabs/Windows/activity/dress_summon_limit_activity"
end

function ActivityDressSummonLimit:initUI()
	ActivityDressSummonLimit.super.initUI(self)
	self:getUIComponent()
	self:layout()
end

function ActivityDressSummonLimit:getUIComponent()
	local goTrans = self.go:NodeByName("activityGroup")
	self.logoImg_ = goTrans:ComponentByName("logoImg", typeof(UISprite))
	self.labelTips_ = goTrans:ComponentByName("logoScrollView/labelTips", typeof(UILabel))
	self.jumpBtn_ = goTrans:NodeByName("jumpBtn").gameObject
	self.jumpBtnLabel_ = goTrans:ComponentByName("jumpBtn/label", typeof(UILabel))
	self.contentPart_ = goTrans:NodeByName("contentPart")
	self.bgImg = self.contentPart_:NodeByName("bg").gameObject
	self.allCon_ = self.contentPart_:NodeByName("allCon").gameObject
	self.imgLine = self.allCon_:NodeByName("imgLine")
	self.itemCon_ = self.contentPart_:ComponentByName("allCon/itemCon", typeof(UILayout))
	self.suitLabel_ = self.contentPart_:ComponentByName("allCon/nameCon/suitLabel", typeof(UILabel))
	self.suitName = self.contentPart_:ComponentByName("allCon/nameCon/suitName", typeof(UILabel))
	self.posRoot = self.contentPart_:NodeByName("allCon/posRoot").gameObject
	self.pointGroup_ = self.posRoot:ComponentByName("pointGroup", typeof(UILayout))
	self.personScroll_ = self.posRoot:ComponentByName("personScroll", typeof(UIScrollView))
	self.grid_ = self.posRoot:ComponentByName("personScroll/grid", typeof(UIGrid))
	self.centerOn_ = self.posRoot:ComponentByName("personScroll/grid", typeof(UICenterOnChild))
	self.centerOn_.onCenter = handler(self, self.onCenter)
	self.personCon = self.posRoot:NodeByName("personCon").gameObject
	self.personEffectRoot = self.personCon:NodeByName("personEffect").gameObject
	self.dotIcon_ = self.posRoot:NodeByName("dotIcon").gameObject

	for i = 1, 5 do
		self["dressPos" .. i] = self.posRoot:NodeByName("dressPos" .. i)
		self["dressPosBorder" .. i] = self["dressPos" .. i]:ComponentByName("dressPosBorder", typeof(UISprite))
		self["dressPosBg" .. i] = self["dressPos" .. i]:ComponentByName("dressPosBg", typeof(UISprite))
		self["dressPosIcon" .. i] = self["dressPos" .. i]:ComponentByName("dressPosIcon", typeof(UIWidget))
		self["dressName" .. i] = self["dressPos" .. i]:ComponentByName("dressName", typeof(UILabel))
	end

	self.giftBagGroup_ = self.contentPart_:NodeByName("giftGroup").gameObject
	self.giftScrollView_ = self.giftBagGroup_:ComponentByName("scroller", typeof(UIScrollView))
	self.wrapContentCon = self.giftBagGroup_:ComponentByName("scroller/groupPackage", typeof(UIWrapContent))
	self.common_giftbag_item = self.giftBagGroup_:NodeByName("common_giftbag_item").gameObject
	self.wrapContent = import("app.common.ui.FixedWrapContent").new(self.giftScrollView_, self.wrapContentCon, self.common_giftbag_item, ValueGiftBagItem, self)

	self.wrapContent:setInfos({}, {})
	self.giftBagGroup_:SetActive(false)

	self.pageGroup = self.contentPart_:NodeByName("pageGroup").gameObject
end

function ActivityDressSummonLimit:updatePos()
	local realHeight = xyd.Global.getRealHeight()

	self.contentPart_:Y(-358 - 0.29213483146067415 * (realHeight - 1280))
	self.allCon_.transform:Y(-0.24719101123595505 * (realHeight - 1280))
	self.imgLine:Y(-393 - 0.23595505617977527 * (realHeight - 1280))
	self.itemCon_.transform:Y(-457 - 0.33707865168539325 * (realHeight - 1280))
end

function ActivityDressSummonLimit:layout()
	self:updatePos()
	self:initNav()

	self.suitLabel_.text = __("DRESS_CHECK_OFFICE_WINDOW_2")
	self.jumpBtnLabel_.text = __("ACTIVITY_DRESS_GACHA_AWARD_JUMP")
	self.labelTips_.text = __("DRESS_SUMMON_LIMIT_ACT_DESC")

	if xyd.Global.lang == "ko_kr" then
		self.labelTips_.fontSize = 19
	end

	xyd.setUISpriteAsync(self.logoImg_, nil, "dress_summon_limit_activity_logo_" .. xyd.Global.lang)

	self.suitList = xyd.tables.miscTable:split2num("dress_gacha_activity_show", "value", "|")

	self.dotIcon_:SetActive(false)

	if self.useScroll_ then
		self.personCon:SetActive(false)
	else
		self.personCon:SetActive(true)
		self.personScroll_.gameObject:SetActive(false)

		UIEventListener.Get(self.bgImg).onDragStart = function (go)
			self.delta_ = 0
		end

		UIEventListener.Get(self.bgImg).onDrag = function (go, delta)
			self.delta_ = self.delta_ + delta.x
		end

		UIEventListener.Get(self.bgImg).onDragEnd = function (go)
			if self.delta_ >= 150 then
				self:turnToIndex(self.chooseIndex_ - 1)
			elseif self.delta_ <= -150 then
				self:turnToIndex(self.chooseIndex_ + 1)
			end
		end
	end

	self.dotIconList_ = {}
	self.effectRootList_ = {}
	self.effectList_ = {}
	self.itemList_ = {}

	for i = 1, #self.suitList do
		local newDot = NGUITools.AddChild(self.pointGroup_.gameObject, self.dotIcon_)

		newDot:SetActive(true)

		local newDotSprit = newDot:GetComponent(typeof(UISprite))
		self.dotIconList_[i] = newDotSprit
		local newCon = NGUITools.AddChild(self.grid_.gameObject, self.personCon)

		newCon:SetActive(true)

		newCon.name = i
		self.effectRootList_[i] = newCon:NodeByName("personEffect").gameObject

		UIEventListener.Get(newDot).onClick = function ()
			if self.useScroll_ then
				self.centerOn_:CenterOn(newCon.transform)
			else
				self:turnToIndex(i)
			end
		end
	end

	if #self.suitList <= 1 then
		self.pointGroup_.gameObject:SetActive(false)
	end
end

function ActivityDressSummonLimit:initNav()
	local tableLabels = {
		"",
		""
	}
	self.tab_ = CommonTabBar.new(self.pageGroup, 2, function (index)
		self.curTabIndex = index

		if index == 2 then
			self.giftBagGroup_:SetActive(false)
			self.allCon_:SetActive(true)

			if not self.initTab2 then
				self.chooseIndex_ = 0

				self:turnToIndex(1)

				self.initTab2 = true
			end
		else
			self.giftBagGroup_:SetActive(true)
			self.allCon_:SetActive(false)
			self:setGiftList(self.hasInit)
		end
	end, nil, , 10)
end

function ActivityDressSummonLimit:updateDotState()
	for i = 1, #self.suitList do
		if i == self.chooseIndex_ then
			xyd.setUISpriteAsync(self.dotIconList_[i], nil, "market_dot_bg2")
		else
			xyd.setUISpriteAsync(self.dotIconList_[i], nil, "market_dot_bg1")
		end
	end
end

function ActivityDressSummonLimit:onRegister()
	UIEventListener.Get(self.jumpBtn_).onClick = function ()
		if not xyd.checkFunctionOpen(xyd.FunctionID.DRESS_BUY) then
			return
		end

		xyd.WindowManager.get():openWindow("dress_summon_window", {})
		xyd.WindowManager.get():closeWindow("activity_window")
	end

	self:registerEvent(xyd.event.RECHARGE, handler(self, self.onRecharge))
end

function ActivityDressSummonLimit:turnToIndex(index)
	print(self.chooseIndex_)
	print(index)

	if self.chooseIndex_ == index then
		return
	end

	if index <= 0 or index > #self.suitList then
		return
	end

	self.chooseIndex_ = index
	self.office_id = self.suitList[index]
	self.default_style_ids = xyd.tables.senpaiDressGroupTable:getStyleUnit(self.office_id)

	for i = 1, 5 do
		local text_index = i + 3
		self["dressName" .. i].text = __("PERSON_DRESS_MAIN_" .. text_index)
		local styleId = self.default_style_ids[i]

		if styleId ~= 0 then
			self:addItem(i, styleId)

			local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(styleId)
			local dress_item_name_id = xyd.tables.senpaiDressTable:getItems(dress_id)[1]
			self["dressName" .. i].text = xyd.tables.itemTable:getName(dress_item_name_id)
		else
			self["dressPosBg" .. i].gameObject:SetActive(true)
		end
	end

	self.suitName.text = xyd.tables.senpaiDressGroupTextTable:getName(self.office_id)

	if self.suitName.height > 24 then
		self.suitName.alignment = NGUIText.Alignment.Center
		self.suitName.overflowMethod = UILabel.Overflow.ShrinkContent
		self.suitName.height = 108
	end

	local suit_name_dress_id = xyd.tables.senpaiDressStyleTable:getDressId(self.default_style_ids[1])
	local suite_name_dress_item_id = xyd.tables.senpaiDressTable:getItems(suit_name_dress_id)[1]

	xyd.labelQulityColor(self.suitName, suite_name_dress_item_id)

	self.effect_arr = {}

	for i in pairs(self.default_style_ids) do
		if self.default_style_ids[i] ~= 0 then
			table.insert(self.effect_arr, self.default_style_ids[i])
		end
	end

	if self.useScroll_ then
		if not self.effectList_[self.chooseIndex_] and self.curTabIndex == 2 then
			self:waitForFrame(1, function ()
				self.effectList_[self.chooseIndex_] = import("app.components.SenpaiModel").new(self.effectRootList_[self.chooseIndex_])

				self.effectList_[self.chooseIndex_]:setModelInfo({
					isNewClipShader = true,
					ids = self.effect_arr
				})
			end)
		elseif self.effectList_[self.chooseIndex_] then
			self.effectList_[self.chooseIndex_]:setModelInfo({
				isNewClipShader = true,
				ids = self.effect_arr
			})
		end
	elseif not self.personEffect_ and self.curTabIndex == 2 then
		self:waitForFrame(1, function ()
			self.personEffect_ = import("app.components.SenpaiModel").new(self.personEffectRoot)

			self.personEffect_:setModelInfo({
				isNewClipShader = false,
				ids = self.effect_arr
			})
		end)
	elseif self.personEffect_ then
		self.personEffect_:setModelInfo({
			isNewClipShader = false,
			ids = self.effect_arr
		})
	end

	self:updateEquipItem()
	self:updateDotState()
end

function ActivityDressSummonLimit:addItem(i, styleId)
	local params = {
		uiRoot = self["dressPosIcon" .. i].gameObject,
		styleID = styleId
	}

	function params.callback()
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		local style_id = self["item_" .. i]:getStyleID()
		local dress_id = xyd.tables.senpaiDressStyleTable:getDressId(style_id)
		local has_ids = xyd.tables.senpaiDressTable:getStyles(dress_id)

		if #has_ids <= 1 then
			xyd.alertTips(__("DRESS_CHECK_OFFICE_WINDOW_3"))

			return
		end

		local all_dress_styles = xyd.tables.senpaiDressTable:getStyles(dress_id)
		local index = 1

		for i in pairs(all_dress_styles) do
			if all_dress_styles[i] == style_id then
				index = i

				break
			end
		end

		xyd.WindowManager.get():openWindow("leadskin_style_exchange_window", {
			isOnlyPreview = true,
			styleIndex = index,
			styleID = style_id,
			window = self
		})
	end

	if self["item_" .. i] then
		local item = self["item_" .. i]

		item:setInfo(params)
	else
		local item = xyd.getItemIcon(params, xyd.ItemIconType.DRESS_STYLE_ICON)
		local scale = 0.6893939393939394

		item:SetLocalScale(scale, scale, scale)

		self["item_" .. i] = item
	end
end

function ActivityDressSummonLimit:onCenter(target)
	if not target then
		return
	end

	local name = target.gameObject.name

	self:turnToIndex(tonumber(name))
end

function ActivityDressSummonLimit:updateStyleOnly(styleId)
	local pos = xyd.tables.senpaiDressStyleTable:getPos(styleId)

	self["item_" .. pos]:setInfo({
		styleID = styleId
	})

	for i in pairs(self.effect_arr) do
		local pos_check = xyd.tables.senpaiDressStyleTable:getPos(self.effect_arr[i])

		if pos_check == pos then
			self.effect_arr[i] = styleId

			break
		end
	end

	if self.useScroll_ then
		if not self.effectList_[self.chooseIndex_] then
			self.effectList_[self.chooseIndex_] = import("app.components.SenpaiModel").new(self.effectRootList_[self.chooseIndex_])
		end

		self.effectList_[self.chooseIndex_]:setModelInfo({
			isNewClipShader = true,
			ids = self.effect_arr
		})
	else
		if not self.personEffect_ then
			self.personEffect_ = import("app.components.SenpaiModel").new(self.personEffectRoot)
		end

		self.personEffect_:setModelInfo({
			isNewClipShader = false,
			ids = self.effect_arr
		})
	end
end

function ActivityDressSummonLimit:updateEquipItem()
	local equip_dress_ids = xyd.tables.senpaiDressGroupTable:getUnit(self.office_id)
	local has_item_ids = {}

	for i in pairs(equip_dress_ids) do
		local item_ids = xyd.tables.senpaiDressTable:getItems(equip_dress_ids[i])

		table.insert(has_item_ids, item_ids[1])
	end

	for i in pairs(has_item_ids) do
		local params = {
			itemID = has_item_ids[i],
			uiRoot = self.itemCon_.gameObject
		}

		if not self.itemList_[i] then
			self.itemList_[i] = xyd.getItemIcon(params)
		else
			self.itemList_[i]:setInfo(params)
		end
	end

	for index, item in ipairs(self.itemList_) do
		if index > #has_item_ids then
			item:SetActive(false)
		else
			item:SetActive(true)
		end
	end

	self.itemCon_:Reposition()
end

function ActivityDressSummonLimit:initGiftList()
end

function ActivityDressSummonLimit:getItemInfos()
	local cantBuy = {}
	local t = {}
	local datas = self.activityData.detail.charges

	for i = 1, #datas do
		local data = datas[i]
		local id = data.table_id
		local params = {
			giftBagID = id,
			data = data,
			parentScroller = self.giftScrollView_
		}

		if xyd.tables.giftBagTable:getBuyLimit(id) <= data.buy_times then
			table.insert(cantBuy, params)
		else
			table.insert(t, params)
		end
	end

	for i = 1, #cantBuy do
		local params = cantBuy[i]

		table.insert(t, params)
	end

	return t
end

function ActivityDressSummonLimit:setGiftList(keepPosition)
	local t = self:getItemInfos()
	self.firstItemArr = t
	self.hasInit = true

	self.wrapContent:setInfos(t, {
		keepPosition = keepPosition
	})
end

function ActivityDressSummonLimit:onRecharge(event)
	local giftBagID = event.data.giftbag_id

	if xyd.tables.giftBagTable:getActivityID(giftBagID) ~= self.id then
		return
	end

	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagID == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end

	self.wrapContent:setInfos(self.firstItemArr, {})
end

function ActivityDressSummonLimit:getScrollView()
	return self.giftScrollView_
end

function ActivityDressSummonLimit:updateFreeList(data)
	local giftBagID = data.giftbag_id
	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagID == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end
end

function ActivityDressSummonLimit:updateCrystalList(data)
	local giftBagID = data.giftbag_id
	local t = self:getItemInfos()
	local isGoOn = false

	for i in pairs(t) do
		for j in pairs(self.firstItemArr) do
			if giftBagID == t[i].giftBagID and giftBagID == self.firstItemArr[j].giftBagID then
				self.firstItemArr[j] = t[i]
				isGoOn = true

				break
			end
		end

		if isGoOn then
			break
		end
	end
end

return ActivityDressSummonLimit
