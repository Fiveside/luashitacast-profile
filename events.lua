-- Allows users to register callbacks to some formalized events.
local ffi = require('ffi');

-- LuAshitaCast doesn't recycle the lua vm on profile change, it just
-- reloads and re-executes the profile files.  So, this FFI definition
-- may still exist and re-defining it will throw an error.
-- This protects against such errors.

-- https://learn.microsoft.com/en-us/windows/win32/sysinfo/acquiring-high-resolution-time-stamps
if not pcall(ffi.typeof, "LARGE_INTEGER") then
    ffi.cdef [[
        typedef long long LONGLONG;
        typedef struct _LARGE_INTEGER {
            LONGLONG QuadPart;
        } LARGE_INTEGER;

        int QueryPerformanceCounter(LARGE_INTEGER *lpPerformanceCounter);
        int QueryPerformanceFrequency(LARGE_INTEGER *lpFrequency);
    ]];
end


-- Frequency is set once at system boot and stays constant after.
local PERFORMANCE_FREQUENCY = ffi.new("LARGE_INTEGER");
local PERFORMANCE_COUNTER = ffi.new("LARGE_INTEGER");

ffi.C.QueryPerformanceFrequency(PERFORMANCE_FREQUENCY);

---Return a performance timestamp with millisecond resolution
---@return number;
local function getPerfStamp()
    ffi.C.QueryPerformanceCounter(PERFORMANCE_COUNTER);

    -- Performance counter is in second resolution, and frequency is in the range of
    -- some hundred thousand or million.  This means we still have high resolution if
    -- we multiply here to obtain milliseconds or even microseconds.
    --
    -- Luajit extends the syntax to include LL and ULL suffixes for int64 and uint64
    -- Simple math operations on 64 bit integers don't cast down to float64.
    local stamp = PERFORMANCE_COUNTER.QuadPart;
    stamp = stamp * 1000LL;
    stamp = stamp / PERFORMANCE_FREQUENCY.QuadPart;

    -- this is obviously a number and not nil.
    local ret = tonumber(stamp);
    ---@cast ret -?
    return ret;
end


