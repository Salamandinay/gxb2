local BaseWindow = import(".BaseWindow")
local ProphetWindow = class("ProphetWindow", BaseWindow)
local CommonTabBar = import("app.common.ui.CommonTabBar")
local WindowTop = import("app.components.WindowTop")
local BaseComponent = import("app.components.BaseComponent")
local ProphetSummon = class("ProphetSummon", BaseComponent)
local BubbleText = import("app.components.BubbleText")
local ProphetBubbleText = class("ProphetBubbleText", BubbleText)
local GambleRewardsWindow = import("app.windows.GambleRewardsWindow")
local ProphetReplace = class("ProphetReplace", import("app.components.BaseComponent"))
local PartnerCardLarge = import("app.components.PartnerCardLarge")
local PartnerChoose = class("PartnerChoose", import("app.components.BaseComponent"))
local ProphetAvatar = class("ProphetAvatar", import("app.components.BaseComponent"))

function ProphetWindow:ctor(name, params)
	BaseWindow.ctor(self, name, params)

	self.curChoose = 1

	if params and params.type then
		self.type = params.type
	end

	local needLoadRes = {}

	table.insert(needLoadRes, xyd.getTexturePath("prophet_bg03"))
	table.insert(needLoadRes, xyd.getSpritePath("prophet_idea"))
	table.insert(needLoadRes, xyd.EffectConstants.caopi)
	self:setResourcePaths(needLoadRes)
end

function ProphetWindow:getUIComponent()
	local winTrans = self.window_.transform
	self.groupMain = winTrans:NodeByName("groupMain").gameObject
	self.groupTabContainer = self.groupMain:NodeByName("groupTab").gameObject
	self.topGroup = winTrans:NodeByName("topGroup").gameObject
	self.groupSummon = self.groupMain:NodeByName("groupSummon").gameObject
	self.groupReplace = self.groupMain:NodeByName("groupReplace").gameObject
end

function ProphetWindow:initWindow()
	BaseWindow.initWindow(self)
	self:getUIComponent()
	self:setLayout()
	self:initTopGroup()
	self:register()
	self:waitForFrame(2, function ()
		if not self then
			return
		end

		self:startAnimation()
	end, nil)
end

function ProphetWindow:register()
	ProphetWindow.super.register(self)
	self.eventProxy_:addEventListener(xyd.event.SUMMON, handler(self, self.onSummon))
end

function ProphetWindow:initTopGroup()
	self.windowTop = WindowTop.new(self.topGroup, self.name_, 30)
	local items = {
		{
			hidePlus = true,
			id = xyd.ItemID.TREE
		},
		{
			hidePlus = true,
			id = xyd.ItemID.BRANCH
		}
	}

	self.windowTop:setItem(items)
end

function ProphetWindow:setLayout()
	if self.type == 1 or self.type == nil then
		self.summon = ProphetSummon.new(self.groupSummon)
		local widget = self.summon.go:GetComponent(typeof(UIWidget))

		widget:SetAnchor(self.groupSummon, 0, 0, 0, 0, 1, 0, 1, 0)

		widget.updateAnchors = UIRect.AnchorUpdate.OnEnable

		self.groupSummon:SetActive(false)
		self.groupSummon:SetActive(true)
		self.groupReplace:SetActive(false)
	else
		self.replace = ProphetReplace.new(self.groupReplace)

		self.groupReplace:SetActive(false)

		local widget = self.replace.go:GetComponent(typeof(UIWidget))

		widget:SetAnchor(self.groupReplace, 0, 0, 0, 0, 1, 0, 1, 0)

		widget.updateAnchors = UIRect.AnchorUpdate.OnUpdate

		self.groupReplace:SetActive(true)
		self.groupSummon:SetActive(false)
	end

	self.groupTab = CommonTabBar.new(self.groupTabContainer, 2, function (index)
		xyd.SoundManager.get():playSound(xyd.SoundID.TAB)

		if self.curChoose == index then
			return
		end

		self.curChoose = index

		self.groupSummon:SetActive(self.curChoose == 1)
		self.groupReplace:SetActive(self.curChoose == 2)

		if self.curChoose == 2 and not self.replace then
			self.replace = ProphetReplace.new(self.groupReplace)
			local widget = self.replace.go:GetComponent(typeof(UIWidget))

			widget:SetAnchor(self.groupReplace, 0, 0, 0, 0, 1, 0, 1, 0)

			widget.updateAnchors = UIRect.AnchorUpdate.OnEnable
		elseif self.curChoose == 1 and not self.summon then
			self.summon = ProphetSummon.new(self.groupSummon)
			local widget = self.summon.go:GetComponent(typeof(UIWidget))

			widget:SetAnchor(self.groupSummon, 0, 0, 0, 0, 1, 0, 1, 0)

			widget.updateAnchors = UIRect.AnchorUpdate.OnEnable
		end
	end)
	local texts = {
		__("PROPHET_MANU1"),
		__("PROPHET_MANU2")
	}
	self.groupTab.tabs[1].label.text = texts[1]
	self.groupTab.tabs[2].label.text = texts[2]
end

function ProphetWindow:setReplacePartner(partner)
	xyd.SoundManager.get():playSound(xyd.SoundID.REPLACE_PARTNER)
	self.replace:setReplacePartner(partner)
end

function ProphetWindow:onSummon(event)
	self.summon:onSummon(event)
end

function ProphetWindow:startAnimation()
	local sequene = self:getSequence()
	local transform = self.groupMain.transform

	transform:SetLocalPosition(-1000, transform.localPosition.y, 0)
	sequene:Append(transform:DOLocalMoveX(50, 0.3))
	sequene:Append(transform:DOLocalMoveX(0, 0.27))
	sequene:AppendCallback(function ()
		sequene:Kill(false)

		sequene = nil
	end)
end

