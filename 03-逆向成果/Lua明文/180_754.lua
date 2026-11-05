local config = {
    [1] = {
        ID=1,
        Condition="U1 == 1",
    },
    [2] = {
        ID=2,
        Condition="<T1#VIP等级> == 123",
    },
    [3] = {
        ID=3,
        Condition="<LEVEL> >= 10",
    },
    [4] = {
        ID=4,
        Condition="<N$无用变量> == 1",
    },
    [5] = {
        ID=5,
        Condition="<RELEVEL> <= 100",
    },
    [6] = {
        ID=6,
        Condition="<RELEVEL> <= 100 & <LEVEL> >= 10",
    },
    [7] = {
        ID=7,
        Condition="<CONDITION,1> & <LEVEL> == 10",
    },
    [8] = {
        ID=8,
        Condition="<CONDITION,1> | <CONDITION,2>",
    },
    [9] = {
        ID=9,
        Condition="<ITEM_COUNT,1> > 20",
    },
}
return config
