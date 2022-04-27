local FortBtn = class("FortBtn")

function FortBtn:ctor(go, params)
	self.go = go
	self.id = params.id
	self.lastLv = params.lastLv
	self.maxLv = params.maxLv
	local transGo = go.transform
	self.lockGroup = transGo:Find("fort_lock")
	self.offGroup = transGo:Find("fort_off")
	self.onGroup = transGo:Find("fort_on")
	self.redMarkImg = transGo:ComponentByName("red_mark", typeof(UISprite))
	self.lockLabel = self.lockGroup:ComponentByName("lock_label", typeof(UILabel))
	self.offLabel = self.offGroup:ComponentByName("off_label", typeof(UILabel))
	self.onLabel = self.onGroup:ComponentByName("on_label", typeof(UILabel))

	self:initBtn()
end

function FortBtn:initBtn()
	self.offLabel.text = __("FORT_BTN_LABEL_" .. self.id)
	self.onLabel.text = __("FORT_BTN_LABEL_" .. self.id)
	self.lockLabel.text = __("FORT_BTN_LABEL_" .. self.id)

	if self.maxLv < self.id then
		self:setLvBtnLock()
	elseif self.id == self.lastLv then
		self:setLvBtnOn()
	else
		self:setLvBtnOff()
	end

	if self.id == self.maxLv and self.lastLv ~= self.maxLv then
		self:setRedMark(true)
	else
		self:setRedMark(false)
	end
end

function FortBtn:setLvBtnOn()
	self.onGroup:SetActive(true)
	self.offGroup:SetActive(false)
	self.lockGroup:SetActive(false)
end

function FortBtn:setLvBtnOff()
	self.onGroup:SetActive(false)
	self.offGroup:SetActive(true)
	self.lockGroup:SetActive(false)
end

function FortBtn:setLvBtnLock()
	self.onGroup:SetActive(false)
	self.offGroup:SetActive(false)
	self.lockGroup:SetActive(true)
end

function FortBtn:setRedMark(status)
	self.redMarkImg:SetActive(status)
end

function FortBtn:isLock()
	return self.maxLv < self.id
end

local FortItem = class("FortItem", import("app.components.CopyComponent"))

function FortItem:ctor(go, params)
	FortItem.super.ctor(self, go)

	self.fortTable = xyd.tables.fortTable
	self.stageTable = xyd.tables.stageTable
	self.mapModel = xyd.models.map
	self.go = go
	self.fortId = tonumber(params.fortId)
	self.currentFortID = tonumber(params.currentFortID)
	self.maxStage = tonumber(params.maxStage)
	self.posId = tonumber(params.posId)
	local transGo = go.transform
	self.nameLabel = transGo:ComponentByName("name_label", typeof(UILabel))
	self.fGroup = transGo:Find("f_group")
	self.maskGroup = transGo:Find("mask_group")
	self.unlockEffetGroup = transGo:Find("unlock_effet_group")
	self.fightEffetGroup = transGo:Find("fight_effet_group")
	self.fortImg = self.fGroup:ComponentByName("fort_img", typeof(UISprite))
	self.desLabel = self.fGroup:ComponentByName("des_label", typeof(UILabel))
	self.askImg = self.maskGroup:ComponentByName("ask_img", typeof(UISprite))
	self.maskImg = self.maskGroup:ComponentByName("mask_img", typeof(UISprite))
	self.lockImg = self.maskGroup:ComponentByName("lock_img", typeof(UISprite))

	self:initItem()
end

function FortItem:initItem()
	self.maxFortId = self.stageTable:getFortID(self.maxStage + 1)

	xyd.setUISprite(self.fortImg, xyd.Atlas.CAMPAIGIN_01, self.fortTable:getFortImgId(self.fortId))

	self.curName = self.fortTable:getName(self.fortId)
	self.curDesc = self.fortTable:getDesc(self.fortId)
	self.nameLabel.text = self.curName

	if self.fortId <= self.maxFortId then
		if self.fortId ~= self.maxFortId or self.currentFortID == self.maxFortId then
			self:unlock()
		else
			self:lock()
			self.lockImg:SetActive(false)
		end
	else
		self:lock()
	end

	UIEventListener.Get(self.go).onClick = handler(self, self.onClickFortItem)