function ProphetWindow:didClose(params)
	ProphetWindow.super.didClose(self, params)

	local wnd = xyd.WindowManager.get():getWindow("prophet_choose_partner_window")

	if wnd then
		wnd:close()
	end

	if self.summon then
		self.summon:onRemove()
	end

	if self.replace then
		self.replace:onRemove()
	end
end

function ProphetWindow:requestSummon()
	self.summon:requestSummon()
end

local EventProxy = import("app.common.EventProxy")

function ProphetSummon:ctor(parentGo)
	ProphetSummon.super.ctor(self, parentGo)

	self.lightAction = self:getSequence()
	self.eventProxy_ = EventProxy.new(xyd.EventDispatcher:inner(), self)
	xyd.models.prophet.currentGroup = 1

	self:setDisplayGirl()
end

function ProphetSummon:getPrefabPath()
	return "Prefabs/Components/prophet_summon"
end

function ProphetSummon:initUI()
	ProphetSummon.super.initUI(self)

	local go = self.go
	self.groupMain_ = go:NodeByName("groupMain_").gameObject
	self.imgBG = self.groupMain_:NodeByName("imgBG").gameObject
	self.imgBGTexture = self.groupMain_:ComponentByName("imgBGTexture", typeof(UITexture))
	self.topGroup = self.groupMain_:NodeByName("topGroup").gameObject
	self.summonHelpBtn = self.topGroup:NodeByName("summonHelpBtn").gameObject
	self.summonRateBtn = self.topGroup:NodeByName("summonRateBtn").gameObject
	self.lightImg = self.topGroup:NodeByName("lightImg").gameObject
	self.groupModel = self.groupMain_:NodeByName("groupModel").gameObject
	local bottomGroup = self.groupMain_:NodeByName("bottomGroup").gameObject
	self.deskImg = bottomGroup:ComponentByName("deskImage", typeof(UITexture))
	self.btnSummon = bottomGroup:NodeByName("btnSummon").gameObject
	self.btnSummonEffectGroup = self.btnSummon:NodeByName("btnSummonEffectGroup").gameObject
	self.labelText01 = self.btnSummon:ComponentByName("labelText01", typeof(UILabel))
	local costGroup = bottomGroup:NodeByName("costGroup").gameObject
	self.labelX1 = costGroup:ComponentByName("labelX1", typeof(UILabel))
	self.group10TimesClick = bottomGroup:NodeByName("group10TimesClick").gameObject
	self.btn10Times = self.group10TimesClick:NodeByName("btn10Times").gameObject
	self.label10Times = self.group10TimesClick:ComponentByName("label10Times", typeof(UILabel))
	self.imgFile = bottomGroup:ComponentByName("imgFile", typeof(UISprite))
	self.imgFileEffect = self.imgFile:NodeByName("fileEffect").gameObject
	self.summonEffectGroup = bottomGroup:NodeByName("summonEffectGroup").gameObject
	self.groupBubble = self.groupMain_:NodeByName("groupBubble").gameObject
	local summonGroup = self.groupMain_:NodeByName("summonGroup").gameObject

	for i = 1, 5 do
		local summon = summonGroup:NodeByName("groupSummon" .. i).gameObject
		self["groupSummon" .. i] = summon
		self["labelGroupText" .. i] = summon:ComponentByName("labelGroupText" .. i, typeof(UILabel))
		self["rectMask" .. i] = summon:NodeByName("rectMask" .. i).gameObject
	end

	self:initUISprite()
	self:setResource()
	self:register()
	self:setLayout()
end

function ProphetSummon:initUISprite()
	for i = 1, 4 do
		self["groupSummon_img" .. i] = self["groupSummon" .. i]:ComponentByName("e:Image", typeof(UISprite))

		xyd.setUISpriteAsync(self["groupSummon_img" .. i], nil, "prophet_icon10")
	end

	self.groupSummon5_img_mask = self.groupSummon5:ComponentByName("img_mask", typeof(UISprite))

	xyd.setUISpriteAsync(self.groupSummon5_img_mask, nil, "prophet_icon10")
	xyd.setUISpriteAsync(self.imgFile, nil, "prophet_icon_group1")

	self.costGroup_Image_icon = self.groupMain_:ComponentByName("bottomGroup/costGroup/Image_icon", typeof(UISprite))

	xyd.setUISpriteAsync(self.costGroup_Image_icon, nil, "icon_20")

	self.btnSummon_uiSprite = self.btnSummon:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.btnSummon_uiSprite, nil, "prophet_icon06")

	self.lightImg_uiSprite = self.lightImg:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.lightImg_uiSprite, nil, "prophet_idea")

	self.imgBG_uiSprite = self.imgBG:GetComponent(typeof(UISprite))

	xyd.setUISpriteAsync(self.imgBG_uiSprite, nil, "prophet_smallbg01")
end

function ProphetSummon:setResource()
	self.effectSummon = xyd.Spine.new(self.imgFileEffect)

	self.effectSummon:setInfo("fx_yinzhang", function ()
		self.effectSummon:SetLocalPosition(20, 0, 0)
		self.effectSummon:SetLocalScale(1, 1, 1)
		self.effectSummon:setRenderTarget(self.imgFileEffect:GetComponent(typeof(UIWidget)), 1)
		self.effectSummon:SetActive(false)
	end)

	self.effectRefresh = xyd.Spine.new(self.imgFileEffect)

	self.effectRefresh:setInfo("fx_shuji", function ()
		self.effectRefresh:SetLocalPosition(0, 0, 0)
		self.effectRefresh:SetLocalScale(1, 1, 1)
		self.effectRefresh:setRenderTarget(self.imgFileEffect:GetComponent(typeof(UIWidget)), 2)
		self.effectRefresh:SetActive(false)
	end)
end

