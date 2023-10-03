-- Generates percentage statistics of 3GPP-Reporting-Reason,  for example
--
-- FINAL (2) - 381 (8.2129769346842 %)
-- QHT (1) - 267 (5.7555507652511 %)
-- VALIDITY_TIME (4) - 3632 (78.292735503341 %)
-- QUOTA_EXHAUSTED (3) - 359 (7.7387367967234 %)


--
-- Lua functions for the  Plugin.
--

plugin_version = "1.0.0"
year = "2020"

--
-- Display version info for Wireshark
--
local plugin_info = {
  version = plugin_version,
  author = "Jarek Hartman",
  repository = "https://jhartman.pl"
}

set_plugin_info(plugin_info)

-- 
-- Configuration
--

local histogramSteps = 25

local win = nil

--
-- Display plugin message. This will either go to the
-- GUI text window or just print to stdout.
--

function message(message)
    -- handle either gui or non gui mode
    if gui_enabled() == true and win ~= nil then
        -- declare window if not yet there
        if win == nil then
            statistics_win()
        end
        win:append(message .. '\n')
     else
        print(message)
     end
end

function median (numlist)
    if type(numlist) ~= 'table' then return numlist end
    if #numlist == 0 then return 0 end
    table.sort(numlist)
    if #numlist %2 == 0 then return (numlist[#numlist/2] + numlist[#numlist/2+1]) / 2 end
    return numlist[math.ceil(#numlist/2)]
end

function average (numlist)
    if type(numlist) ~= 'table' then return numlist end
    if #numlist == 0 then return 0 end
    
    local total = 0
    
    for index, value in ipairs(numlist) do
        total = total + value
    end
    
    return total / #numlist
end

function min(numlist)
    if type(numlist) ~= 'table' then return numlist end 
    if #numlist == 0 then return 0 end
    
    local number = nil
    
    for index, value in ipairs(numlist) do
        if number == nil then  
            number = value
        end
        if value <= number then
            number = value
        end
    end
    
    return number
end

function max(numlist)
    if type(numlist) ~= 'table' then return numlist end 
    if #numlist == 0 then return 0 end
    
    local number = 0
    
    for index, value in ipairs(numlist) do
        if value >= number then
            number = value
        end
    end
    
    return number
end

function histogram(numlist)
    local histo = {}
    local maximum = max(numlist)
    local factor = 1024*1024
    
    local stepSize = maximum / histogramSteps
    
    for i = 1, histogramSteps do
        histo[i] = 0
    end
    
    
    for index, value in ipairs(numlist) do
        local step = math.ceil(value / stepSize)
        histo[step] = histo[step] + 1 or 0
    end
    
    message("Histogram of USU (Validity-Time)")
    
    local currentStep = 0
    for index, value in ipairs(histo) do
        message(string.format("%2d: %9d MB - %9d MB : %6d (%3.2f %%)", index, currentStep/factor, (currentStep + stepSize+1)/factor, value , value/(#numlist)*100))
        currentStep = currentStep + stepSize
    end        
end


--
-- Output window
--

local function statistics_win()
    -- Declare the window we will use
    win = TextWindow.new("Diameter Statistics")
    
    local function remove()
        -- this way we remove the listener that otherwise will remain running indefinitely
        tap:remove();
    end
    
    win:set_atclose(remove)
end

local function report(reportingReasons, totalOctets, total)

    if (totalOctets == nil) then
        message('')
        message('--------------------------------------')
        message("Result Codes:")
    else
        message('--------------------------------------')
        message("Reporting Reasons:")
    end

    for k, v in pairs(reportingReasons) do
        local percentage = string.format("%.3f", (tostring(v)/total*100))
        message(string.format("%-30s", k) .. " - " .. tostring(v) .. ' \t\t(' .. percentage .. ' %)')
    end
    message('')
    message(string.format("%-30s", 'Total') .. " - " .. tostring(total) .. ' \t\t(' .. 100 .. ' %)')
    
    message('')
    
    if not (totalOctets == nil) then
        message("USU (octets) when VALIDITY_TIME (4)")

        local median  = median(totalOctets)
        local average =  average(totalOctets)
        local min = min(totalOctets)
        local max = max(totalOctets)
    
        message(string.format("Median  : %d octets, %.2f kB", median, median / 1024))
        message(string.format("Average : %d octets, %.2f kB", average, average / 1024))
        message(string.format("Min     : %d octets", min))
        message(string.format("Max     : %d octets, %.2f kB", max, max / 1024))
    end
    
    

    -- histogram(totalOctets)
end


------------------------------------
--
-- Here start of the plugin
--
------------------------------------

do
    local rrField = Field.new("diameter.3GPP-Reporting-Reason")
    local toField = Field.new("diameter.CC-Total-Octets")
    local rcField = Field.new("diameter.Result-Code")
    local total = 0
    local totalRC = 0

    local function init_listener()
        -- Hash of reportingReasons
        local reportingReasons = {}
        local resultCodes = {}
        local totalOctets = {}
        local filter = 'diameter.3GPP-Reporting-Reason'

        if gui_enabled() then
            statistics_win()
        end
        
        message("Registering Listener")
        tap = Listener.new("diameter")
        
        -- this function will be called once for each packet
        function tap.packet(pinfo, tvb, tapdata)
            
            local rrFields = {rrField()}
            local toFields = {toField()}
            
            -- print(string.format("Loop begins for #rrFields: %d, #toFields %d", #rrFields, #toFields))
            
            for index, _ in pairs(rrFields) do 
                local to = 0
                
                -- Retrieve Reporting Reason and corresponing Total-Octets
                -- Note, this may *not* always work
                
                local rr = rrFields[index].display
                
                if index <= #toFields then
                    to = toFields[index].display
                end
                
                -- print(string.format("    %s - %s - %s (octets)", index, rr, to))
                
                reportingReasons[rr] = (reportingReasons[rr] or 0 ) + 1
                
                if rr == 'VALIDITY_TIME (4)' and to ~= nil then
                    -- print(string.format("%d - %d", pinfo.number, to))
                    -- print("RR:" .. rr)
                    table.insert(totalOctets, tonumber(to))
                end
                
                total = total + 1
            end
        end
        
        
--------------------------------------

        local filterRC = 'diameter.Result-Code'
        
        tap = Listener.new("diameter", filterRC)
        
        -- this function will be called once for each packet
        function tap.packet(pinfo, tvb, tapdata)
            
            local rcFields = {rcField()}
            
            for indexRC, _ in pairs(rcFields) do 
                local to = 0
                
                local rc = rcFields[indexRC].display
                
                if indexRC <= #rcFields then
                    to = rcFields[indexRC].display
                end
                
                resultCodes[rc] = (resultCodes[rc] or 0 ) + 1
                
                totalRC = totalRC + 1
            end
        end

-----------------------------        
        
        
        
        function tap.draw(t)
            if gui_enabled() then
                win:clear()
                if total > 0 then
                    report(reportingReasons, totalOctets, total)
                    report(resultCodes, nil, totalRC)
                end
            end
        end
        
        -- a listener tap's reset function is called at the end of a live capture run,
        -- when a file is opened, or closed.  TShark never appears to call it.
        function tap.reset()
            if gui_enabled() and win ~= nil then
                win:clear()
            end
            
            report(reportingReasons, totalOctets, total)
            report(resultCodes, nil, totalRC)

            reportingReasons = {}
            totalOctets = {}
            total = 0
        end
        
        if gui_enabled() then
            retap_packets()
        end
    end

    if gui_enabled() == true then
        -- Starting in GUI mode
        register_menu("Statistics/Diameter Statistics", init_listener, MENU_TOOLS_UNSORTED)
        -- Call the init function to get things started.
    else
        message("Starting in command-line mode")
        -- Call the init function to get things started.
        init_listener()
    end
end
