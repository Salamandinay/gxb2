local ActivityContent = import(".ActivityContent")
local ShelterGiftBag = class("ShelterGiftBag", ActivityContent)
local cjson = require("cjson")
local float_delta_ = 5
local float_time_ = 1

function ShelterGiftBag:ctor(parentGO, params, parent)
	self.ids_ = xyd.tables.activityShelterGiftBagTable:getIDs()
	self.max_page = math.ceil(#self.ids_ * 1 / 3)
	self.cur_page = 1
	self.partnerIDGroup_ = {}
	self.pageList_ = {}

	for i = 1, self.max_page do
		table.insert(self.partnerIDGroup_, {})
	end

	for i = 1, #self.ids_ do
		local id = self.ids_[i]
		local index = math.floor((i - 1) / 3) + 1

		table.insert(self.partnerIDGroup_[index], id)
	end

	ShelterGiftBag.super.ctor(self, parentGO, params, parent)
end

function ShelterGiftBag:initUI()
	ShelterGiftBag.super.initUI(self)
	self:getUIComponent()
	self:initPages()
	self:layout()
	self:registScroll()
end

function ShelterGiftBag:getPrefabPath()
	return "Prefabs/Windows/activity/shelter_giftBag"
end

function ShelterGiftBag:getUIComponent()
	local goTrans = self.go.transform
	self.touchScroll_ = goTrans:NodeByName("touchScrollGroup").gameObject
	self.pageGrid_ = goTrans:ComponentByName("groupScroller/grid", typeof(UIGrid))
	self.centerOn_ = goTrans:ComponentByName("groupScroller/grid", typeof(UICenterOnChild))
	self.pageRoot_ = goTrans:NodeByName("groupScroller/grid/pageRoot").gameObject

	self.pageRoot_:SetActive(false)

	self.rootHeight = self.pageRoot_:GetComponent(typeof(UIWidget)).height
	self.imgText01_ = goTrans:ComponentByName("groupOther/imgText01", typeof(UITexture))
	self.helpBtn_ = goTrans:NodeByName("groupOther/helpBtn").gameObject
	self.endLabel_ = goTrans:ComponentByName("groupOther/endLabel", typeof(UILabel))
	self.timeLabel_ = goTrans:ComponentByName("groupOther/timeLabel", typeof(UILabel))
	self.leftPageBtn_ = goTrans:NodeByName("groupOther/leftPageBtn")
	self.RightPageBtn_ = goTrans:NodeByName("groupOther/RightPageBtn")
	self.tipsGroup_ = goTrans:NodeByName("groupOther/tipsGroup")
	self.itemFloatRoot_ = goTrans:NodeByName("groupOther/itemFloat").gameObject
	self.tipsGroupLabel_ = goTrans:ComponentByName("groupOther/tipsGroup/label", typeof(UILabel))

	if xyd.Global.lang == "de_de" then
		self.timeLabel_:X(-10)
		self.endLabel_:X(0)
	end
end

function ShelterGiftBag:initPages()
	for i = 1, self.max_page do
		local pageNewRoot = NGUITools.AddChild(self.pageGrid_.gameObject, self.pageRoot_)

		pageNewRoot:SetActive(true)
		self:getPageComponent(i, pageNewRoot)
		table.insert(self.pageList_, {
			root = pageNewRoot
		})
	end
end

function ShelterGiftBag:getPageComponent(pageNum, root)
	local rootrans = root.transform

	for i = 1, 3 do
		local partnerRoot = rootrans:NodeByName("partner_" .. i).gameObject
		self["partner" .. pageNum .. "_" .. i] = partnerRoot
		local index = (pageNum - 1) * 3 + i
		local id = self.ids_[index]
		local partnerId = xyd.tables.activityShelterGiftBagTable:getPartner(self.ids_[index])

		if not id or not partnerId then
			self["partner" .. pageNum .. "_" .. i]:SetActive(false)
		else
			self["partner" .. pageNum .. "_" .. i]:SetActive(true)

			self["partner" .. pageNum .. "_" .. i .. "_bgImgRoot"] = partnerRoot:NodeByName("bgImg")
			self["partner" .. pageNum .. "_" .. i .. "_bgImg"] = partnerRoot:ComponentByName("bgImg/bgImg", typeof(UISprite))
			self["partner" .. pageNum .. "_" .. i .. "_bgImg2"] = partnerRoot:ComponentByName("bgImg/bgImg2", typeof(UITexture))
			self["partner" .. pageNum .. "_" .. i .. "_bgImg3"] = partnerRoot:ComponentByName("bgImg/bgImg3", typeof(UISprite))
			self["partner" .. pageNum .. "_" .. i .. "_missionBtn"] = partnerRoot:ComponentByName("missionBtn", typeof(UISprite))
			self["partner" .. pageNum .. "_" .. i .. "_missionBtnLabel"] = partnerRoot:ComponentByName("missionBtn/button_label", typeof(UILabel))
			self["partner" .. pageNum .. "_" .. i .. "_itemRoot"] = partnerRoot:NodeByName("modelPanel/itemRoot").gameObject

			self:initPagePartner(pageNum, i)
			self:registBtnEvent(pageNum, i)
		end
	end
end

function ShelterGiftBag:registBtnEvent(pageNum, i)
	local index = (pageNum - 1) * 3 + i
	local id = self.ids_[index]
	local missionBtn = self["partner" .. pageNum .. "_" .. i .. "_missionBtn"]
	local label = self["partner" .. pageNum .. "_" .. i .. "_missionBtnLabel"]
	label.text = __("SHELTER_ACCEPT_MISSION")

	UIEventListener.Get(missionBtn.gameObject).onClick = function ()
		xyd.WindowManager.get():openWindow("activity_sheleter_mission_window", {
			id = id,
			parentContent = self
		})
	end
end

function ShelterGiftBag:getCurMissionBtn(id)
	local pageNum = math.floor((id - 1) / 3) + 1
	local i = (id - 1) % 3 + 1

	return self["partner" .. pageNum .. "_" .. i .. "_missionBtn"], self["partner" .. pageNum .. "_" .. i .. "_missionBtnLabel"]
end

function ShelterGiftBag:initPagePartner(pageNum, i)
	local p_height = self.go.transform.parent:GetComponent(typeof(UIPanel)).height

	if p_height >= 1047 then
		p_height = 1047
	end

	local index = (pageNum - 1) * 3 + i
	local id = self.ids_[index]
	local partnerId = xyd.tables.activityShelterGiftBagTable:getPartner(id)
	local path = xyd.tables.partnerPictureTable:getPartnerPic(partnerId)
	local partnerPic = self["partner" .. pageNum .. "_" .. i .. "_bgImg2"]
	path = xyd.PARTNER_PICTURE_PATH .. path
	local img1Name = xyd.tables.activityShelterGiftBagTable:getBg(id)

	xyd.setUISpriteAsync(self["partner" .. pageNum .. "_" .. i .. "_bgImg"], nil, img1Name)
	xyd.setUITextureAsync(partnerPic, path, function ()
		partnerPic:MakePixelPerfect()

		local img2Scale = xyd.tables.activityShelterGiftBagTable:getPicScale(id)
		local picOffset = xyd.tables.activityShelterGiftBagTable:getPicOffset2(index)

		partnerPic.transform:SetLocalScale(math.abs(img2Scale) * 0.68, math.abs(img2Scale) * 0.68, math.abs(img2Scale) * 0.68)
		partnerPic.transform:SetLocalPosition(picOffset[1], picOffset[2], 0)
	end)
	self:registerModelGroup(pageNum, i, partnerId)
end

function ShelterGiftBag:registerModelGroup(pageNum, i)
	local modelRoot = self["partner" .. pageNum .. "_" .. i .. "_itemRoot"]
	local index = (pageNum - 1) * 3 + i
	local id = self.ids_[index]
	local partner = xyd.tables.activityShelterGiftBagTable:getPartner(id)

	UIEventListener.Get(modelRoot).onClick = function ()
		if partner then
			xyd.WindowManager.get():openWindow("partner_info", {
				grade = 0,
				lev = 1,
				table_id = xyd.tables.activityShelterGiftBagTable:getPartner(id)
			})
		end
	end

	if partner then
		self:loadHerobyID(partner, modelRoot)
	else
		local effect = xyd.Spine.new(modelRoot)
		local spineName = xyd.tables.activityShelterGiftBagTable:getFix(id)

		effect:setInfo(spineName, function ()
			effect:play("idle", 0, 1)
		end, true)
	end
end

function ShelterGiftBag:loadHerobyID(heroID, root)
	local modelID = xyd.tables.partnerTable:getModelID(heroID)
	local name = xyd.tables.modelTable:getModelName(modelID)
	local scale = xyd.tables.modelTable:getScale(modelID) * xyd.tables.miscTable:getVal("shelter_model_scale")
	self["model_" .. heroID] = xyd.Spine.new(root)

	self["model_" .. heroID]:setInfo(name, function ()
		self["model_" .. heroID]:SetLocalPosition(0, 50, 10 * math.random())
		self["model_" .. heroID]:SetLocalScale(scale, scale, scale)
		self["model_" .. heroID]:setRenderTarget(root:GetComponent(typeof(UIWidget)), 1)
		self["model_" .. heroID]:play("idle", 0, 1)
	end, true)
end

function ShelterGiftBag:layout()
	xyd.setUITextureAsync(self.imgText01_, "Textures/activity_text_web/shelter_giftbag_text01_" .. xyd.Global.lang)
	self.eventProxyInner_:addEventListener(xyd.event.GET_ACTIVITY_AWARD, handler(self, self.onActivityAward))

	UIEventListener.Get(self.helpBtn_).onClick = function ()
		local params = {
			key = "SHELTER_GIFTBAG_HELP",
			title = __("SHELTER_GIFTBAG_HELP_TITLE")
		}

		xyd.WindowManager.get():openWindow("help_window", params)
	end

	UIEventListener.Get(self.RightPageBtn_.gameObject).onClick = function ()
		self:onPageChange(false, 1)
	end

	UIEventListener.Get(self.leftPageBtn_.gameObject).onClick = function ()
		self:onPageChange(false, -1)
	end

	print("self.activityData:getUpdateTime()")

	local updateTime = self.activityData:getUpdateTime()

	print(updateTime)

	if xyd.getServerTime() < updateTime then
		local params = {
			duration = updateTime - xyd.getServerTime()
		}
		self.endLabel_.text = __("END_TEXT")

		if not self.timeCount_ then
			self.timeCount_ = import("app.components.CountDown").new(self.timeLabel_, params)
		else
			self.timeCount_:setInfo(params)
		end
	end

	self.tipsGroupLabel_.text = __("SHELTER_TIPS")

	self.centerOn_:CenterOn(self.pageList_[self.cur_page].root.transform)
	self:checkTips()
	self:playPage()
	self:onPageChange(false, 0)
	self:registScroll()
end

function ShelterGiftBag:onActivityAward(event)
	if event.data.activity_id ~= xyd.ActivityID.SHELTER_GIFTBAG then
		return
	end

	local realData = cjson.decode(event.data.detail)

	for i = 1, #self.ids_ do
		local id = self.ids_[i]

		if realData.award_id == id then
			local curBtn, cur_btnLabel = self:getCurMissionBtn(id)

			self:setBtnStatus(curBtn, cur_btnLabel, false)
		end
	end

	local item = realData.awards

	xyd.itemFloat(item, nil, self.itemFloatRoot_, 6000)
end

function ShelterGiftBag:setBtnStatus(curBtn, cur_btnLabel, flag)
	curBtn.gameObject:GetComponent(typeof(UnityEngine.BoxCollider)).enabled = flag

	if not flag then
		xyd.applyChildrenGrey(curBtn.gameObject)

		cur_btnLabel.text = __("PUB_MISSION_COMPLETE")
	end
end

function ShelterGiftBag:updateMissionBtn(id)
	local cur_btn, cur_btnLabel = self:getCurMissionBtn(id)

	if not cur_btn then
		return
	end

	if (id - 1) % 3 + 1 > #self.partnerIDGroup_[self.cur_page] then
		cur_btn.gameObject:SetActive(false)

		return
	end

	self:setBtnStatus(cur_btn, cur_btnLabel, self:judgeMissionStatus(id))
end

function ShelterGiftBag:judgeMissionStatus(id)
	if self.activityData.detail.awarded[id] and self.activityData.detail.awarded[id] ~= 0 then
		return false
	else
		return true
	end
end

function ShelterGiftBag:onPageChange(needCheck, changeNum)
	if needCheck then
		xyd.db.misc:setValue({
			value = 1,
			key = "shelter_tips_" .. tostring(self.activityData:getUpdateTime())
		})
		self:checkTips()
	end

	if self.max_page < changeNum + self.cur_page then
		self.cur_page = self.max_page

		return
	elseif changeNum + self.cur_page < 1 then
		self.cur_page = 1

		return
	else
		self.cur_page = changeNum + self.cur_page
	end

	self.RightPageBtn_.gameObject:SetActive(self.cur_page < self.max_page)
	self.leftPageBtn_.gameObject:SetActive(self.cur_page > 1)
	self.centerOn_:CenterOn(self.pageList_[self.cur_page].root.transform)

	for i = 1, #self.ids_ do
		self:updateMissionBtn(self.ids_[i])
	end
end

function ShelterGiftBag:checkTips()
	local key = "shelter_tips_" .. tostring(self.activityData:getUpdateTime())

	if tonumber(xyd.db.misc:getValue(key) == 1 or self.max_page < 2) then
		self.tipsGroup_:SetActive(false)
	else
		self.tipsGroup_.transform:SetLocalScale(0.01, 0.01, 1)

		local action = DG.Tweening.DOTween.Sequence()

		table.insert(self.sequences_, action)
		action:Insert(0, self.tipsGroup_.transform:DOScale(Vector3(1.1, 1.1, 1), 0.3))
		action:Insert(0.3, self.tipsGroup_.transform:DOScale(Vector3(1, 1, 1), 0.3))
	end
end

function ShelterGiftBag:playPage()
	local positionLeft = -330
	local positionRight = 330

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end

	function self.playAni2_()
		self.sequence2_ = DG.Tweening.DOTween.Sequence()

		self.sequence2_:Insert(0, self.leftPageBtn_:DOLocalMoveX(positionLeft - 10, 1))
		self.sequence2_:Insert(1, self.leftPageBtn_:DOLocalMoveX(positionLeft + 10, 1))
		self.sequence2_:Insert(0, self.RightPageBtn_:DOLocalMoveX(positionRight + 10, 1))
		self.sequence2_:Insert(1, self.RightPageBtn_:DOLocalMoveX(positionRight - 10, 1))
		self.sequence2_:AppendCallback(function ()
			self.playAni1_()
		end)
	end

	function self.playAni1_()
		self.sequence1_ = DG.Tweening.DOTween.Sequence()

		self.sequence1_:Insert(0, self.leftPageBtn_:DOLocalMoveX(positionLeft - 10, 1))
		self.sequence1_:Insert(1, self.leftPageBtn_:DOLocalMoveX(positionLeft + 10, 1))
		self.sequence1_:Insert(0, self.RightPageBtn_:DOLocalMoveX(positionRight + 10, 1))
		self.sequence1_:Insert(1, self.RightPageBtn_:DOLocalMoveX(positionRight - 10, 1))
		self.sequence1_:AppendCallback(function ()
			self.playAni2_()
		end)
	end

	self.playAni1_()
end

function ShelterGiftBag:registScroll()
	UIEventListener.Get(self.touchScroll_).onDragStart = function ()
		self.hasMove_ = false
		self.delta_ = 0
	end

	UIEventListener.Get(self.touchScroll_).onDrag = function (go, delta)
		self.delta_ = self.delta_ + delta.x

		if self.delta_ > 100 and not self.hasMove_ then
			self.hasMove_ = true

			self:onPageChange(false, -1)
		end

		if self.delta_ < -100 and not self.hasMove_ then
			self.hasMove_ = true

			self:onPageChange(false, 1)
		end
	end

	UIEventListener.Get(self.touchScroll_).onDragEnd = function ()
		self.delta_ = 0
		self.hasMove_ = false
	end
end

function ShelterGiftBag:dispose()
	ShelterGiftBag.super.dispose(self)

	if self.sequence1_ then
		self.sequence1_:Kill(false)

		self.sequence1_ = nil
	end

	if self.sequence2_ then
		self.sequence2_:Kill(false)

		self.sequence2_ = nil
	end
end

return ShelterGiftBag
