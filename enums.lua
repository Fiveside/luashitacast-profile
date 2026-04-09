-- This is a lua reference of https://github.com/AshitaXI/Ashita-v4beta/blob/main/plugins/sdk/ffxi/enums.h
-- Not all enums have been copied over.
-- Enums should be added to this file as they are required

local Export = T{};

Export.LanguageId = {
    Default = 0,
    Japanese = 1,
    English = 2,
}

Export.JobMask = {
    None  = 0x00000000,
    WAR   = 0x00000002,
    MNK   = 0x00000004,
    WHM   = 0x00000008,
    BLM   = 0x00000010,
    RDM   = 0x00000020,
    THF   = 0x00000040,
    PLD   = 0x00000080,
    DRK   = 0x00000100,
    BST   = 0x00000200,
    BRD   = 0x00000400,
    RNG   = 0x00000800,
    SAM   = 0x00001000,
    NIN   = 0x00002000,
    DRG   = 0x00004000,
    SMN   = 0x00008000,
    BLU   = 0x00010000,
    COR   = 0x00020000,
    PUP   = 0x00040000,
    DNC   = 0x00080000,
    SCH   = 0x00100000,
    GEO   = 0x00200000,
    RUN   = 0x00400000,
    MON   = 0x00800000,
    JOB24 = 0x01000000,
    JOB25 = 0x02000000,
    JOB26 = 0x04000000,
    JOB27 = 0x08000000,
    JOB28 = 0x10000000,
    JOB29 = 0x20000000,
    JOB30 = 0x40000000,
    JOB31 = 0x80000000,

    AllJobs = 0x007FFFFE,
}

return Export;