function ProphetSummon:register()
	for i = 1, 5 do
		UIEventListener.Get(self["groupSummon" .. i]).onClick = function ()
			self:onGroupSelect(i)
		end
	end

	UIEventListener.Get(self.btnSummon).onClick = handler(self, self.requestSummon)
	UIEventListener.Get(self.btn10Times).onClick = handler(self, self.set10Times)
	UIEventListener.Get(self.summonHelpBtn).onClick = handler(self, self.helpRuleWindow)
	UIEventListener.Get(self.summonRateBtn).onClick = handler(self, self.helpRateWindow)
end

function ProphetSummon:setLayout()
	for i = 1, 5 do
		self["labelGroupText" .. i].text = __("GROUP_" .. tostring(i))
	end

	self.labelGroupText5.text = __("GROUP_5_6")

	if xyd.Global.lang == "fr_fr" then
		self.labelGroupText5.fontSize = 26
	end

	self.labelGroupText5:SetActive(false)
	self.rectMask5:SetActive(false)
	xyd.setUITextureAsync(self.deskImg, "Textures/scenes_web/prophet_icon07")
	xyd.setUITextureAsync(self.imgBGTexture, "Textures/scenes_web/prophet_bg03")

	self.labelText01.text = __("PROPHET_TEXT01")

	self:setBtn10TimesState(xyd.models.prophet.is10Times and "down" or "up")

	self.labelX1.text = xyd.models.prophet.is10Times and "X10" or "X 1"
	self.label10Times.text = __("PROPHET_SUMMON_TEN_TIMES")

	self.group10TimesClick:SetActive(true)

	if xyd.Global.lang == "de_de" then
		for i = 1, 5 do
			self["labelGroupText" .. i].fontSize = 24
		end
	end
end

function ProphetSummon:setBtn10TimesState(state)
	local sprite = self.btn10Times:GetComponent(typeof(UISprite))

	if state == "down" then
		sprite.spriteName = "setting_up_pick"
	elseif state == "up" then
		sprite.spriteName = "setting_up_unpick"
	end
end

function ProphetSummon:onGroupSelect(group)
	xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

	if xyd.models.prophet.currentGroup == group then
		return
	end

	if self.inSummonAnim then
		return
	end

	local sequene1 = self:getSequence()
	local cGroup = xyd.models.prophet.currentGroup
	local currentGroup = self["groupSummon" .. xyd.models.prophet.currentGroup]

	sequene1:Append(currentGroup.transform:DOLocalMoveX(163, 0.6))
	sequene1:AppendCallback(function ()
		if cGroup == 5 then
			self.labelGroupText5:SetActive(false)
		end

		sequene1:Kill(false)

		sequene1 = nil
	end)

	xyd.models.prophet.currentGroup = group
	self.imgFile.spriteName = "prophet_icon_group" .. tostring(xyd.models.prophet.currentGroup)

	if group == 5 then
		self.labelGroupText5:SetActive(true)
	end

	local sequene2 = self:getSequence()
	currentGroup = self["groupSummon" .. xyd.models.prophet.currentGroup]

	sequene2:Append(currentGroup.transform:DOLocalMoveX(0, 0.6))
	sequene2:AppendCallback(function ()
		sequene2:Kill(false)

		sequene2 = nil
	end)

	if not self.effectRefresh or not self.effectRefresh:isValid() then
		return
	end

	local name = "texiao0" .. tostring(xyd.models.prophet.currentGroup)

	self.effectRefresh:SetActive(true)
	self.effectRefresh:play(name, 1, 1, function ()
		self.effectRefresh:SetActive(false)
	end)
end

function ProphetSummon:requestSummon()
	if self.inSummonAnim then
		return
	end

	local costs = xyd.tables.miscTable:split2Cost("prophet_cost", "value", "|#")
	local cost = costs[xyd.models.prophet.is10Times and 2 or 1]

	if xyd.isItemAbsence(cost[1], cost[2]) then
		return
	end

	xyd.models.prophet:reqProphetSummon()

	self.inSummonAnim = true

	self:setTouchClose()
end

function ProphetSummon:onSummon(event)
	local items = event.data.summon_result.items
	local partners = event.data.summon_result.partners
	local award = event.data.award
	local params = {}

	if #items > 0 then
		for i in pairs(items) do
			if items[i].item_id and items[i].item_id ~= 0 then
				table.insert(params, {
					item_num = items[i].item_num,
					item_id = items[i].item_id
				})
			end
		end
	end

	if #partners > 0 then
		for i in pairs(partners) do
			table.insert(params, {
				item_num = 1,
				item_id = partners[i].table_id
			})
		end
	end

	if award and award.item_num then
		table.insert(params, {
			item_num = award.item_num,
			item_id = award.item_id
		})
	end

	for i = 1, #params do
		local itemID = params[i].item_id
		local type_ = xyd.tables.itemTable:getType(itemID)

		if tonumber(type_) == xyd.ItemType.HERO_DEBRIS and tonumber(params[i].item_num) == 50 then
			params[i].cool = 1
		else
			params[i].cool = 0
		end
	end

	if not self.effectSummon or not self.effectSummon:isValid() then
		self.inSummonAnim = false

		if self.touchImage then
			self.touchImage:SetActive(false)
		end

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			data = params,
			wnd_type = GambleRewardsWindow.WindowType.PROPHET
		})

		return
	end

	self.effectSummon:SetActive(true)
	xyd.SoundManager.get():playSound(xyd.SoundID.PROPHET_SUMMON)
	self.effectSummon:play("texiao", 1)

	if self.effectSummon then
		self:waitForTime(0.57, function ()
			if not self then
				return
			end

			self.effectSummon:SetActive(false)

			if self.effectRefresh then
				if self.effectRefresh then
					local name = "texiao0" .. tostring(xyd.models.prophet.currentGroup)

					self.effectRefresh:SetActive(true)
					self.effectRefresh:play(name, 1, 1, function ()
						self.effectRefresh:SetActive(false)
					end)
					self:waitForTime(0.5, function ()
						if not self then
							return
						end

						self.inSummonAnim = false

						if self.touchImage then
							self.touchImage:SetActive(false)
						end

						xyd.WindowManager.get():openWindow("gamble_rewards_window", {
							data = params,
							wnd_type = GambleRewardsWindow.WindowType.PROPHET
						})
					end, nil)
				else
					self.inSummonAnim = false

					if self.touchImage then
						self.touchImage:SetActive(false)
					end

					xyd.WindowManager.get():openWindow("gamble_rewards_window", {
						data = params,
						wnd_type = GambleRewardsWindow.WindowType.PROPHET
					})
				end
			end
		end, nil)
	else
		self.effectSummon:SetActive(false)

		self.inSummonAnim = false

		xyd.WindowManager.get():openWindow("gamble_rewards_window", {
			data = params,
			wnd_type = GambleRewardsWindow.WindowType.PROPHET
		})
	end

	if self.girlsModel and not self.girlsModel:isPlayChooseSound() then
		self.girlsModel:playChooseAction()
	end