end

function FortItem:lock()
	self.isLocked = true

	self.maskGroup:SetActive(true)
	self.fGroup:SetActive(false)

	self.nameLabel.text = "？？？"
	self.desLabel.text = ""
end

function FortItem:unlock()
	self.isLocked = false

	self.maskGroup:SetActive(false)
	self.fGroup:SetActive(true)

	self.nameLabel.text = self.fortTable:getName(self.fortId)
	self.desLabel.text = self.fortTable:getDesc(self.fortId)
end

function FortItem:onClickFortItem()
	if self.isLocked then
		return false
	elseif self.fortId == self.currentFortID then
		return false
	else
		local need_lv = self.stageTable:getLv(self.fortTable:getFirstStageId(self.fortId))

		if xyd.models.backpack:getLev() < need_lv then
			xyd.showToast(__("STAGE_LV_NOT_ENOUGH", need_lv))

			return
		end

		if self.fortId < self.currentFortID then
			xyd.alertYesNo(__("CHANGE_FORT"), function (yes_no)
				if yes_no then
					local firstStageId = self.fortTable:getFirstStageId(self.fortId)

					xyd.models.map:hang(firstStageId)
					xyd.closeWindow("campaign_fort_window")
					xyd.EventDispatcher.inner():dispatchEvent({
						name = xyd.event.HIGH_PRAISE
					})
				end
			end)
		else
			local firstStageId = self.fortTable:getFirstStageId(self.fortId)

			xyd.models.map:hang(firstStageId)
			xyd.closeWindow("campaign_fort_window")
			xyd.EventDispatcher.inner():dispatchEvent({
				name = xyd.event.HIGH_PRAISE
			})
		end
	end
end

function FortItem:addUnlockEffect(ifAll)
	if not ifAll then
		self:unlock()
	end

	if not self.suoxEffect then
		self.suoxEffect = xyd.Spine.new(self.unlockEffetGroup.gameObject)
	end

	self.suoxEffect:setInfo("suox", function ()
		self.suoxEffect:SetLocalPosition(0, 0, 0)
		self.suoxEffect:SetLocalScale(1, 1, 1)
		self.suoxEffect:play("texiao1", 1, 1, handler(self, function ()
			if ifAll then
				self:playUnlockAnimation()
			end
		end))
	end)
end

function FortItem:playUnlockAnimation()
	local sequence1 = self:getSequence()
	local w = self.maskGroup:GetComponent(typeof(UIWidget))

	sequence1:Append(xyd.getTweenAlpha(w, 0.01, 0.2))
	sequence1:AppendCallback(function ()
		self.maskGroup:SetActive(false)

		w.alpha = 1

		sequence1:Kill(false)

		sequence1 = nil
	end)

	local sequence2 = self:getSequence()
	local w2 = self.fGroup:GetComponent(typeof(UIWidget))
	w2.alpha = 0.01

	local function setter2(value)
		w2.alpha = value
	end

	local function setter3(value)
		local oldColor = self.nameLabel.color
		local newColor = Color.New(oldColor.r, oldColor.g, oldColor.b, value)
		self.nameLabel.color = newColor
	end

	local labelW = self.nameLabel:GetComponent(typeof(UIWidget))

	sequence2:Insert(0.1, xyd.getTweenAlpha(w2, 1, 0.3))
	sequence2:Insert(0.1, xyd.getTweenAlpha(labelW, 1, 0.3))
	sequence2:InsertCallback(0.1, function ()
		self.fGroup:SetActive(true)
	end)
	sequence2:AppendCallback(function ()
		self.nameLabel.alpha = 1
		self.nameLabel.text = ""

		self:playTextEffect()
		sequence2:Kill(false)

		sequence2 = nil
	end)
end

function FortItem:playTextEffect()
	self:playOneLabelAction(self.nameLabel, self.curName)
	XYDCo.WaitForTime(0.1 * #xyd.getColorLabelList(self.curName), function ()
		if tolua.isnull(self.desLabel) then
			return
		end

		self:playOneLabelAction(self.desLabel, self.curDesc, function ()
			self.isLocked = false
		end)
	end, nil)
