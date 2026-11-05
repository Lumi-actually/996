/*
 * frida-996-skip-realname.js
 *
 * 目的：让 996 客户端认为账号已完成实名，跳过 RealNameActivity，直接进服务器列表。
 *
 * 依据（本轮实测 dump）：
 *   com.xqhy.login.bean.LoginBean
 *       F ageStatus : Integer
 *       M getAgeStatus() : Integer
 *       M setAgeStatus(Integer) : void
 *   com.xqhy.cloudphone.bean.SDKLoginResultBean
 *       F ageStatus : Integer
 *
 * 服务端下发的 ageStatus = 0（未实名）。本地 shared_prefs 的 xqhy_age_status 会被
 * 服务端覆盖，所以只能在这一层 hook。
 *
 * 用法：
 *   frida -U -n <进程> -l frida-996-skip-realname.js
 *   或者 python run-frida-996.py --attach --script ... --seconds 120
 */

'use strict';

const TAG = '[996-skip]';

function hookGetter(className, methodName, value) {
    try {
        const C = Java.use(className);
        if (!C[methodName]) {
            console.log(`${TAG} [miss] ${className}.${methodName}`);
            return false;
        }
        C[methodName].implementation = function () {
            let orig = null;
            try { orig = C[methodName].call(this); } catch (e) { }
            console.log(`${TAG} ${className}.${methodName}() → ${value}  (原始: ${orig})`);
            return Java.use('java.lang.Integer').valueOf(value);
        };
        console.log(`${TAG} [hook] ${className}.${methodName} → ${value}`);
        return true;
    } catch (e) {
        console.log(`${TAG} [fail] ${className}.${methodName}: ${e.message}`);
        return false;
    }
}

function hookSetter(className, methodName, value) {
    try {
        const C = Java.use(className);
        if (!C[methodName]) { console.log(`${TAG} [miss] ${className}.${methodName}`); return false; }
        C[methodName].implementation = function (v) {
            console.log(`${TAG} ${className}.${methodName}(${v}) → 强制 ${value}`);
            return C[methodName].call(this, Java.use('java.lang.Integer').valueOf(value));
        };
        console.log(`${TAG} [hook] ${className}.${methodName}(…) → ${value}`);
        return true;
    } catch (e) {
        console.log(`${TAG} [fail] ${className}.${methodName}: ${e.message}`);
        return false;
    }
}

/* 观察 RealNameActivity 是否还会被拉起；如果被拉起就直接 finish */
function watchRealNameActivity() {
    try {
        const RA = Java.use('com.xqhy.login.view.RealNameActivity');
        RA.onCreate.implementation = function (b) {
            console.log(`${TAG} RealNameActivity.onCreate 被调用 → 立即 finish 并尝试继续`);
            try {
                const Intent = Java.use('android.content.Intent');
                const AppAct = Java.use('org.cocos2dx.cpp.AppActivity');
                const it = Intent.$new(this, AppAct.class);
                it.addFlags(0x10000000); // FLAG_ACTIVITY_NEW_TASK
                this.startActivity(it);
                console.log(`${TAG} 已启动 AppActivity`);
            } catch (e) {
                console.log(`${TAG} 启动 AppActivity 失败: ${e.message}`);
            }
            this.finish();
        };
        console.log(`${TAG} [hook] RealNameActivity.onCreate → 跳过`);
        return true;
    } catch (e) {
        console.log(`${TAG} [fail] RealNameActivity: ${e.message}`);
        return false;
    }
}

setImmediate(() => {
    if (!Java.available) { console.log(`${TAG} Java 不可用`); return; }
    Java.perform(() => {
        console.log(`${TAG} ===== 开始安装 hook =====`);
        let n = 0;
        if (hookGetter('com.xqhy.login.bean.LoginBean', 'getAgeStatus', 1)) n++;
        if (hookSetter('com.xqhy.login.bean.LoginBean', 'setAgeStatus', 1)) n++;
        if (hookGetter('com.xqhy.cloudphone.bean.SDKLoginResultBean', 'getAgeStatus', 1)) n++;
        if (watchRealNameActivity()) n++;
        console.log(`${TAG} 安装完成，共 ${n} 个 hook。现在去点「立即登录」。`);
    });
});