end

function ProphetSummon:helpRuleWindow()
	local params = {
		key = "PROPHET_SUMMON_RULE_HELP"
	}

	xyd.WindowManager.get():openWindow("help_window", params)
end

function ProphetSummon:helpRateWindow()
	xyd.WindowManager.get():openWindow("prophet_drop_probability_window")
end

function ProphetSummon:setDisplayGirl()
	local function clickCheck()
		print("self.inSummonAnim", self.inSummonAnim)

		if self.inSummonAnim then
			return false
		else
			return true
		end
	end

	self.girlsModel = import("app.components.GirlsModel").new(self.groupModel)

	self.girlsModel:setModelInfo({
		id = ProphetSummon.GirlModelID,
		clickCheck = clickCheck
	}, function ()
		local bubble = ProphetBubbleText.new(self.groupBubble, {
			attach_callback = function ()
				self:playLightUp()
			end,
			disappear_callback = function ()
				self:playLightDisappear()
			end
		})

		self.girlsModel:setBubble(bubble)
	end)
end

function ProphetSummon:setEnable(bool)
	if bool then
		-- Nothing
	end
end

function ProphetSummon:set10Times()
	xyd.models.prophet.is10Times = not xyd.models.prophet.is10Times

	self:setBtn10TimesState(xyd.models.prophet.is10Times and "down" or "up")

	self.labelX1.text = xyd.models.prophet.is10Times and "X10" or "X 1"
end

function ProphetSummon:playLightUp()
	if self.lightAction then
		self.lightAction:Kill(false)

		self.lightAction = nil
		self.lightAction = self:getSequence()
	end

	local transform = self.lightImg.transform

	transform:SetLocalScale(0, 0, 0)
	self.lightImg:SetActive(true)
	self.lightAction:Append(transform:DOScale(Vector3(1.1, 1.1, 1), 0.3))
	self.lightAction:Append(transform:DOScale(Vector3(1, 1, 1), 0.16))
end

function ProphetSummon:playLightDisappear()
	if self.lightAction then
		self.lightAction:Kill(false)

		self.lightAction = nil
		self.lightAction = self:getSequence()
	end

	self:waitForTime(0.3, function ()
		if not self then
			return
		end

		if self.lightImg and not tolua.isnull(self.lightImg) then
			self.lightImg:SetActive(false)
		end
	end, nil)
end

function ProphetSummon:onRemove()
	if self.eventProxy_ ~= nil then
		self.eventProxy_:removeAllEventListeners()

		self.eventProxy_ = nil
	end

	if self.lightAction then
		self.lightAction:Kill(false)

		self.lightImg = nil
	end

	if self.touchImage then
		NGUITools.DestroyChildren(self.touchImage.transform)

		self.touchImage = nil
	end
end

function ProphetSummon:setTouchClose()
end

ProphetSummon.GirlModelID = 5

function ProphetBubbleText:ctor(parentGo, params)
	BubbleText.ctor(self, parentGo, params)

	self.attach_callback = params.attach_callback
	self.disappear_callback = params.disappear_callback
end

function ProphetBubbleText:playDialogAction(text)
	BubbleText.playDialogAction(self, text)

	if self.attach_callback then
		self:attach_callback()
	end
end

function ProphetBubbleText:playDisappear()
	BubbleText.playDisappear(self)

	if self.disappear_callback then
		self:disappear_callback()
	end
end

function ProphetReplace:ctor(parentGo)
	self.eventProxy_ = xyd.EventProxy.new(xyd.EventDispatcher:inner(), self)
	self.wnd = xyd.WindowManager.get():getWindow("prophet_window")

	ProphetReplace.super.ctor(self, parentGo)
end

function ProphetReplace:getPrefabPath()
	return "Prefabs/Components/prophet_replace"
end