end

function FortItem:playOneLabelAction(label, str, complete)
	if not str or str == "" or str == " " then
		if complete then
			complete()
		end

		return
	end

	local curStr = ""
	local curStrPos = 1
	local curStrList_ = xyd.getColorLabelList(str)

	local function callback()
		if tolua.isnull(label) then
			return
		end

		curStr = curStr .. curStrList_[curStrPos]
		label.text = curStr

		if curStrPos == #curStrList_ and complete then
			complete()
		end

		curStrPos = curStrPos + 1
	end

	local speed = 0.1
	local loop = #curStrList_
	local timer = Timer.New(callback, speed, loop)

	timer:Start()
end

function FortItem:playDianjiEffect()
	print("playDianjiEffect============")
end

function FortItem:addFightEffect()
	if not self.fightEffect then
		self.fightEffect = xyd.Spine.new(self.fightEffetGroup.gameObject)
	end

	self.fightEffect:setInfo("jianxg", function ()
		self.fightEffect:SetLocalPosition(0, 0, 0)
		self.fightEffect:SetLocalScale(1, 1, 1)
		self.fightEffect:play("texiao1", -1)
	end)
end

local CampaignFortWindow = class("CampaignFortWindow", import(".BaseWindow"))
local WindowTop = import("app.components.WindowTop")

function CampaignFortWindow:ctor(name, params)
	CampaignFortWindow.super.ctor(self, name, params)

	self.callback = nil
	self.mapModel = xyd.models.map
	self.stageTable = xyd.tables.stageTable
	self.fortTable = xyd.tables.fortTable

	if params and params.listener ~= nil then
		self.callback = params.listener
	end
end

function CampaignFortWindow:initWindow()
	CampaignFortWindow.super.initWindow(self)

	local winTrans = self.window_.transform
	local bgGroup = winTrans:Find("bg_group")
	self.bgUpImg = bgGroup:ComponentByName("bg_up", typeof(UISprite))
	self.bgDownImg = bgGroup:ComponentByName("bg_down", typeof(UISprite))
	self.mainGroup = winTrans:Find("main")
	self.dragScrollView = self.mainGroup:ComponentByName("drag", typeof(UIDragScrollView))
	self.fortScroller = self.mainGroup:ComponentByName("fort_scroller", typeof(UIScrollView))
	self.fortListGrid = self.mainGroup:ComponentByName("fort_scroller/fort_list_grid", typeof(UIGrid))
	self.fortItem = self.mainGroup:Find("fort_item")

	self.fortItem:SetActive(false)

	self.fortBtnLeft = winTrans:Find("fort_btn_left")
	self.fortBtnMid = winTrans:Find("fort_btn_mid")
	self.fortBtnRight = winTrans:Find("fort_btn_right")

	self.fortBtnLeft:SetActive(false)
	self.fortBtnMid:SetActive(false)
	self.fortBtnRight:SetActive(false)

	self.buttonsGroup = winTrans:Find("buttons_group")
	self.windowTop = WindowTop.new(self.window_, self.name_, 3)
	local items = {
		{
			hidePlus = 1,
			id = xyd.ItemID.PARTNER_EXP
		},
		{
			id = xyd.ItemID.MANA
		}
	}

	self.windowTop:setItem(items)
	self.windowTop:setTitle(__("BIG_MAP"))

	self.mapInfo = self.mapModel:getMapInfo(xyd.MapType.CAMPAIGN)
	self.currentStage = self.mapInfo.current_stage

	if self.currentStage == 0 then
		self.currentStage = 1
	end

	self.currentFortID = self.stageTable:getFortID(self.currentStage)
	self.hangTime = self.mapInfo.hang_time
	self.maxStage = self.mapInfo.max_stage

	if self.maxStage == 0 then
		self.maxStage = 1
	end

	self.currentLv = self.fortTable:getLv(self.currentFortID)
	self.lastLv = self.currentLv
	local atlas = xyd.Atlas.CAMPAIGIN_02

	xyd.setUISpriteAsync(self.bgUpImg, atlas, "fort_bg_" .. tostring(self.lastLv) .. "_up")
	xyd.setUISpriteAsync(self.bgDownImg, atlas, "fort_bg_" .. tostring(self.lastLv) .. "_down")
	self:initLvButton()
	self:initFortList(self.currentLv)
	self:waitForFrame(1, function ()
		self.fortScroller:ResetPosition()
	end)
