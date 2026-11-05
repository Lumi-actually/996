local config = {
    [1] = {
        ID=1,
        Condition="<U1> < 1",
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
        Condition="<N$无限变量> == 1",
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
        Condition="<ITEM_COUNT,2> >= 1000 | <ITEM_COUNT,2000> >= 1",
    },
    [10] = {
        ID=10,
        Condition="<{6}> == 1",
    },
    [11] = {
        ID=11,
        Condition="<HUMAN(变量)> >= 1",
    },
    [12] = {
        ID=12,
        Condition="<HUMAN(变NIL量)> == nil | <HUMAN(变NIL量)> == 0",
    },
    [13] = {
        ID=13,
        Condition="<HUMAN(变NIL量)>+0 == 0",
    },
    [14] = {
        ID=14,
        Condition="<ITEM_COUNT,2>+<ITEM_COUNT,4>+<ITEM_COUNT,20> >= 1000",
    },
    [15] = {
        ID=15,
        Condition="<ITEM_COUNT,3000>+<ITEM_COUNT,5000>+<ITEM_COUNT,8000> >= 1000",
    },
    [16] = {
        ID=16,
        Condition="<HUMAN(变量)>+<N$变量>-<U10>-<HUMAN(变量3)> <= 100",
    },
    [17] = {
        ID=17,
        Condition="<N$变量>+<HUMAN(变量)> == 100 & <N$变量>+<HUMAN(变量)>+<U6> > 100 & <HUMAN(变1量)>+<N$变1量>+<U6>-<HUMAN(变2量)> <= 100",
    },
    [18] = {
        ID=18,
        Condition="<N$1变量>-<N$2变量> >= 1",
    },
    [19] = {
        ID=19,
        Condition="(<U1> >= 1 & <U2> == 1) |(<U3> >= 1 & <U4> == 1)",
    },
    [20] = {
        ID=20,
        Condition="<CONDITION,21> | <CONDITION,22>| <CONDITION,23>",
    },
    [21] = {
        ID=21,
        Condition="<CONDITION,31> | <CONDITION,32>| <CONDITION,33>",
    },
    [22] = {
        ID=22,
        Condition="<CONDITION,34> | <CONDITION,35>| <CONDITION,36>",
    },
    [23] = {
        ID=23,
        Condition="<CONDITION,37> | <CONDITION,38>| <CONDITION,39>",
    },
    [24] = {
        ID=24,
        Condition="<N$1变量>~=0",
    },
    [25] = {
        ID=25,
        Condition="<N$1变量>+0<1",
    },
    [26] = {
        ID=26,
        Condition="<N$1变量>-<N$2变量>~=1",
    },
    [27] = {
        ID=27,
        Condition="<HUMAN(值NIL变量)> == 0 & <HUMAN(变1量)> >= 1 & <ITEM_COUNT,2> >= 9",
    },
    [28] = {
        ID=28,
        Condition="(<HUMAN(值NIL变量)> == 0 | <HUMAN(值NIL变量)> == nil) & <HUMAN(变1量)> >= 1 & <ITEM_COUNT,2> >= 9",
    },
    [29] = {
        ID=29,
        Condition="(<HUMAN(值NIL变量)>==0|<HUMAN(值NIL变量)>==nil)&<HUMAN(变1量)>>=1&<ITEM_COUNT,2>>=9",
    },
    [30] = {
        ID=30,
        Condition="<HUMAN(值NIL变量)>+0==0&<HUMAN(变1量)>>=1&<ITEM_COUNT,2>>=9",
    },
    [31] = {
        ID=31,
        Condition="<T3#31> == nil & <ITEM_COUNT,31131> >= 1",
    },
    [32] = {
        ID=32,
        Condition="<T3#32> == nil & <ITEM_COUNT,31132> >= 1",
    },
    [33] = {
        ID=33,
        Condition="<T3#33> == nil & <ITEM_COUNT,31133> >= 1",
    },
    [34] = {
        ID=34,
        Condition="<T3#34> == nil & <ITEM_COUNT,31134> >= 1",
    },
    [35] = {
        ID=35,
        Condition="<T3#35> == nil & <ITEM_COUNT,31135> >= 1",
    },
    [36] = {
        ID=36,
        Condition="<T3#36> == nil & <ITEM_COUNT,31136> >= 1",
    },
    [37] = {
        ID=37,
        Condition="<T3#37> == nil & <ITEM_COUNT,31137> >= 1",
    },
    [38] = {
        ID=38,
        Condition="<T3#38> == nil & <ITEM_COUNT,31138> >= 1",
    },
    [39] = {
        ID=39,
        Condition="<T3#39> == nil & <ITEM_COUNT,31139> >= 1",
    },
    [40] = {
        ID=40,
        Condition="<EQUIPBYPOS,1> == 屠龙",
    },
    [41] = {
        ID=41,
        Condition="<EQUIP_DATA,1>.Index == 30028",
    },
    [42] = {
        ID=42,
        Condition="<MONEY_ASSOCIATED,29> >= 1500",
    },
    [43] = {
        ID=43,
        Condition="<MONEY,29> >= 1000",
    },
}
return config
