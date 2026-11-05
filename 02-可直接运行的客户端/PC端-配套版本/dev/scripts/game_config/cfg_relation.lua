local config = {
    [100] = {
        id=100,
        type_name="夫妻关系",
        func_desc="结为夫妻",
        sex_diff=1,
        maxCount=1,
        multistage=1,
        callCD=60,
        allowSwitch=1,
        sync_flag=1,
        mode_name="夫妻",
        filter_name="我的伴侣",
    },
    [101] = {
        id=101,
        type_name="师徒关系",
        func_desc="成为师徒",
        sex_diff=0,
        maxCount=5,
        multistage=0,
        callCD=60,
        allowSwitch=1,
        sync_flag=0,
        mode_name="师徒",
        filter_name="我的师父#我的同门#我的徒弟",
    },
}
return config
