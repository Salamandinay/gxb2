local ActivityCrystalBallLAFWindow = class("ActivityCrystalBallLAFWindow", import(".BaseWindow"))

function ActivityCrystalBallLAFWindow:ctor(name, params)
	ActivityCrystalBallLAFWindow.super.ctor(self, name, params)

	self.activityData = xyd.models.activity:getActivity(xyd.ActivityID.CRYSTAL_BALL)
	self.effectList_ = {}
end

function ActivityCrystalBallLAFWindow:initWindow()
	ActivityCrystalBallLAFWindow.super.initWindow(self)
	self:getComponent()
	self:initLayout()
	self:register()
	self:updateLayout()
end

function ActivityCrystalBallLAFWindow:playOpenAnimation()
	ActivityCrystalBallLAFWindow.super.playOpenAnimation(self, function ()
		local seq = self:getSequence()
		local goTrans = self.window_:NodeByName("groupAction")

		seq:Insert(0, goTrans:DOLocalMove(Vector3(0, 0, 0), 0.4))
	end)
end

function ActivityCrystalBallLAFWindow:register()
	self.eventProxy_:addEventListener(xyd.event.CRYSTAL_BALL_READ_PLOT, handler(self, self.updateLayout))
end

function ActivityCrystalBallLAFWindow:getComponent()
	local goTrans = self.window_:NodeByName("groupAction")
	self.tltleLabel_ = goTrans:ComponentByName("titleBg/tltleLabel", typeof(UILabel))
	self.descLabel_ = goTrans:ComponentByName("descPart/descLabel", typeof(UILabel))
	self.tipsLabel_ = goTrans:ComponentByName("tipsLabel", typeof(UILabel))

	for i = 1, 5 do
		self["laf_item" .. i] = goTrans:NodeByName("contentPart/laf_Item" .. i).gameObject
		self["laf_item" .. i .. "itemImg"] = self["laf_item" .. i]:NodeByName("itemImg").gameObject
		self["laf_item" .. i .. "redPoint"] = self["laf_item" .. i]:NodeByName("redPoint").gameObject
		self["laf_item" .. i .. "finishIcon"] = self["laf_item" .. i]:NodeByName("finishIcon").gameObject
		self["laf_item" .. i .. "effectNode"] = self["laf_item" .. i]:NodeByName("effectNode").gameObject
	end
end

function ActivityCrystalBallLAFWindow:initLayout()
	self.tltleLabel_.text = __("ACTIVITY_CRYSTAL_BALL_TEXT01")
	self.descLabel_.text = __("ACTIVITY_CRYSTAL_BALL_TEXT05")
	self.tipsLabel_.text = __("LOGIN_HANGUP_TEXT04")

	for i = 1, 5 do
		UIEventListener.Get(self["laf_item" .. i]).onClick = function ()
			local lafData = self.activityData:getLafData()

			if lafData[i].is_finish then
				xyd.alertTips(__("ACTIVITY_CRYSTAL_BALL_TEXT07"))

				return
			end

			xyd.WindowManager.get():openWindow("activity_crystal_ball_qa_window", {
				id = i
			})
		end
	end
end

function ActivityCrystalBallLAFWindow:updateLayout()
	local lafData = self.activityData:getLafData()

	for _, laf in ipairs(lafData) do
		local id = laf.id

		if not laf.canShow then
			self["laf_item" .. id]:SetActive(false)
		else
			self["laf_item" .. id]:SetActive(true)
			self["laf_item" .. id .. "finishIcon"]:SetActive(laf.is_finish)
			self["laf_item" .. id .. "redPoint"]:SetActive(not laf.is_finish)
		end
	end

	for i = 1, 5 do
		local laf = lafData[i]

		if not laf.is_finish then
			if not self.effectList_[i] then
				self.effectList_[i] = xyd.Spine.new(self["laf_item" .. i .. "effectNode"])
			end

			self.effectList_[i]:SetActive(true)
			self.effectList_[i]:setInfo("fx_ui_dianji", function ()
				self.effectList_[i]:play("texiao01", 0)
			end)

			break
		elseif self.effectList_[i] then
			self.effectList_[i]:SetActive(false)
		end
	end
end

return ActivityCrystalBallLAFWindow