function ProphetReplace:initUI()
	self.groupReplace = self.go:NodeByName("groupReplace").gameObject
	self.imgBG = self.groupReplace:NodeByName("imgBG").gameObject
	self.imgBGTexture = self.groupReplace:ComponentByName("imgBGTexture", typeof(UITexture))
	self.group1 = self.groupReplace:NodeByName("group1").gameObject
	self.cardBorder1 = self.group1:NodeByName("cardBorder1").gameObject
	local partnerCard1Contaner = self.cardBorder1:NodeByName("partnerCard1").gameObject
	self.partnerCard1 = PartnerCardLarge.new(partnerCard1Contaner)
	self.groupEffect4_1 = self.cardBorder1:NodeByName("groupEffect4_1").gameObject
	self.rightGroup1 = self.group1:NodeByName("rightGroup1").gameObject
	self.label_name1 = self.rightGroup1:ComponentByName("label_name1", typeof(UILabel))
	self.groupEffect5 = self.rightGroup1:NodeByName("groupEffect5").gameObject
	self.groupEffect2_1 = self.rightGroup1:NodeByName("groupEffect2_1").gameObject
	self.groupModel1 = self.rightGroup1:NodeByName("groupModel1").gameObject
	self.groupEffect3_1 = self.rightGroup1:NodeByName("groupEffect3_1").gameObject
	self.loadingCircleImg1 = self.rightGroup1:NodeByName("loadingCircleImg1").gameObject
	self.btn_detail = self.group1:NodeByName("btn_detail").gameObject
	self.group2 = self.groupReplace:NodeByName("group2").gameObject
	self.cardBorder2 = self.group2:NodeByName("cardBorder2").gameObject
	local partnerCard2Container = self.cardBorder2:NodeByName("partnerCard2").gameObject
	self.partnerCard2 = PartnerCardLarge.new(partnerCard2Container)
	self.groupEffect4_2 = self.cardBorder2:NodeByName("groupEffect4_2").gameObject
	self.tipGroup = self.group2:NodeByName("tipGroup").gameObject
	self.label_text01 = self.tipGroup:ComponentByName("label_text01", typeof(UILabel))
	self.rightGroup2 = self.group2:NodeByName("rightGroup2").gameObject
	self.groupEffect1 = self.rightGroup2:NodeByName("groupEffect1").gameObject
	self.groupEffect2_2 = self.rightGroup2:NodeByName("groupEffect2_2").gameObject
	self.groupModel2 = self.rightGroup2:NodeByName("groupModel2").gameObject
	self.groupEffect3_2 = self.rightGroup2:NodeByName("groupEffect3_2").gameObject
	self.loadingCircleImg2 = self.rightGroup2:NodeByName("loadingCircleImg2").gameObject
	self.touchGroup = self.groupReplace:NodeByName("touchGroup").gameObject
	self.touchGroup2 = self.groupReplace:NodeByName("touchGroup2").gameObject
	self.bottom = self.groupReplace:NodeByName("bottom").gameObject
	self.btnCancel = self.bottom:NodeByName("btnCancel").gameObject
	self.btnCancelLabel = self.btnCancel:ComponentByName("button_label", typeof(UILabel))
	self.btnSave = self.bottom:NodeByName("btnSave").gameObject
	self.btnSaveLabel = self.btnSave:ComponentByName("button_label", typeof(UILabel))
	self.btnReplace = self.bottom:NodeByName("btnReplace").gameObject
	local btnContainer = self.btnReplace:NodeByName("container").gameObject
	self.btnReplaceTable = btnContainer:GetComponent(typeof(UITable))
	self.btnReplaceLabel = btnContainer:ComponentByName("button_label", typeof(UILabel))
	self.btnReplaceCostLabel = btnContainer:ComponentByName("cost/costLabel", typeof(UILabel))
	self.btnReplaceCostImg = btnContainer:ComponentByName("cost/costImg", typeof(UISprite))
	self.btn_help = self.groupReplace:NodeByName("top/btn_help").gameObject

	xyd.setUISpriteAsync(self.btnReplaceCostImg, nil, "icon_19")

	self.group2_img = self.groupReplace:ComponentByName("group2/e:Image", typeof(UISprite))

	xyd.setUISpriteAsync(self.group2_img, nil, "prophet_bg02")

	self.group1_img = self.groupReplace:ComponentByName("group1/e:Image", typeof(UISprite))

	xyd.setUISpriteAsync(self.group1_img, nil, "prophet_bg02")

	self.imgBG_img = self.groupReplace:ComponentByName("imgBG", typeof(UISprite))

	xyd.setUISpriteAsync(self.imgBG_img, nil, "prophet_smallbg01")
	self:setChildren()
end

function ProphetReplace:setChildren()
	self:setText()
	self:setLayout()

	local partnerID = xyd.models.slot:getReplacePartner()
	local replaceID = xyd.models.slot:getReplaceTableID()

	if partnerID and replaceID and xyd.models.slot:getPartner(partnerID) then
		self.btnReplace:SetActive(false)
		self.btnSave:SetActive(false)
		self.btnCancel:SetActive(false)

		local partner = xyd.models.slot:getPartner(partnerID)
		local data = xyd.tables.partnerReplaceTable:getCost(partner:getTableID())
		self.btnReplaceCostImg.spriteName = xyd.tables.itemTable:getIcon(data[1])
		self.btnReplaceCostLabel.text = data[2]

		self.btnReplaceTable:Reposition()
	end

	self.partnerCard1:setNameVisible(false)
	self.partnerCard2:setNameVisible(false)
	self:setResource()
	self:registerEvent()
end