end

function CampaignFortWindow:initLvButton()
	NGUITools.DestroyChildren(self.buttonsGroup)

	local maxLv = self.fortTable:getLv(self.stageTable:getFortID(self.stageTable:getNextStage(self.maxStage)))
	self.fortBtnList = {}

	for i = 1, 5 do
		local btnGo = nil

		if i > 1 and i < 5 then
			btnGo = self.fortBtnMid.gameObject
		elseif i == 1 then
			btnGo = self.fortBtnLeft.gameObject
		elseif i == 5 then
			btnGo = self.fortBtnRight.gameObject
		end

		local go = NGUITools.AddChild(self.buttonsGroup.gameObject, btnGo)

		go:SetActive(true)

		go.name = "fort_btn_" .. i
		local fortBtnParams = {
			id = i,
			lastLv = self.lastLv,
			maxLv = maxLv
		}
		local fortBtn = FortBtn.new(go, fortBtnParams)

		table.insert(self.fortBtnList, fortBtn)

		UIEventListener.Get(go).onClick = handler(self, function ()
			if self.lastLv == i then
				return
			end

			local fortBtn = self.fortBtnList[i]
			local lastFortBtn = self.fortBtnList[self.lastLv]

			fortBtn:setRedMark(false)

			if fortBtn:isLock() then
				xyd.showToast(__("CAMPAIGN_LOCKING"))

				return
			end

			fortBtn:setLvBtnOn()
			lastFortBtn:setLvBtnOff()
			self:onClickLvBtn(i)

			self.lastLv = i
			local atlas = xyd.Atlas.CAMPAIGIN_02

			xyd.setUISpriteAsync(self.bgUpImg, atlas, "fort_bg_" .. tostring(self.lastLv) .. "_up")
			xyd.setUISpriteAsync(self.bgDownImg, atlas, "fort_bg_" .. tostring(self.lastLv) .. "_down")
		end)
	end
end

function CampaignFortWindow:onClickLvBtn(lv)
	if self.lastLv == lv then
		return
	end

	self:initFortList(lv)
end

function CampaignFortWindow:initFortList(lv)
	NGUITools.DestroyChildren(self.fortListGrid.transform)

	local fortIds_ = self.fortTable:getLvFortIds(lv)
	local selectedId = 0
	local maxHeight = 0
	self.currentFortItem = nil
	self.maxFortItem = nil
	self.maxFortId = self.stageTable:getFortID(self.maxStage + 1)
	self.fortItemList = {}

	for id in ipairs(fortIds_) do
		local fortId = fortIds_[id]
		local go = NGUITools.AddChild(self.fortListGrid.gameObject, self.fortItem.gameObject)

		go:SetActive(true)

		go.name = "fort_item_" .. id
		local fortParams = {
			fortId = fortId,
			currentFortID = self.currentFortID,
			maxStage = self.maxStage,
			posId = tonumber(id)
		}
		local fortItem = FortItem.new(go, fortParams)

		table.insert(self.fortItemList, fortItem)

		if tonumber(fortId) == self.currentFortID then
			selectedId = tonumber(id)
			self.currentFortItem = fortItem
		end

		if tonumber(fortId) == self.maxFortId then
			self.maxFortItem = fortItem
		end
	end

	self.fortListGrid:Reposition()
	self.fortScroller:ResetPosition()

	if self.currentFortID ~= self.maxFortId and self.maxFortItem then
		local ifAll = false
		local maxStage = xyd.models.map:getMapInfo(xyd.MapType.CAMPAIGN).max_stage

		if xyd.tables.stageTable:getFortFinal(maxStage) >= 1 then
			ifAll = true
		end

		self.maxFortItem:addUnlockEffect(ifAll)
	end

	if self.currentFortItem then
		self.currentFortItem:addFightEffect()
	end
end

function CampaignFortWindow:willClose()
	CampaignFortWindow.super.willClose(self)
end

return CampaignFortWindow
