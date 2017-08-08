local RO = RO

RO.UltList = {}
local UltList = RO.UltList

--========================================== LOCAL VARIABLES ===========================================================

local customUltimateIds = {

}



--========================================== LOCAL FUNCTIONS ===========================================================


--========================================= PUBLIC FUNCTIONS ===========================================================


function UltList.NewUltimate(ultimateId)

    return {
        ult = ultimateId,
        uptime = 0,
        time = GetTimeStamp(),
        pct = 0,
        Process = function(self,ultCoord)
            local time = GetTimeStamp()
            local data1, data2 = RO.Ping.SplitDecimal_4( ultCoord )
            local ultimate, number = RO.Ping.SplitDecimal_2( data1 )
            local pct = RO.Ping.RealPct( data2 )
            local uptime = self.uptime

            if pct < 100 then
                uptime = 0
            else
                uptime = uptime + 1
            end


            self.time = time
            self.pct = pct
        end

    }


end