function ProphetReplace:registerEvent()
	UIEventListener.Get(self.btnReplace).onClick = handler(self, self.replaceRequest)
	UIEventListener.Get(self.btnCancel).onClick = handler(self, self.cancelRequest)
	UIEventListener.Get(self.btnSave).onClick = handler(self, self.saveRequest)
	UIEventListener.Get(self.touchGroup).onClick = handler(self, self.setPartnerChoose)

	UIEventListener.Get(self.touchGroup2).onClick = function ()
		if self.partner then
			xyd.openWindow("replace_probability_window", {
				partner = self.partner
			})
		end
	end

	UIEventListener.Get(self.cardBorder2).onClick = handler(self, self.setPartnerChoose)
	UIEventListener.Get(self.btn_detail).onClick = handler(self, self.showPartnerInfo)

	UIEventListener.Get(self.btn_help).onClick = function ()
		local params = {
			key = "PROPHET_REPLACE_HELP"
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end

	self.eventProxy_:addEventListener(xyd.event.PROPHET_REPLACE, handler(self, self.onReplace))
	self.eventProxy_:addEventListener(xyd.event.PROPHET_REPLACE_SAVE, handler(self, self.onReplaceSave))
end

function ProphetReplace:cancelRequest()
	if not self.partner then
		return
	end

	local msg = messages_pb:prophet_replace_save_req()
	msg.partner_id = self.partner:getPartnerID()
	msg.is_save = 0

	xyd.Backend.get():request(xyd.mid.PROPHET_REPLACE_SAVE, msg)
end

function ProphetReplace:replaceRequest()
	if not self.partner then
		return
	end

	local cost = xyd.tables.partnerReplaceTable:getCost(self.partner:getTableID())

	if xyd.models.backpack:getItemNumByID(xyd.ItemID.BRANCH) < cost[2] then
		xyd.alert(xyd.AlertType.TIPS, __("NOT_ENOUGH", xyd.tables.itemTable:getName(xyd.ItemID.BRANCH)))
		xyd.SoundManager.get():playSound(xyd.SoundID.BUTTON)

		return
	end

	if self.partner:isVowed() then
		xyd.alert(xyd.AlertType.YES_NO, __("VOW_SWAP_TIPS"), handler(self, function (self, yes_no)
			if yes_no then
				local msg = messages_pb:prophet_replace_req()
				msg.partner_id = self.partner:getPartnerID()

				xyd.Backend.get():request(xyd.mid.PROPHET_REPLACE, msg)
				self.btnReplace:SetActive(false)
				xyd.SoundManager.get():playSound(xyd.SoundID.REPLACE_SUCCESS)
			end
		end))

		return
	end

	local msg = messages_pb:prophet_replace_req()
	msg.partner_id = self.partner:getPartnerID()

	xyd.Backend:get():request(xyd.mid.PROPHET_REPLACE, msg)
	self.btnReplace:SetActive(false)
	xyd.SoundManager.get():playSound(xyd.SoundID.REPLACE_SUCCESS)
end

function ProphetReplace:saveRequest()
	if not self.partner then
		return
	end

	local msg = messages_pb:prophet_replace_save_req()
	msg.partner_id = self.partner:getPartnerID()
	msg.is_save = 1

	xyd.Backend:get():request(xyd.mid.PROPHET_REPLACE_SAVE, msg)
	self.btnSave:SetActive(false)
	self.btnCancel:SetActive(false)
end

function ProphetReplace:setText()
	self.label_text01.text = __("PROPHET_TIP1")
	self.btnCancelLabel.text = __("PROPHET_BTN_CANCEL")
	self.btnSaveLabel.text = __("PROPHET_BTN_SAVE")
	self.btnReplaceLabel.text = __("PROPHET_BTN_REPLACE")

	if xyd.Global.lang == "de_de" or xyd.Global.lang == "en_en" or xyd.Global.lang == "fr_fr" then
		self.btnReplaceLabel:X(15)
	elseif xyd.Global.lang == "ja_jp" or xyd.Global.lang == "zh_tw" then
		self.btnReplaceLabel:X(10)
	elseif xyd.Global.lang == "ko_kr" then
		self.btnReplaceLabel:X(8)
	end
end

function ProphetReplace:setLayout()
	xyd.setUITextureAsync(self.imgBGTexture, "Textures/scenes_web/prophet_bg03")
	self.partnerCard1:loadResource()
	self.partnerCard1:setUIItemsVisible(false, false, false)
	self.partnerCard1:setDefaultCardVisible(false)
	self.partnerCard1:setHeroCardVisible(false)
	self.partnerCard2:loadResource()
	self.partnerCard2:setUIItemsVisible(false, false, false)
	self.partnerCard2:setDefaultCardVisible(false)
	self.partnerCard2:setHeroCardVisible(false)
	self.btnReplace:SetActive(false)
	self.btnSave:SetActive(false)
	self.btnCancel:SetActive(false)
	self.label_name1:SetActive(false)
	self.btn_detail:SetActive(false)

	self.btnReplaceCostImg.spriteName = xyd.tables.itemTable:getIcon(xyd.ItemID.BRANCH)
	self.btnReplaceCostLabel.text = 100

	self.btnReplaceTable:Reposition()

	self.partnerChoose = xyd.WindowManager.get():openWindow("prophet_choose_partner_window")

	self.partnerChoose.window_:SetActive(false)
end

function ProphetReplace:setModel(callback)
	local tableID = self.partner:getTableID()
	local modelID = 0

	if self.partner:getSkinId() ~= 0 then
		modelID = xyd.tables.equipTable:getSkinModel(self.partner.skin_id)
	else
		modelID = xyd.tables.partnerTable:getModelID(tableID)
	end

	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID)

	self.tipGroup:SetActive(false)
	self.partnerCard2:setInfo(nil, self.partner)
	self.partnerCard2:setUIItemsVisible(true, true, true)
	self.partnerCard2:setNameVisible(true, true)

	local animationCallback = nil

	function animationCallback()
		local onComplete = nil

		function onComplete()
			self.effect3_2:SetActive(false)

			if callback then
				callback()
			end

			if self.partner:getTableID() ~= tableID then
				return
			end

			self.effect2_2:SetActive(true)
			self.effect2_2:play("texiao", 0)
			self.model2:SetActive(true)
			self.model2:play("idle", 0)
		end

		if self.effect1.go.activeSelf then
			self.effect1:play("texiao02", 1, 1, function ()
				self.effect1:SetActive(false)

				if self.effect3_2 then
					self.effect3_2:SetActive(true)
					self.effect3_2:play("texiao", 1, 1, onComplete)
				end
			end)
		elseif self.effect3_2 then
			self.effect3_2:SetActive(true)
			self.effect3_2:play("texiao", 1, 1, onComplete)
		end
	end

	if self.model2 and self.model2:isValid() and self.model2:getName() == name then
		self.model2:SetActive(false)
		animationCallback()
	else
		self:startLoading(2)
		NGUITools.DestroyChildren(self.groupModel2.transform)

		self.model2 = xyd.Spine.new(self.groupModel2)

		self.model2:setInfo(name, function ()
			self.model2:SetLocalPosition(0, 0, -2)
			self.model2:SetLocalScale(scale, scale, 1)
			self.model2:setRenderTarget(self.groupModel2:GetComponent(typeof(UIWidget)), 2)
			self:stopLoading(2)
			animationCallback()
		end, true)
		self.model2:SetActive(false)
	end
end

function ProphetReplace:setReplaceModel(tableID)
	local name = xyd.tables.modelTable:getModelName(xyd.tables.partnerTable:getModelID(tableID))
	local scale = xyd.tables.modelTable:getScale(xyd.tables.partnerTable:getModelID(tableID))

	self:startLoading(1)

	local md = nil
	local model = xyd.Spine.new(self.groupModel1)

	NGUITools.DestroyChildren(self.groupModel1.transform)
	model:setInfo(name, function ()
		model:SetLocalPosition(0, 0, -1)
		model:SetLocalScale(scale, scale, 1)
		model:setRenderTarget(self.groupModel1:GetComponent(typeof(UIWidget)), 1)
		self:stopLoading(1)

		if not self.partner then
			return
		end

		local info = self.partner:getInfo()
		info.tableID = tableID
		info.skin_id = 0
		info.heroBg_slider = 0

		self.effect3_1:SetActive(true)
		self.effect3_1:play("texiao", 1, 1, function ()
			self.effect3_1:SetActive(false)
			self.effect2_1:SetActive(true)
			self.effect2_1:play("texiao", 0)
			model:SetActive(true)
			model:play("idle", 0)
			self:waitForTime(0.833, function ()
				if not self then
					return
				end

				self.partnerCard1:setNameVisible(true, true)
				self.btn_detail:SetActive(true)
				self.btnSave:SetActive(true)
				self.btnCancel:SetActive(true)
			end, nil)
		end)
		self.partnerCard1:setUIItemsVisible(true, false, true)
		self.partnerCard1:setInfo(info)
		self.partnerCard1:showCardEffect(1.333)
	end, true)
	model:SetActive(false)

	self.model1 = model
end

function ProphetReplace:setPartnerChoose()
	if self.replaceID then
		return
	end

	if self.partnerChoose then
		self.partnerChoose:setVisibleEase(true)
		self.partnerChoose:reset()
	end
end

function ProphetReplace:setReplacePartner(partner)
	self.partner = partner

	self.partnerChoose:setVisibleEase(false)
	self.btnReplace:SetActive(false)

	local data = xyd.tables.partnerReplaceTable:getCost(self.partner:getTableID())

	if not data then
		return
	end

	self.btnReplaceCostImg.spriteName = tostring(xyd.tables.itemTable:getIcon(data[1]))
	self.btnReplaceCostLabel.text = data[2]

	self.btnReplaceTable:Reposition()
	self.partnerCard1:setNameVisible(false)
	self.partnerCard1:setUIItemsVisible(false, false, false)
	self:setModel(function ()
		local info = {
			lev = self.partner:getLevel(),
			group = self.partner:getGroup(),
			star = self.partner:getStar()
		}

		self.partnerCard1:setInfo(info)
		self.partnerCard1:setUIItemsVisible(true, true, true)
		self.partnerCard1:setDefaultCardVisible(true)
		self.btnReplace:SetActive(true)
	end)

	if not self.effect5 and not self.effect5:isValid() then
		return
	end

	self.effect5:SetActive(true)
	self.effect5:play("texiao01", 1, 1, function ()
		self.effect5:play("texiao02", 0)
	end)
end

function ProphetReplace:reset2()
	self.partner = nil
	self.replaceID = nil

	self.partnerCard1:setUIItemsVisible(false, false, true)
	self.partnerCard1:setNameVisible(false)
	self.partnerCard1:setHeroCardVisible(false)
	NGUITools.DestroyChildren(self.groupModel1.transform)
	self.label_name1:SetActive(false)
	self.btnReplace:SetActive(false)
	self.btnSave:SetActive(false)
	self.btnCancel:SetActive(false)
	self.btn_detail:SetActive(false)
	xyd.WindowManager.get():closeWindow("prophet_choose_partner_window", function ()
		self.partnerChoose = xyd.WindowManager.get():openWindow("prophet_choose_partner_window")

		self.partnerChoose.window_:SetActive(false)
	end)
	self.effect2_1:SetActive(false)
	self.effect2_1:stop()
end

function ProphetReplace:setReplacePartner2(partner)
	self.partner = partner

	self.effect5:SetActive(true)
	self.effect5:play("texiao01", 1, 1, function ()
		self.effect5:play("texiao02", 0)

		local info = {
			lev = self.partner:getLevel(),
			group = self.partner:getGroup(),
			star = self.partner:getStar()
		}

		self.partnerCard1:setUIItemsVisible(true, true, true)
		self.partnerCard1:setInfo(info)
		self.partnerCard1:setDefaultCardVisible(true)
		self.btnReplace:SetActive(true)
	end)
end

function ProphetReplace:onReplaceSave(event)
	local replace_id = event.data.replace_id
	local partner_id = event.data.partner_id
	local is_save = event.data.is_save

	if not self.partner then
		self.partner = xyd.models.slot:getPartner(partner_id)
	end

	if is_save == 0 then
		local partner = self.partner

		self:reset2()
		self:setReplacePartner2(partner)

		return
	end

	local items = {
		{
			item_num = 1,
			item_id = replace_id
		}
	}

	xyd.alertItems(items, nil, __("ACQUIRE_AVATAR"))
	xyd.WindowManager.get():closeWindow("prophet_choose_partner_window", function ()
		self.partnerChoose = xyd.WindowManager.get():openWindow("prophet_choose_partner_window")

		self.partnerChoose.window_:SetActive(false)
	end)
	self:reset()
	self.effect1:SetActive(true)
	self.effect1:play("texiao01", 0)
end

function ProphetReplace:onReplace(event)
	local replace_id = event.data.replace_id
	local partner_id = event.data.partner_id
	self.replaceID = replace_id

	self.effect5:play("texiao03", 1, 1, function ()
		self.effect5:SetActive(false)
		self:setReplaceModel(replace_id)
	end)
end

function ProphetReplace:reset()
	self.partner = nil
	self.replaceID = nil

	self.partnerCard1:setUIItemsVisible(false, false, false)
	self.partnerCard2:setUIItemsVisible(false, false, false)
	self.partnerCard1:setHeroCardVisible(false)
	self.partnerCard2:setHeroCardVisible(false)
	self.partnerCard1:setNameVisible(false)
	self.partnerCard2:setNameVisible(false)
	NGUITools.DestroyChildren(self.groupModel1.transform)
	NGUITools.DestroyChildren(self.groupModel2.transform)

	self.model2 = nil
	self.model1 = nil

	self.tipGroup:SetActive(true)
	self.btnReplace:SetActive(false)
	self.btnSave:SetActive(false)
	self.btnCancel:SetActive(false)
	self.btn_detail:SetActive(false)

	if self.partnerChoose then
		self.partnerChoose:reset()
	end

	self.effect2_1:SetActive(false)
	self.effect2_1:stop()
	self.effect2_2:SetActive(false)
	self.effect2_2:stop()
end

function ProphetReplace:showPartnerInfo()
	if not self.replaceID then
		return
	end

	local lev = self.partner:getLevel()
	local grade = self.partner:getGrade()

	xyd.WindowManager:get():openWindow("partner_info", {
		table_id = self.replaceID,
		lev = lev,
		grade = grade
	})
end

function ProphetReplace:setResource()
	for i = 1, 5 do
		if self["groupEffect" .. i] then
			local params = {}

			if i == 5 then
				params.scaleX = 1.1
				params.sxaleY = 1.1
			end

			local effect = xyd.Spine.new(self["groupEffect" .. i])

			effect:setInfo(ProphetReplace.LoadResource[i], function ()
				if params then
					effect:SetLocalPosition(0, 0, i + 5)
					effect:SetLocalScale(params.scaleX, params.scaleY, 1)
					effect:setRenderTarget(self["groupEffect" .. i]:GetComponent(typeof(UIWidget)), i + 5)
				end
			end)
			effect:SetActive(false)

			self["effect" .. i] = effect
		elseif self["groupEffect" .. i .. "_1"] and self["groupEffect" .. i .. "_2"] then
			local groupEffect1 = self["groupEffect" .. i .. "_1"]
			local effect1 = xyd.Spine.new(groupEffect1)

			effect1:setInfo(ProphetReplace.LoadResource[i], function ()
				effect1:SetLocalScale(1, 1, 1)
				effect1:SetLocalPosition(0, 0, 6)
				effect1:setRenderTarget(groupEffect1:GetComponent(typeof(UIWidget)), 6)
			end)
			effect1:SetActive(false)

			self["effect" .. i .. "_1"] = effect1
			local groupEffect2 = self["groupEffect" .. i .. "_2"]
			local effect2 = xyd.Spine.new(groupEffect2)

			effect2:setInfo(ProphetReplace.LoadResource[i], function ()
				effect2:SetLocalScale(1, 1, 1)
				effect1:SetLocalPosition(0, 0, 7)
				effect2:setRenderTarget(groupEffect2:GetComponent(typeof(UIWidget)), 7)
			end)
			effect2:SetActive(false)

			self["effect" .. i .. "_2"] = effect2
		end
	end

	local partnerID = xyd.models.slot:getReplacePartner()
	local replaceID = xyd.models.slot:getReplaceTableID()

	if not partnerID or not replaceID or not xyd.models.slot:getPartner(partnerID) then
		local function callback()
			self.effect1:SetLocalScale(1, 1, 1)
			self.effect1:SetActive(true)
			self.effect1:play("texiao01", 0)
		end

		if self.effect1:isValid() then
			callback()
		else
			self.effect1.callback = callback
		end
	else
		self.replaceID = replaceID
		self.partner = xyd.models.slot:getPartner(partnerID)

		local function callback()
			self.effect1:SetLocalScale(1, 1, 1)
			self:setModel()
			self:setReplaceModel(replaceID)
		end

		if self.effect1:isValid() then
			callback()
		else
			self.effect1.callback = callback
		end
	end
end

function ProphetReplace:setVisibleEase(obj)
	obj:SetActive(true)

	local widget = obj:GetComponent(typeof(UIWidget))
	widget.alpha = 0
	local getter, setter = xyd.getTweenAlphaGeterSeter(widget)
	local action = self:getSequence()

	action:Append(DG.Tweening.DOTween.ToAlpha(getter, setter, 1, 0.3))
	action:AppendCallback(function ()
		action:Kill(false)

		action = nil
	end)
end

function ProphetReplace:onRemove()
	if self.eventProxy_ ~= nil then
		self.eventProxy_:removeAllEventListeners()

		self.eventProxy_ = nil
	end

	local wnd = xyd.WindowManager.get():getWindow("prophet_choose_partner_window")

	if wnd then
		wnd:close()
	end
end

function ProphetReplace:setEnable(bool)
end

function ProphetReplace:startLoading(type)
	if type > 2 then
		return
	end

	local action = self["loadingAction" .. tostring(type)]
	local img = self["loadingCircleImg" .. tostring(type)]

	self:playLoading(type)
end

function ProphetReplace:playLoading(type)
	if type > 2 then
		return
	end
end

function ProphetReplace:stopLoading(type)
end

ProphetReplace.LoadResource = {
	"fx_guanghuan",
	"fx_daiji",
	"fx_guangzhu",
	"fx_saomiao",
	"fx_wenhao"
}

return ProphetWindow
